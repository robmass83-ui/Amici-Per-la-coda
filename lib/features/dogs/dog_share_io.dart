import 'dart:io';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

Future<void> shareSchedaBytes({
  required Uint8List bytes,
  required String fileName,
  required String text,
}) async {
  final file = File(
    '${Directory.systemTemp.path}${Platform.pathSeparator}$fileName',
  );
  await file.writeAsBytes(bytes, flush: true);
  await Share.shareXFiles([XFile(file.path)], text: text);
}

Future<void> shareSchedaTesto(String text) => Share.share(text);
