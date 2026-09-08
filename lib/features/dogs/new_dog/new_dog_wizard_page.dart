import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format_it.dart';
import '../../../data/data_providers.dart';
import '../../../data/models/enums.dart';
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
import '../dogs_providers.dart';
import 'new_dog_draft.dart';
import 'new_dog_providers.dart';
import 'new_dog_submit.dart';
import 'new_dog_treatment_sheet.dart';
import 'new_dog_validation.dart';

const _caratterePreset = [
  'Dolce',
  'Socievole',
  'Equilibrata',
  'Timida',
  'Vivace',
  'Protettiva',
];

const _testSanitari = ['Leishmania', 'Filaria', 'Ehrlichia'];

const _labelStyle = TextStyle(
  fontFamily: 'Roboto',
  fontSize: AppText.label,
  color: AppColor.muted,
  height: AppDim.lineH,
);

// ── CONTRATTO DI LAYOUT · Nuovo cane (wizard 3 passaggi) ───────────────────
// Column
// ├ SafeArea bottom=false
// │  └ AppHeader h=44  back 34×34  titolo «Nuovo cane · n di 3»  «Salva bozza»
// ├ Padding 12 0 0 12  Row 3 barre  h=4  gap=6  radius=4  green se fatto
// └ Expanded ListView  padding=12
//    STEP 1
//    ├ SectionTitle Anagrafica  icona carattere
//    ├ AppTextField Nome *  h=40
//    ├ SizedBox 9
//    ├ label Sesso * + AppSegmented Femmina|Maschio  h=34
//    ├ SizedBox 9
//    ├ Row gap=9
//    │   ├ Expanded AppTextField Data di nascita  h=40  readOnly
//    │   └ Expanded label Precisione + AppSegmented Presunta|Certa
//    ├ SizedBox 9
//    ├ Row gap=9  Razza  |  label Taglia + AppSegmented 3
//    ├ SizedBox 9
//    ├ Row gap=9  Peso kg  |  Mantello
//    ├ SectionTitle Identificazione  icona microchip
//    ├ AppTextField Microchip  h=40  suffix scanner 40×40
//    ├ SizedBox 9
//    ├ label Anagrafe + AppSegmented Sì|No|Da verificare
//    ├ SectionTitle Provenienza e ingresso  icona provenienza
//    ├ AppTextField Luogo
//    ├ SizedBox 9
//    ├ AppTextField Modalità  readOnly → sheet
//    ├ SizedBox 9
//    ├ Row gap=9  Data ingresso *  |  Box  readOnly → sheet
//    └ AppButton Continua  h=40
//    STEP 2
//    ├ SectionTitle Foto  icona fotocamera
//    ├ area tratteggiata padding=18  radius=12  testi 11.5/10  maxLines=2
//    ├ SizedBox 9
//    ├ Grid 3 col  gap=7  AspectRatio 1  radius=9  + tessera +
//    ├ SectionTitle Presentazione
//    ├ AppTextField Slogan  h=52  maxLines=2
//    ├ SizedBox 9
//    ├ AppTextField Descrizione  h=80  maxLines=4
//    ├ SectionTitle Carattere  icona carattere
//    ├ Wrap chip h=28  spacing=6
//    ├ SizedBox 12
//    ├ 4 × label + AppSegmented  (persone, cani, gatti, bambini)
//    ├ AppTextField Note  h=56  maxLines=3
//    └ Row gap=9  Indietro grey | Continua
//    STEP 3
//    ├ SectionTitle Situazione sanitaria  icona vaccino
//    ├ label Sterilizz. + AppSegmented Sì|No|Programmata
//    ├ (se non No) AppTextField Data intervento
//    ├ AppCard  elenco trattamenti + AppButton ghost Aggiungi
//    ├ label Test + Wrap chip
//    ├ AppTextField Terapie in corso
//    ├ SectionTitle Adozione  icona adottabile
//    ├ AppSegmented Adottabile 3  ·  Pubblica 2  ·  Referente sheet
//    ├ AppCard greenTint  KeyValueRow × 4  riepilogo
//    └ Row gap=9  Indietro | Crea profilo
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
    setState(() {
      _draft = draft;
      _nomeError = nomeErr;
      _microchipError = chipErr;
      _ingressoError = dateErr;
    });
    return nomeErr == null && chipErr == null && dateErr == null;
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
    final available = boxes.where((item) => !item.inManutenzione).toList();
    await AppSheet.show<void>(
      context: context,
      title: 'Box assegnato',
      children: [
        OptionRow(
          icon: const IconBadge(AppIcons.box, size: IconBadge.inMenu),
          title: 'Nessun box',
          onTap: () {
            Navigator.of(context).pop();
            setState(() => _draft = _draft.copyWith(settore: '', box: ''));
          },
        ),
        for (final box in available)
          OptionRow(
            icon: const IconBadge(AppIcons.box, size: IconBadge.inMenu),
            title: boxAssegnatoLabel(box.settore, box.numero),
            subtitle: 'Capienza ${box.capienza}',
            onTap: () {
              Navigator.of(context).pop();
              setState(
                () => _draft = _draft.copyWith(
                  settore: box.settore,
                  box: box.numero,
                ),
              );
            },
          ),
      ],
    );
  }

  Future<void> _pickReferente(List<Volunteer> volunteers) async {
    final attivi = volunteers.where((item) => item.attivo).toList();
    await AppSheet.show<void>(
      context: context,
      title: 'Volontario referente',
      children: [
        OptionRow(
          icon: const IconBadge(AppIcons.volontari, size: IconBadge.inMenu),
          title: 'Nessun referente',
          onTap: () {
            Navigator.of(context).pop();
            setState(() => _draft = _draft.copyWith(clearReferenteId: true));
          },
        ),
        for (final volunteer in attivi)
          OptionRow(
            icon: const IconBadge(AppIcons.volontari, size: IconBadge.inMenu),
            title: volunteer.nome,
            subtitle: volunteer.email,
            onTap: () {
              Navigator.of(context).pop();
              setState(
                () => _draft = _draft.copyWith(referenteId: volunteer.id),
              );
            },
          ),
      ],
    );
  }

  Future<void> _pickModalita() async {
    await AppSheet.show<void>(
      context: context,
      title: 'Modalità di ingresso',
      children: [
        for (final value in ModalitaIngresso.values)
          OptionRow(
            icon: const IconBadge(AppIcons.provenienza, size: IconBadge.inMenu),
            title: modalitaIngressoLabel(value),
            onTap: () {
              Navigator.of(context).pop();
              setState(() => _draft = _draft.copyWith(modalitaIngresso: value));
            },
          ),
      ],
    );
  }

  Future<void> _addCustomTrait() async {
    final controller = TextEditingController();
    final added = await AppSheet.present<String>(
      context: context,
      builder: (context) {
        return Padding(
          padding: AppDim.pagePad,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Altro tratto',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: AppText.h2,
                  fontWeight: FontWeight.w700,
                  color: AppColor.ink,
                  height: AppDim.lineH,
                ),
              ),
              const SizedBox(height: AppDim.gapM),
              AppTextField(
                label: 'Carattere',
                hint: 'Es. giocherellona',
                controller: controller,
              ),
              const SizedBox(height: AppDim.gapM),
              AppButton(
                label: 'Aggiungi',
                onPressed: () =>
                    Navigator.of(context).pop(controller.text.trim()),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
    if (added == null || added.isEmpty || !mounted) {
      return;
    }
    if (_draft.carattere.contains(added)) {
      return;
    }
    setState(
      () => _draft = _draft.copyWith(
        carattere: [..._draft.carattere, added],
      ),
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
                  ..._step1(boxes)
                else if (step == 1)
                  ..._step2()
                else
                  ..._step3(volunteers),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _step1(List<ShelterBox> boxes) {
    return [
      const SectionTitle(
        title: 'Anagrafica',
        icon: IconBadge(AppIcons.carattere, size: IconBadge.inTitle),
      ),
      AppTextField(
        key: NewDogWizardPage.nomeKey,
        label: 'Nome del cane *',
        hint: 'Es. Fenice',
        controller: _nome,
        errorText: _nomeError,
        textInputAction: TextInputAction.next,
      ),
      const SizedBox(height: AppDim.gapM),
      const Text('Sesso *', style: _labelStyle),
      const SizedBox(height: AppDim.gapXs),
      AppSegmented(
        values: const ['Femmina', 'Maschio'],
        selectedIndex: _draft.sesso == DogSex.F ? 0 : 1,
        onChanged: (i) => setState(
          () => _draft = _draft.copyWith(sesso: i == 0 ? DogSex.F : DogSex.M),
        ),
      ),
      const SizedBox(height: AppDim.gapM),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AppTextField(
              label: 'Data di nascita',
              hint: 'gg/mm/aaaa',
              controller: _dataNascita,
              keyboardType: TextInputType.datetime,
            ),
          ),
          const SizedBox(width: AppDim.gapM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Precisione', style: _labelStyle),
                const SizedBox(height: AppDim.gapXs),
                AppSegmented(
                  values: const ['Presunta', 'Certa'],
                  selectedIndex: _draft.nascitaPresunta ? 0 : 1,
                  onChanged: (i) => setState(
                    () => _draft = _draft.copyWith(nascitaPresunta: i == 0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: AppDim.gapM),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AppTextField(
              label: 'Razza / tipo',
              hint: 'Es. Meticcia',
              controller: _razza,
            ),
          ),
          const SizedBox(width: AppDim.gapM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Taglia', style: _labelStyle),
                const SizedBox(height: AppDim.gapXs),
                AppSegmented(
                  values: const ['Piccola', 'Media', 'Grande'],
                  selectedIndex: Taglia.values.indexOf(_draft.taglia),
                  onChanged: (i) => setState(
                    () => _draft = _draft.copyWith(taglia: Taglia.values[i]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: AppDim.gapM),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AppTextField(
              label: 'Peso attuale (kg)',
              hint: 'Es. 22',
              controller: _peso,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ),
          const SizedBox(width: AppDim.gapM),
          Expanded(
            child: AppTextField(
              label: 'Mantello',
              hint: 'Es. fulvo chiaro',
              controller: _mantello,
            ),
          ),
        ],
      ),
      const SectionTitle(
        title: 'Identificazione',
        icon: IconBadge(AppIcons.microchip, size: IconBadge.inTitle),
      ),
      AppTextField(
        key: NewDogWizardPage.microchipKey,
        label: 'Microchip',
        hint: '15 cifre',
        controller: _microchip,
        errorText: _microchipError,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(microchipCifre),
        ],
        suffix: GestureDetector(
          key: NewDogWizardPage.scanKey,
          behavior: HitTestBehavior.opaque,
          onTap: () => unawaited(_scanMicrochip()),
          child: const IconBadge(AppIcons.fotocamera, size: IconBadge.inTitle),
        ),
      ),
      const SizedBox(height: AppDim.gapM),
      const Text('Iscritto in anagrafe canina', style: _labelStyle),
      const SizedBox(height: AppDim.gapXs),
      AppSegmented(
        values: const ['Sì', 'No', 'Da verificare'],
        selectedIndex: IscrittoAnagrafe.values.indexOf(_draft.iscrittoAnagrafe),
        onChanged: (i) => setState(
          () => _draft = _draft.copyWith(
            iscrittoAnagrafe: IscrittoAnagrafe.values[i],
          ),
        ),
      ),
      const SectionTitle(
        title: 'Provenienza e ingresso',
        icon: IconBadge(AppIcons.provenienza, size: IconBadge.inTitle),
      ),
      AppTextField(
        label: 'Luogo di provenienza',
        hint: 'Es. Corleto Perticara (PZ)',
        controller: _provenienza,
      ),
      const SizedBox(height: AppDim.gapM),
      _TapField(
        label: 'Modalità di ingresso',
        value: modalitaIngressoLabel(_draft.modalitaIngresso),
        chevron: true,
        onTap: () => unawaited(_pickModalita()),
      ),
      const SizedBox(height: AppDim.gapM),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AppTextField(
              label: 'Data di ingresso *',
              hint: 'gg/mm/aaaa',
              errorText: _ingressoError,
              controller: _dataIngresso,
              keyboardType: TextInputType.datetime,
            ),
          ),
          const SizedBox(width: AppDim.gapM),
          Expanded(
            child: _TapField(
              label: 'Box assegnato',
              value: boxAssegnatoLabel(_draft.settore, _draft.box),
              chevron: true,
              onTap: () => unawaited(_pickBox(boxes)),
            ),
          ),
        ],
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
      const SectionTitle(
        title: 'Foto del profilo',
        icon: IconBadge(AppIcons.fotocamera, size: IconBadge.inTitle),
      ),
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
      const SizedBox(height: AppDim.gapM),
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
              onTap: () => setState(() => _draft = _draft.copyWith(coverIndex: i)),
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
      const SectionTitle(
        title: 'Presentazione',
        icon: IconBadge(AppIcons.annuncio, size: IconBadge.inTitle),
      ),
      AppTextField(
        label: 'Slogan (2 righe in scheda)',
        controller: _slogan,
        maxLines: 2,
        fieldHeight: AppDim.fabSize,
      ),
      const SizedBox(height: AppDim.gapM),
      AppTextField(
        label: "Descrizione per l'annuncio",
        controller: _descrizione,
        maxLines: 4,
        fieldHeight: AppDim.descFieldH,
      ),
      const SectionTitle(
        title: 'Carattere e compatibilità',
        icon: IconBadge(AppIcons.carattere, size: IconBadge.inTitle),
      ),
      const Text('Carattere', style: _labelStyle),
      const SizedBox(height: AppDim.gapXs),
      Wrap(
        spacing: AppDim.gapS,
        runSpacing: AppDim.gapS,
        children: [
          for (final label in [
            ..._caratterePreset,
            ..._draft.carattere.where((item) => !_caratterePreset.contains(item)),
          ])
            AppChip(
              label: label,
              selected: _draft.carattere.contains(label),
              onSelected: () => _toggleTrait(label),
            ),
          AppChip(label: '+', selected: false, onSelected: () => unawaited(_addCustomTrait())),
        ],
      ),
      const SizedBox(height: AppDim.gapL),
      const Text('Con le persone', style: _labelStyle),
      const SizedBox(height: AppDim.gapXs),
      AppSegmented(
        values: [
          'Molto socievole',
          _draft.sesso == DogSex.F ? 'Selettiva' : 'Selettivo',
          'Diffidente',
        ],
        selectedIndex: ConPersone.values.indexOf(_draft.conPersone),
        onChanged: (i) => setState(
          () => _draft = _draft.copyWith(conPersone: ConPersone.values[i]),
        ),
      ),
      const SizedBox(height: AppDim.gapM),
      const Text('Con altri cani', style: _labelStyle),
      const SizedBox(height: AppDim.gapXs),
      AppSegmented(
        values: const ['Sì', 'Solo femmine', 'No', 'Da testare'],
        selectedIndex: _conCaniIndex(_draft.conCani),
        onChanged: (i) => setState(
          () => _draft = _draft.copyWith(conCani: _conCaniAt(i)),
        ),
      ),
      const SizedBox(height: AppDim.gapM),
      const Text('Con i gatti', style: _labelStyle),
      const SizedBox(height: AppDim.gapXs),
      AppSegmented(
        values: const ['Sì', 'Da testare', 'No'],
        selectedIndex: _conGattiIndex(_draft.conGatti),
        onChanged: (i) => setState(
          () => _draft = _draft.copyWith(conGatti: _conGattiAt(i)),
        ),
      ),
      const SizedBox(height: AppDim.gapM),
      const Text('Con i bambini', style: _labelStyle),
      const SizedBox(height: AppDim.gapXs),
      AppSegmented(
        values: const ['Sì', 'Solo grandi', 'No', 'Da testare'],
        selectedIndex: _conBambiniIndex(_draft.conBambini),
        onChanged: (i) => setState(
          () => _draft = _draft.copyWith(conBambini: _conBambiniAt(i)),
        ),
      ),
      const SizedBox(height: AppDim.gapM),
      AppTextField(
        label: 'Note sul carattere',
        controller: _noteCarattere,
        maxLines: 3,
        fieldHeight: AppDim.emptyTodoH,
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

  List<Widget> _step3(List<Volunteer> volunteers) {
    final referente = volunteers.where((item) => item.id == _draft.referenteId);
    final referenteNome = referente.isEmpty ? 'Nessun referente' : referente.first.nome;
    final showSterilDate = _draft.sterilizzazione != WizardSterilizzazione.no;
    return [
      const SectionTitle(
        title: 'Situazione sanitaria',
        icon: IconBadge(AppIcons.vaccino, size: IconBadge.inTitle),
      ),
      Text(
        _draft.sesso == DogSex.F ? 'Sterilizzata' : 'Castrato',
        style: _labelStyle,
      ),
      const SizedBox(height: AppDim.gapXs),
      AppSegmented(
        values: const ['Sì', 'No', 'Programmata'],
        selectedIndex: WizardSterilizzazione.values.indexOf(_draft.sterilizzazione),
        onChanged: (i) => setState(
          () => _draft = _draft.copyWith(
            sterilizzazione: WizardSterilizzazione.values[i],
          ),
        ),
      ),
      if (showSterilDate) ...[
        const SizedBox(height: AppDim.gapM),
        AppTextField(
          label: 'Data intervento',
          hint: 'gg/mm/aaaa',
          controller: _dataSterilizzazione,
          keyboardType: TextInputType.datetime,
        ),
      ],
      const SizedBox(height: AppDim.gapM),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Vaccinazioni e trattamenti',
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
              for (final item in _draft.trattamenti) ...[
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
                const SizedBox(height: AppDim.gapS),
              ],
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
          ],
        ),
      ),
      const SizedBox(height: AppDim.gapM),
      const Text('Test effettuati', style: _labelStyle),
      const SizedBox(height: AppDim.gapXs),
      Wrap(
        spacing: AppDim.gapS,
        runSpacing: AppDim.gapS,
        children: [
          for (final label in _testSanitari)
            AppChip(
              label: _draft.testEffettuati.contains(label) ? '$label ✓' : label,
              selected: _draft.testEffettuati.contains(label),
              onSelected: () => _toggleTest(label),
            ),
        ],
      ),
      const SizedBox(height: AppDim.gapM),
      AppTextField(
        label: 'Terapie in corso',
        hint: 'Nessuna',
        controller: _terapie,
      ),
      const SectionTitle(
        title: 'Adozione',
        icon: IconBadge(AppIcons.adottabile, size: IconBadge.inTitle),
      ),
      const Text('Adottabile', style: _labelStyle),
      const SizedBox(height: AppDim.gapXs),
      AppSegmented(
        values: const ['Sì', 'Non ancora', 'Non adottabile'],
        selectedIndex: WizardAdottabile.values.indexOf(_draft.adottabile),
        onChanged: (i) => setState(
          () => _draft = _draft.copyWith(
            adottabile: WizardAdottabile.values[i],
          ),
        ),
      ),
      const SizedBox(height: AppDim.gapM),
      const Text('Pubblica su sito e social', style: _labelStyle),
      const SizedBox(height: AppDim.gapXs),
      AppSegmented(
        values: const ['Sì, subito', 'Solo interno'],
        selectedIndex: _draft.pubblicato ? 0 : 1,
        onChanged: (i) => setState(
          () => _draft = _draft.copyWith(pubblicato: i == 0),
        ),
      ),
      const SizedBox(height: AppDim.gapM),
      _TapField(
        label: 'Volontario referente',
        value: referenteNome,
        chevron: true,
        onTap: () => unawaited(_pickReferente(volunteers)),
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

class _TapField extends StatelessWidget {
  const _TapField({
    required this.label,
    required this.value,
    required this.onTap,
    this.chevron = false,
  });

  final String label;
  final String value;
  final bool chevron;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: AppDim.gapXs),
        Material(
          color: AppColor.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDim.radInput),
            side: const BorderSide(color: AppColor.line),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppDim.radInput),
            child: SizedBox(
              height: AppDim.minTouch,
              child: Padding(
                padding: AppDim.inputPad,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: AppText.body,
                          color: AppColor.ink,
                          height: AppDim.lineH,
                        ),
                      ),
                    ),
                    if (chevron)
                      const Text(
                        '▾',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: AppText.body,
                          color: AppColor.muted,
                          height: AppDim.lineH,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
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

int _conCaniIndex(ConCani value) {
  return switch (value) {
    ConCani.si => 0,
    ConCani.selettivo => 1,
    ConCani.no => 2,
    ConCani.daTestare => 3,
  };
}

ConCani _conCaniAt(int index) {
  return switch (index) {
    0 => ConCani.si,
    1 => ConCani.selettivo,
    2 => ConCani.no,
    _ => ConCani.daTestare,
  };
}

int _conGattiIndex(ConGatti value) {
  return switch (value) {
    ConGatti.si => 0,
    ConGatti.daTestare => 1,
    ConGatti.no => 2,
  };
}

ConGatti _conGattiAt(int index) {
  return switch (index) {
    0 => ConGatti.si,
    2 => ConGatti.no,
    _ => ConGatti.daTestare,
  };
}

int _conBambiniIndex(ConBambini value) {
  return switch (value) {
    ConBambini.si => 0,
    ConBambini.soloGrandi => 1,
    ConBambini.no => 2,
    ConBambini.daTestare => 3,
  };
}

ConBambini _conBambiniAt(int index) {
  return switch (index) {
    0 => ConBambini.si,
    1 => ConBambini.soloGrandi,
    2 => ConBambini.no,
    _ => ConBambini.daTestare,
  };
}
