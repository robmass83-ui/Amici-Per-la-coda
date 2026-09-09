import 'dart:convert';
import 'dart:io';

import 'github_release.dart';
import 'github_update_config.dart';

class GithubReleaseFeed {
  GithubReleaseFeed({
    this._httpClient,
    this.owner = GithubUpdateConfig.owner,
    this.repo = GithubUpdateConfig.repo,
    this.token = GithubUpdateConfig.token,
  });

  final String owner;
  final String repo;
  final String token;
  final HttpClient? _httpClient;

  Uri get latestUri => Uri.https(
    'api.github.com',
    '/repos/$owner/$repo/releases/latest',
  );

  Future<GithubRelease?> fetchLatest({required List<String> preferredAbis}) async {
    final client = _httpClient ?? HttpClient();
    final owned = _httpClient == null;
    try {
      final request = await client.getUrl(latestUri);
      _headers(request);
      final response = await request.close();
      final body = await utf8.decodeStream(response);
      if (response.statusCode == 404) {
        return null;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'GitHub ha risposto ${response.statusCode}.',
          uri: latestUri,
        );
      }
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        return null;
      }
      return parseGithubReleaseJson(
        {
          for (final entry in decoded.entries) '${entry.key}': entry.value,
        },
        preferredAbis: preferredAbis,
      );
    } finally {
      if (owned) {
        client.close(force: true);
      }
    }
  }

  Future<void> downloadApk({
    required GithubRelease release,
    required String savePath,
    void Function(int received, int? total)? onProgress,
  }) async {
    final client = _httpClient ?? HttpClient();
    final owned = _httpClient == null;
    try {
      final uri = token.isEmpty
          ? Uri.parse(release.downloadUrl)
          : Uri.parse(release.apiAssetUrl);
      var request = await client.getUrl(uri);
      _headers(request, download: true);
      var response = await request.close();
      if (response.statusCode >= 300 && response.statusCode < 400) {
        final location = response.headers.value(HttpHeaders.locationHeader);
        await response.drain<void>();
        if (location == null || location.isEmpty) {
          throw HttpException('Redirect GitHub senza destinazione.', uri: uri);
        }
        request = await client.getUrl(uri.resolve(location));
        _headers(request, download: true);
        response = await request.close();
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Download APK fallito (${response.statusCode}).',
          uri: uri,
        );
      }
      final total = response.contentLength >= 0 ? response.contentLength : null;
      final file = File(savePath);
      await file.parent.create(recursive: true);
      if (file.existsSync()) {
        await file.delete();
      }
      final sink = file.openWrite();
      var received = 0;
      try {
        await for (final chunk in response) {
          sink.add(chunk);
          received += chunk.length;
          onProgress?.call(received, total);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      if (!await isApkFile(file)) {
        await file.delete();
        throw const FormatException('Il file scaricato non è un APK valido.');
      }
    } finally {
      if (owned) {
        client.close(force: true);
      }
    }
  }

  void _headers(HttpClientRequest request, {bool download = false}) {
    request.headers.set(HttpHeaders.userAgentHeader, GithubUpdateConfig.userAgent);
    request.headers.set('X-GitHub-Api-Version', '2022-11-28');
    if (download && token.isNotEmpty) {
      request.headers.set(HttpHeaders.acceptHeader, 'application/octet-stream');
    } else {
      request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
    }
    if (token.isNotEmpty) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
  }
}

/// Un APK è uno ZIP: inizia con "PK" e pesa almeno 1 MB.
Future<bool> isApkFile(File file) async {
  if (!file.existsSync() || file.lengthSync() < 1024 * 1024) {
    return false;
  }
  final raf = file.openSync();
  try {
    final header = raf.readSync(2);
    return header.length == 2 && header[0] == 0x50 && header[1] == 0x4B;
  } finally {
    raf.closeSync();
  }
}
