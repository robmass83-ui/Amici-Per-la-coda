import 'dart:io';

String pubspecVersionName() {
  final yaml = File('pubspec.yaml').readAsStringSync();
  final match = RegExp(
    r'^version:\s*([^+\s]+)',
    multiLine: true,
  ).firstMatch(yaml);
  if (match == null) {
    throw StateError('version mancante in pubspec.yaml');
  }
  return match.group(1)!;
}
