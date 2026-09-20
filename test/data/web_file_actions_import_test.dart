import 'dart:io';

import 'package:amici_per_la_coda/data/documents/web_file_actions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WebFileShare e WebFileOpener esistono e non importano dart:io nel file web', () {
    expect(WebFileShare.new, isNotNull);
    expect(WebFileOpener.new, isNotNull);
  });

  group('sorgenti web senza dart:io', () {
    test('i file web non importano dart:io', () {
      const paths = [
        'lib/data/documents/web_file_actions.dart',
        'lib/data/firestore/identity_toolkit_http_web.dart',
        'lib/features/dogs/dog_share_web.dart',
        'lib/features/dogs/export/web_gallery_saver.dart',
      ];
      for (final path in paths) {
        final src = File(path).readAsStringSync();
        expect(src.contains("import 'dart:io'"), isFalse, reason: path);
      }
    });
  });
}
