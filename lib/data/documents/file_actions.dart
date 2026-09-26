import 'dart:typed_data';

abstract interface class FileShare {
  Future<void> shareFile({
    required Uint8List bytes,
    required String fileName,
    required String mime,
    required String text,
  });

  Future<void> shareExistingFile({
    required String path,
    required String fileName,
    required String mime,
    required String text,
  });

  Future<void> shareText(String text);
}

abstract interface class FileOpener {
  Future<void> openFile({
    required Uint8List bytes,
    required String fileName,
    required String mime,
  });
}
