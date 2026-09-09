import 'dart:typed_data';

abstract interface class FileShare {
  Future<void> shareFile({
    required Uint8List bytes,
    required String fileName,
    required String mime,
    required String text,
  });
}

abstract interface class FileOpener {
  Future<void> openFile({
    required Uint8List bytes,
    required String fileName,
    required String mime,
  });
}
