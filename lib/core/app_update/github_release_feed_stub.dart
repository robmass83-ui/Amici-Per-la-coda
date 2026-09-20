import 'github_release.dart';

/// Stub web: l'updater APK non gira nel browser.
class GithubReleaseFeed {
  GithubReleaseFeed({
    this.owner = '',
    this.repo = '',
    this.token = '',
  });

  final String owner;
  final String repo;
  final String token;

  Future<GithubRelease?> fetchLatest({required List<String> preferredAbis}) {
    throw UnsupportedError('Aggiornamenti GitHub solo su Android.');
  }

  Future<void> downloadApk({
    required GithubRelease release,
    required String savePath,
    void Function(int received, int? total)? onProgress,
  }) {
    throw UnsupportedError('Aggiornamenti GitHub solo su Android.');
  }
}
