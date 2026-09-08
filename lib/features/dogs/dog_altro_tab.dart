import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format_it.dart';
import '../../data/models/dog.dart';
import '../../data/models/photo.dart';
import '../../data/models/volunteer.dart';
import '../../router.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import 'dog_labels.dart';
import 'dogs_providers.dart';
import 'tab_labels.dart';

// ── CONTRATTO DI LAYOUT · Tab Altro ────────────────────────────────────────
// Padding 12/9  Column stretch
// ├ AppCard  OptionRow ×4  icona 32  titolo 12sp  subtitle 10sp  chevron 18
// ├ SizedBox 9
// ├ AppCard  Storico completo  TimelineList
// ├ SizedBox 9
// └ AppCard  OptionRow esporta / trasferisci / archivia (titolo rosso)
// ───────────────────────────────────────────────────────────────────────────

class DogAltroTab extends ConsumerWidget {
  const DogAltroTab({super.key, required this.dog});

  final Dog dog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              !other.archiviato,
        )
        .map((other) => dogDisplayName(other.nome))
        .where((name) => name.isNotEmpty)
        .toList();
    final photos = ref
        .watch(photosByDogProvider(dog.id))
        .maybeWhen(data: (items) => items, orElse: () => const <Photo>[]);
    final nFoto = photos.length;
    final gallerySubtitle = nFoto == 0
        ? 'Nessuna copertina'
        : (nFoto == 1 ? '1 foto' : '$nFoto foto');
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
                icon: const IconBadge(AppIcons.galleria, size: IconBadge.inMenu),
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
                icon: const IconBadge(AppIcons.box, size: IconBadge.inMenu),
                title: 'Box e collocazione',
                subtitle: boxLine.isEmpty ? '—' : boxLine,
                onTap: () => AppToast.show(
                  context,
                  'Box: disponibile negli step successivi.',
                ),
              ),
              OptionRow(
                icon: const IconBadge(
                  AppIcons.volontari,
                  size: IconBadge.inMenu,
                ),
                title: 'Volontario referente',
                subtitle: referente.isEmpty ? '—' : referente,
                onTap: () => AppToast.show(
                  context,
                  'Referente: disponibile negli step successivi.',
                ),
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
                        subtitle: voce.note.isEmpty
                            ? autoreEtichetta(volunteers, voce.autoreId)
                            : voce.note,
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
                icon: const IconBadge(AppIcons.esporta, size: IconBadge.inMenu),
                title: 'Esporta scheda in PDF',
                onTap: () => AppToast.show(
                  context,
                  'Esporta PDF: disponibile negli step successivi.',
                ),
              ),
              OptionRow(
                icon: const IconBadge(
                  AppIcons.trasferimento,
                  size: IconBadge.inMenu,
                ),
                title: 'Trasferisci ad altra struttura',
                onTap: () => AppToast.show(
                  context,
                  'Trasferimento: disponibile negli step successivi.',
                ),
              ),
              OptionRow(
                icon: const IconBadge(AppIcons.archivia, size: IconBadge.inMenu),
                title: 'Archivia scheda',
                titleColor: AppColor.red,
                onTap: () => AppToast.show(
                  context,
                  'Archivia: disponibile negli step successivi.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
