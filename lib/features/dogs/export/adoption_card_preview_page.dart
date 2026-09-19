import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/data_providers.dart';
import '../../../ui/components.dart';
import '../../../ui/tokens.dart';
import 'adoption_post_text.dart';
import 'adoption_profile.dart';

class AdoptionCardPreviewPage extends ConsumerWidget {
  const AdoptionCardPreviewPage({
    super.key,
    required this.profile,
    required this.jpeg,
  });

  static const pageKey = Key('adoption-card-preview');
  static const shareKey = Key('adoption-card-share');
  static const saveKey = Key('adoption-card-save');

  final AdoptionProfile profile;
  final Uint8List jpeg;

  Future<void> _share(WidgetRef ref) {
    return ref.read(fileShareProvider).shareFile(
      bytes: jpeg,
      fileName: fileNameCardJpeg(profile.nome),
      mime: 'image/jpeg',
      text: testoPostAdozione(profile),
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(gallerySaverProvider).saveImage(
        jpeg,
        fileName: fileNameCardJpeg(profile.nome),
      );
      if (context.mounted) {
        AppToast.show(context, 'Salvata nella galleria.');
      }
    } catch (_) {
      if (context.mounted) {
        AppToast.show(context, 'Salvataggio non riuscito.');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      key: AdoptionCardPreviewPage.pageKey,
      backgroundColor: AppColor.bg,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: AppHeader(
              title: 'Card per i social',
              compact: true,
              onBack: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: Padding(
              padding: AppDim.pagePad,
              child: Center(
                child: AspectRatio(
                  aspectRatio: AppDim.exportCardW / AppDim.exportCardH,
                  child: Image.memory(jpeg, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDim.gapL,
                AppDim.gapS,
                AppDim.gapL,
                AppDim.gapL,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      key: shareKey,
                      label: 'Condividi',
                      onPressed: () => _share(ref),
                    ),
                  ),
                  const SizedBox(width: AppDim.gapM),
                  Expanded(
                    child: AppButton(
                      key: saveKey,
                      label: 'Salva nella galleria',
                      variant: AppButtonVariant.grey,
                      onPressed: () => _save(context, ref),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
