import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/data_providers.dart';
import '../../data/models/adoption.dart';
import '../../data/models/app_document.dart';
import '../../data/models/dog.dart';
import '../../router.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../affido/affido_copy.dart';
import '../affido/affido_providers.dart';
import '../auth/auth_providers.dart';
import '../dashboard/home_aggregators.dart';
import '../dogs/dog_labels.dart';
import '../dogs/dogs_providers.dart';
import '../dogs/edit_permissions.dart';
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
  static const bannerKey = Key('richiesta-modulo-inviato');
  static const inviaModuloKey = Key('richiesta-invia-modulo');
  static const chiamaKey = Key('richiesta-chiama');
  static const emailKey = Key('richiesta-email');

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

  Future<void> _openTel(String value) async {
    final phone = value.trim();
    if (phone.isEmpty) {
      AppToast.show(context, 'Telefono non disponibile.');
      return;
    }
    final ok = await ref.read(appLinkOpenerProvider).open(
      Uri(scheme: 'tel', path: phone),
    );
    if (!ok && mounted) {
      AppToast.show(context, 'Impossibile aprire il telefono.');
    }
  }

  Future<void> _openMail(String value, String? dogName) async {
    final email = value.trim();
    if (email.isEmpty) {
      AppToast.show(context, 'Email non disponibile.');
      return;
    }
    final subject = dogName == null || dogName.isEmpty
        ? 'Adozione'
        : 'Adozione di $dogName';
    final ok = await ref.read(appLinkOpenerProvider).open(
      Uri(
        scheme: 'mailto',
        path: email,
        queryParameters: {'subject': subject},
      ),
    );
    if (!ok && mounted) {
      AppToast.show(context, 'Impossibile aprire l\'email.');
    }
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

  String? _inviatoBanner(Adoption adoption, WidgetRef ref) {
    final voce = latestModuloInviato(adoption);
    if (voce == null) {
      return null;
    }
    final nome = ref.watch(currentVolunteerProvider)?.nome ?? '';
    return moduloInviatoEtichetta(
      moduloId: voce.moduloId ?? 'preaffido',
      data: voce.data,
      volontarioNome: nome,
    );
  }

  Future<void> _editQuestionario(Adoption adoption) async {
    await context.push(AppRoutes.modificaRichiesta(adoption.id));
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
        final canWrite = canWriteRecords(ref.watch(currentVolunteerProvider));
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
                    child: GestureDetector(
                      onLongPress: () => _copy(
                        'Telefono',
                        adoption.richiedente.telefono,
                      ),
                      child: AppButton(
                        key: AdoptionDetailPage.chiamaKey,
                        label: 'Chiama',
                        variant: AppButtonVariant.ghost,
                        onPressed: () => _openTel(
                          adoption.richiedente.telefono,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDim.gapM),
                  Expanded(
                    child: GestureDetector(
                      onLongPress: () =>
                          _copy('Email', adoption.richiedente.email),
                      child: AppButton(
                        key: AdoptionDetailPage.emailKey,
                        label: 'Email',
                        variant: AppButtonVariant.grey,
                        onPressed: () => _openMail(
                          adoption.richiedente.email,
                          dog == null ? null : dogDisplayName(dog.nome),
                        ),
                      ),
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
                onSeeAll: !canWrite || _busy
                    ? null
                    : () => _editQuestionario(adoption),
              ),
              const SizedBox(height: AppDim.gapM),
              _QuestionarioCard(questionario: adoption.questionario),
              const SizedBox(height: AppDim.gapL),
              if (_inviatoBanner(adoption, ref) != null) ...[
                AppCard(
                  key: AdoptionDetailPage.bannerKey,
                  color: AppColor.greenTint,
                  child: Text(
                    _inviatoBanner(adoption, ref)!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: AppText.label,
                      color: AppColor.ink,
                      height: AppDim.lineH,
                    ),
                  ),
                ),
                const SizedBox(height: AppDim.gapL),
              ],
              const SectionTitle(
                title: 'Documenti',
                icon: IconBadge(AppIcons.documenti, size: IconBadge.inTitle),
              ),
              const SizedBox(height: AppDim.gapM),
              _DocumentiCard(
                adoption: adoption,
                documents: docs,
                canWrite: canWrite,
              ),
              const SizedBox(height: AppDim.gapL),
              if (canWrite &&
                  (canRejectAdoption(adoption.stato) ||
                      canAdvanceAdoption(adoption.stato)))
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
      onTap: () => AppRoutes.openDog(
        context,
        dog!.id,
        from: GoRouterState.of(context).uri.path,
      ),
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
                    if (dog!.adottabile == true)
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
    required this.canWrite,
  });

  final Adoption adoption;
  final List<AppDocument> documents;
  final bool canWrite;

  @override
  Widget build(BuildContext context) {
    final received = documents
        .where(
          (doc) =>
              doc.adoptionId == adoption.id ||
              doc.dogId == adoption.dogId ||
              (adoption.adopterId.isNotEmpty &&
                  doc.adopterId == adoption.adopterId),
        )
        .toList()
      ..sort((a, b) => b.caricatoIl.compareTo(a.caricatoIl));
    return AppCard(
      child: Column(
        children: [
          if (canWrite)
            OptionRow(
              key: AdoptionDetailPage.inviaModuloKey,
              icon: const IconBadge(AppIcons.modulo, size: IconBadge.inMenu),
              title: 'Invia modulo',
              subtitle: 'Preaffido o adozione in bianco',
              onTap: () => context.push(
                AppRoutes.affidoPer(
                  adoptionId: adoption.id,
                  dogId: adoption.dogId,
                ),
              ),
            ),
          if (received.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: AppDim.gapS),
              child: EmptyState(
                icon: IconBadge(AppIcons.allegato),
                message: 'Nessun documento ricevuto.',
                compact: true,
              ),
            )
          else
            for (final doc in received)
              OptionRow(
                icon: IconBadge(
                  AppIcons.perDocumento(doc.tipo.wire),
                  size: IconBadge.inMenu,
                ),
                title: doc.nome.isEmpty
                    ? documentTipoLabel(doc.tipo)
                    : doc.nome,
                subtitle: documentTipoLabel(doc.tipo),
                onTap: () => context.push(
                  AppRoutes.affidoPer(
                    adoptionId: adoption.id,
                    dogId: adoption.dogId,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
