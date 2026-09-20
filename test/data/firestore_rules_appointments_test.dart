import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

int? _javaMajor(String home) {
  final exe = File(
    '$home${Platform.pathSeparator}bin${Platform.pathSeparator}java.exe',
  );
  if (!exe.existsSync()) {
    return null;
  }
  final result = Process.runSync(exe.path, const ['-version']);
  final text = '${result.stderr}${result.stdout}';
  final match = RegExp(r'version "(\d+)').firstMatch(text);
  return match == null ? null : int.tryParse(match.group(1)!);
}

String? _javaHome() {
  final candidates = <String>[
    r'C:\Program Files\Android\Android Studio\jbr',
    if ((Platform.environment['JAVA_HOME'] ?? '').isNotEmpty)
      Platform.environment['JAVA_HOME']!,
  ];
  final microsoft = Directory(r'C:\Program Files\Microsoft');
  if (microsoft.existsSync()) {
    for (final entity in microsoft.listSync()) {
      if (entity is Directory) {
        candidates.add(entity.path);
      }
    }
  }
  for (final path in candidates) {
    final major = _javaMajor(path);
    if (major != null && major >= 21) {
      return path;
    }
  }
  return null;
}

Map<String, String> _envWithJava() {
  final env = Map<String, String>.from(Platform.environment);
  final javaHome = _javaHome();
  if (javaHome != null) {
    env['JAVA_HOME'] = javaHome;
    env['PATH'] = '$javaHome\\bin;${env['PATH'] ?? ''}';
  }
  return env;
}

void main() {
  test('sceglie un JDK 21 o superiore per l\'emulatore', () {
    final home = _javaHome();
    expect(home, isNotNull, reason: 'Serve un JDK 21+ per l\'emulatore');
    expect(_javaMajor(home!), greaterThanOrEqualTo(21));
  });

  test(
    'le regole Firestore passano con l\'emulatore',
    () async {
      final backend = Directory('backend');
      expect(
        backend.existsSync(),
        isTrue,
        reason: 'Le regole stanno in backend/',
      );
      expect(
        _javaHome(),
        isNotNull,
        reason: 'Serve un JDK per l\'emulatore Firestore',
      );

      final env = _envWithJava();
      final npm = await Process.run(
        Platform.isWindows ? 'npm.cmd' : 'npm',
        const ['install', '--no-fund', '--no-audit'],
        workingDirectory: backend.path,
        environment: env,
        runInShell: true,
      );
      expect(
        npm.exitCode,
        0,
        reason: 'npm install:\n${npm.stdout}\n${npm.stderr}',
      );

      final result = await Process.run(
        Platform.isWindows ? 'firebase.cmd' : 'firebase',
        const [
          'emulators:exec',
          '--only',
          'firestore',
          '--project',
          'demo-amici-per-la-coda',
          'npm run test:rules',
        ],
        workingDirectory: backend.path,
        environment: env,
        runInShell: true,
      );
      expect(
        result.exitCode,
        0,
        reason:
            'emulatore Firestore:\n${result.stdout}\n${result.stderr}',
      );
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
