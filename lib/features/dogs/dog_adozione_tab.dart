import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format_it.dart';
import '../../data/data_providers.dart';
import '../../data/models/adopter.dart';
import '../../data/models/adoption.dart';
import '../../data/models/dog.dart';
import '../../router.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../adoptions/family_link.dart';
import '../affido/affido_providers.dart';
import 'dog_labels.dart';
import 'dogs_providers.dart';
import 'edit_permissions.dart';
import 'export/adoption_export.dart';

// ── CONTRATTO DI LAYOUT · Tab Adozione ─────────────────────────────────────
// Padding 12/9  Column stretch
// ├ AppCard  banner adottabile
// ├ se nessun legame e canWrite:
// │    SizedBox 9  AppButton Registra famiglia
// │    SizedBox 9  AppButton grey Collega famiglia
// ├ se legame: SizedBox 9  AppCard famigliaCardKey
// │    nome / città / telefono  tap → profilo
// │    se canWrite: Sostituisci + Scollega
// └ AppCard  Annuncio  PDF / card / copia
// Nessun iter, nessuna lista richieste.
// ───────────────────────────────────────────────────────────────────────────

class DogAdozioneTab extends ConsumerWidget {
  const DogAdozioneTab({super.key, required this.dog});

  static const registraFamigliaKey = Key('dog-adozione-registra-famiglia');
  static const collegaFamigliaKey = Key('dog-adozione-collega-famiglia');
  static const famigliaCardKey = Key('dog-adozione-famiglia-card');
  static const scollegaKey = Key('dog-adozione-scollega');
  static const sostituisciKey = Key('dog-adozione-sostituisci');
  static const confermaSiKey = Key('dog-adozione-conferma-si');
  static const confermaNoKey = Key('dog-adozione-conferma-no');

  static const pdfKey = Key('dog-adozione-pdf');
  static const cardKey = Key('dog-adozione-card');
  static const copiaTestoKey = Key('dog-adozione-copia-testo');

  final Dog dog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(dogAdoptionsProvider(dog.id));
    final adopters = ref.watch(adoptersStreamProvider).maybeWhen(
          data: (items) => items,
          orElse: () => const <Adopter>[],
        );
    final link = familyLinkOf(requests, dog.id);
    Adopter? family;
    if (link != null) {
      for (final item in adopters) {
        if (item.id == link.adopterId) {
          family = item;
          break;
        }
      }
    }
    final nome = dogDisplayName(dog.nome);
    final canWrite = canWriteRecords(ref.watch(currentVolunteerProvider));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionTitle(
                title: dog.adottabile == true
                    ? '$nome è adottabile'
                    : '$nome non è adottabile',
                icon: const IconBadge(
                  AppIcons.adottabile,
                  size: IconBadge.inTitle,
                ),
              ),
              const SizedBox(height: AppDim.gapM),
              Text(
                _bannerText(dog),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: AppText.value,
                  color: AppColor.ink2,
                  height: AppDim.lineH,
                ),
              ),
            ],
          ),
        ),
        if (link == null && canWrite) ...[
          const SizedBox(height: AppDim.gapM),
          AppButton(
            key: registraFamigliaKey,
            label: 'Registra famiglia',
            onPressed: () => context.push(AppRoutes.adottanteNuovoPer(dog.id)),
          ),
          const SizedBox(height: AppDim.gapM),
          AppButton(
            key: collegaFamigliaKey,
            label: 'Collega famiglia',
            variant: AppButtonVariant.grey,
            onPressed: () => unawaited(
              _collega(context, ref, adopters: adopters, requests: requests),
            ),
          ),
        ],
        if (link != null) ...[
          const SizedBox(height: AppDim.gapM),
          AppCard(
            key: famigliaCardKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OptionRow(
                  icon: const IconBadge(
                    AppIcons.famiglie,
                    size: IconBadge.inMenu,
                  ),
                  title: (family?.nomeCompleto ??
                          link.richiedente.nomeCompleto)
                      .trim()
                      .isEmpty
                      ? '—'
                      : (family?.nomeCompleto ??
                          link.richiedente.nomeCompleto),
                  subtitle: [
                    if ((family?.citta ?? link.richiedente.citta).isNotEmpty)
                      family?.citta ?? link.richiedente.citta,
                    if ((family?.telefono ?? link.richiedente.telefono)
                        .isNotEmpty)
                      family?.telefono ?? link.richiedente.telefono,
                  ].join(' · '),
                  minHeight: AppDim.menuRowH,
                  titleSize: AppText.formCard,
                  onTap: link.adopterId.isEmpty
                      ? () {}
                      : () => context.push(AppRoutes.adottante(link.adopterId)),
                ),
                if (canWrite) ...[
                  const SizedBox(height: AppDim.gapM),
                  AppButton(
                    key: sostituisciKey,
                    label: 'Sostituisci',
                    variant: AppButtonVariant.grey,
                    onPressed: () => unawaited(
                      _collega(
                        context,
                        ref,
                        adopters: adopters,
                        requests: requests,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDim.gapM),
                  AppButton(
                    key: scollegaKey,
                    label: 'Scollega',
                    variant: AppButtonVariant.grey,
                    onPressed: () => unawaited(_scollega(ref, link)),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: AppDim.gapM),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle(
                title: 'Annuncio pubblico',
                icon: IconBadge(AppIcons.annuncio, size: IconBadge.inTitle),
              ),
              const SizedBox(height: AppDim.gapM),
              KeyValueRow(
                label: 'Pubblicato',
                value: _pubblicatoValue(dog),
                valueColor: dog.pubblicato ? AppColor.green : null,
              ),
              const SizedBox(height: AppDim.gapM),
              AppButton(
                key: pdfKey,
                label: 'Scheda di adozione (PDF)',
                onPressed: () => esportaSchedaAdozionePdf(
                  context: context,
                  ref: ref,
                  dog: dog,
                ),
              ),
              const SizedBox(height: AppDim.gapM),
              AppButton(
                key: cardKey,
                label: 'Card per i social (immagine)',
                variant: AppButtonVariant.grey,
                onPressed: () => esportaCardSocial(
                  context: context,
                  ref: ref,
                  dog: dog,
                ),
              ),
              const SizedBox(height: AppDim.gapM),
              AppButton(
                key: copiaTestoKey,
                label: 'Copia testo dell\'annuncio',
                variant: AppButtonVariant.grey,
                onPressed: () => copiaTestoAnnuncio(
                  context: context,
                  ref: ref,
                  dog: dog,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _collega(
    BuildContext context,
    WidgetRef ref, {
    required List<Adopter> adopters,
    required List<Adoption> requests,
  }) async {
    final tabContext = context;
    await AppSheet.present<void>(
      context: context,
      builder: (sheetContext) => AppSheet(
        title: 'Collega famiglia',
        children: [
          if (adopters.isEmpty)
            const Text(
              'Nessuna famiglia in anagrafe.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: AppText.body,
                color: AppColor.muted,
                height: AppDim.lineH,
              ),
            )
          else
            for (final adopter in adopters)
              OptionRow(
                icon: const IconBadge(
                  AppIcons.famiglie,
                  size: IconBadge.inMenu,
                ),
                title: adopter.nomeCompleto,
                subtitle: adopter.citta,
                minHeight: AppDim.menuRowH,
                titleSize: AppText.formCard,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  unawaited(
                    _linkThenConfirm(tabContext, ref, adopter, requests),
                  );
                },
              ),
        ],
      ),
    );
  }

  Future<void> _linkThenConfirm(
    BuildContext context,
    WidgetRef ref,
    Adopter adopter,
    List<Adoption> requests,
  ) async {
    final adoptions = ref.read(adoptionRepositoryProvider);
    final adopterRepo = ref.read(adopterRepositoryProvider);
    final volunteer = ref.read(currentVolunteerProvider);
    if (adoptions == null || adopterRepo == null || volunteer == null) {
      return;
    }
    final now = DateTime.now();
    await replaceDogFamily(
      adoptions: adoptions,
      adopters: adopterRepo,
      existing: requests,
      adopter: adopter,
      dogId: dog.id,
      uid: volunteer.id,
      now: now,
    );
    if (!context.mounted) {
      return;
    }
    await _confirmAdottato(context, ref);
  }

  Future<void> _confirmAdottato(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(dogRepositoryProvider);
    final volunteer = ref.read(currentVolunteerProvider);
    final current = dog;
    await AppSheet.present<void>(
      context: context,
      builder: (sheetContext) => AppSheet(
        title: 'Segnare ${dogDisplayName(current.nome)} come adottato?',
        children: [
          AppButton(
            key: confermaSiKey,
            label: 'Sì',
            onPressed: () {
              Navigator.of(sheetContext).pop();
              if (repo == null || volunteer == null) {
                return;
              }
              final result = markDogAdottatoIfNeeded(
                dog: current,
                now: DateTime.now(),
                autoreId: volunteer.id,
              );
              unawaited(repo.save(result.dog));
            },
          ),
          const SizedBox(height: AppDim.gapM),
          AppButton(
            key: confermaNoKey,
            label: 'No',
            variant: AppButtonVariant.grey,
            onPressed: () => Navigator.of(sheetContext).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _scollega(WidgetRef ref, Adoption link) async {
    final adoptions = ref.read(adoptionRepositoryProvider);
    final adopterRepo = ref.read(adopterRepositoryProvider);
    if (adoptions == null || adopterRepo == null) {
      return;
    }
    await adoptions.delete(link.id);
    final previous = await adopterRepo.getById(link.adopterId);
    if (previous != null) {
      await adopterRepo.save(previous.withoutAdozioneId(link.id));
    }
  }
}

String _pubblicatoValue(Dog dog) {
  if (!dog.pubblicato) {
    return 'Non pubblicato';
  }
  final at = dog.dataPubblicazione;
  if (at == null) {
    return 'Sì';
  }
  return formatItalianDate(at);
}

String _bannerText(Dog dog) {
  if (dog.slogan.isNotEmpty) {
    return dog.slogan;
  }
  if (dog.descrizione.isNotEmpty) {
    return dog.descrizione;
  }
  if (dog.adottabile == true) {
    return 'In attesa di una famiglia.';
  }
  return 'Al momento non è in adozione.';
}
