import 'dart:typed_data';

const documentChunkBytes = 600 * 1024;
const documentMaxBytes = 10 * 1024 * 1024;
const documentInlineMaxBytes = 700 * 1024;

class DocumentTooLarge implements Exception {
  const DocumentTooLarge();

  static const message =
      'Il file pesa più di 10 MB. Riduci la scansione (meno pagine o qualità più bassa) e riprova.';

  @override
  String toString() => message;
}

int documentChunkCount(int byteLength) {
  if (byteLength <= documentInlineMaxBytes) {
    return 0;
  }
  return (byteLength + documentChunkBytes - 1) ~/ documentChunkBytes;
}

void ensureDocumentSizeAllowed(int byteLength) {
  if (byteLength > documentMaxBytes) {
    throw const DocumentTooLarge();
  }
}

List<Uint8List> splitDocumentBytes(Uint8List bytes) {
  if (bytes.lengthInBytes <= documentInlineMaxBytes) {
    return const [];
  }
  final chunks = <Uint8List>[];
  var offset = 0;
  while (offset < bytes.lengthInBytes) {
    final end = (offset + documentChunkBytes).clamp(0, bytes.lengthInBytes);
    chunks.add(Uint8List.fromList(bytes.sublist(offset, end)));
    offset = end;
  }
  return chunks;
}

Uint8List joinDocumentChunks(Iterable<Uint8List> chunks) {
  final total = chunks.fold<int>(0, (sum, chunk) => sum + chunk.lengthInBytes);
  final out = Uint8List(total);
  var offset = 0;
  for (final chunk in chunks) {
    out.setRange(offset, offset + chunk.lengthInBytes, chunk);
    offset += chunk.lengthInBytes;
  }
  return out;
}
