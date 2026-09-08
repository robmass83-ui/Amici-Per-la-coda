import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_update/app_update_controller.dart';
import '../../core/app_update/app_update_state.dart';
import '../../ui/components.dart';
import 'update_sheet.dart';

/// Controlla GitHub all'apertura e alla ripresa dell'app, mostra il foglio
/// di aggiornamento e la notifica di sistema.
class AppUpdateListener extends ConsumerStatefulWidget {
  const AppUpdateListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppUpdateListener> createState() => _AppUpdateListenerState();
}

class _AppUpdateListenerState extends ConsumerState<AppUpdateListener>
    with WidgetsBindingObserver {
  bool _sheetOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        ref.read(appUpdateControllerProvider.notifier).check(),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(
        ref.read(appUpdateControllerProvider.notifier).onAppResumed(),
      );
    }
  }

  void _presentSheet() {
    if (_sheetOpen || !mounted) {
      return;
    }
    _sheetOpen = true;
    unawaited(
      AppSheet.present<void>(
        context: context,
        builder: (context) => const UpdateSheet(),
      ).whenComplete(() {
        _sheetOpen = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AppUpdateState>(appUpdateControllerProvider, (previous, next) {
      if (next.phase == AppUpdatePhase.available ||
          next.phase == AppUpdatePhase.downloading ||
          next.phase == AppUpdatePhase.installing) {
        _presentSheet();
      }
      if (next.phase == AppUpdatePhase.upToDate && next.userInitiated) {
        AppToast.show(context, 'Hai già l\'ultima versione.');
      }
      if (next.phase == AppUpdatePhase.failed &&
          next.userInitiated &&
          next.error != null &&
          !_sheetOpen) {
        AppToast.show(context, next.error!);
      }
    });
    return widget.child;
  }
}
