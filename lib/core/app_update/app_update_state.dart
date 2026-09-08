import 'github_release.dart';
import 'installed_version.dart';

enum AppUpdatePhase {
  idle,
  checking,
  available,
  downloading,
  installing,
  upToDate,
  failed,
}

class AppUpdateState {
  const AppUpdateState({
    this.phase = AppUpdatePhase.idle,
    this.installed,
    this.release,
    this.progress,
    this.error,
    this.userInitiated = false,
  });

  final AppUpdatePhase phase;
  final InstalledVersion? installed;
  final GithubRelease? release;
  final double? progress;
  final String? error;
  final bool userInitiated;

  bool get hasUpdate =>
      phase == AppUpdatePhase.available ||
      phase == AppUpdatePhase.downloading ||
      phase == AppUpdatePhase.installing;

  AppUpdateState copyWith({
    AppUpdatePhase? phase,
    InstalledVersion? installed,
    GithubRelease? release,
    double? progress,
    String? error,
    bool? userInitiated,
    bool clearError = false,
    bool clearRelease = false,
    bool clearProgress = false,
  }) {
    return AppUpdateState(
      phase: phase ?? this.phase,
      installed: installed ?? this.installed,
      release: clearRelease ? null : (release ?? this.release),
      progress: clearProgress ? null : (progress ?? this.progress),
      error: clearError ? null : (error ?? this.error),
      userInitiated: userInitiated ?? this.userInitiated,
    );
  }
}
