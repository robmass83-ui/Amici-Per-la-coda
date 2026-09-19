import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/data_providers.dart';
import '../../../data/models/dog.dart';
import '../../../data/models/health_record.dart';
import '../../../data/models/photo.dart';
import '../../../data/models/weight.dart';
import '../../../data/photos/cover_photo.dart';
import '../../../ui/components.dart';
import '../../../ui/tokens.dart';
import '../../dashboard/home_providers.dart';
import '../dogs_providers.dart';
import 'adoption_card_preview_page.dart';
import 'adoption_card_render.dart';
import 'adoption_pdf_preview_page.dart';
import 'adoption_post_text.dart';
import 'adoption_profile.dart';
import 'photo_prepare.dart';

Future<void> esportaSchedaAdozionePdf({
  required BuildContext context,
  required WidgetRef ref,
  required Dog dog,
}) async {
  final profile = await _preparaProfilo(context, ref, dog);
  if (profile == null || !context.mounted) {
    return;
  }
  await Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => AdoptionPdfPreviewPage(profile: profile),
    ),
  );
}

Future<void> esportaCardSocial({
  required BuildContext context,
  required WidgetRef ref,
  required Dog dog,
}) async {
  final profile = await _preparaProfilo(context, ref, dog);
  if (profile == null || !context.mounted) {
    return;
  }
  Uint8List? jpeg;
  try {
    jpeg = await captureAdoptionCardJpeg(context, profile);
  } catch (_) {
    if (context.mounted) {
      AppToast.show(context, 'Export non riuscito.');
    }
    return;
  }
  if (!context.mounted) {
    return;
  }
  await Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => AdoptionCardPreviewPage(
        profile: profile,
        jpeg: jpeg!,
      ),
    ),
  );
}

Future<void> copiaTestoAnnuncio({
  required BuildContext context,
  required WidgetRef ref,
  required Dog dog,
}) async {
  final profile = await _preparaProfilo(
    context,
    ref,
    dog,
    resizePhotos: false,
    loadPhotos: false,
  );
  if (profile == null || !context.mounted) {
    return;
  }
  await Clipboard.setData(ClipboardData(text: testoPostAdozione(profile)));
  if (context.mounted) {
    AppToast.show(context, 'Testo copiato negli appunti.');
  }
}

Future<AdoptionProfile?> _preparaProfilo(
  BuildContext context,
  WidgetRef ref,
  Dog dog, {
  bool resizePhotos = true,
  bool loadPhotos = true,
}) async {
  _showPrep(context);
  try {
    final now = ref.read(dogListNowProvider);
    final health = ref
        .read(healthByDogProvider(dog.id))
        .maybeWhen(
          data: (items) => items,
          orElse: () => const <HealthRecord>[],
        );
    final weights = ref
        .read(weightsByDogProvider(dog.id))
        .maybeWhen(
          data: (items) => items,
          orElse: () => const <Weight>[],
        );
    final photoRepo = ref.read(photoRepositoryProvider);
    final photos = !loadPhotos || photoRepo == null
        ? const <Photo>[]
        : await photoRepo.watchByDog(dog.id).first;
    final settings = ref.read(associationSettingsProvider).maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    Uint8List? assetLogo;
    try {
      assetLogo = await ref.read(assetBytesLoaderProvider).load(logoAssetPath);
    } catch (_) {
      assetLogo = null;
    }
    final association = AdoptionAssociation.fromSettings(
      settings,
      assetLogo: assetLogo,
    );
    if (association.logo == null || association.logo!.isEmpty) {
      debugPrint(
        'Export adozione: logo assente, uso il nome «${association.nome}».',
      );
    }
    final bytes = !loadPhotos
        ? const <Uint8List>[]
        : await _photoBytes(ref, dog, photos);
    final prepared = resizePhotos && bytes.isNotEmpty
        ? await preparePhotosForPdf(bytes)
        : bytes;
    return AdoptionProfile.fromDog(
      dog,
      health,
      weights,
      prepared,
      association,
      now: now,
    );
  } catch (_) {
    if (context.mounted) {
      AppToast.show(context, 'Export non riuscito.');
    }
    return null;
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}

Future<List<Uint8List>> _photoBytes(
  WidgetRef ref,
  Dog dog,
  List<Photo> photos,
) async {
  final cover = coverPhotoOf(photos, dog.fotoCopertinaId);
  final ordered = <Photo>[
    ?cover,
    ...photos.where((item) => item.id != cover?.id),
  ];
  final repo = ref.read(photoRepositoryProvider);
  final out = <Uint8List>[];
  for (final photo in ordered.take(maxFotoSchedaAdozione)) {
    Uint8List? full;
    if (repo != null) {
      full = await repo.loadFull(photo.id);
    }
    if (full == null && photo.thumb.isNotEmpty) {
      full = photo.thumb;
    }
    if (full != null && full.isNotEmpty) {
      out.add(full);
    }
  }
  return out;
}

void _showPrep(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return Center(
        child: Material(
          color: AppColor.card,
          borderRadius: BorderRadius.circular(AppDim.dialogRad),
          child: const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDim.gapXl,
              vertical: AppDim.gapL,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: AppDim.dialogSpinner,
                  height: AppDim.dialogSpinner,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColor.green,
                  ),
                ),
                SizedBox(height: AppDim.gapM),
                Text(
                  'Preparo la scheda…',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: AppText.body,
                    color: AppColor.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
