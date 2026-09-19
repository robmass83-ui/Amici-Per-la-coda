import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format_it.dart';
import '../../data/data_providers.dart';
import '../../data/models/dog.dart';
import '../../data/models/enums.dart';
import '../../data/models/shelter_box.dart';
import '../../data/models/volunteer.dart';
import '../affido/affido_providers.dart';
import '../auth/auth_providers.dart';
import '../../router.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../dashboard/home_providers.dart';
import 'concurrent_edit.dart';
import 'dog_labels.dart';
import 'dog_profile_fields.dart';
import 'dog_profile_pickers.dart';
import 'dogs_providers.dart';
import 'edit_permissions.dart';
import 'new_dog/new_dog_draft.dart';
import 'new_dog/new_dog_providers.dart';
import 'new_dog/new_dog_validation.dart';
import 'record_actions.dart';
import 'tab_labels.dart';
import '../volunteers/volunteer_labels.dart';

// ── CONTRATTO DI LAYOUT · Modifica cane ────────────────────────────────────
// AppScaffold compactHeader  NESSUNA bottom nav  NESSUN FAB
// └ AppHeader h=40
//    ├ ←  ├ Titolo "Modifica <nome senza [PROVA]>" 13sp w700
//    └ Salva  faint se pulito · pillola verde 11sp w700 se dirty
// └ ListView padding=12  gap 9 fra FormCard  inset basso = barra di sistema
    //    ├ Anagrafica · Identificazione · Chip e anagrafe · Provenienza
//    ├ Presentazione · Carattere · Situazione sanitaria · Adozione
//    └ Ultima modifica 10sp muted centrato
// ───────────────────────────────────────────────────────────────────────────

String saveDogErrorMessage(Object error) {
  final text = error.toString();
  if (text.contains('permission-denied') ||
      text.contains('PERMISSION_DENIED')) {
    return 'Non hai il permesso di salvare. Il profilo volontario deve avere ruolo presidente o referente.';
  }
  return 'Salvataggio non riuscito. Riprova.';
}

class EditDogPage extends ConsumerStatefulWidget {
  const EditDogPage({super.key, required this.dogId, this.sezione});

  final String dogId;
  final String? sezione;

  static const saveKey = Key('edit-dog-save');
  static const nomeKey = Key('edit-dog-nome');
  static const microchipKey = Key('edit-dog-microchip');
  static const tagliaKey = Key('edit-dog-taglia');
  static const ultimaModificaKey = Key('edit-dog-ultima-modifica');
  static const formListKey = Key('edit-dog-form-list');
  static const sloganKey = Key('edit-dog-slogan');
  static const descrizioneKey = Key('edit-dog-descrizione');
  static const sterilizzazioneKey = Key('edit-dog-sterilizzazione');
  static const dataSterilizzazioneKey = Key('edit-dog-data-sterilizzazione');

  @override
  ConsumerState<EditDogPage> createState() => _EditDogPageState();
}

class _EditDogPageState extends ConsumerState<EditDogPage> {
  final _scroll = ScrollController();
  final _provenienzaKey = GlobalKey();
  final _nome = TextEditingController();
  final _razza = TextEditingController();
  final _mantello = TextEditingController();
  final _microchip = TextEditingController();
  final _provenienza = TextEditingController();
  final _dataNascita = TextEditingController();
  final _dataIngresso = TextEditingController();
  final _slogan = TextEditingController();
  final _descrizione = TextEditingController();
  final _noteCarattere = TextEditingController();
  final _dataSterilizzazione = TextEditingController();
  final _dataApplicazioneChip = TextEditingController();
  final _zonaApplicazioneChip = TextEditingController();
  final _veterinarioApplicatore = TextEditingController();
  final _dataIscrizioneAnagrafe = TextEditingController();
  final _ultimaUbicazione = TextEditingController();

  Dog? _original;
  DateTime? _openedUpdatedAt;
  DogSex? _sesso;
  var _nascitaPresunta = true;
  var _taglia = Taglia.media;
  var _iscritto = IscrittoAnagrafe.daVerificare;
  ModalitaIngresso? _modalita;
  var _settore = '';
  var _box = '';
  var _carattere = <String>[];
  ConPersone? _conPersone;
  var _conCani = ConCani.daTestare;
  var _conGatti = ConGatti.daTestare;
  var _conBambini = ConBambini.daTestare;
  WizardAdottabile? _adottabile;
  WizardSterilizzazione? _sterilizzazione;
  var _pubblicato = false;
  TipoPelo? _tipoPelo;
  Purezza? _purezza;
  var _dataIngressoStimata = false;
  String? _referenteId;
  String? _nomeError;
  String? _nascitaError;
  String? _microchipError;
  String? _ingressoError;
  String? _chipDateError;
  String? _anagrafeDateError;
  String? _sterDateError;
  var _busy = false;
  var _loaded = false;
  var _didScrollSezione = false;

  @override
  void initState() {
    super.initState();
    for (final c in [
      _nome,
      _razza,
      _mantello,
      _microchip,
      _provenienza,
      _dataNascita,
      _dataIngresso,
      _slogan,
      _descrizione,
      _noteCarattere,
      _dataSterilizzazione,
      _dataApplicazioneChip,
      _zonaApplicazioneChip,
      _veterinarioApplicatore,
      _dataIscrizioneAnagrafe,
      _ultimaUbicazione,
    ]) {
      c.addListener(_onFieldTick);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_load());
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final c in [
      _nome,
      _razza,
      _mantello,
      _microchip,
      _provenienza,
      _dataNascita,
      _dataIngresso,
      _slogan,
      _descrizione,
      _noteCarattere,
      _dataSterilizzazione,
      _dataApplicazioneChip,
      _zonaApplicazioneChip,
      _veterinarioApplicatore,
      _dataIscrizioneAnagrafe,
      _ultimaUbicazione,
    ]) {
      c.removeListener(_onFieldTick);
      c.dispose();
    }
    super.dispose();
  }

  void _onFieldTick() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _load() async {
    final dogs = ref.read(dogRepositoryProvider);
    final dog = await dogs?.getById(widget.dogId);
    if (!mounted || dog == null) {
      setState(() => _loaded = true);
      return;
    }
    _applyDog(dog);
    setState(() {
      _original = dog;
      _openedUpdatedAt = dog.audit.updatedAt;
      _loaded = true;
    });
    _scrollToSezione();
  }

  void _scrollToSezione() {
    if (_didScrollSezione || widget.sezione != 'provenienza') {
      return;
    }
    _didScrollSezione = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _provenienzaKey.currentContext;
      if (ctx == null) {
        return;
      }
      Scrollable.ensureVisible(ctx, alignment: 0, duration: Duration.zero);
    });
  }

  void _applyDog(Dog dog) {
    _nome.text = dog.nome;
    _razza.text = dog.razza;
    _mantello.text = dog.mantello;
    _microchip.text = dog.microchip;
    _provenienza.text = dog.provenienza;
    _dataNascita.text = dog.dataNascita == null
        ? ''
        : formatItalianDate(dog.dataNascita!);
    _dataIngresso.text = formatItalianDate(dog.dataIngresso);
    _slogan.text = dog.slogan;
    _descrizione.text = dog.descrizione;
    _noteCarattere.text = dog.noteCarattere;
    _sesso = dog.sesso;
    _nascitaPresunta = dog.nascitaPresunta;
    _taglia = dog.taglia;
    _iscritto = dog.iscrittoAnagrafe;
    _modalita = dog.modalitaIngresso;
    _settore = dog.settore;
    _box = dog.box;
    _carattere = List<String>.of(dog.carattere);
    _conPersone = dog.conPersone;
    _conCani = dog.conCani;
    _conGatti = dog.conGatti;
    _conBambini = dog.conBambini;
    _adottabile = dog.adottabile == true
        ? WizardAdottabile.si
        : dog.adottabile == false
        ? WizardAdottabile.nonAdottabile
        : null;
    _sterilizzazione = sterilizzazioneFromDog(
      sterilizzato: dog.sterilizzato,
      dataSterilizzazione: dog.dataSterilizzazione,
    );
    _dataSterilizzazione.text = dog.dataSterilizzazione == null
        ? ''
        : formatItalianDate(dog.dataSterilizzazione!);
    _dataApplicazioneChip.text = dog.dataApplicazioneChip == null
        ? ''
        : formatItalianDate(dog.dataApplicazioneChip!);
    _zonaApplicazioneChip.text = dog.zonaApplicazioneChip;
    _veterinarioApplicatore.text = dog.veterinarioApplicatore;
    _dataIscrizioneAnagrafe.text = dog.dataIscrizioneAnagrafe == null
        ? ''
        : formatItalianDate(dog.dataIscrizioneAnagrafe!);
    _ultimaUbicazione.text = dog.ultimaUbicazione;
    _pubblicato = dog.pubblicato;
    _referenteId = dog.referenteId;
    _tipoPelo = dog.tipoPelo;
    _purezza = dog.purezza;
    _dataIngressoStimata = dog.dataIngressoStimata;
    _nomeError = null;
    _microchipError = null;
    _ingressoError = null;
  }

  bool get _dirty {
    final original = _original;
    if (original == null) {
      return false;
    }
    final nascitaShown = original.dataNascita == null
        ? ''
        : formatItalianDate(original.dataNascita!);
    return original.nome != _nome.text.trim() ||
        original.sesso != _sesso ||
        nascitaShown != _dataNascita.text.trim() ||
        original.nascitaPresunta != _nascitaPresunta ||
        original.razza != _razza.text.trim() ||
        original.taglia != _taglia ||
        original.mantello != _mantello.text.trim() ||
        original.microchip != _microchip.text.trim() ||
        original.iscrittoAnagrafe != _iscritto ||
        original.provenienza != _provenienza.text.trim() ||
        original.modalitaIngresso != _modalita ||
        formatItalianDate(original.dataIngresso) != _dataIngresso.text.trim() ||
        original.settore != _settore ||
        original.box != _box ||
        original.slogan != _slogan.text.trim() ||
        original.descrizione != _descrizione.text.trim() ||
        !_sameList(original.carattere, _carattere) ||
        original.conPersone != _conPersone ||
        original.conCani != _conCani ||
        original.conGatti != _conGatti ||
        original.conBambini != _conBambini ||
        original.noteCarattere != _noteCarattere.text.trim() ||
        original.adottabile != _adottabileFlag ||
        original.pubblicato != _pubblicato ||
        original.referenteId != _referenteId ||
        original.tipoPelo != _tipoPelo ||
        original.purezza != _purezza ||
        original.dataIngressoStimata != _dataIngressoStimata ||
        original.zonaApplicazioneChip != _zonaApplicazioneChip.text.trim() ||
        original.veterinarioApplicatore !=
            _veterinarioApplicatore.text.trim() ||
        original.ultimaUbicazione != _ultimaUbicazione.text.trim() ||
        _dateShown(original.dataApplicazioneChip) !=
            _dataApplicazioneChip.text.trim() ||
        _dateShown(original.dataIscrizioneAnagrafe) !=
            _dataIscrizioneAnagrafe.text.trim() ||
        sterilizzazioneFromDog(
              sterilizzato: original.sterilizzato,
              dataSterilizzazione: original.dataSterilizzazione,
            ) !=
            _sterilizzazione ||
        _sterilDateShown(original) != _sterilDateCurrent;
  }

  bool? get _adottabileFlag {
    return switch (_adottabile) {
      WizardAdottabile.si => true,
      WizardAdottabile.nonAncora || WizardAdottabile.nonAdottabile => false,
      null => null,
    };
  }

  String get _sterilDateCurrent {
    if (_sterilizzazione == null ||
        _sterilizzazione == WizardSterilizzazione.no) {
      return '';
    }
    return _dataSterilizzazione.text.trim();
  }

  String _dateShown(DateTime? value) {
    return value == null ? '' : formatItalianDate(value);
  }

  bool _validate() {
    final nomeErr = validateNomeCane(_nome.text);
    final chipErr = validateMicrochip(_microchip.text);
    final ingresso = parseItalianDate(_dataIngresso.text);
    String? dateErr = validateDataIngresso(ingresso);
    if (_dataIngresso.text.trim().isNotEmpty && ingresso == null) {
      dateErr = 'Data non valida (gg/mm/aaaa).';
    }
    final nascitaErr = validateOptionalItalianDate(_dataNascita.text);
    final chipDateErr = validateOptionalItalianDate(_dataApplicazioneChip.text);
    final anagrafeErr = validateOptionalItalianDate(_dataIscrizioneAnagrafe.text);
    final sterErr = validateOptionalItalianDate(_dataSterilizzazione.text);
    setState(() {
      _nomeError = nomeErr;
      _nascitaError = nascitaErr;
      _microchipError = chipErr;
      _ingressoError = dateErr;
      _chipDateError = chipDateErr;
      _anagrafeDateError = anagrafeErr;
      _sterDateError = sterErr;
    });
    return nomeErr == null &&
        chipErr == null &&
        dateErr == null &&
        nascitaErr == null &&
        chipDateErr == null &&
        anagrafeErr == null &&
        sterErr == null;
  }

  Dog _merged(Dog base, {required String uid, required DateTime now}) {
    final nascita = _dataNascita.text.trim().isEmpty
        ? null
        : parseItalianDate(_dataNascita.text);
    final ingresso = parseItalianDate(_dataIngresso.text) ?? base.dataIngresso;
    final sterilDate =
        _sterilizzazione == null ||
            _sterilizzazione == WizardSterilizzazione.no
        ? null
        : parseItalianDate(_dataSterilizzazione.text);
    final chipDate = parseItalianDate(_dataApplicazioneChip.text);
    final iscrizioneDate = parseItalianDate(_dataIscrizioneAnagrafe.text);
    DateTime? pubblicazione = base.dataPubblicazione;
    if (_pubblicato && pubblicazione == null) {
      pubblicazione = now;
    }
    return base.copyWith(
      nome: _nome.text.trim(),
      sesso: _sesso,
      dataNascita: nascita,
      clearDataNascita: nascita == null,
      nascitaPresunta: _nascitaPresunta,
      razza: _razza.text.trim(),
      taglia: _taglia,
      mantello: _mantello.text.trim(),
      microchip: _microchip.text.trim(),
      iscrittoAnagrafe: _iscritto,
      provenienza: _provenienza.text.trim(),
      modalitaIngresso: _modalita,
      clearModalitaIngresso: _modalita == null,
      dataIngresso: ingresso,
      dataIngressoStimata: _dataIngressoStimata,
      settore: _settore,
      box: _box,
      slogan: _slogan.text.trim(),
      descrizione: _descrizione.text.trim(),
      carattere: List<String>.of(_carattere),
      conPersone: _conPersone,
      clearConPersone: _conPersone == null,
      conCani: _conCani,
      conGatti: _conGatti,
      conBambini: _conBambini,
      noteCarattere: _noteCarattere.text.trim(),
      adottabile: _adottabileFlag,
      clearAdottabile: _adottabileFlag == null,
      sterilizzato: _sterilizzazione == null
          ? null
          : _sterilizzazione == WizardSterilizzazione.si,
      clearSterilizzato: _sterilizzazione == null,
      dataSterilizzazione: sterilDate,
      clearDataSterilizzazione: sterilDate == null,
      tipoPelo: _tipoPelo,
      clearTipoPelo: _tipoPelo == null,
      purezza: _purezza,
      clearPurezza: _purezza == null,
      dataApplicazioneChip: chipDate,
      clearDataApplicazioneChip: chipDate == null,
      zonaApplicazioneChip: _zonaApplicazioneChip.text.trim(),
      veterinarioApplicatore: _veterinarioApplicatore.text.trim(),
      dataIscrizioneAnagrafe: iscrizioneDate,
      clearDataIscrizioneAnagrafe: iscrizioneDate == null,
      ultimaUbicazione: _ultimaUbicazione.text.trim(),
      pubblicato: _pubblicato,
      dataPubblicazione: pubblicazione,
      referenteId: _referenteId,
      clearReferenteId: _referenteId == null || _referenteId!.isEmpty,
      audit: base.audit.touched(uid, now),
    );
  }

  Future<void> _save({bool overwrite = false}) async {
    if (_busy) {
      return;
    }
    if (!_validate()) {
      return;
    }
    final dogs = ref.read(dogRepositoryProvider);
    if (dogs == null) {
      AppToast.show(context, 'Archivio cani non disponibile.');
      return;
    }
    setState(() => _busy = true);
    try {
      final server = await dogs.getById(widget.dogId);
      if (server == null) {
        if (mounted) {
          AppToast.show(context, 'Cane non trovato.');
        }
        return;
      }
      final opened = _openedUpdatedAt;
      if (!overwrite &&
          opened != null &&
          hasConcurrentDogEdit(
            openedUpdatedAt: opened,
            serverUpdatedAt: server.audit.updatedAt,
          )) {
        if (!mounted) {
          return;
        }
        final volunteers = ref.read(volunteersStreamProvider).maybeWhen(
          data: (items) => items,
          orElse: () => const <Volunteer>[],
        );
        final editor = autoreEtichetta(volunteers, server.audit.updatedBy);
        final choice = await showConcurrentEditSheet(
          context: context,
          message: concurrentEditMessage(editor),
        );
        if (!mounted) {
          return;
        }
        if (choice == ConcurrentEditChoice.ricarica) {
          _applyDog(server);
          setState(() {
            _original = server;
            _openedUpdatedAt = server.audit.updatedAt;
            _busy = false;
          });
        } else if (choice == ConcurrentEditChoice.overwrite) {
          setState(() => _busy = false);
          await _save(overwrite: true);
        }
        return;
      }
      final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
      final now = DateTime.now();
      final updated = _merged(server, uid: uid, now: now);
      await dogs.save(updated);
      ref.invalidate(dogsStreamProvider);
      if (!mounted) {
        return;
      }
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.dog(widget.dogId));
      }
    } catch (error) {
      if (mounted) {
        AppToast.show(context, saveDogErrorMessage(error));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _onBack() async {
    if (!_dirty) {
      _leave();
      return;
    }
    final stay = !await confirmAction(
      context: context,
      title: 'Modifiche non salvate',
      message: 'Hai modifiche non salvate. Uscire senza salvare?',
      confirmLabel: 'Esci',
      confirmKey: ConfirmActionKeys.discardLeave,
      cancelKey: ConfirmActionKeys.discardStay,
    );
    if (!stay && mounted) {
      _leave();
    }
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.dog(widget.dogId));
    }
  }

  Future<void> _scanMicrochip() async {
    final raw = await ref.read(microchipScannerProvider).scan(context);
    if (!mounted || raw == null) {
      return;
    }
    final chip = extractMicrochipDigits(raw);
    setState(() {
      _microchip.text = chip ?? raw;
      _microchipError = validateMicrochip(_microchip.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final volunteersAsync = ref.watch(volunteersStreamProvider);
    if (volunteersAsync.isLoading) {
      return AppScaffold(
        compactHeader: true,
        title: 'Modifica',
        onBack: _leave,
        body: const Center(
          child: SizedBox(
            width: AppDim.fabSize,
            height: AppDim.fabSize,
            child: CircularProgressIndicator(strokeWidth: AppDim.gapXs),
          ),
        ),
      );
    }
    final volunteer = ref.watch(currentVolunteerProvider);
    if (!canWriteRecords(volunteer)) {
      return AppScaffold(
        compactHeader: true,
        title: 'Modifica',
        onBack: _leave,
        body: const Center(
          child: EmptyState(
            icon: IconBadge(AppIcons.modifica),
            message: 'Non hai il permesso di modificare la scheda.',
          ),
        ),
      );
    }
    final boxes = ref
        .watch(boxesStreamProvider)
        .maybeWhen(data: (items) => items, orElse: () => const <ShelterBox>[]);
    final volunteers = ref
        .watch(volunteersStreamProvider)
        .maybeWhen(data: (items) => items, orElse: () => const <Volunteer>[]);
    final referente = volunteers.where((item) => item.id == _referenteId);
    final referenteNome = referente.isEmpty
        ? 'Nessun referente'
        : volunteerDisplayName(referente.first);
    final editor = _original == null
        ? ''
        : autoreEtichetta(volunteers, _original!.audit.updatedBy);
    final nomeMostrato = dogDisplayName(
      _nome.text.trim().isEmpty ? 'scheda' : _nome.text.trim(),
    );
    final canSave = _dirty && !_busy && _loaded && _original != null;

    return AppScaffold(
      compactHeader: true,
      title: 'Modifica $nomeMostrato',
      onBack: () => unawaited(_onBack()),
      headerActions: [
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppDim.minTouch,
            minHeight: AppDim.minTouch,
          ),
          child: GestureDetector(
            key: EditDogPage.saveKey,
            behavior: HitTestBehavior.opaque,
            onTap: canSave ? () => unawaited(_save()) : null,
            child: Center(
              child: DecoratedBox(
                decoration: canSave
                    ? BoxDecoration(
                        color: AppColor.green,
                        borderRadius: BorderRadius.circular(AppDim.radChip),
                      )
                    : const BoxDecoration(),
                child: Padding(
                  padding: canSave
                      ? const EdgeInsets.symmetric(
                          horizontal: AppDim.formSavePadH,
                          vertical: AppDim.formSavePadV,
                        )
                      : EdgeInsets.zero,
                  child: Text(
                    'Salva',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: canSave ? AppText.segmented : AppText.h2,
                      fontWeight: FontWeight.w700,
                      color: canSave ? AppColor.card : AppColor.faint,
                      height: AppDim.lineH,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
      body: !_loaded
          ? const Center(
              child: SizedBox(
                width: AppDim.fabSize,
                height: AppDim.fabSize,
                child: CircularProgressIndicator(strokeWidth: AppDim.gapXs),
              ),
            )
          : _original == null
          ? const Center(
              child: EmptyState(
                icon: IconBadge(AppIcons.carattere),
                message: 'Cane non trovato.',
              ),
            )
          : ListView(
              key: EditDogPage.formListKey,
              controller: _scroll,
              padding: AppDim.pagePad,
              children: [
                DogAnagraficaFields(
                  nome: _nome,
                  dataNascita: _dataNascita,
                  razza: _razza,
                  mantello: _mantello,
                  sesso: _sesso,
                  nascitaPresunta: _nascitaPresunta,
                  taglia: _taglia,
                  nomeError: _nomeError,
                  nascitaError: _nascitaError,
                  nomeKey: EditDogPage.nomeKey,
                  tagliaKey: EditDogPage.tagliaKey,
                  onSesso: (value) => setState(() => _sesso = value),
                  onNascitaPresunta: (value) =>
                      setState(() => _nascitaPresunta = value),
                  onTaglia: (value) => setState(() => _taglia = value),
                ),
                const SizedBox(height: AppDim.gapM),
                DogIdentificazioneFields(
                  microchip: _microchip,
                  iscrittoAnagrafe: _iscritto,
                  microchipError: _microchipError,
                  microchipKey: EditDogPage.microchipKey,
                  onScan: () => unawaited(_scanMicrochip()),
                  onIscritto: (value) => setState(() => _iscritto = value),
                ),
                const SizedBox(height: AppDim.gapM),
                DogChipAnagrafeFields(
                  tipoPelo: _tipoPelo,
                  purezza: _purezza,
                  dataApplicazioneChip: _dataApplicazioneChip,
                  zonaApplicazioneChip: _zonaApplicazioneChip,
                  veterinarioApplicatore: _veterinarioApplicatore,
                  dataIscrizioneAnagrafe: _dataIscrizioneAnagrafe,
                  ultimaUbicazione: _ultimaUbicazione,
                  chipDateError: _chipDateError,
                  anagrafeDateError: _anagrafeDateError,
                  onTipoPelo: (value) => setState(() => _tipoPelo = value),
                  onPurezza: (value) => setState(() => _purezza = value),
                ),
                const SizedBox(height: AppDim.gapM),
                DogProvenienzaFields(
                  key: _provenienzaKey,
                  provenienza: _provenienza,
                  dataIngresso: _dataIngresso,
                  modalitaLabel: modalitaIngressoLabel(_modalita),
                  boxLabel: boxAssegnatoLabel(_settore, _box),
                  referenteLabel: referenteNome,
                  ingressoError: _ingressoError,
                  ingressoStimata: _dataIngressoStimata,
                  onIngressoStimata: (value) =>
                      setState(() => _dataIngressoStimata = value),
                  onModalita: () async {
                    final picked = await pickModalitaIngresso(context);
                    if (picked != null && mounted) {
                      setState(() => _modalita = picked);
                    }
                  },
                  onBox: () async {
                    final picked = await pickBoxAssegnato(context, boxes);
                    if (picked != null && mounted) {
                      setState(() {
                        _settore = picked.settore;
                        _box = picked.box;
                      });
                    }
                  },
                  onReferente: () async {
                    final picked = await pickReferente(context, volunteers);
                    if (picked == null || !mounted) {
                      return;
                    }
                    setState(
                      () => _referenteId = picked.isEmpty ? null : picked,
                    );
                  },
                ),
                const SizedBox(height: AppDim.gapM),
                DogPresentazioneFields(
                  slogan: _slogan,
                  descrizione: _descrizione,
                  sloganKey: EditDogPage.sloganKey,
                  descrizioneKey: EditDogPage.descrizioneKey,
                ),
                const SizedBox(height: AppDim.gapM),
                DogCarattereFields(
                  sesso: _sesso,
                  carattere: _carattere,
                  conPersone: _conPersone,
                  conCani: _conCani,
                  conGatti: _conGatti,
                  conBambini: _conBambini,
                  noteCarattere: _noteCarattere,
                  onToggleTrait: (label) {
                    setState(() {
                      if (_carattere.contains(label)) {
                        _carattere = List<String>.of(_carattere)..remove(label);
                      } else {
                        _carattere = [..._carattere, label];
                      }
                    });
                  },
                  onAddCustom: () async {
                    final added = await pickCustomTrait(context);
                    if (added == null || !mounted) {
                      return;
                    }
                    if (_carattere.contains(added)) {
                      return;
                    }
                    setState(() => _carattere = [..._carattere, added]);
                  },
                  onConPersone: (value) => setState(() => _conPersone = value),
                  onConCani: (value) => setState(() => _conCani = value),
                  onConGatti: (value) => setState(() => _conGatti = value),
                  onConBambini: (value) => setState(() => _conBambini = value),
                ),
                const SizedBox(height: AppDim.gapM),
                FormCard(
                  title: 'Situazione sanitaria',
                  icon: AppIcons.vaccino,
                  children: [
                    DogSterilizzazioneFields(
                      sesso: _sesso,
                      sterilizzazione: _sterilizzazione,
                      dataSterilizzazione: _dataSterilizzazione,
                      sterilizzazioneKey: EditDogPage.sterilizzazioneKey,
                      dataKey: EditDogPage.dataSterilizzazioneKey,
                      dataError: _sterDateError,
                      onSterilizzazione: (value) =>
                          setState(() => _sterilizzazione = value),
                    ),
                  ],
                ),
                const SizedBox(height: AppDim.gapM),
                DogAdozioneFields(
                  adottabile: _adottabile,
                  pubblicato: _pubblicato,
                  onAdottabile: (value) => setState(() => _adottabile = value),
                  onPubblicato: (value) => setState(() => _pubblicato = value),
                ),
                const SizedBox(height: AppDim.gapS),
                Text(
                  key: EditDogPage.ultimaModificaKey,
                  ultimaModificaLabel(
                    editorNome: editor,
                    updatedAt: _original!.audit.updatedAt,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: AppText.caption,
                    color: AppColor.muted,
                    height: AppDim.lineH,
                  ),
                ),
                const SizedBox(height: AppDim.gapL),
              ],
            ),
    );
  }
}

bool _sameList(List<String> a, List<String> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

String _sterilDateShown(Dog dog) {
    if (sterilizzazioneFromDog(
          sterilizzato: dog.sterilizzato,
          dataSterilizzazione: dog.dataSterilizzazione,
        ) ==
        WizardSterilizzazione.no ||
        sterilizzazioneFromDog(
              sterilizzato: dog.sterilizzato,
              dataSterilizzazione: dog.dataSterilizzazione,
            ) ==
            null) {
    return '';
  }
  return dog.dataSterilizzazione == null
      ? ''
      : formatItalianDate(dog.dataSterilizzazione!);
}
