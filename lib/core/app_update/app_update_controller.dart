import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_install_channel.dart';
import 'app_update_state.dart';
import 'github_release.dart';
import 'github_release_feed.dart';

final appUpdateEnabledProvider = Provider<bool>((ref) => true);

final githubReleaseFeedProvider = Provider<GithubReleaseFeed>((ref) {
  return GithubReleaseFeed();
});

final appUpdateControllerProvider =
    NotifierProvider<AppUpdateController, AppUpdateState>(
      AppUpdateController.new,
    );

class AppUpdateController extends Notifier<AppUpdateState> {
  bool _busy = false;
  final Set<String> _dismissedTags = <String>{};
  final Set<String> _notifiedTags = <String>{};
  bool _awaitingInstallPermission = false;
  GithubRelease? _pendingInstall;

  @override
  AppUpdateState build() => const AppUpdateState();

  Future<void> check({bool userInitiated = false}) async {
    if (!ref.read(appUpdateEnabledProvider)) {
      return;
    }
    if (_busy) {
      return;
    }
    _busy = true;
    state = state.copyWith(
      phase: AppUpdatePhase.checking,
      userInitiated: userInitiated,
      clearError: true,
    );
    try {
      final installed = await AppInstallChannel.getVersion();
      final feed = ref.read(githubReleaseFeedProvider);
      final release = await feed.fetchLatest(preferredAbis: installed.abis);
      if (release == null ||
          !release.isNewerThan(installedCode: installed.versionCode)) {
        state = AppUpdateState(
          phase: userInitiated
              ? AppUpdatePhase.upToDate
              : AppUpdatePhase.idle,
          installed: installed,
          userInitiated: userInitiated,
        );
        return;
      }
      if (!userInitiated && _dismissedTags.contains(release.tagName)) {
        state = AppUpdateState(
          phase: AppUpdatePhase.idle,
          installed: installed,
          release: release,
        );
        return;
      }
      state = AppUpdateState(
        phase: AppUpdatePhase.available,
        installed: installed,
        release: release,
        userInitiated: userInitiated,
      );
      if (_notifiedTags.add(release.tagName)) {
        await AppInstallChannel.requestNotificationPermission();
        await AppInstallChannel.showUpdateNotification(
          title: 'Nuova versione ${release.versionName}',
          body: 'Tocca Installa per scaricare e aggiornare l\'app.',
        );
      }
    } catch (error) {
      state = state.copyWith(
        phase: AppUpdatePhase.failed,
        error: userInitiated
            ? _italianError(error)
            : null,
        userInitiated: userInitiated,
        clearError: !userInitiated,
      );
    } finally {
      _busy = false;
    }
  }

  void dismiss() {
    final tag = state.release?.tagName;
    if (tag != null) {
      _dismissedTags.add(tag);
    }
    _pendingInstall = null;
    _awaitingInstallPermission = false;
    state = state.copyWith(
      phase: AppUpdatePhase.idle,
      userInitiated: false,
      clearError: true,
      clearProgress: true,
    );
  }

  Future<void> acceptAndInstall() async {
    final release = state.release ?? _pendingInstall;
    if (release == null) {
      return;
    }
    if (_busy) {
      return;
    }
    _busy = true;
    _pendingInstall = release;
    try {
      final allowed = await AppInstallChannel.canInstallPackages();
      if (!allowed) {
        _awaitingInstallPermission = true;
        await AppInstallChannel.requestInstallPermission();
        state = state.copyWith(
          phase: AppUpdatePhase.available,
          release: release,
          error:
              'Autorizza l\'installazione da questa app, poi tocca di nuovo Installa.',
        );
        return;
      }
      _awaitingInstallPermission = false;
      state = state.copyWith(
        phase: AppUpdatePhase.downloading,
        release: release,
        progress: 0,
        clearError: true,
      );
      final path = await AppInstallChannel.getDownloadPath();
      final feed = ref.read(githubReleaseFeedProvider);
      await feed.downloadApk(
        release: release,
        savePath: path,
        onProgress: (received, total) {
          if (total == null || total <= 0) {
            return;
          }
          state = state.copyWith(
            phase: AppUpdatePhase.downloading,
            progress: received / total,
          );
        },
      );
      state = state.copyWith(
        phase: AppUpdatePhase.installing,
        progress: 1,
      );
      await AppInstallChannel.installApk(path);
    } catch (error) {
      state = state.copyWith(
        phase: AppUpdatePhase.failed,
        error: _italianError(error),
        release: release,
      );
    } finally {
      _busy = false;
    }
  }

  Future<void> onAppResumed() async {
    if (_awaitingInstallPermission && _pendingInstall != null) {
      final allowed = await AppInstallChannel.canInstallPackages();
      if (allowed) {
        await acceptAndInstall();
        return;
      }
    }
    await check();
  }
}

String _italianError(Object error) {
  if (error is PlatformException) {
    final message = error.message?.trim();
    if (message != null && message.isNotEmpty) {
      return message;
    }
  }
  final text = error.toString();
  if (text.contains('SocketException') || text.contains('Failed host lookup')) {
    return 'Nessuna connessione. Riprova quando hai rete.';
  }
  if (text.contains('401') || text.contains('403')) {
    return 'GitHub ha rifiutato l\'accesso alla release.';
  }
  if (text.contains('404')) {
    return 'Nessuna release trovata su GitHub.';
  }
  if (text.contains('non è un APK') || text.contains('Download incompleto')) {
    return 'Il file scaricato non è un APK valido. Riprova.';
  }
  if (text.contains('firma')) {
    return 'La firma di questa build non coincide con l\'app installata. '
        'I dati restano su Firebase: disinstalla e reinstalla una volta sola.';
  }
  if (text.contains('più vecchia') || text.contains('versionCode')) {
    return 'Android non installa una versione uguale o più vecchia.';
  }
  return 'Aggiornamento non riuscito. Riprova.';
}

@visibleForTesting
String italianUpdateError(Object error) => _italianError(error);
