import 'dart:typed_data';

import 'package:gal/gal.dart';

import 'gallery_saver.dart';

class GalGallerySaver implements GallerySaver {
  @override
  Future<void> saveImage(Uint8List bytes, {required String fileName}) {
    final name = fileName.replaceFirst(RegExp(r'\.jpe?g$', caseSensitive: false), '');
    return Gal.putImageBytes(bytes, name: name);
  }
}
