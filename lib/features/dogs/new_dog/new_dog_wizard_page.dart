import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format_it.dart';
import '../../../data/data_providers.dart';
import '../../../data/models/shelter_box.dart';
import '../../../data/models/volunteer.dart';
import '../../../data/photos/photo_codec.dart';
import '../../../data/photos/photo_limit.dart';
import '../../auth/auth_providers.dart';
import '../../../router.dart';
import '../../../ui/components.dart';
import '../../../ui/tokens.dart';
import '../../dashboard/home_providers.dart';
import '../dog_labels.dart';
import '../../volunteers/volunteer_labels.dart';
import '../dog_profile_fields.dart';
import '../dog_profile_pickers.dart';
import '../dogs_providers.dart';
import 'new_dog_draft.dart';
import 'new_dog_providers.dart';
import 'new_dog_submit.dart';
import 'new_dog_treatment_sheet.dart';
import 'new_dog_validation.dart';

const _testSanitari = ['Leishmania', 'Filaria', 'Ehrlichia'];

// ── CONTRATTO DI LAYOUT · Nuovo cane (wizard 3 passaggi) ───────────────────
// AppScaffold compactHeader  NESSUNA bottom nav  NESSUN FAB
// └ AppHeader h=40  «Nuovo cane · n di 3»  «Salva bozza»
// └ Padding 12 0 0 12  Row 3 barre h=4 gap=6
// └ Expanded ListView padding=12  gap 9 fra FormCard
//    STEP 1  Anagrafica · Identificazione · Provenienza (+ referente) · Continua
//    STEP 2  Foto · Presentazione · Carattere · Indietro | Continua
//    STEP 3  Sanitario · Adozione · Riepilogo · Indietro | Crea profilo
// ───────────────────────────────────────────────────────────────────────────

class NewDogWizardPage extends ConsumerStatefulWidget {
  const NewDogWizardPage({super.key});

  static const nomeKey = Key('new-dog-nome');
  static const microchipKey = Key('new-dog-microchip');
  static const scanKey = Key('new-dog-scan');
  static const continuaKey = Key('new-dog-continua');
  static const indietroKey = Key('new-dog-indietro');
  static const creaKey = Key('new-dog-crea');
  static const salvaBozzaKey = Key('new-dog-salva-bozza');
  static const fotoKey = Key('new-dog-foto');

  @override
  ConsumerState<NewDogWizardPage> createState() => _NewDogWizardPageState();
}

class _NewDogWizardPageState extends ConsumerState<NewDogWizardPage> {
  final _nome = TextEditingController();
  final _razza = TextEditingController();
  final _peso = TextEditingController();
  final _mantello = TextEditingController();
  final _microchip = TextEditingController();
  final _provenienza = TextEditingController();
  final _dataNascita = TextEditingController();
  final _dataIngresso = TextEditingController();
  final _dataSterilizzazione = TextEditingController();
  final _slogan = TextEditingController();
  final _descrizione = TextEditingController();
  final _noteCarattere = TextEditingController();
  final _terapie = TextEditingController();

  var _draft = const NewDogDraft();
  final _photos = <Uint8List>[];
  String? _nomeError;
  String? _nascitaError;
  String? _microchipError;
  String? _ingressoError;
  var _busy = false;
  var _loaded = false;

  DateTime get _now => ref.read(dogListNowProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadDraft());
    });
  }

  @override
  void dispose() {
    _nome.dispose();
    _razza.dispose();
    _peso.dispose();
    _mantello.dispose();
    _microchip.dispose();
    _provenienza.dispose();
    _dataNascita.dispose();
    _dataIngresso.dispose();
    _dataSterilizzazione.dispose();
    _slogan.dispose();
    _descrizione.dispose();
    _noteCarattere.dispose();
    _terapie.dispose();
    super.dispose();
  }

  Future<void> _loadDraft() async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    final stored = await ref.read(dogDraftStoreProvider).load(uid);
    if (!mounted) {
      return;
    }
    setState(() {
      _draft = (stored ?? const NewDogDraft()).copyWith(
        dataIngresso: stored?.dataIngresso ?? _now,
      );
      _applyDraftToControllers(_draft);
      _loaded = true;
    });
  }

  void _applyDraftToControllers(NewDogDraft draft) {
    _nome.text = draft.nome;
    _razza.text = draft.razza;
    _peso.text = draft.pesoText;
    _mantello.text = draft.mantello;
    _microchip.text = draft.microchip;
    _provenienza.text = draft.provenienza;
    _dataNascita.text = draft.dataNascita == null
        ? ''
        : formatItalianDate(draft.dataNascita!);
    _dataIngresso.text = draft.dataIngresso == null
        ? ''
        : formatItalianDate(draft.dataIngresso!);
    _dataSterilizzazione.text = draft.dataSterilizzazione == null
        ? ''
        : formatItalianDate(draft.dataSterilizzazione!);
    _slogan.text = draft.slogan;
    _descrizione.text = draft.descrizione;
    _noteCarattere.text = draft.noteCarattere;
    _terapie.text = draft.terapieInCorso;
  }

  NewDogDraft _fromControllers({int? step}) {
    final nascita = _dataNascita.text.trim().isEmpty
        ? null
        : parseItalianDate(_dataNascita.text);
    final ingresso = parseItalianDate(_dataIngresso.text);
    final steril = _dataSterilizzazione.text.trim().isEmpty
        ? null
        : parseItalianDate(_dataSterilizzazione.text);
    return _draft.copyWith(
      step: step ?? _draft.step,
      nome: _nome.text,
      razza: _razza.text,
      pesoText: _peso.text,
      mantello: _mantello.text,
      microchip: _microchip.text,
      provenienza: _provenienza.text,
      dataNascita: nascita,
      clearDataNascita: nascita == null,
      dataIngresso: ingresso,
      clearDataIngresso: ingresso == null,
      dataSterilizzazione: steril,
      clearDataSterilizzazione: steril == null,
      slogan: _slogan.text,
      descrizione: _descrizione.text,
      noteCarattere: _noteCarattere.text,
      terapieInCorso: _terapie.text,
    );
  }

  Future<void> _persist({int? step, bool toast = false}) async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    final draft = _fromControllers(step: step);
    _draft = draft;
    await ref.read(dogDraftStoreProvider).save(uid, draft);
    if (toast && mounted) {
      AppToast.show(context, 'Bozza salvata.');
    }
  }

  bool _validateStep1() {
    final draft = _fromControllers();
    final nomeErr = validateNomeCane(_nome.text);
    final chipErr = validateMicrochip(_microchip.text);
    String? dateErr = validateDataIngresso(draft.dataIngresso);
    if (_dataIngresso.text.trim().isNotEmpty && draft.dataIngresso == null) {
      dateErr = 'Data non valida (gg/mm/aaaa).';
    }
    final nascitaErr = validateOptionalItalianDate(_dataNascita.text);
    setState(() {
      _draft = draft;
      _nomeError = nomeErr;
      _nascitaError = nascitaErr;
      _microchipError = chipErr;
      _ingressoError = dateErr;
    });
    return nomeErr == null &&
        chipErr == null &&
        dateErr == null &&
        nascitaErr == null;
  }

  Future<void> _continua() async {
    if (_draft.step == 0 && !_validateStep1()) {
      return;
    }
    final next = (_draft.step + 1).clamp(0, 2);
    setState(() => _draft = _fromControllers(step: next));
    await _persist(step: next);
  }

  Future<void> _indietro() async {
    final prev = (_draft.step - 1).clamp(0, 2);
    setState(() => _draft = _fromControllers(step: prev));
    await _persist(step: prev);
  }

  Future<void> _crea() async {
    if (_busy) {
      return;
    }
    if (!_validateStep1()) {
      setState(() => _draft = _fromControllers(step: 0));
      return;
    }
    final dogs = ref.read(dogRepositoryProvider);
    if (dogs == null) {
      AppToast.show(context, 'Archivio cani non disponibile.');
      return;
    }
    setState(() => _busy = true);
    try {
      final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
      final result = await submitNewDog(
        draft: _fromControllers(step: 2),
        photos: List<Uint8List>.of(_photos),
        dogs: dogs,
        uid: uid,
        now: _now,
        health: ref.read(healthRepositoryProvider),
        weights: ref.read(weightRepositoryProvider),
        photoRepo: ref.read(photoRepositoryProvider),
        drafts: ref.read(dogDraftStoreProvider),
      );
      if (!mounted) {
        return;
      }
      context.go(AppRoutes.dog(result.dogId));
    } on PhotoLimitReached {
      if (mounted) {
        AppToast.show(context, PhotoLimitReached.message);
      }
    } on PhotoTooLarge {
      if (mounted) {
        AppToast.show(context, PhotoTooLarge.message);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _scanMicrochip() async {
    final raw = await ref.read(microchipScannerProvider).scan(context);
    if (!mounted || raw == null) {
      return;
    }
    final chip = extractMicrochipDigits(raw);
    if (chip == null) {
      setState(() {
        _microchip.text = raw;
        _microchipError = validateMicrochip(raw);
      });
      return;
    }
    setState(() {
      _microchip.text = chip;
      _microchipError = null;
    });
  }

  Future<void> _openPhotos() async {
    await AppSheet.show<void>(
      context: context,
      title: 'Aggiungi foto',
      children: [
        OptionRow(
          icon: const IconBadge(AppIcons.fotocamera, size: IconBadge.inMenu),
          title: 'Fotocamera',
          subtitle: 'Scatta una foto',
          onTap: () {
            Navigator.of(context, rootNavigator: true).pop();
            unawaited(_pickCamera());
          },
        ),
        OptionRow(
          icon: const IconBadge(AppIcons.galleria, size: IconBadge.inMenu),
          title: 'Scegli dalla galleria',
          subtitle: 'Selezione multipla',
          onTap: () {
            Navigator.of(context, rootNavigator: true).pop();
            unawaited(_pickGallery());
          },
        ),
      ],
    );
  }

  Future<void> _pickCamera() async {
    final bytes = await ref.read(photoPickerProvider).pickFromCamera();
    if (bytes == null || !mounted) {
      return;
    }
    _addPhotos([bytes]);
  }

  Future<void> _pickGallery() async {
    final files = await ref.read(photoPickerProvider).pickFromGallery();
    if (files.isEmpty || !mounted) {
      return;
    }
    _addPhotos(files);
  }

  void _addPhotos(List<Uint8List> files) {
    if (_photos.length + files.length > photoMaxPerDog) {
      AppToast.show(context, PhotoLimitReached.message);
      return;
    }
    setState(() => _photos.addAll(files));
  }

  Future<void> _pickBox(List<ShelterBox> boxes) async {
    final picked = await pickBoxAssegnato(context, boxes);
    if (picked == null || !mounted) {
      return;
    }
    setState(
      () => _draft = _draft.copyWith(settore: picked.settore, box: picked.box),
    );
  }

  Future<void> _pickReferente(List<Volunteer> volunteers) async {
    final picked = await pickReferente(context, volunteers);
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _draft = picked.isEmpty
          ? _draft.copyWith(clearReferenteId: true)
          : _draft.copyWith(referenteId: picked);
    });
  }

  Future<void> _pickModalita() async {
    final picked = await pickModalitaIngresso(context);
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _draft = _draft.copyWith(modalitaIngresso: picked));
  }

  Future<void> _addCustomTrait() async {
    final added = await pickCustomTrait(context);
    if (added == null || !mounted) {
      return;
    }
    if (_draft.carattere.contains(added)) {
      return;
    }
    setState(
      () => _draft = _draft.copyWith(carattere: [..._draft.carattere, added]),
    );
  }

  void _toggleTrait(String label) {
    final next = List<String>.of(_draft.carattere);
    if (next.contains(label)) {
      next.remove(label);
    } else {
      next.add(label);
    }
    setState(() => _draft = _draft.copyWith(carattere: next));
  }

  void _toggleTest(String label) {
    final next = List<String>.of(_draft.testEffettuati);
    if (next.contains(label)) {
      next.remove(label);
    } else {
      next.add(label);
    }
    setState(() => _draft = _draft.copyWith(testEffettuati: next));
  }

  @override
  Widget build(BuildContext context) {
    final boxes = ref
        .watch(boxesStreamProvider)
        .maybeWhen(data: (items) => items, orElse: () => const <ShelterBox>[]);
    final volunteers = ref
        .watch(volunteersStreamProvider)
        .maybeWhen(
          data: (items) => items,
          orElse: () => const <Volunteer>[],
        );
    final step = _draft.step.clamp(0, 2);

    return AppScaffold(
      compactHeader: true,
      title: 'Nuovo cane · ${step + 1} di 3',
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.animali);
        }
      },
      headerActions: [
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppDim.minTouch,
            minHeight: AppDim.minTouch,
          ),
          child: GestureDetector(
            key: NewDogWizardPage.salvaBozzaKey,
            behavior: HitTestBehavior.opaque,
            onTap: () => unawaited(_persist(toast: true)),
            child: const Center(
              child: Text(
                'Salva bozza',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: AppText.value,
                  fontWeight: FontWeight.w600,
                  color: AppColor.muted,
                  height: AppDim.lineH,
                ),
              ),
            ),
          ),
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDim.gapL,
              AppDim.gapL,
              AppDim.gapL,
              0,
            ),
            child: _StepBar(step: step),
          ),
          Expanded(
            child: ListView(
              padding: AppDim.pagePad,
              children: [
                if (!_loaded)
                  const SizedBox(height: AppDim.minTouch)
                else if (step == 0)
                  ..._step1(boxes, volunteers)
                else if (step == 1)
                  ..._step2()
                else
                  ..._step3(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _step1(List<ShelterBox> boxes, List<Volunteer> volunteers) {
    return [
      DogAnagraficaFields(
        nome: _nome,
        dataNascita: _dataNascita,
        razza: _razza,
        mantello: _mantello,
        peso: _peso,
        showPeso: true,
        sesso: _draft.sesso,
        nascitaPresunta: _draft.nascitaPresunta,
        taglia: _draft.taglia,
        nomeError: _nomeError,
        nascitaError: _nascitaError,
        nomeKey: NewDogWizardPage.nomeKey,
        onSesso: (value) => setState(() => _draft = _draft.copyWith(sesso: value)),
        onNascitaPresunta: (value) =>
            setState(() => _draft = _draft.copyWith(nascitaPresunta: value)),
        onTaglia: (value) =>
            setState(() => _draft = _draft.copyWith(taglia: value)),
      ),
      const SizedBox(height: AppDim.gapM),
      DogIdentificazioneFields(
        microchip: _microchip,
        iscrittoAnagrafe: _draft.iscrittoAnagrafe,
        microchipError: _microchipError,
        microchipKey: NewDogWizardPage.microchipKey,
        scanKey: NewDogWizardPage.scanKey,
        onScan: () => unawaited(_scanMicrochip()),
        onIscritto: (value) =>
            setState(() => _draft = _draft.copyWith(iscrittoAnagrafe: value)),
      ),
      const SizedBox(height: AppDim.gapM),
      DogProvenienzaFields(
        provenienza: _provenienza,
        dataIngresso: _dataIngresso,
        modalitaLabel: modalitaIngressoLabel(_draft.modalitaIngresso),
        boxLabel: boxAssegnatoLabel(_draft.settore, _draft.box),
        referenteLabel: () {
          final referente = volunteers.where(
            (item) => item.id == _draft.referenteId,
          );
          return referente.isEmpty
              ? 'Nessun referente'
              : volunteerDisplayName(referente.first);
        }(),
        ingressoError: _ingressoError,
        onModalita: () => unawaited(_pickModalita()),
        onBox: () => unawaited(_pickBox(boxes)),
        onReferente: () => unawaited(_pickReferente(volunteers)),
      ),
      const SizedBox(height: AppDim.gapM),
      AppButton(
        key: NewDogWizardPage.continuaKey,
        label: 'Continua →',
        onPressed: _busy ? null : () => unawaited(_continua()),
      ),
      const SizedBox(height: AppDim.gapXl),
    ];
  }

  List<Widget> _step2() {
    final nome = _nome.text.trim().isEmpty ? 'il cane' : _nome.text.trim();
    return [
      FormCard(
        title: 'Foto del profilo',
        icon: AppIcons.fotocamera,
        children: [
          Material(
            key: NewDogWizardPage.fotoKey,
            color: AppColor.greenTint,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDim.radCard),
              side: const BorderSide(color: AppColor.line, width: AppDim.dashW),
            ),
            child: InkWell(
              onTap: () => unawaited(_openPhotos()),
              borderRadius: BorderRadius.circular(AppDim.radCard),
              child: Padding(
                padding: const EdgeInsets.all(AppDim.iconNav),
                child: Column(
                  children: [
                    const IconBadge(AppIcons.fotocamera, size: IconBadge.inStat),
                    const SizedBox(height: AppDim.gapS),
                    Text(
                      'Scatta o carica le foto di $nome',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: AppText.value,
                        color: AppColor.muted,
                        height: AppDim.lineH,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppDim.todoGap,
            crossAxisSpacing: AppDim.todoGap,
            children: [
              for (var i = 0; i < _photos.length; i++)
                _PhotoTile(
                  bytes: _photos[i],
                  isCover: i == _draft.coverIndex,
                  onTap: () =>
                      setState(() => _draft = _draft.copyWith(coverIndex: i)),
                  onDelete: () => setState(() {
                    _photos.removeAt(i);
                    final cover = _draft.coverIndex;
                    _draft = _draft.copyWith(
                      coverIndex: cover >= _photos.length
                          ? (_photos.isEmpty ? 0 : _photos.length - 1)
                          : cover,
                    );
                  }),
                ),
              _AddPhotoTile(onTap: () => unawaited(_openPhotos())),
            ],
          ),
        ],
      ),
      const SizedBox(height: AppDim.gapM),
      DogPresentazioneFields(
        slogan: _slogan,
        descrizione: _descrizione,
      ),
      const SizedBox(height: AppDim.gapM),
      DogCarattereFields(
        sesso: _draft.sesso,
        carattere: _draft.carattere,
        conPersone: _draft.conPersone,
        conCani: _draft.conCani,
        conGatti: _draft.conGatti,
        conBambini: _draft.conBambini,
        noteCarattere: _noteCarattere,
        onToggleTrait: _toggleTrait,
        onAddCustom: () => unawaited(_addCustomTrait()),
        onConPersone: (value) =>
            setState(() => _draft = _draft.copyWith(conPersone: value)),
        onConCani: (value) =>
            setState(() => _draft = _draft.copyWith(conCani: value)),
        onConGatti: (value) =>
            setState(() => _draft = _draft.copyWith(conGatti: value)),
        onConBambini: (value) =>
            setState(() => _draft = _draft.copyWith(conBambini: value)),
      ),
      const SizedBox(height: AppDim.gapM),
      _NavRow(
        backKey: NewDogWizardPage.indietroKey,
        nextKey: NewDogWizardPage.continuaKey,
        nextLabel: 'Continua →',
        onBack: () => unawaited(_indietro()),
        onNext: () => unawaited(_continua()),
      ),
      const SizedBox(height: AppDim.gapXl),
    ];
  }

  List<Widget> _step3() {
    return [
      FormCard(
        title: 'Situazione sanitaria',
        icon: AppIcons.vaccino,
        children: [
          DogSterilizzazioneFields(
            sesso: _draft.sesso,
            sterilizzazione: _draft.sterilizzazione,
            dataSterilizzazione: _dataSterilizzazione,
            onSterilizzazione: (value) => setState(
              () => _draft = _draft.copyWith(sterilizzazione: value),
            ),
          ),
          if (_draft.trattamenti.isEmpty)
            const Text(
              'Nessun trattamento ancora.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: AppText.caption,
                color: AppColor.muted,
                height: AppDim.lineH,
              ),
            )
          else
            for (final item in _draft.trattamenti)
              Row(
                children: [
                  IconBadge(
                    AppIcons.perTrattamento(item.tipo.wire),
                    size: IconBadge.inTitle,
                  ),
                  const SizedBox(width: AppDim.gapS),
                  Expanded(
                    child: Text(
                      item.descrizione,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: AppText.value,
                        fontWeight: FontWeight.w600,
                        color: AppColor.ink,
                        height: AppDim.lineH,
                      ),
                    ),
                  ),
                  Text(
                    formatItalianDate(item.data),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: AppText.caption,
                      color: AppColor.muted,
                      height: AppDim.lineH,
                    ),
                  ),
                ],
              ),
          AppButton(
            label: '➕ Aggiungi',
            variant: AppButtonVariant.ghost,
            onPressed: () async {
              final item = await NewDogTreatmentSheet.open(
                context,
                now: _now,
              );
              if (item == null || !mounted) {
                return;
              }
              setState(
                () => _draft = _draft.copyWith(
                  trattamenti: [..._draft.trattamenti, item],
                ),
              );
            },
          ),
          Wrap(
            spacing: AppDim.gapS,
            runSpacing: AppDim.gapS,
            children: [
              for (final label in _testSanitari)
                AppChip(
                  label: _draft.testEffettuati.contains(label)
                      ? '$label ✓'
                      : label,
                  selected: _draft.testEffettuati.contains(label),
                  height: AppDim.formChipH,
                  onSelected: () => _toggleTest(label),
                ),
            ],
          ),
          AppFormField(
            label: 'Terapie in corso',
            hint: 'Nessuna',
            controller: _terapie,
          ),
        ],
      ),
      const SizedBox(height: AppDim.gapM),
      DogAdozioneFields(
        adottabile: _draft.adottabile,
        pubblicato: _draft.pubblicato,
        onAdottabile: (value) =>
            setState(() => _draft = _draft.copyWith(adottabile: value)),
        onPubblicato: (value) =>
            setState(() => _draft = _draft.copyWith(pubblicato: value)),
      ),
      const SizedBox(height: AppDim.gapM),
      AppCard(
        color: AppColor.greenTint,
        borderColor: AppColor.greenSoft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Riepilogo',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: AppText.value,
                fontWeight: FontWeight.w700,
                color: AppColor.ink,
                height: AppDim.lineH,
              ),
            ),
            const SizedBox(height: AppDim.gapS),
            KeyValueRow(
              label: 'Nome',
              value:
                  '${_nome.text.trim().isEmpty ? '—' : _nome.text.trim()} · '
                  '${dogSexLabel(_draft.sesso)} · '
                  '${_razza.text.trim().isEmpty ? '—' : _razza.text.trim()}',
            ),
            KeyValueRow(
              label: 'Microchip',
              value: dashIfEmpty(_microchip.text),
            ),
            KeyValueRow(
              label: 'Ingresso',
              value:
                  '${_draft.dataIngresso == null ? '—' : formatItalianDate(_draft.dataIngresso!)}'
                  ' · Box ${boxAssegnatoLabel(_draft.settore, _draft.box)}',
            ),
            KeyValueRow(
              label: 'Foto caricate',
              value: '${_photos.length}',
            ),
          ],
        ),
      ),
      const SizedBox(height: AppDim.gapM),
      _NavRow(
        backKey: NewDogWizardPage.indietroKey,
        nextKey: NewDogWizardPage.creaKey,
        nextLabel: _busy ? 'Creazione…' : '✓ Crea profilo',
        onBack: _busy ? null : () => unawaited(_indietro()),
        onNext: _busy ? null : () => unawaited(_crea()),
      ),
      const SizedBox(height: AppDim.gapXl),
    ];
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: AppDim.gapS),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: i <= step ? AppColor.green : AppColor.line,
                borderRadius: BorderRadius.circular(AppDim.gapXs),
              ),
              child: const SizedBox(height: AppDim.gapXs),
            ),
          ),
        ],
      ],
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.backKey,
    required this.nextKey,
    required this.nextLabel,
    required this.onBack,
    required this.onNext,
  });

  final Key backKey;
  final Key nextKey;
  final String nextLabel;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            key: backKey,
            label: '← Indietro',
            variant: AppButtonVariant.grey,
            onPressed: onBack,
          ),
        ),
        const SizedBox(width: AppDim.gapM),
        Expanded(
          child: AppButton(key: nextKey, label: nextLabel, onPressed: onNext),
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.bytes,
    required this.isCover,
    required this.onTap,
    required this.onDelete,
  });

  final Uint8List bytes;
  final bool isCover;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.neutralSoft,
      borderRadius: BorderRadius.circular(AppDim.arriviRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(bytes, fit: BoxFit.cover),
            if (isCover)
              const Align(
                alignment: Alignment.bottomCenter,
                child: ColoredBox(
                  color: AppColor.green,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: AppDim.coverBadgePad,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        'COPERTINA',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: AppText.micro,
                          fontWeight: FontWeight.w700,
                          color: AppColor.card,
                          height: AppDim.lineH,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: onDelete,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(AppDim.gapXs),
                  child: IconBadge(AppIcons.elimina, size: IconBadge.inTitle),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.greenTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDim.arriviRadius),
        side: const BorderSide(color: AppColor.line, width: AppDim.dashW),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDim.arriviRadius),
        child: const Center(
          child: IconBadge(AppIcons.foto, size: IconBadge.inStat),
        ),
      ),
    );
  }
}
