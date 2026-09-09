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
import 'adoption_flow.dart';

// ── CONTRATTO DI LAYOUT · Nuova richiesta ────────────────────────────────────
// AppScaffold  titolo «Nuova richiesta»  back
// ListView padding=12
// ├ AppTextField Cane  readOnly → sheet elenco
// ├ SizedBox 12
// ├ SectionTitle Richiedente
// ├ AppTextField Nome, Cognome, Telefono, Email, Città, Indirizzo,
// │              Documento, Numero, Età
// ├ (se match) AppCard  «Famiglia già in archivio»
// ├ SizedBox 12
// ├ SectionTitle Questionario
// ├ AppTextField Abitazione
// ├ AppSegmented Giardino  No/Sì
// ├ AppTextField recinzione, animali, bambini, ore, esperienza, dorme, note
// └ AppButton Salva richiesta  h=40
// ───────────────────────────────────────────────────────────────────────────

class NewAdoptionPage extends ConsumerStatefulWidget {
  const NewAdoptionPage({super.key, this.dogId});

  final String? dogId;

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
  static const animaliKey = Key('nuova-richiesta-animali');
  static const bambiniKey = Key('nuova-richiesta-bambini');
  static const oreKey = Key('nuova-richiesta-ore');
  static const esperienzaKey = Key('nuova-richiesta-esperienza');
  static const dormeKey = Key('nuova-richiesta-dorme');
  static const noteKey = Key('nuova-richiesta-note');
  static const matchKey = Key('nuova-richiesta-match');

  @override
  ConsumerState<NewAdoptionPage> createState() => _NewAdoptionPageState();
}

class _NewAdoptionPageState extends ConsumerState<NewAdoptionPage> {
  final _dog = TextEditingController();
  final _nome = TextEditingController();
  final _cognome = TextEditingController();
  final _telefono = TextEditingController();
  final _email = TextEditingController();
  final _citta = TextEditingController();
  final _indirizzo = TextEditingController();
  final _docTipo = TextEditingController(text: 'CI');
  final _docNumero = TextEditingController();
  final _eta = TextEditingController();
  final _abitazione = TextEditingController();
  final _recinzione = TextEditingController();
  final _animali = TextEditingController();
  final _bambini = TextEditingController();
  final _ore = TextEditingController();
  final _esperienza = TextEditingController();
  final _dorme = TextEditingController();
  final _note = TextEditingController();

  String? _dogId;
  String? _dogError;
  String? _nomeError;
  var _giardino = true;
  var _busy = false;
  Adopter? _match;

  @override
  void initState() {
    super.initState();
    _dogId = widget.dogId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _fillDogName();
    });
  }

  @override
  void dispose() {
    _dog.dispose();
    _nome.dispose();
    _cognome.dispose();
    _telefono.dispose();
    _email.dispose();
    _citta.dispose();
    _indirizzo.dispose();
    _docTipo.dispose();
    _docNumero.dispose();
    _eta.dispose();
    _abitazione.dispose();
    _recinzione.dispose();
    _animali.dispose();
    _bambini.dispose();
    _ore.dispose();
    _esperienza.dispose();
    _dorme.dispose();
    _note.dispose();
    super.dispose();
  }

  void _fillDogName() {
    final id = _dogId;
    if (id == null) {
      return;
    }
    final dogs = ref.read(dogsStreamProvider).maybeWhen(
      data: (items) => items,
      orElse: () => const <Dog>[],
    );
    for (final dog in dogs) {
      if (dog.id == id) {
        _dog.text = dogDisplayName(dog.nome);
        setState(() {});
        return;
      }
    }
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
      _docTipo.text = adopter.docTipo;
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
                _dog.text = dogDisplayName(dog.nome);
                _dogError = null;
              });
            },
          ),
      ],
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
      final audit = Audit(
        createdAt: now,
        createdBy: uid,
        updatedAt: now,
        updatedBy: uid,
      );
      final adoptionId = newEntityId('ad', now);
      final richiedente = Richiedente(
        nome: nome,
        cognome: _cognome.text.trim(),
        telefono: _telefono.text.trim(),
        email: _email.text.trim(),
        citta: _citta.text.trim(),
        indirizzo: _indirizzo.text.trim(),
        docTipo: _docTipo.text.trim(),
        docNumero: _docNumero.text.trim(),
        eta: int.tryParse(_eta.text.trim()) ?? 0,
      );
      var adopter = _match ??
          findMatchingAdopter(
            ref.read(adoptersStreamProvider).maybeWhen(
              data: (items) => items,
              orElse: () => const <Adopter>[],
            ),
            telefono: richiedente.telefono,
            email: richiedente.email,
          );
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
        questionario: Questionario(
          abitazione: _abitazione.text.trim(),
          giardinoRecintato: _giardino,
          altezzaRecinzione: _recinzione.text.trim(),
          altriAnimali: _animali.text.trim(),
          bambini: _bambini.text.trim(),
          oreDaSolo: _ore.text.trim(),
          esperienzaCani: _esperienza.text.trim(),
          doveDormira: _dorme.text.trim(),
          note: _note.text.trim(),
        ),
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
      if (!mounted) {
        return;
      }
      AppToast.show(context, 'Richiesta registrata.');
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.richieste);
      }
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
    return AppScaffold(
      title: 'Nuova richiesta',
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.richieste);
        }
      },
      body: ListView(
        padding: AppDim.pagePad,
        children: [
          AppTextField(
            key: NewAdoptionPage.dogKey,
            label: 'Cane',
            hint: 'Scegli il cane',
            controller: _dog,
            readOnly: true,
            errorText: _dogError,
            onTap: () => _pickDog(dogs),
            suffix: const Icon(
              Icons.chevron_right_rounded,
              size: AppDim.iconNav,
              color: AppColor.faint,
            ),
          ),
          const SizedBox(height: AppDim.gapL),
          const SectionTitle(
            title: 'Richiedente',
            icon: IconBadge(AppIcons.richieste, size: IconBadge.inTitle),
          ),
          const SizedBox(height: AppDim.gapM),
          AppTextField(
            key: NewAdoptionPage.nomeKey,
            label: 'Nome',
            controller: _nome,
            errorText: _nomeError,
          ),
          const SizedBox(height: AppDim.gapM),
          AppTextField(
            key: NewAdoptionPage.cognomeKey,
            label: 'Cognome',
            controller: _cognome,
          ),
          const SizedBox(height: AppDim.gapM),
          AppTextField(
            key: NewAdoptionPage.telefonoKey,
            label: 'Telefono',
            controller: _telefono,
            keyboardType: TextInputType.phone,
            onChanged: (_) => _lookupMatch(),
          ),
          const SizedBox(height: AppDim.gapM),
          AppTextField(
            key: NewAdoptionPage.emailKey,
            label: 'Email',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => _lookupMatch(),
          ),
          if (_match != null) ...[
            const SizedBox(height: AppDim.gapM),
            AppCard(
              key: NewAdoptionPage.matchKey,
              onTap: () => _useMatch(_match!),
              child: KeyValueRow(
                label: 'Famiglia già in archivio',
                value: _match!.nomeCompleto,
                valueColor: AppColor.green,
              ),
            ),
          ],
          const SizedBox(height: AppDim.gapM),
          AppTextField(
            key: NewAdoptionPage.cittaKey,
            label: 'Città',
            controller: _citta,
          ),
          const SizedBox(height: AppDim.gapM),
          AppTextField(
            key: NewAdoptionPage.indirizzoKey,
            label: 'Indirizzo',
            controller: _indirizzo,
          ),
          const SizedBox(height: AppDim.gapM),
          AppTextField(
            key: NewAdoptionPage.docTipoKey,
            label: 'Documento',
            controller: _docTipo,
          ),
          const SizedBox(height: AppDim.gapM),
          AppTextField(
            key: NewAdoptionPage.docNumeroKey,
            label: 'Numero documento',
            controller: _docNumero,
          ),
          const SizedBox(height: AppDim.gapM),
          AppTextField(
            key: NewAdoptionPage.etaKey,
            label: 'Età',
            controller: _eta,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppDim.gapL),
          const SectionTitle(
            title: 'Questionario',
            icon: IconBadge(AppIcons.questionario, size: IconBadge.inTitle),
          ),
          const SizedBox(height: AppDim.gapM),
          AppTextField(
            key: NewAdoptionPage.abitazioneKey,
            label: 'Abitazione',
            controller: _abitazione,
          ),
          const SizedBox(height: AppDim.gapM),
          const Text(
            'Giardino recintato',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: AppText.label,
              color: AppColor.muted,
              height: AppDim.lineH,
            ),
          ),
          const SizedBox(height: AppDim.gapXs),
          AppSegmented(
            values: const ['No', 'Sì'],
            selectedIndex: _giardino ? 1 : 0,
            onChanged: (index) => setState(() => _giardino = index == 1),
          ),
          const SizedBox(height: AppDim.gapM),
          AppTextField(
            key: NewAdoptionPage.recinzioneKey,
            label: 'Altezza recinzione',
            controller: _recinzione,
          ),
          const SizedBox(height: AppDim.gapM),
          AppTextField(
            key: NewAdoptionPage.animaliKey,
            label: 'Altri animali',
            controller: _animali,
          ),
          const SizedBox(height: AppDim.gapM),
          AppTextField(
            key: NewAdoptionPage.bambiniKey,
            label: 'Bambini in casa',
            controller: _bambini,
          ),
          const SizedBox(height: AppDim.gapM),
          AppTextField(
            key: NewAdoptionPage.oreKey,
            label: 'Ore da solo',
            controller: _ore,
          ),
          const SizedBox(height: AppDim.gapM),
          AppTextField(
            key: NewAdoptionPage.esperienzaKey,
            label: 'Esperienza cani',
            controller: _esperienza,
          ),
          const SizedBox(height: AppDim.gapM),
          AppTextField(
            key: NewAdoptionPage.dormeKey,
            label: 'Dove dormirà',
            controller: _dorme,
          ),
          const SizedBox(height: AppDim.gapM),
          AppTextField(
            key: NewAdoptionPage.noteKey,
            label: 'Note',
            controller: _note,
            fieldHeight: AppDim.statoNoteH,
            maxLines: 3,
          ),
          const SizedBox(height: AppDim.gapL),
          AppButton(
            key: NewAdoptionPage.saveKey,
            label: 'Salva richiesta',
            onPressed: _busy ? null : _save,
          ),
          const SizedBox(height: AppDim.gapL),
        ],
      ),
    );
  }
}
