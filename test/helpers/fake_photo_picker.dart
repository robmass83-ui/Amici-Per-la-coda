import 'dart:typed_data';

import 'package:amici_per_la_coda/data/photos/photo_picker.dart';

class FakePhotoPicker implements PhotoPicker {
  FakePhotoPicker({this.gallery = const [], this.camera});

  List<Uint8List> gallery;
  Uint8List? camera;

  @override
  Future<List<Uint8List>> pickFromGallery() async => List.of(gallery);

  @override
  Future<Uint8List?> pickFromCamera() async => camera;
}
