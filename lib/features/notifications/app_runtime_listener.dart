import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_connectivity.dart';
import '../../core/local_notifications.dart';
import '../../data/data_providers.dart';
import '../dashboard/home_providers.dart';
import '../dogs/dogs_providers.dart';
import 'local_notification_plan.dart';
import 'notice_providers.dart';

final localNotificationsProvider = Provider<LocalNotifications>(
  (ref) => PluginLocalNotifications(),
);

final pendingWritesFlushProvider = Provider<Future<void> Function()?>((ref) {
  final db = ref.watch(firestoreProvider);
  if (db == null) {
    return null;
  }
  return db.waitForPendingWrites;
});

/// Allinea le notifiche locali alle 8:00 e, al rientro della rete, svuota
/// la coda di scritture di Firestore.
class AppRuntimeListener extends ConsumerStatefulWidget {
  const AppRuntimeListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppRuntimeListener> createState() => _AppRuntimeListenerState();
}

class _AppRuntimeListenerState extends ConsumerState<AppRuntimeListener>
    with WidgetsBindingObserver {
  var _ready = false;
  var _wasOffline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_boot());
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
      unawaited(_syncNotifications());
    }
  }

  Future<void> _boot() async {
    final plugin = ref.read(localNotificationsProvider);
    await plugin.initialize();
    await plugin.requestPermission();
    if (!mounted) {
      return;
    }
    _ready = true;
    await _syncNotifications();
  }

  Future<void> _syncNotifications() async {
    if (!_ready) {
      return;
    }
    final plugin = ref.read(localNotificationsProvider);
    final settings = ref.read(associationSettingsProvider).maybeWhen(
          data: (item) => item,
          orElse: () => null,
        );
    final plan = buildLocalNotificationPlan(
      dogs: ref.read(dogsStreamProvider).maybeWhen(
            data: (items) => items,
            orElse: () => const [],
          ),
      health: ref.read(healthAllProvider).maybeWhen(
            data: (items) => items,
            orElse: () => const [],
          ),
      adoptions: ref.read(adoptionsStreamProvider).maybeWhen(
            data: (items) => items,
            orElse: () => const [],
          ),
      switches: NotificationSwitches.fromSettings(settings),
      now: ref.read(dogListNowProvider),
    );
    await plugin.scheduleAll(plan);
  }

  Future<void> _flushWrites() async {
    final flush = ref.read(pendingWritesFlushProvider);
    if (flush == null) {
      return;
    }
    try {
      await flush();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(noticesProvider, (previous, next) {
      unawaited(_syncNotifications());
    });
    ref.listen(associationSettingsProvider, (previous, next) {
      unawaited(_syncNotifications());
    });
    ref.listen(connectivityResultsProvider, (previous, next) {
      final offline = next.maybeWhen(
        data: isOfflineConnectivity,
        orElse: () => false,
      );
      if (_wasOffline && !offline) {
        unawaited(_flushWrites());
      }
      _wasOffline = offline;
    });
    return widget.child;
  }
}
