import 'package:flutter/material.dart';

import '../tokens.dart';

/// SnackBar ridisegnato: barra scura compatta in fondo.
abstract final class AppToast {
  static void show(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColor.ink,
        elevation: 0,
        margin: AppDim.pagePad,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDim.radChip),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: AppText.body,
            color: AppColor.card,
            height: AppDim.lineH,
          ),
        ),
      ),
    );
  }
}
