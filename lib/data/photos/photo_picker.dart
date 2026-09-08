import 'dart:typed_data';

abstract interface class PhotoPicker {
  Future<List<Uint8List>> pickFromGallery();
  Future<Uint8List?> pickFromCamera();
}
