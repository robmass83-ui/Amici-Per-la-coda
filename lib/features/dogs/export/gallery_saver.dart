import 'dart:typed_data';

abstract interface class GallerySaver {
  Future<void> saveImage(Uint8List bytes, {required String fileName});
}
