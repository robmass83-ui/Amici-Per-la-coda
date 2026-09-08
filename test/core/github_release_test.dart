import 'dart:convert';

import 'package:amici_per_la_coda/core/app_update/app_update_controller.dart';
import 'package:amici_per_la_coda/core/app_update/github_release.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('il tag GitHub porta nome versione e versionCode', () {
    expect(parseReleaseTag('v1.0.1+2'), (versionName: '1.0.1', versionCode: 2));
    expect(parseReleaseTag('1.0.0+14'), (versionName: '1.0.0', versionCode: 14));
    expect(parseReleaseTag('v1.0.1'), (versionName: '1.0.1', versionCode: 0));
  });

  test('un versionCode più alto è un aggiornamento', () {
    const release = GithubRelease(
      tagName: 'v1.0.1+2',
      versionName: '1.0.1',
      versionCode: 2,
      assetName: 'app-release.apk',
      downloadUrl: 'https://example.com/app.apk',
      apiAssetUrl: 'https://api.github.com/asset',
    );
    expect(
      release.isNewerThan(installedCode: 1, installedName: '1.0.0'),
      isTrue,
    );
    expect(
      release.isNewerThan(installedCode: 2, installedName: '1.0.1'),
      isFalse,
    );
  });

  test('a parità di versionCode vince il nome versione più alto', () {
    const release = GithubRelease(
      tagName: 'v1.0.1+1',
      versionName: '1.0.1',
      versionCode: 1,
      assetName: 'app-release.apk',
      downloadUrl: 'https://example.com/app.apk',
      apiAssetUrl: 'https://api.github.com/asset',
    );
    expect(
      release.isNewerThan(installedCode: 1, installedName: '1.0.0'),
      isTrue,
    );
  });

  test('sceglie l\'APK dell\'ABI del telefono, altrimenti l\'universale', () {
    const arm64 = GithubAsset(
      name: 'app-arm64-v8a-release.apk',
      downloadUrl: 'https://example.com/arm64.apk',
      apiUrl: 'https://api.github.com/arm64',
    );
    const universal = GithubAsset(
      name: 'app-release.apk',
      downloadUrl: 'https://example.com/app.apk',
      apiUrl: 'https://api.github.com/app',
    );
    expect(
      pickApkAsset([universal, arm64], preferredAbis: ['arm64-v8a'])?.name,
      'app-arm64-v8a-release.apk',
    );
    expect(
      pickApkAsset([universal], preferredAbis: ['arm64-v8a'])?.name,
      'app-release.apk',
    );
  });

  test('legge l\'ultima release GitHub e ignora gli asset non APK', () {
    final decoded = jsonDecode(_fixture);
    expect(decoded, isA<Map<String, dynamic>>());
    final json = Map<String, Object?>.from(decoded as Map<String, dynamic>);
    final release = parseGithubReleaseJson(
      json,
      preferredAbis: const ['arm64-v8a', 'armeabi-v7a'],
    );
    expect(release, isNotNull);
    expect(release!.tagName, 'v1.0.1+2');
    expect(release.versionName, '1.0.1');
    expect(release.versionCode, 2);
    expect(release.assetName, 'app-arm64-v8a-release.apk');
    expect(release.downloadUrl, 'https://example.com/arm64.apk');
  });

  test('i falli di rete diventano messaggi italiani', () {
    expect(
      italianUpdateError(Exception('SocketException: Failed host lookup')),
      'Nessuna connessione. Riprova quando hai rete.',
    );
    expect(
      italianUpdateError(Exception('GitHub ha risposto 401')),
      'GitHub ha rifiutato l\'accesso alla release.',
    );
  });
}

const _fixture = '''
{
  "tag_name": "v1.0.1+2",
  "body": "Correzioni.",
  "assets": [
    {
      "name": "notes.txt",
      "browser_download_url": "https://example.com/notes.txt",
      "url": "https://api.github.com/notes"
    },
    {
      "name": "app-arm64-v8a-release.apk",
      "browser_download_url": "https://example.com/arm64.apk",
      "url": "https://api.github.com/arm64"
    }
  ]
}
''';
