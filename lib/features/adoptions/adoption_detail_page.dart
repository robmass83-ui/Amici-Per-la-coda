import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/firestore_codec.dart';
import '../../data/data_providers.dart';
import '../../data/models/adoption.dart';
import '../../data/models/app_document.dart';
import '../../data/models/dog.dart';
import '../../data/models/enums.dart';
import '../../router.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../auth/auth_providers.dart';
import '../dashboard/home_aggregators.dart';
import '../dogs/dog_labels.dart';
import '../dogs/dogs_providers.dart';
import '../dogs/tab_labels.dart';
import 'adoption_flow.dart';
import 'adoption_labels.dart';
import 'adoptions_page.dart';

// ── CONTRATTO DI LAYOUT · Dettaglio richiesta ──────────────────────────────
// AppScaffold  titolo «Richiesta · {cane}»  back
// ListView padding=12
// ├ AppCard padding=12  Row  avatar 44 · nome 15sp w800 · città 11sp · MiniBadge
// ├ SizedBox 9
// ├ Row gap=9  AppButton ghost Chiama · AppButton grey Email
// ├ SectionTitle Cane richiesto
// ├ AppCard tap → /animali/:id  Row  nome · razza · MiniBadge stato · chevron
// ├ SectionTitle Avanzamento iter
// ├ AppCard  TimelineList 5 tappe
// ├ SectionTitle Questionario  azione Modifica ›
// ├ AppCard  KeyValueRow × 7
// ├ SectionTitle Documenti
// ├ AppCard  OptionRow identità / preaffido
// ├ SizedBox 12
// └ Row  AppButton ghost Respingi · AppButton Avanza
// ───────────────────────────────────────────────────────────────────────────

class AdoptionDetailPage extends ConsumerStatefulWidget {
  const AdoptionDetailPage({super.key, required this.adoptionId});

  final String adoptionId;

  static const avanzaKey = Key('richiesta-avanza');
  static const respingiKey = Key('richiesta-respingi');
  static const confirmKey = Key('richiesta-conferma');
  static const cancelKey = Key('richiesta-annulla');
  static const saveQuestionarioKey = Key('richiesta-q-salva');
  static const abitazioneKey = Key('richiesta-q-abitazione');
  static const giardinoKey = Key('richiesta-q-giardino');
  static const recinzioneKey = Key('richiesta-q-recinzione');
  static const animaliKey = Key('richiesta-q-animali');
  static const bambiniKey = Key('richiesta-q-bambini');
  static const oreKey = Key('richiesta-q-ore');
  static const esperienzaKey = Key('richiesta-q-esperienza');
  static const dormeKey = Key('richiesta-q-dorme');
  static const noteKey = Key('richiesta-q-note');

  @override
  ConsumerState<AdoptionDetailPage> createState() =>
      _AdoptionDetailPageState();
}

class _AdoptionDetailPageState extends ConsumerState<AdoptionDetailPage> {
  var _busy = false;

  Adoption? _adoptionOf(List<Adoption> items) {
    for (final item in items) {
      if (item.id == widget.adoptionId) {
        return item;
      }
    }
    return null;
  }

  Dog? _dogOf(List<Dog> dogs, String dogId) {
    for (final dog in dogs) {
      if (dog.id == dogId) {
        return dog;
      }
    }
    return null;
  }

  Future<void> _copy(String label, String value) async {
    if (value.trim().isEmpty) {
      AppToast.show(context, '$label non disponibile.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: value.trim()));
    if (!mounted) {
      return;
    }
    AppToast.show(context, '$label copiato.');
  }

  Future<bool> _confirm(String title, String message) async {
    final result = await AppSheet.present<bool>(
      context: context,
      builder: (context) {
        return AppSheet(
          title: title,
          children: [
            Text(
              message,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: AppText.body,
                color: AppColor.ink,
                height: AppDim.lineH,
              ),
            ),
            const SizedBox(height: AppDim.gapL),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    key: AdoptionDetailPage.cancelKey,
                    label: 'Annulla',
                    variant: AppButtonVariant.grey,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: AppDim.gapM),
                Expanded(
                  child: AppButton(
                    key: AdoptionDetailPage.confirmKey,
                    label: 'Conferma',
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
    return result == true;
  }

  Future<void> _avanza(Adoption adoption, Dog dog) async {
    final next = nextAdoptionStato(adoption.stato);
    if (next == null) {
      return;
    }
    if (adoptionAdvanceNeedsConfirm(next)) {
      final ok = await _confirm(
        'Conferma adozione',
        'Il passaggio ad adozione definitiva è definitivo. Confermi?',
      );
      if (!ok) {
        return;
      }
    }
    await _apply((now, uid) {
      return advanceAdoption(
        adoption: adoption,
        dog: dog,
        now: now,
        autoreId: uid,
      );
    });
  }

  Future<void> _respingi(Adoption adoption, Dog dog) async {
    final ok = await _confirm(
      'Respingi richiesta',
      'La richiesta verrà archiviata come respinta. Il cane torna adottabile.',
    );
    if (!ok) {
      return;
    }
    await _apply((now, uid) {
      return rejectAdoption(
        adoption: adoption,
        dog: dog,
        now: now,
        autoreId: uid,
      );
    });
  }

  Future<void> _apply(
    ({Adoption adoption, Dog dog}) Function(DateTime now, String uid) build,
  ) async {
    final adoptions = ref.read(adoptionRepositoryProvider);
    final dogs = ref.read(dogRepositoryProvider);
    if (adoptions == null || dogs == null) {
      return;
    }
    setState(() => _busy = true);
    try {
      final now = ref.read(dogListNowProvider);
      final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
      final result = build(now, uid);
      await adoptions.save(result.adoption);
      await dogs.save(result.dog);
      if (mounted) {
        AppToast.show(context, 'Richiesta aggiornata.');
      }
    } on ArgumentError catch (error) {
      if (mounted) {
        AppToast.show(context, error.message?.toString() ?? 'Errore.');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _editQuestionario(Adoption adoption) async {
    await AppSheet.present<void>(
      context: context,
      builder: (sheetContext) {
        return SingleChildScrollView(
          child: _QuestionarioSheet(
            adoption: adoption,
            onSaved: () {
              if (mounted) {
                AppToast.show(context, 'Questionario salvato.');
              }
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adoptionsStreamProvider);
    final dogs = ref
        .watch(dogsStreamProvider)
        .maybeWhen(data: (items) => items, orElse: () => const <Dog>[]);
    final now = ref.watch(dogListNowProvider);

    return async.when(
      loading: () => AppScaffold(
        title: 'Richiesta',
        onBack: () => _back(context),
        body: const Center(
          child: SizedBox(
            width: AppDim.fabSize,
            height: AppDim.fabSize,
            child: CircularProgressIndicator(strokeWidth: AppDim.gapXs),
          ),
        ),
      ),
      error: (_, _) => AppScaffold(
        title: 'Richiesta',
        onBack: () => _back(context),
        body: const Center(
          child: EmptyState(
            icon: IconBadge(AppIcons.errore),
            message: 'Impossibile caricare la richiesta.',
          ),
        ),
      ),
      data: (items) {
        final adoption = _adoptionOf(items);
        if (adoption == null) {
          return AppScaffold(
            title: 'Richiesta',
            onBack: () => _back(context),
            body: const Center(
              child: EmptyState(
                icon: IconBadge(AppIcons.richieste),
                message: 'Richiesta non trovata.',
              ),
            ),
          );
        }
        final dog = _dogOf(dogs, adoption.dogId);
        final docs = ref
            .watch(documentsByDogProvider(adoption.dogId))
            .maybeWhen(
              data: (items) => items,
              orElse: () => const <AppDocument>[],
            );
        return AppScaffold(
          title: dog == null
              ? 'Richiesta'
              : 'Richiesta · ${dogDisplayName(dog.nome)}',
          onBack: () => _back(context),
          body: ListView(
            padding: AppDim.pagePad,
            children: [
              _HeaderCard(adoption: adoption),
              const SizedBox(height: AppDim.gapM),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Chiama',
                      variant: AppButtonVariant.ghost,
                      onPressed: () => _copy(
                        'Telefono',
                        adoption.richiedente.telefono,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDim.gapM),
                  Expanded(
                    child: AppButton(
                      label: 'Email',
                      variant: AppButtonVariant.grey,
                      onPressed: () =>
                          _copy('Email', adoption.richiedente.email),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDim.gapL),
              const SectionTitle(
                title: 'Cane richiesto',
                icon: IconBadge(AppIcons.carattere, size: IconBadge.inTitle),
              ),
              const SizedBox(height: AppDim.gapM),
              _DogCard(dog: dog, now: now),
              const SizedBox(height: AppDim.gapL),
              const SectionTitle(
                title: 'Avanzamento iter',
                icon: IconBadge(AppIcons.iter, size: IconBadge.inTitle),
              ),
              const SizedBox(height: AppDim.gapM),
              AppCard(child: TimelineList(items: iterTimelineItems(adoption))),
              const SizedBox(height: AppDim.gapL),
              SectionTitle(
                title: 'Questionario',
                icon: const IconBadge(
                  AppIcons.questionario,
                  size: IconBadge.inTitle,
                ),
                seeAllLabel: 'Modifica ›',
                onSeeAll: _busy ? null : () => _editQuestionario(adoption),
              ),
              const SizedBox(height: AppDim.gapM),
              _QuestionarioCard(questionario: adoption.questionario),
              const SizedBox(height: AppDim.gapL),
              const SectionTitle(
                title: 'Documenti',
                icon: IconBadge(AppIcons.documenti, size: IconBadge.inTitle),
              ),
              const SizedBox(height: AppDim.gapM),
              _DocumentiCard(adoption: adoption, documents: docs),
              const SizedBox(height: AppDim.gapL),
              if (canRejectAdoption(adoption.stato) ||
                  canAdvanceAdoption(adoption.stato))
                Row(
                  children: [
                    if (canRejectAdoption(adoption.stato))
                      Expanded(
                        child: AppButton(
                          key: AdoptionDetailPage.respingiKey,
                          label: 'Respingi',
                          variant: AppButtonVariant.ghost,
                          onPressed: _busy || dog == null
                              ? null
                              : () => _respingi(adoption, dog),
                        ),
                      ),
                    if (canRejectAdoption(adoption.stato) &&
                        canAdvanceAdoption(adoption.stato))
                      const SizedBox(width: AppDim.gapM),
                    if (canAdvanceAdoption(adoption.stato))
                      Expanded(
                        child: AppButton(
                          key: AdoptionDetailPage.avanzaKey,
                          label: adoptionAdvanceLabel(adoption.stato),
                          onPressed: _busy || dog == null
                              ? null
                              : () => _avanza(adoption, dog),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: AppDim.gapL),
            ],
          ),
        );
      },
    );
  }

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.richieste);
    }
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.adoption});

  final Adoption adoption;

  @override
  Widget build(BuildContext context) {
    final who = richiedenteNome(adoption);
    final luogo = [
      adoption.richiedente.citta,
      if (adoption.richiedente.eta > 0) '${adoption.richiedente.eta} anni',
    ].where((item) => item.isNotEmpty).join(' · ');
    return AppCard(
      padding: const EdgeInsets.all(AppDim.gapL),
      child: Row(
        children: [
          RequestInitialsAvatar(nome: who),
          const SizedBox(width: AppDim.gapM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  who.isEmpty ? '—' : who,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: AppText.title,
                    fontWeight: FontWeight.w800,
                    color: AppColor.ink,
                    height: AppDim.lineH,
                  ),
                ),
                Text(
                  luogo.isEmpty ? '—' : luogo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: AppText.label,
                    color: AppColor.muted,
                    height: AppDim.lineH,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDim.gapS),
          MiniBadge(
            label: adoptionListBadgeLabel(adoption.stato),
            variant: adoptionStatoBadge(adoption.stato),
          ),
        ],
      ),
    );
  }
}

class _DogCard extends StatelessWidget {
  const _DogCard({required this.dog, required this.now});

  final Dog? dog;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    if (dog == null) {
      return const AppCard(
        child: EmptyState(
          icon: IconBadge(AppIcons.carattere),
          message: 'Cane non trovato.',
          compact: true,
        ),
      );
    }
    return AppCard(
      onTap: () => context.push(AppRoutes.dog(dog!.id)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dogDisplayName(dog!.nome),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: AppText.body,
                    fontWeight: FontWeight.w700,
                    color: AppColor.ink,
                    height: AppDim.lineH,
                  ),
                ),
                Text(
                  dogListSubtitle(dog!, now: now),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: AppText.label,
                    color: AppColor.muted,
                    height: AppDim.lineH,
                  ),
                ),
                const SizedBox(height: AppDim.gapXs),
                Wrap(
                  spacing: AppDim.gapS,
                  runSpacing: AppDim.gapXs,
                  children: [
                    MiniBadge(
                      label: dogStatoLabel(dog!.stato),
                      variant: dogStatoBadge(dog!.stato),
                    ),
                    if (dog!.adottabile)
                      const MiniBadge(
                        label: 'Adottabile',
                        variant: MiniBadgeVariant.red,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: AppDim.iconNav,
            color: AppColor.faint,
          ),
        ],
      ),
    );
  }
}

class _QuestionarioCard extends StatelessWidget {
  const _QuestionarioCard({required this.questionario});

  final Questionario questionario;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          KeyValueRow(
            label: 'Abitazione',
            value: dashIfEmpty(questionario.abitazione),
          ),
          const SizedBox(height: AppDim.gapS),
          KeyValueRow(
            label: 'Giardino recintato',
            value: giardinoValue(questionario),
            valueColor: questionario.giardinoRecintato ? AppColor.green : null,
          ),
          const SizedBox(height: AppDim.gapS),
          KeyValueRow(
            label: 'Altri animali',
            value: dashIfEmpty(questionario.altriAnimali),
          ),
          const SizedBox(height: AppDim.gapS),
          KeyValueRow(
            label: 'Bambini in casa',
            value: dashIfEmpty(questionario.bambini),
          ),
          const SizedBox(height: AppDim.gapS),
          KeyValueRow(
            label: 'Ore da solo',
            value: dashIfEmpty(questionario.oreDaSolo),
          ),
          const SizedBox(height: AppDim.gapS),
          KeyValueRow(
            label: 'Esperienza cani',
            value: dashIfEmpty(questionario.esperienzaCani),
          ),
          const SizedBox(height: AppDim.gapS),
          KeyValueRow(
            label: 'Dove dormirà',
            value: dashIfEmpty(questionario.doveDormira),
          ),
        ],
      ),
    );
  }
}

class _DocumentiCard extends StatelessWidget {
  const _DocumentiCard({
    required this.adoption,
    required this.documents,
  });

  final Adoption adoption;
  final List<AppDocument> documents;

  @override
  Widget build(BuildContext context) {
    AppDocument? identita;
    AppDocument? preaffido;
    for (final doc in documents) {
      if (doc.adoptionId == adoption.id &&
          doc.tipo == DocumentTipo.anagrafe) {
        identita = doc;
      }
      if (doc.tipo == DocumentTipo.preaffido &&
          (doc.adoptionId == adoption.id || doc.dogId == adoption.dogId)) {
        preaffido = doc;
      }
    }
    return AppCard(
      child: Column(
        children: [
          OptionRow(
            icon: const IconBadge(AppIcons.anagrafe, size: IconBadge.inMenu),
            title: 'Documento d\'identità',
            subtitle: identita == null
                ? 'Non caricato'
                : documentTipoLabel(identita.tipo),
            onTap: () => AppToast.show(
              context,
              identita == null
                  ? 'Caricamento documenti: step successivo.'
                  : identita.nome,
            ),
          ),
          OptionRow(
            icon: const IconBadge(AppIcons.modulo, size: IconBadge.inMenu),
            title: 'Modulo di preaffido',
            subtitle: preaffido == null
                ? 'Non ancora generato'
                : documentTipoLabel(preaffido.tipo),
            onTap: () => context.push(AppRoutes.affido),
          ),
        ],
      ),
    );
  }
}

class _QuestionarioSheet extends ConsumerStatefulWidget {
  const _QuestionarioSheet({
    required this.adoption,
    required this.onSaved,
  });

  final Adoption adoption;
  final VoidCallback onSaved;

  @override
  ConsumerState<_QuestionarioSheet> createState() => _QuestionarioSheetState();
}

class _QuestionarioSheetState extends ConsumerState<_QuestionarioSheet> {
  late final TextEditingController _abitazione;
  late final TextEditingController _recinzione;
  late final TextEditingController _animali;
  late final TextEditingController _bambini;
  late final TextEditingController _ore;
  late final TextEditingController _esperienza;
  late final TextEditingController _dorme;
  late final TextEditingController _note;
  late bool _giardino;

  @override
  void initState() {
    super.initState();
    final q = widget.adoption.questionario;
    _abitazione = TextEditingController(text: q.abitazione);
    _recinzione = TextEditingController(text: q.altezzaRecinzione);
    _animali = TextEditingController(text: q.altriAnimali);
    _bambini = TextEditingController(text: q.bambini);
    _ore = TextEditingController(text: q.oreDaSolo);
    _esperienza = TextEditingController(text: q.esperienzaCani);
    _dorme = TextEditingController(text: q.doveDormira);
    _note = TextEditingController(text: q.note);
    _giardino = q.giardinoRecintato;
  }

  @override
  void dispose() {
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

  Future<void> _save() async {
    final repo = ref.read(adoptionRepositoryProvider);
    if (repo == null) {
      return;
    }
    final now = ref.read(dogListNowProvider);
    final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    final adoption = widget.adoption;
    await repo.save(
      adoption.withQuestionario(
        Questionario(
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
        audit: Audit(
          createdAt: adoption.audit.createdAt,
          createdBy: adoption.audit.createdBy,
          updatedAt: now,
          updatedBy: uid,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: 'Questionario',
      children: [
        AppTextField(
          key: AdoptionDetailPage.abitazioneKey,
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
          key: AdoptionDetailPage.giardinoKey,
          values: const ['No', 'Sì'],
          selectedIndex: _giardino ? 1 : 0,
          onChanged: (index) => setState(() => _giardino = index == 1),
        ),
        const SizedBox(height: AppDim.gapM),
        AppTextField(
          key: AdoptionDetailPage.recinzioneKey,
          label: 'Altezza recinzione',
          controller: _recinzione,
        ),
        const SizedBox(height: AppDim.gapM),
        AppTextField(
          key: AdoptionDetailPage.animaliKey,
          label: 'Altri animali',
          controller: _animali,
        ),
        const SizedBox(height: AppDim.gapM),
        AppTextField(
          key: AdoptionDetailPage.bambiniKey,
          label: 'Bambini in casa',
          controller: _bambini,
        ),
        const SizedBox(height: AppDim.gapM),
        AppTextField(
          key: AdoptionDetailPage.oreKey,
          label: 'Ore da solo',
          controller: _ore,
        ),
        const SizedBox(height: AppDim.gapM),
        AppTextField(
          key: AdoptionDetailPage.esperienzaKey,
          label: 'Esperienza cani',
          controller: _esperienza,
        ),
        const SizedBox(height: AppDim.gapM),
        AppTextField(
          key: AdoptionDetailPage.dormeKey,
          label: 'Dove dormirà',
          controller: _dorme,
        ),
        const SizedBox(height: AppDim.gapM),
        AppTextField(
          key: AdoptionDetailPage.noteKey,
          label: 'Note',
          controller: _note,
          fieldHeight: AppDim.statoNoteH,
          maxLines: 3,
        ),
        const SizedBox(height: AppDim.gapL),
        AppButton(
          key: AdoptionDetailPage.saveQuestionarioKey,
          label: 'Salva questionario',
          onPressed: _save,
        ),
      ],
    );
  }
}
