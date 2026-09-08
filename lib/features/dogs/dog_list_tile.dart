import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/dog.dart';
import '../../data/models/photo.dart';
import '../../data/photos/cover_photo.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import 'dog_labels.dart';
import 'dogs_providers.dart';
import 'photo_thumb.dart';

// ── CONTRATTO DI LAYOUT · Card di un cane nell'elenco ──────────────────────
// AppCard  h=auto  padding=8  radius=11  bordo AppColor.line  fondo bianco
// └ Row  crossAxisAlignment=center
//   ├ foto/avatar  44×44  radius=9                      (flex: none)
//   ├ SizedBox w=9
//   ├ Expanded
//   │  └ Column  crossAxisAlignment=start  mainAxisSize=min
//   │     ├ Text nome            12.5sp w700  AppColor.ink   maxLines=1 ellipsis
//   │     ├ SizedBox h=1
//   │     ├ Text sottotitolo     10sp   w400  AppColor.muted maxLines=1 ellipsis
//   │     ├ SizedBox h=4
//   │     └ Wrap spacing=4 runSpacing=4
//   │        └ MiniBadge ×n      9sp w700  padding 2/6  radius 20
//   └ Icon chevron_right  size=16  AppColor.faint
// Distanza fra due card: 8
// ───────────────────────────────────────────────────────────────────────────

class DogListTile extends ConsumerWidget {
  const DogListTile({
    super.key,
    required this.dog,
    required this.now,
    this.onTap,
  });

  final Dog dog;
  final DateTime now;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref
        .watch(photosByDogProvider(dog.id))
        .maybeWhen(data: (items) => items, orElse: () => const <Photo>[]);
    final cover = coverPhotoOf(photos, dog.fotoCopertinaId);
    return AppCard(
      padding: const EdgeInsets.all(AppDim.radIconBox),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          PhotoThumb(nome: dog.nome, photo: cover),
          const SizedBox(width: AppDim.gapM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dog.nome,
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
                const SizedBox(height: AppDim.gapHair),
                Text(
                  dogListSubtitle(dog, now: now),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: AppText.caption,
                    color: AppColor.muted,
                    height: AppDim.lineH,
                  ),
                ),
                const SizedBox(height: AppDim.gapXs),
                Wrap(
                  spacing: AppDim.gapXs,
                  runSpacing: AppDim.gapXs,
                  children: [
                    MiniBadge(
                      label: dogStatoLabel(dog.stato),
                      variant: dogStatoBadge(dog.stato),
                    ),
                    if (dog.sterilizzato)
                      MiniBadge(label: dogSterilizedLabel(dog)),
                    if (dog.adottabile)
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
            size: AppDim.iconTab,
            color: AppColor.faint,
          ),
        ],
      ),
    );
  }
}
