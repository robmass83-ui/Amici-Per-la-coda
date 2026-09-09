import 'dart:typed_data';

class PickedDocumentFile {
  const PickedDocumentFile({
    required this.bytes,
    required this.name,
    required this.mime,
  });

  final Uint8List bytes;
  final String name;
  final String mime;
}

abstract interface class DocumentFilePicker {
  Future<PickedDocumentFile?> pickPdf();
  Future<List<PickedDocumentFile>> pickImages();
}
