import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

Future<void> shareSchedaBytes({
  required Uint8List bytes,
  required String fileName,
  required String text,
}) {
  return Share.shareXFiles(
    [XFile.fromData(bytes, name: fileName)],
    text: text,
  );
}

Future<void> shareSchedaTesto(String text) => Share.share(text);
