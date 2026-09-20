import 'dart:typed_data';

import 'package:amici_per_la_coda/data/photos/photo_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'tre immagini: limiti, proporzioni e tabella JPEG attuale vs pipeline nuova',
    () async {
      final camera = await noisyPng(width: 4000, height: 3000);
      final small = await solidPng(width: 64, height: 48);
      final alpha = await transparentPng(width: 320, height: 240);
      expect(camera.lengthInBytes, greaterThan(2 * 1024 * 1024));

      final cases = <(String, Uint8List, double)>[
        ('foto fotocamera ~4 MB', camera, 4000 / 3000),
        ('immagine già piccola', small, 64 / 48),
        ('PNG con trasparenza', alpha, 320 / 240),
      ];

      final savings = <double>[];
      final rows = <String>[];
      for (final (label, source, ratio) in cases) {
        final next = await compressDogPhoto(source);
        final jpeg = await compressDogPhotoJpegBaseline(source);
        expect(
          next.full.lengthInBytes,
          lessThanOrEqualTo(photoFullMaxBytes),
          reason: label,
        );
        expect(
          next.thumb.lengthInBytes,
          lessThanOrEqualTo(photoThumbMaxBytes),
          reason: label,
        );
        expect(next.width, lessThanOrEqualTo(photoFullMaxSide));
        expect(next.height, lessThanOrEqualTo(photoFullMaxSide));
        expect(next.width / next.height, closeTo(ratio, 0.03));
        expect(next.mime, anyOf(photoMimeWebp, photoMimeJpeg, photoMimePng));

        final save = 1 - next.full.lengthInBytes / jpeg.full.lengthInBytes;
        savings.add(save);
        rows.add(
          '$label\tsrc=${source.lengthInBytes}\t'
          'JPEG full=${jpeg.full.lengthInBytes} thumb=${jpeg.thumb.lengthInBytes}\t'
          'nuova (${next.mime}) full=${next.full.lengthInBytes} '
          'thumb=${next.thumb.lengthInBytes}\t'
          '${(save * 100).toStringAsFixed(1)}%',
        );
      }

      final avg = savings.reduce((a, b) => a + b) / savings.length;
      // ignore: avoid_print
      print('STEP4 codec (VM: PNG se il plugin WebP non c\'è):');
      for (final row in rows) {
        // ignore: avoid_print
        print(row);
      }
      // ignore: avoid_print
      print('risparmio medio full vs JPEG attuale: ${(avg * 100).toStringAsFixed(1)}%');
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
