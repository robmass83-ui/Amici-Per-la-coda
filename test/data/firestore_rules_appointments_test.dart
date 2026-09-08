import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String? _javaHome() {
  final fromEnv = Platform.environment['JAVA_HOME'];
  if (fromEnv != null &&
      fromEnv.isNotEmpty &&
      File('$fromEnv${Platform.pathSeparator}bin${Platform.pathSeparator}java.exe')
          .existsSync()) {
    return fromEnv;
  }
  const known = <String>[
    r'C:\Program Files\Android\Android Studio\jbr',
  ];
  for (final path in known) {
    if (File('$path\\bin\\java.exe').existsSync()) {
      return path;
    }
  }
  final microsoft = Directory(r'C:\Program Files\Microsoft');
  if (microsoft.existsSync()) {
    for (final entity in microsoft.listSync()) {
      if (entity is Directory &&
          File('${entity.path}\\bin\\java.exe').existsSync()) {
        return entity.path;
      }
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
  test(
    'volontario attivo si iscrive al turno; non può cambiare altri campi',
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
