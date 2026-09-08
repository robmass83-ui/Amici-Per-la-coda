import 'package:amici_per_la_coda/data/photos/photo_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'un JPEG 4000×3000 da ~4 MB produce full ≤ 700 KB e thumb ≤ 15 KB',
    () async {
      final source = await noisyPng(width: 4000, height: 3000);
      expect(source.lengthInBytes, greaterThan(2 * 1024 * 1024));

      final compressed = await compressDogPhoto(source);
      expect(compressed.full.lengthInBytes, lessThanOrEqualTo(photoFullMaxBytes));
      expect(
        compressed.thumb.lengthInBytes,
        lessThanOrEqualTo(photoThumbMaxBytes),
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
