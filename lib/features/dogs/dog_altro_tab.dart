import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format_it.dart';
import '../../data/data_providers.dart';
import '../../data/dog_archive.dart';
import '../../data/dog_purge.dart';
import '../../data/models/dog.dart';
import '../../data/models/enums.dart';
import '../../data/models/volunteer.dart';
import '../../router.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../affido/affido_providers.dart';
import '../auth/auth_providers.dart';
import '../volunteers/volunteer_labels.dart';
import 'dog_labels.dart';
import 'dogs_providers.dart';
import 'edit_permissions.dart';
import 'export/adoption_export.dart';
import 'record_actions.dart';
import 'tab_labels.dart';

// ── CONTRATTO DI LAYOUT · Tab Altro ────────────────────────────────────────
// Padding 12/9  Column stretch
// ├ AppCard  OptionRow ×4  icona 32  titolo 12sp  subtitle 10sp  chevron 18
// ├ SizedBox 9
// ├ AppCard  Storico completo  TimelineList
// ├ SizedBox 9
// └ AppCard  OptionRow esporta PDF / trasferisci / archivia / elimina (rosso)
//    OptionRow scheda PDF / trasferisci / archivia / elimina definitivamente
//    Scheda di adozione (PDF) → anteprima + condividi
// ───────────────────────────────────────────────────────────────────────────

class DogAltroTab extends ConsumerWidget {
  const DogAltroTab({super.key, required this.dog});

  static const archiviaKey = Key('dog-altro-archivia');
  static const eliminaKey = Key('dog-altro-elimina');
  static const trasferisciKey = Key('dog-altro-trasferisci');
  static const boxKey = Key('dog-altro-box');
  static const referenteKey = Key('dog-altro-referente');
  static const esportaPdfKey = Key('dog-altro-esporta-pdf');

  final Dog dog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canWrite = canWriteRecords(ref.watch(currentVolunteerProvider));
    final volunteers = ref
        .watch(volunteersStreamProvider)
        .maybeWhen(data: (items) => items, orElse: () => const <Volunteer>[]);
    final dogs = ref
        .watch(dogsStreamProvider)
        .maybeWhen(data: (items) => items, orElse: () => const <Dog>[]);
    final mates = dogs
        .where(
          (other) =>
              other.id != dog.id &&
              other.settore == dog.settore &&
              other.box == dog.box &&
              !dogEsclusoDaConteggiRifugio(other),
        )
        .map((other) => dogDisplayName(other.nome))
        .where((name) => name.isNotEmpty)
        .toList();
    final gallerySubtitle = dogGalleryCountLabel(dog);
    final referente = volunteerNomeDi(volunteers, dog.referenteId ?? '');
    final boxLine = [
      if (dog.settore.isNotEmpty) 'Settore ${dog.settore}',
      if (dog.box.isNotEmpty) 'Box ${dog.box}',
      if (mates.isNotEmpty) 'con ${mates.join(', ')}',
    ].join(' · ');
    final storico = List.of(dog.storicoStati)
      ..sort((a, b) => b.dal.compareTo(a.dal));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            children: [
              OptionRow(
                icon: const IconBadge(
                  AppIcons.galleria,
                  size: IconBadge.inMenu,
                ),
                title: 'Galleria foto e video',
                subtitle: gallerySubtitle,
                onTap: () => context.push(AppRoutes.dogFoto(dog.id)),
              ),
              OptionRow(
                icon: const IconBadge(
                  AppIcons.cambiaStato,
                  size: IconBadge.inMenu,
                ),
                title: 'Cambia stato del cane',
                subtitle: 'Attuale: ${dogStatoLabel(dog.stato)}',
                onTap: () => context.push(AppRoutes.dogStato(dog.id)),
              ),
              OptionRow(
                key: boxKey,
                icon: const IconBadge(AppIcons.box, size: IconBadge.inMenu),
                title: 'Box e collocazione',
                subtitle: boxLine.isEmpty ? '—' : boxLine,
                onTap: () => context.push(AppRoutes.boxPerCane(dog.id)),
              ),
              OptionRow(
                key: referenteKey,
                icon: const IconBadge(
                  AppIcons.volontari,
                  size: IconBadge.inMenu,
                ),
                title: 'Volontario referente',
                subtitle: referente.isEmpty ? '—' : referente,
                onTap: () => _pickReferente(context, ref, volunteers, canWrite),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDim.gapM),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle(
                title: 'Storico completo',
                icon: IconBadge(AppIcons.data, size: IconBadge.inTitle),
              ),
              const SizedBox(height: AppDim.gapM),
              if (storico.isEmpty)
                const Text(
                  'Nessuno storico.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: AppText.caption,
                    color: AppColor.muted,
                    height: AppDim.lineH,
                  ),
                )
              else
                TimelineList(
                  items: [
                    for (final voce in storico)
                      TimelineItem(
                        title:
                            '${formatItalianDate(voce.dal)} · ${dogStatoLabel(voce.stato)}',
                        subtitle: _storicoSubtitle(voce, volunteers),
                      ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: AppDim.gapM),
        AppCard(
          child: Column(
            children: [
              OptionRow(
                key: esportaPdfKey,
                icon: const IconBadge(AppIcons.schedaPdf, size: IconBadge.inMenu),
                title: 'Scheda di adozione (PDF)',
                onTap: () => esportaSchedaAdozionePdf(
                  context: context,
                  ref: ref,
                  dog: dog,
                ),
              ),
              if (canWrite) ...[
                OptionRow(
                  key: trasferisciKey,
                  icon: const IconBadge(
                    AppIcons.trasferimento,
                    size: IconBadge.inMenu,
                  ),
                  title: 'Trasferisci ad altra struttura',
                  onTap: () => context.push(
                    AppRoutes.dogStato(dog.id, stato: DogStato.trasferito.wire),
                  ),
                ),
                OptionRow(
                  key: archiviaKey,
                  icon: const IconBadge(
                    AppIcons.archivia,
                    size: IconBadge.inMenu,
                  ),
                  title: 'Archivia scheda',
                  titleColor: AppColor.red,
                  onTap: () =>
                      archiviaSchedaCane(context: context, ref: ref, dog: dog),
                ),
                OptionRow(
                  key: eliminaKey,
                  icon: const IconBadge(
                    AppIcons.elimina,
                    size: IconBadge.inMenu,
                  ),
                  title: 'Elimina definitivamente',
                  titleColor: AppColor.red,
                  onTap: () =>
                      eliminaSchedaCane(context: context, ref: ref, dog: dog),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickReferente(
    BuildContext context,
    WidgetRef ref,
    List<Volunteer> volunteers,
    bool canWrite,
  ) async {
    final attivi = volunteers.where((item) => item.attivo).toList();
    await AppSheet.show<void>(
      context: context,
      title: 'Volontario referente',
      children: [
        for (final volunteer in attivi)
          OptionRow(
            key: Key('dog-referente-${volunteer.id}'),
            icon: const IconBadge(AppIcons.volontari, size: IconBadge.inMenu),
            title: volunteerDisplayName(volunteer),
            subtitle: volunteer.email,
            onTap: () async {
              Navigator.of(context).pop();
              if (!canWrite) {
                return;
              }
              final repo = ref.read(dogRepositoryProvider);
              if (repo == null) {
                return;
              }
              final uid =
                  ref.read(authRepositoryProvider).currentUser?.uid ?? '';
              final now = ref.read(dogListNowProvider);
              await repo.save(
                dog.copyWith(
                  referenteId: volunteer.id,
                  audit: dog.audit.touched(uid, now),
                ),
              );
            },
          ),
      ],
    );
  }

  String _storicoSubtitle(StatoVoce voce, List<Volunteer> volunteers) {
    final base = voce.note.isEmpty
        ? autoreEtichetta(volunteers, voce.autoreId)
        : voce.note;
    final dest = voce.strutturaDestinazione?.trim() ?? '';
    if (dest.isEmpty) {
      return base;
    }
    if (base.isEmpty) {
      return dest;
    }
    return '$dest · $base';
  }
}

Future<void> archiviaSchedaCane({
  required BuildContext context,
  required WidgetRef ref,
  required Dog dog,
}) async {
  final nome = dogDisplayName(dog.nome);
  final ok = await confirmAction(
    context: context,
    title: 'Archivia scheda',
    message: 'Archiviare la scheda di $nome?',
    confirmLabel: 'Archivia',
  );
  if (!ok) {
    return;
  }
  final repo = ref.read(dogRepositoryProvider);
  if (repo == null) {
    if (context.mounted) {
      AppToast.show(context, 'Archivio cani non disponibile.');
    }
    return;
  }
  final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
  final now = ref.read(dogListNowProvider);
  await repo.save(applyArchivia(dog: dog, autoreId: uid, now: now));
  if (!context.mounted) {
    return;
  }
  context.go(AppRoutes.animali);
}

Future<void> eliminaSchedaCane({
  required BuildContext context,
  required WidgetRef ref,
  required Dog dog,
}) async {
  final nome = dogDisplayName(dog.nome);
  final ok = await confirmAction(
    context: context,
    title: 'Elimina scheda',
    message:
        'Eliminare per sempre la scheda di $nome? Foto, note, spese e documenti del cane verranno cancellati. Non si può annullare.',
    confirmLabel: 'Elimina',
  );
  if (!ok) {
    return;
  }
  final repo = ref.read(dogRepositoryProvider);
  if (repo == null) {
    if (context.mounted) {
      AppToast.show(context, 'Archivio cani non disponibile.');
    }
    return;
  }
  await purgeDogProfile(
    dogId: dog.id,
    dogs: repo,
    photos: ref.read(photoRepositoryProvider),
    health: ref.read(healthRepositoryProvider),
    weights: ref.read(weightRepositoryProvider),
    expenses: ref.read(expenseRepositoryProvider),
    notes: ref.read(noteRepositoryProvider),
    documents: ref.read(documentRepositoryProvider),
    sponsorships: ref.read(sponsorshipRepositoryProvider),
    appointments: ref.read(appointmentRepositoryProvider),
    adoptions: ref.read(adoptionRepositoryProvider),
  );
  if (!context.mounted) {
    return;
  }
  context.go(AppRoutes.animali);
}
