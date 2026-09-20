import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

import 'gallery_saver.dart';

class WebGallerySaver implements GallerySaver {
  @override
  Future<void> saveImage(Uint8List bytes, {required String fileName}) {
    return Share.shareXFiles([
      XFile.fromData(bytes, mimeType: 'image/jpeg', name: fileName),
    ]);
  }
}
