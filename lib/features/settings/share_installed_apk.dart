import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_update/installed_apk_share.dart';
import '../../data/data_providers.dart';
import '../../ui/components.dart';

Future<void> shareInstalledApk(BuildContext context, WidgetRef ref) async {
  try {
    final apk = await ref.read(installedApkShareProvider).prepare();
    if (!context.mounted) {
      return;
    }
    await ref.read(fileShareProvider).shareExistingFile(
      path: apk.path,
      fileName: apk.fileName,
      mime: 'application/vnd.android.package-archive',
      text:
          'Amici per la Coda ${apk.versionLabel}. Installa questo APK per usare la stessa versione.',
    );
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    AppToast.show(context, _italianShareError(error));
  }
}

String _italianShareError(Object error) {
  if (error is PlatformException) {
    final message = error.message?.trim();
    if (message != null && message.isNotEmpty) {
      return message;
    }
  }
  final text = error.toString();
  if (text.contains('non disponibile') || text.contains('non trovato')) {
    return 'APK installato non disponibile.';
  }
  return 'Impossibile condividere l\'app. Riprova.';
}
