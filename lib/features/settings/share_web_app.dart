import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/web_app.dart';
import '../../data/data_providers.dart';
import '../../ui/components.dart';

Future<void> shareWebApp(BuildContext context, WidgetRef ref) async {
  try {
    await ref.read(fileShareProvider).shareText(webAppShareText);
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
  return 'Impossibile condividere la web app. Riprova.';
}
