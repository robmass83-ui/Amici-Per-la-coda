import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import 'file_actions.dart';

Future<File> writeTempFile(Uint8List bytes, String fileName) async {
  final safe = fileName.replaceAll(RegExp(r'[^\w.\-]+'), '_');
  final file = File('${Directory.systemTemp.path}/$safe');
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

class SharePlusFileShare implements FileShare {
  @override
  Future<void> shareFile({
    required Uint8List bytes,
    required String fileName,
    required String mime,
    required String text,
  }) async {
    final file = await writeTempFile(bytes, fileName);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: mime, name: fileName)],
      text: text,
    );
  }
}

class OpenFilexOpener implements FileOpener {
  @override
  Future<void> openFile({
    required Uint8List bytes,
    required String fileName,
    required String mime,
  }) async {
    final file = await writeTempFile(bytes, fileName);
    await OpenFilex.open(file.path, type: mime);
  }
}
