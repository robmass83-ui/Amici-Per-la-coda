import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// I componenti devono usare solo AppDim / AppText / AppColor, niente numeri grezzi
/// per padding, font, raggio, larghezza o altezza.
void main() {
  final forbidden = <RegExp>[
    RegExp(r'fontSize:\s*\d'),
    RegExp(r'(?<![\w.])(height|width):\s*\d'),
    RegExp(r'EdgeInsets\.(all|symmetric|only|fromLTRB)\(\s*\d'),
    RegExp(r'BorderRadius\.circular\(\s*\d'),
    RegExp(r'Radius\.circular\(\s*\d'),
    RegExp(r'(blurRadius|spreadRadius|letterSpacing):\s*\d'),
    RegExp(r'Color\(0x'),
  ];

  test('nessun valore numerico fuori da AppDim/AppText nei componenti', () {
    final dir = Directory('lib/ui/components');
    expect(dir.existsSync(), isTrue);

    final files = dir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.endsWith('icon_badge.dart'))
        .toList();
    expect(files, isNotEmpty);

    final violations = <String>[];
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) {
          continue;
        }
        for (final pattern in forbidden) {
          if (pattern.hasMatch(line)) {
            violations.add('${file.path}:${i + 1}: $line');
          }
        }
      }
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
