import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/firestore_codec.dart';
import '../../core/new_id.dart';
import '../../data/data_providers.dart';
import '../../data/models/adopter.dart';
import '../../data/models/adoption.dart';
import '../../data/models/dog.dart';
import '../../data/models/enums.dart';
import '../../router.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../auth/auth_providers.dart';
import '../dogs/dog_labels.dart';
import '../dogs/dogs_providers.dart';
import '../dogs/photo_thumb.dart';
import '../dogs/record_actions.dart';
import 'adoption_flow.dart';

// ── CONTRATTO DI LAYOUT · Nuova/Modifica richiesta ─────────────────────────────
// AppScaffold compactHeader  NESSUNA bottom nav  NESSUN FAB
// ├ AppBar h=40  ← · titolo · Salva pillola verde quando valido
// └ ListView padding=12  gap 9 fra le card
//    ├ FormCard «Cane»  riga thumb 28 + nome + chevron
//    ├ FormCard «Richiedente»  AppIcons.richieste
//    │    NOME|COGNOME  TELEFONO|EMAIL  CITTÀ|ETÀ  INDIRIZZO
//    │    DOCUMENTO (CI/Patente/Passaporto) | NUMERO
//    │    riga 10sp match adottante
//    └ FormCard «Questionario»  AppIcons.modulo
//         ABITAZIONE | ORE DA SOLO
//         CompatRow 2 valori: etichetta Expanded maxLines=2 + Sì/No w=compatYesNoW
//         giardino + ALTEZZA se Sì · animali + QUALI se Sì
//         bambini + ETÀ se Sì · esperienza
//         DOVE DORMIRÀ  In casa / Fuori / Entrambi
//         NOTE multilinea
// ───────────────────────────────────────────────────────────────────────────

class NewAdoptionPage extends ConsumerStatefulWidget {
  const NewAdoptionPage({super.key, this.dogId, this.existingId});

  final String? dogId;
  final String? existingId;

  static const saveKey = Key('nuova-richiesta-salva');
  static const dogKey = Key('nuova-richiesta-cane');
  static const nomeKey = Key('nuova-richiesta-nome');
  static const cognomeKey = Key('nuova-richiesta-cognome');
  static const telefonoKey = Key('nuova-richiesta-telefono');
  static const emailKey = Key('nuova-richiesta-email');
  static const cittaKey = Key('nuova-richiesta-citta');
  static const indirizzoKey = Key('nuova-richiesta-indirizzo');
  static const docTipoKey = Key('nuova-richiesta-doctipo');
  static const docNumeroKey = Key('nuova-richiesta-docnumero');
  static const etaKey = Key('nuova-richiesta-eta');
  static const abitazioneKey = Key('nuova-richiesta-abitazione');
  static const recinzioneKey = Key('nuova-richiesta-recinzione');
  static const giardinoRowKey = Key('nuova-richiesta-giardino');
  static const animaliRowKey = Key('nuova-richiesta-animali-row');
  static const animaliKey = Key('nuova-richiesta-animali');
  static const bambiniRowKey = Key('nuova-richiesta-bambini-row');
  static const bambiniKey = Key('nuova-richiesta-bambini');
  static const oreKey = Key('nuova-richiesta-ore');
  static const esperienzaKey = Key('nuova-richiesta-esperienza');
  static const dormeKey = Key('nuova-richiesta-dorme');
  static const noteKey = Key('nuova-richiesta-note');
  static const matchKey = Key('nuova-richiesta-match');
  static const formListKey = Key('nuova-richiesta-list');

  @override
  ConsumerState<NewAdoptionPage> createState() => _NewAdoptionPageState();
}

const _abitazioni = ['Casa', 'Appartamento', 'Altro'];
const _docTipi = ['CI', 'Patente', 'Passaporto'];
const _dormeValori = ['In casa', 'Fuori', 'Entrambi'];

class _NewAdoptionPageState extends ConsumerState<NewAdoptionPage> {
  final _nome = TextEditingController();
  final _cognome = TextEditingController();
  final _telefono = TextEditingController();
  final _email = TextEditingController();
  final _citta = TextEditingController();
  final _indirizzo = TextEditingController();
  final _docNumero = TextEditingController();
  final _eta = TextEditingController();
  final _recinzione = TextEditingController();
  final _animaliQuali = TextEditingController();
  final _bambiniEta = TextEditingController();
  final _ore = TextEditingController();
  final _note = TextEditingController();

  String? _dogId;
  String? _dogError;
  String? _nomeError;
  var _docTipo = 0;
  var _abitazione = 0;
  var _giardino = false;
  var _altriAnimali = false;
  var _bambini = false;
  var _esperienza = false;
  var _dorme = 0;
  var _busy = false;
  var _loadedExisting = false;
  Adopter? _match;
  Adoption? _existing;
  late String _initial;

  @override
  void initState() {
    super.initState();
    _dogId = widget.dogId;
    _initial = '';
    for (final controller in [
      _nome,
      _cognome,
      _telefono,
      _email,
      _citta,
      _indirizzo,
      _docNumero,
      _eta,
      _recinzione,
      _animaliQuali,
      _bambiniEta,
      _ore,
      _note,
    ]) {
      controller.addListener(_mark);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _initial = _snapshot());
      }
    });
  }

  @override
  void dispose() {
    for (final controller in [
      _nome,
      _cognome,
      _telefono,
      _email,
      _citta,
      _indirizzo,
      _docNumero,
      _eta,
      _recinzione,
      _animaliQuali,
      _bambiniEta,
      _ore,
      _note,
    ]) {
      controller.removeListener(_mark);
      controller.dispose();
    }
    super.dispose();
  }

  void _mark() => setState(() {});

  String _snapshot() {
    return [
      _dogId ?? '',
      _nome.text,
      _cognome.text,
      _telefono.text,
      _email.text,
      _citta.text,
      _indirizzo.text,
      '$_docTipo',
      _docNumero.text,
      _eta.text,
      '$_abitazione',
      _giardino ? '1' : '0',
      _recinzione.text,
      _altriAnimali ? '1' : '0',
      _animaliQuali.text,
      _bambini ? '1' : '0',
      _bambiniEta.text,
      _ore.text,
      _esperienza ? '1' : '0',
      '$_dorme',
      _note.text,
    ].join('|');
  }

  bool get _canSave {
    return _dogId != null &&
        _dogId!.isNotEmpty &&
        _nome.text.trim().isNotEmpty &&
        !_busy;
  }

  bool get _dirty => _initial.isNotEmpty && _snapshot() != _initial;

  void _fillExisting(Adoption adoption) {
    final r = adoption.richiedente;
    final q = adoption.questionario;
    _existing = adoption;
    _dogId = adoption.dogId;
    _nome.text = r.nome;
    _cognome.text = r.cognome;
    _telefono.text = r.telefono;
    _email.text = r.email;
    _citta.text = r.citta;
    _indirizzo.text = r.indirizzo;
    _docTipo = _indexOf(_docTipi, r.docTipo, 0);
    _docNumero.text = r.docNumero;
    _eta.text = r.eta == 0 ? '' : '${r.eta}';
    _abitazione = _indexOf(_abitazioni, q.abitazione, 0);
    _giardino = q.giardinoRecintato;
    _recinzione.text = q.altezzaRecinzione;
    _altriAnimali = q.altriAnimali.trim().isNotEmpty &&
        q.altriAnimali.trim().toLowerCase() != 'no';
    _animaliQuali.text = _altriAnimali ? q.altriAnimali : '';
    _bambini = q.bambini.trim().isNotEmpty &&
        q.bambini.trim().toLowerCase() != 'no';
    _bambiniEta.text = _bambini ? q.bambini : '';
    _ore.text = q.oreDaSolo;
    _esperienza = q.esperienzaCani.trim().isNotEmpty &&
        q.esperienzaCani.trim().toLowerCase() != 'no';
    _dorme = _indexOf(_dormeValori, q.doveDormira, 0);
    _note.text = q.note;
    _loadedExisting = true;
    _initial = _snapshot();
  }

  int _indexOf(List<String> values, String raw, int fallback) {
    final trimmed = raw.trim();
    for (var i = 0; i < values.length; i++) {
      if (values[i].toLowerCase() == trimmed.toLowerCase()) {
        return i;
      }
    }
    return fallback;
  }

  void _lookupMatch() {
    final adopters = ref.read(adoptersStreamProvider).maybeWhen(
      data: (items) => items,
      orElse: () => const <Adopter>[],
    );
    final found = findMatchingAdopter(
      adopters,
      telefono: _telefono.text,
      email: _email.text,
    );
    setState(() => _match = found);
  }

  void _useMatch(Adopter adopter) {
    setState(() {
      _nome.text = adopter.nome;
      _cognome.text = adopter.cognome;
      _telefono.text = adopter.telefono;
      _email.text = adopter.email;
      _citta.text = adopter.citta;
      _indirizzo.text = adopter.indirizzo;
      _docTipo = _indexOf(_docTipi, adopter.docTipo, 0);
      _docNumero.text = adopter.docNumero;
      _match = adopter;
    });
  }

  Future<void> _pickDog(List<Dog> dogs) async {
    await AppSheet.show<void>(
      context: context,
      title: 'Cane richiesto',
      children: [
        for (final dog in dogs)
          OptionRow(
            icon: const IconBadge(AppIcons.carattere, size: IconBadge.inMenu),
            title: dogDisplayName(dog.nome),
            subtitle: dogListSubtitle(dog, now: ref.read(dogListNowProvider)),
            onTap: () {
              Navigator.of(context).pop();
              setState(() {
                _dogId = dog.id;
                _dogError = null;
              });
            },
          ),
      ],
    );
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
      context.go(AppRoutes.richieste);
    }
  }

  Questionario _questionario() {
    return Questionario(
      abitazione: _abitazioni[_abitazione],
      giardinoRecintato: _giardino,
      altezzaRecinzione: _giardino ? _recinzione.text.trim() : '',
      altriAnimali: _altriAnimali ? _animaliQuali.text.trim() : '',
      bambini: _bambini ? _bambiniEta.text.trim() : '',
      oreDaSolo: _ore.text.trim(),
      esperienzaCani: _esperienza ? 'Sì' : 'No',
      doveDormira: _dormeValori[_dorme],
      note: _note.text.trim(),
    );
  }

  Richiedente _richiedente(String nome) {
    return Richiedente(
      nome: nome,
      cognome: _cognome.text.trim(),
      telefono: _telefono.text.trim(),
      email: _email.text.trim(),
      citta: _citta.text.trim(),
      indirizzo: _indirizzo.text.trim(),
      docTipo: _docTipi[_docTipo],
      docNumero: _docNumero.text.trim(),
      eta: int.tryParse(_eta.text.trim()) ?? 0,
    );
  }

  Future<void> _save() async {
    final dogId = _dogId;
    final nome = _nome.text.trim();
    setState(() {
      _dogError = dogId == null || dogId.isEmpty ? 'Scegli il cane.' : null;
      _nomeError = nome.isEmpty ? 'Il nome è obbligatorio.' : null;
    });
    if (_dogError != null || _nomeError != null) {
      return;
    }

    final adoptions = ref.read(adoptionRepositoryProvider);
    final adoptersRepo = ref.read(adopterRepositoryProvider);
    if (adoptions == null) {
      return;
    }
    setState(() => _busy = true);
    try {
      final now = ref.read(dogListNowProvider);
      final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
      final richiedente = _richiedente(nome);
      var adopter = _match ??
          findMatchingAdopter(
            ref.read(adoptersStreamProvider).maybeWhen(
              data: (items) => items,
              orElse: () => const <Adopter>[],
            ),
            telefono: richiedente.telefono,
            email: richiedente.email,
          );
      final existing = _existing;
      if (existing != null) {
        final adoptionId = existing.id;
        if (adopter == null) {
          adopter = adopterFromRichiedente(
            id: existing.adopterId.isEmpty
                ? newEntityId('adp', now)
                : existing.adopterId,
            richiedente: richiedente,
            adoptionId: adoptionId,
            audit: existing.audit.touched(uid, now),
          );
        } else {
          adopter = Adopter(
            id: adopter.id,
            nome: richiedente.nome,
            cognome: richiedente.cognome,
            telefono: richiedente.telefono,
            email: richiedente.email,
            citta: richiedente.citta,
            indirizzo: richiedente.indirizzo,
            docTipo: richiedente.docTipo,
            docNumero: richiedente.docNumero,
            dataNascita: adopter.dataNascita,
            note: adopter.note,
            adozioniIds: adopter.adozioniIds.contains(adoptionId)
                ? adopter.adozioniIds
                : [...adopter.adozioniIds, adoptionId],
            affidabilita: adopter.affidabilita,
            audit: Audit(
              createdAt: adopter.audit.createdAt,
              createdBy: adopter.audit.createdBy,
              updatedAt: now,
              updatedBy: uid,
            ),
          );
        }
        await adoptersRepo?.save(adopter);
        await adoptions.save(
          existing.copyWith(
            dogId: dogId,
            adopterId: adopter.id,
            richiedente: richiedente,
            questionario: _questionario(),
            audit: existing.audit.touched(uid, now),
          ),
        );
      } else {
        final audit = Audit(
          createdAt: now,
          createdBy: uid,
          updatedAt: now,
          updatedBy: uid,
        );
        final adoptionId = newEntityId('ad', now);
        if (adopter == null) {
          adopter = adopterFromRichiedente(
            id: newEntityId('adp', now),
            richiedente: richiedente,
            adoptionId: adoptionId,
            audit: audit,
          );
        } else {
          adopter = Adopter(
            id: adopter.id,
            nome: richiedente.nome,
            cognome: richiedente.cognome,
            telefono: richiedente.telefono,
            email: richiedente.email,
            citta: richiedente.citta,
            indirizzo: richiedente.indirizzo,
            docTipo: richiedente.docTipo,
            docNumero: richiedente.docNumero,
            dataNascita: adopter.dataNascita,
            note: adopter.note,
            adozioniIds: adopter.adozioniIds.contains(adoptionId)
                ? adopter.adozioniIds
                : [...adopter.adozioniIds, adoptionId],
            affidabilita: adopter.affidabilita,
            audit: Audit(
              createdAt: adopter.audit.createdAt,
              createdBy: adopter.audit.createdBy,
              updatedAt: now,
              updatedBy: uid,
            ),
          );
        }
        final adoption = Adoption(
          id: adoptionId,
          dogId: dogId!,
          adopterId: adopter.id,
          richiedente: richiedente,
          questionario: _questionario(),
          stato: AdoptionStato.ricevuta,
          storicoStati: [
            AdoptionStatoVoce(
              stato: AdoptionStato.ricevuta,
              data: now,
              note: '',
              autoreId: uid,
            ),
          ],
          preaffidoDal: null,
          preaffidoAl: null,
          referenteId: uid,
          dataRichiesta: now,
          audit: audit,
        );
        await adoptersRepo?.save(adopter);
        await adoptions.save(adoption);
      }
      if (!mounted) {
        return;
      }
      AppToast.show(
        context,
        existing == null ? 'Richiesta registrata.' : 'Richiesta aggiornata.',
      );
      _leave();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dogs = ref
        .watch(dogsStreamProvider)
        .maybeWhen(data: (items) => items, orElse: () => const <Dog>[]);
    final existingId = widget.existingId;
    if (existingId != null && !_loadedExisting) {
      final adoptions = ref.watch(adoptionsStreamProvider).maybeWhen(
        data: (items) => items,
        orElse: () => const <Adoption>[],
      );
      for (final item in adoptions) {
        if (item.id == existingId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_loadedExisting) {
              setState(() => _fillExisting(item));
            }
          });
          break;
        }
      }
    }
    Dog? selected;
    for (final dog in dogs) {
      if (dog.id == _dogId) {
        selected = dog;
        break;
      }
    }
    final cover = selected == null
        ? null
        : ref.watch(coverPhotoProvider(selected.id));
    final title = _existing == null ? 'Nuova richiesta' : 'Modifica richiesta';
    final canSave = _canSave;

    return AppScaffold(
      compactHeader: true,
      title: title,
      onBack: () => unawaited(_onBack()),
      headerActions: [
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppDim.minTouch,
            minHeight: AppDim.minTouch,
          ),
          child: GestureDetector(
            key: NewAdoptionPage.saveKey,
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
      body: ListView(
        key: NewAdoptionPage.formListKey,
        padding: AppDim.pagePad,
        children: [
          FormCard(
            title: 'Cane',
            icon: AppIcons.carattere,
            children: [
              Material(
                color: AppColor.card,
                child: InkWell(
                  key: NewAdoptionPage.dogKey,
                  onTap: () => _pickDog(dogs),
                  child: SizedBox(
                    height: AppDim.minTouch,
                    child: Row(
                      children: [
                        PhotoThumb(
                          nome: selected?.nome ?? '?',
                          photo: cover,
                          width: AppDim.requestThumb,
                          height: AppDim.requestThumb,
                          radius: AppDim.formRad,
                        ),
                        const SizedBox(width: AppDim.formRowGap),
                        Expanded(
                          child: Text(
                            selected == null
                                ? 'Scegli il cane'
                                : dogDisplayName(selected.nome),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: AppText.body,
                              fontWeight: FontWeight.w700,
                              color: selected == null
                                  ? AppColor.faint
                                  : AppColor.ink,
                              height: AppDim.lineH,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: AppDim.iconNav,
                          color: AppColor.faint,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_dogError != null)
                Text(
                  _dogError!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: AppText.caption,
                    color: AppColor.red,
                    height: AppDim.lineH,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDim.gapM),
          FormCard(
            title: 'Richiedente',
            icon: AppIcons.richieste,
            children: [
              FormRow2(
                left: AppFormField(
                  key: NewAdoptionPage.nomeKey,
                  label: 'Nome',
                  controller: _nome,
                  errorText: _nomeError,
                ),
                right: AppFormField(
                  key: NewAdoptionPage.cognomeKey,
                  label: 'Cognome',
                  controller: _cognome,
                ),
              ),
              FormRow2(
                left: AppFormField(
                  key: NewAdoptionPage.telefonoKey,
                  label: 'Telefono',
                  controller: _telefono,
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => _lookupMatch(),
                ),
                right: AppFormField(
                  key: NewAdoptionPage.emailKey,
                  label: 'Email',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => _lookupMatch(),
                ),
              ),
              FormRow2(
                left: AppFormField(
                  key: NewAdoptionPage.cittaKey,
                  label: 'Città',
                  controller: _citta,
                ),
                right: AppFormField(
                  key: NewAdoptionPage.etaKey,
                  label: 'Età',
                  controller: _eta,
                  keyboardType: TextInputType.number,
                ),
              ),
              AppFormField(
                key: NewAdoptionPage.indirizzoKey,
                label: 'Indirizzo',
                controller: _indirizzo,
              ),
              FormRow2(
                left: AppFormField(
                  key: NewAdoptionPage.docTipoKey,
                  label: 'Documento',
                  child: AppSegmented(
                    values: _docTipi,
                    selectedIndex: _docTipo,
                    onChanged: (i) => setState(() => _docTipo = i),
                  ),
                ),
                right: AppFormField(
                  key: NewAdoptionPage.docNumeroKey,
                  label: 'Numero',
                  controller: _docNumero,
                ),
              ),
              if (_match != null)
                Material(
                  color: AppColor.greenSoft,
                  borderRadius: BorderRadius.circular(AppDim.formRad),
                  child: InkWell(
                    key: NewAdoptionPage.matchKey,
                    onTap: () => _useMatch(_match!),
                    borderRadius: BorderRadius.circular(AppDim.formRad),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDim.gapS,
                        vertical: AppDim.gapS,
                      ),
                      child: Text(
                        'Trovato: ${_match!.nomeCompleto}, '
                        '${_match!.adozioniIds.length} '
                        '${_match!.adozioniIds.length == 1 ? 'richiesta precedente' : 'richieste precedenti'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: AppText.caption,
                          color: AppColor.green,
                          height: AppDim.lineH,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDim.gapM),
          FormCard(
            title: 'Questionario',
            icon: AppIcons.modulo,
            children: [
              FormRow2(
                left: AppFormField(
                  key: NewAdoptionPage.abitazioneKey,
                  label: 'Abitazione',
                  child: AppSegmented(
                    values: _abitazioni,
                    selectedIndex: _abitazione,
                    onChanged: (i) => setState(() => _abitazione = i),
                  ),
                ),
                right: AppFormField(
                  key: NewAdoptionPage.oreKey,
                  label: 'Ore da solo',
                  controller: _ore,
                  keyboardType: TextInputType.number,
                ),
              ),
              CompatRow(
                key: NewAdoptionPage.giardinoRowKey,
                label: 'Giardino recintato',
                values: const ['Sì', 'No'],
                selectedIndex: _giardino ? 0 : 1,
                onChanged: (i) => setState(() => _giardino = i == 0),
              ),
              if (_giardino)
                AppFormField(
                  key: NewAdoptionPage.recinzioneKey,
                  label: 'Altezza (m)',
                  controller: _recinzione,
                ),
              CompatRow(
                key: NewAdoptionPage.animaliRowKey,
                label: 'Altri animali',
                values: const ['Sì', 'No'],
                selectedIndex: _altriAnimali ? 0 : 1,
                onChanged: (i) => setState(() => _altriAnimali = i == 0),
              ),
              if (_altriAnimali)
                AppFormField(
                  key: NewAdoptionPage.animaliKey,
                  label: 'Quali',
                  controller: _animaliQuali,
                ),
              CompatRow(
                key: NewAdoptionPage.bambiniRowKey,
                label: 'Bambini in casa',
                values: const ['Sì', 'No'],
                selectedIndex: _bambini ? 0 : 1,
                onChanged: (i) => setState(() => _bambini = i == 0),
              ),
              if (_bambini)
                AppFormField(
                  key: NewAdoptionPage.bambiniKey,
                  label: 'Età',
                  controller: _bambiniEta,
                ),
              CompatRow(
                key: NewAdoptionPage.esperienzaKey,
                label: 'Esperienza con cani',
                values: const ['Sì', 'No'],
                selectedIndex: _esperienza ? 0 : 1,
                onChanged: (i) => setState(() => _esperienza = i == 0),
              ),
              AppFormField(
                key: NewAdoptionPage.dormeKey,
                label: 'Dove dormirà',
                child: AppSegmented(
                  values: _dormeValori,
                  selectedIndex: _dorme,
                  onChanged: (i) => setState(() => _dorme = i),
                ),
              ),
              AppFormField(
                key: NewAdoptionPage.noteKey,
                label: 'Note',
                controller: _note,
                maxLines: 4,
                minLines: 1,
              ),
            ],
          ),
          const SizedBox(height: AppDim.gapL),
        ],
      ),
    );
  }
}
