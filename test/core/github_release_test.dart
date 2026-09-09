import 'dart:convert';
import 'dart:io';

import 'package:amici_per_la_coda/core/app_update/app_update_controller.dart';
import 'package:amici_per_la_coda/core/app_update/github_release.dart';
import 'package:amici_per_la_coda/core/app_update/github_release_feed.dart';
import 'package:flutter/services.dart';
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
      release.isNewerThan(installedCode: 1),
      isTrue,
    );
    expect(
      release.isNewerThan(installedCode: 2),
      isFalse,
    );
  });

  test('a parità di versionCode Android rifiuta l\'installazione', () {
    const release = GithubRelease(
      tagName: 'v1.0.1+1',
      versionName: '1.0.1',
      versionCode: 1,
      assetName: 'app-release.apk',
      downloadUrl: 'https://example.com/app.apk',
      apiAssetUrl: 'https://api.github.com/asset',
    );
    expect(
      release.isNewerThan(installedCode: 1),
      isFalse,
    );
    expect(
      release.isNewerThan(installedCode: 2),
      isFalse,
    );
  });

  test('un tag senza versionCode non è un aggiornamento', () {
    const release = GithubRelease(
      tagName: 'v1.0.3',
      versionName: '1.0.3',
      versionCode: 0,
      assetName: 'app-release.apk',
      downloadUrl: 'https://example.com/app.apk',
      apiAssetUrl: 'https://api.github.com/asset',
    );
    expect(
      release.isNewerThan(installedCode: 3),
      isFalse,
    );
  });

  test('sceglie l\'APK dell\'ABI del telefono, altrimenti l\'universale', () {
    const arm64 = GithubAsset(
      name: 'app-arm64-v8a-release.apk',
      downloadUrl: 'https://example.com/arm64.apk',
      apiUrl: 'https://api.github.com/arm64',
    );
    const v7a = GithubAsset(
      name: 'app-armeabi-v7a-release.apk',
      downloadUrl: 'https://example.com/v7a.apk',
      apiUrl: 'https://api.github.com/v7a',
    );
    const universal = GithubAsset(
      name: 'app-release.apk',
      downloadUrl: 'https://example.com/app.apk',
      apiUrl: 'https://api.github.com/app',
    );
    expect(
      pickApkAsset(
        [universal, v7a, arm64],
        preferredAbis: ['arm64-v8a', 'armeabi-v7a'],
      )?.name,
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
    expect(release.size, 18874368);
  });

  test('i falli di rete e di installazione diventano messaggi italiani', () {
    expect(
      italianUpdateError(Exception('SocketException: Failed host lookup')),
      'Nessuna connessione. Riprova quando hai rete.',
    );
    expect(
      italianUpdateError(Exception('GitHub ha risposto 401')),
      'GitHub ha rifiutato l\'accesso alla release.',
    );
    expect(
      italianUpdateError(
        const FormatException('Il file scaricato non è un APK valido.'),
      ),
      'Il file scaricato non è un APK valido. Riprova.',
    );
    expect(
      italianUpdateError(
        PlatformException(
          code: 'install',
          message:
              'La firma di questa build non coincide con l\'app installata. I dati restano su Firebase: disinstalla e reinstalla una volta sola.',
        ),
      ),
      'La firma di questa build non coincide con l\'app installata. I dati restano su Firebase: disinstalla e reinstalla una volta sola.',
    );
    expect(
      italianUpdateError(
        PlatformException(
          code: 'install',
          message:
              'Android non installa una versione uguale o più vecchia (codice 4, sul telefono c\'è 4).',
        ),
      ),
      'Android non installa una versione uguale o più vecchia (codice 4, sul telefono c\'è 4).',
    );
  });

  test('isApkFile accetta solo ZIP completi abbastanza grandi', () async {
    final dir = Directory.systemTemp.createTempSync('amici-apk');
    addTearDown(() => dir.deleteSync(recursive: true));
    final tooSmall = File('${dir.path}/small.apk')
      ..writeAsBytesSync(List<int>.filled(100, 0x50));
    final notZip = File('${dir.path}/html.apk')
      ..writeAsBytesSync(List<int>.filled(2 * 1024 * 1024, 0x3C));
    final truncated = File('${dir.path}/trunc.apk')
      ..writeAsBytesSync([0x50, 0x4B, ...List<int>.filled(2 * 1024 * 1024, 0)]);
    final ok = File('${dir.path}/ok.apk')..writeAsBytesSync(_validApkBytes());
    expect(await isApkFile(tooSmall), isFalse);
    expect(await isApkFile(notZip), isFalse);
    expect(await isApkFile(truncated), isFalse);
    expect(await isApkFile(ok), isTrue);
  });

  test('assertValidApk rifiuta un download di dimensione sbagliata', () async {
    final dir = Directory.systemTemp.createTempSync('amici-apk-size');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/ok.apk')..writeAsBytesSync(_validApkBytes());
    await expectLater(
      assertValidApk(file, expectedSize: 999),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Download incompleto'),
        ),
      ),
    );
    expect(file.existsSync(), isFalse);
  });
}

List<int> _validApkBytes() {
  final bytes = List<int>.filled(2 * 1024 * 1024, 0);
  bytes[0] = 0x50;
  bytes[1] = 0x4B;
  final eocd = bytes.length - 22;
  bytes[eocd] = 0x50;
  bytes[eocd + 1] = 0x4B;
  bytes[eocd + 2] = 0x05;
  bytes[eocd + 3] = 0x06;
  return bytes;
}

const _fixture = '''
{
  "tag_name": "v1.0.1+2",
  "body": "Correzioni.",
  "assets": [
    {
      "name": "notes.txt",
      "browser_download_url": "https://example.com/notes.txt",
      "url": "https://api.github.com/notes",
      "size": 12
    },
    {
      "name": "app-arm64-v8a-release.apk",
      "browser_download_url": "https://example.com/arm64.apk",
      "url": "https://api.github.com/arm64",
      "size": 18874368
    }
  ]
}
''';
