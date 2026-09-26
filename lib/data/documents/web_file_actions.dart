import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

import 'file_actions.dart';

class WebFileShare implements FileShare {
  @override
  Future<void> shareFile({
    required Uint8List bytes,
    required String fileName,
    required String mime,
    required String text,
  }) {
    return Share.shareXFiles(
      [XFile.fromData(bytes, mimeType: mime, name: fileName)],
      text: text,
    );
  }

  @override
  Future<void> shareExistingFile({
    required String path,
    required String fileName,
    required String mime,
    required String text,
  }) {
    return Share.share(text);
  }

  @override
  Future<void> shareText(String text) {
    return Share.share(text);
  }
}

class WebFileOpener implements FileOpener {
  @override
  Future<void> openFile({
    required Uint8List bytes,
    required String fileName,
    required String mime,
  }) {
    return Share.shareXFiles([
      XFile.fromData(bytes, mimeType: mime, name: fileName),
    ]);
  }
}
