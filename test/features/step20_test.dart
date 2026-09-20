import 'dart:io';

import 'package:amici_per_la_coda/features/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';
import '../helpers/pubspec_version.dart';

void main() {
  const maxApkBytes = 30 * 1024 * 1024;

  String read(String path) => File(path).readAsStringSync();

  test('README copre Firebase, utenti e installazione volontari', () {
    final readme = read('README.md');
    expect(readme.contains('origini sconosciute'), isTrue);
    expect(readme.contains('Email/Password'), isTrue);
    expect(readme.contains('volunteers'), isTrue);
    expect(readme.contains('attivo'), isTrue);
    expect(readme.contains('presidente'), isTrue);
    expect(readme.contains('Non attivare Firebase Storage'), isTrue);
    expect(readme.contains('eur3'), isTrue);
    expect(readme.contains('flutterfire configure'), isTrue);
    expect(readme.contains('split-per-abi'), isTrue);
    expect(readme.contains('30 MB'), isTrue);
    expect(readme.contains('Disinstallare e reinstallare'), isTrue);
    expect(readme.contains('Firestore'), isTrue);
    expect(readme.contains('Condividi app'), isTrue);
    expect(readme.contains('keystore'), isTrue);
    expect(readme.contains('1aa1211e900e794873ea1632ed09f5ce116e20f87010d96a9ecbf699c9d68fe2'), isTrue);
    expect(readme.contains('publish_test_release.ps1'), isTrue);
  });

  test('keystore di firma configurato, gitignored, esempio presente', () {
    expect(File('android/key.properties.example').existsSync(), isTrue);
    expect(File('android/app/proguard-rules.pro').existsSync(), isTrue);
    expect(File('android/app/google-services.json').existsSync(), isTrue);

    final gradle = read('android/app/build.gradle.kts');
    expect(gradle.contains('signingConfigs'), isTrue);
    expect(gradle.contains('isMinifyEnabled = true'), isTrue);
    expect(gradle.contains('isShrinkResources = true'), isTrue);
    expect(gradle.contains('useLegacyPackaging = true'), isTrue);
    expect(gradle.contains('proguard-rules.pro'), isTrue);
    expect(gradle.contains('ANDROID_KEYSTORE_PATH'), isTrue);
    expect(gradle.contains('key.properties'), isTrue);

    final androidIgnore = read('android/.gitignore');
    expect(androidIgnore.contains('key.properties'), isTrue);
    expect(androidIgnore.contains('*.keystore') || androidIgnore.contains('**/*.keystore'), isTrue);
    expect(androidIgnore.contains('*.jks') || androidIgnore.contains('**/*.jks'), isTrue);

    final rootIgnore = read('.gitignore');
    expect(rootIgnore.contains('*.jks'), isTrue);
    expect(rootIgnore.contains('*.keystore'), isTrue);
    expect(rootIgnore.contains('key.properties'), isTrue);
  });

  test('CI e script di pubblicazione usano split-per-abi e tetto 30 MB', () {
    final workflow = read('.github/workflows/release-apk.yml');
    expect(workflow.contains('split-per-abi'), isTrue);
    expect(workflow.contains('31457280'), isTrue);
    expect(workflow.contains('EXPECTED_CERT_SHA256'), isTrue);
    expect(workflow.contains('ANDROID_DEBUG_KEYSTORE_BASE64'), isTrue);

    final script = read('tool/publish_test_release.ps1');
    expect(script.contains('split-per-abi'), isTrue);
    expect(script.contains('arm64-v8a'), isTrue);
    expect(script.contains('armeabi-v7a'), isTrue);
    expect(script.contains('Force'), isTrue);
  });

  test('APK ABI di release più nuovi del gradle pesano meno di 30 MB', () {
    const names = [
      'app-arm64-v8a-release.apk',
      'app-armeabi-v7a-release.apk',
    ];
    final gradleStamp = File('android/app/build.gradle.kts').lastModifiedSync();
    var checked = 0;
    for (final name in names) {
      final file = File('build/app/outputs/flutter-apk/$name');
      if (!file.existsSync()) {
        continue;
      }
      if (file.lastModifiedSync().isBefore(gradleStamp)) {
        continue;
      }
      checked += 1;
      expect(
        file.lengthSync(),
        lessThan(maxApkBytes),
        reason: '$name è ${file.lengthSync()} byte',
      );
    }
    expect(
      checked == names.length || checked == 0,
      isTrue,
    );
  });

  testWidgets('login mostra la versione del pubspec', (tester) async {
    await pumpApp(tester, size: const Size(360, 900));
    final version = pubspecVersionName();
    expect(find.byKey(LoginPage.versionKey), findsOneWidget);
    expect(find.text('Versione $version'), findsOneWidget);
  });
}
