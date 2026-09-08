import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import 'photo_picker.dart';

class ImagePhotoPicker implements PhotoPicker {
  ImagePhotoPicker({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<List<Uint8List>> pickFromGallery() async {
    final files = await _picker.pickMultiImage();
    final bytes = <Uint8List>[];
    for (final file in files) {
      bytes.add(await file.readAsBytes());
    }
    return bytes;
  }

  @override
  Future<Uint8List?> pickFromCamera() async {
    final file = await _picker.pickImage(source: ImageSource.camera);
    if (file == null) {
      return null;
    }
    return file.readAsBytes();
  }
}
