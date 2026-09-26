import 'dart:typed_data';

import '../../data/documents/document_codec.dart';

List<Uint8List> splitContabilitaBytes(Uint8List bytes) {
  if (bytes.isEmpty) {
    throw ArgumentError.value(bytes, 'bytes', 'Il file non può essere vuoto.');
  }
  ensureDocumentSizeAllowed(bytes.lengthInBytes);
  final chunks = <Uint8List>[];
  for (
    var offset = 0;
    offset < bytes.lengthInBytes;
    offset += documentChunkBytes
  ) {
    final end = (offset + documentChunkBytes).clamp(0, bytes.lengthInBytes);
    chunks.add(Uint8List.fromList(bytes.sublist(offset, end)));
  }
  return chunks;
}
