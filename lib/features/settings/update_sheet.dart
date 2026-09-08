import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_update/app_update_controller.dart';
import '../../core/app_update/app_update_state.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';

// ── CONTRATTO DI LAYOUT · Aggiornamento app ────────────────────────────────
// AppSheet titolo
// Column
// ├ testo corpo 12sp  maxLines=4
// ├ SizedBox 9
// ├ (se download) LinearProgressIndicator h=7  + percentuale 10sp
// ├ (se errore) testo red 10.5sp  maxLines=3
// ├ SizedBox 12
// └ Row gap=9
//    ├ Expanded AppButton grey "Dopo"
//    └ Expanded AppButton primary "Installa"
// ───────────────────────────────────────────────────────────────────────────

class UpdateSheet extends ConsumerWidget {
  const UpdateSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appUpdateControllerProvider);
    final release = state.release;
    final busy =
        state.phase == AppUpdatePhase.downloading ||
        state.phase == AppUpdatePhase.installing;
    final versionLabel = release == null
        ? ''
        : '${release.versionName} (${release.versionCode})';
    final installedLabel = state.installed?.label ?? '';

    final body = switch (state.phase) {
      AppUpdatePhase.downloading =>
        'Download della versione $versionLabel in corso.',
      AppUpdatePhase.installing =>
        'Download completato. Conferma l\'installazione su Android.',
      AppUpdatePhase.failed =>
        'Non sono riuscito a installare $versionLabel.',
      _ => installedLabel.isEmpty
          ? 'È disponibile la versione $versionLabel. Se accetti, la scarico e la installo subito.'
          : 'È disponibile la versione $versionLabel. Ora hai $installedLabel. Se accetti, la scarico e la installo subito.',
    };

    return AppSheet(
      title: 'Nuova versione',
      children: [
        Text(
          body,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: AppText.body,
            color: AppColor.ink2,
            height: AppDim.lineH,
          ),
        ),
        if (state.phase == AppUpdatePhase.downloading) ...[
          const SizedBox(height: AppDim.gapM),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDim.statBarR),
            child: LinearProgressIndicator(
              minHeight: AppDim.statBarH,
              value: state.progress,
              color: AppColor.green,
              backgroundColor: AppColor.barTrack,
            ),
          ),
          const SizedBox(height: AppDim.gapXs),
          Text(
            state.progress == null
                ? 'Download…'
                : '${((state.progress ?? 0) * 100).clamp(0, 100).round()}%',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: AppText.caption,
              color: AppColor.muted,
              height: AppDim.lineH,
            ),
          ),
        ],
        if (state.error != null) ...[
          const SizedBox(height: AppDim.gapM),
          Text(
            state.error!,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: AppText.label,
              color: AppColor.red,
              height: AppDim.lineH,
            ),
          ),
        ],
        const SizedBox(height: AppDim.gapL),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Dopo',
                variant: AppButtonVariant.grey,
                onPressed: busy
                    ? null
                    : () {
                        ref.read(appUpdateControllerProvider.notifier).dismiss();
                        Navigator.of(context).pop();
                      },
              ),
            ),
            const SizedBox(width: AppDim.gapM),
            Expanded(
              child: AppButton(
                label: busy ? 'Attendi' : 'Installa',
                onPressed: busy
                    ? null
                    : () => unawaited(
                        ref
                            .read(appUpdateControllerProvider.notifier)
                            .acceptAndInstall(),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
