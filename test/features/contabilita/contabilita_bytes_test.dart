import 'dart:typed_data';

import 'package:amici_per_la_coda/data/documents/document_codec.dart';
import 'package:amici_per_la_coda/features/contabilita/contabilita_bytes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('un file piccolo è un solo pezzo', () {
    final parts = splitContabilitaBytes(Uint8List.fromList([1, 2, 3, 4]));
    expect(parts, hasLength(1));
    expect(joinDocumentChunks(parts), [1, 2, 3, 4]);
  });

  test('sopra 600 KiB si spezza e si ricompone', () {
    final raw = Uint8List(documentChunkBytes + 10);
    raw[0] = 7;
    raw[documentChunkBytes] = 9;
    final parts = splitContabilitaBytes(raw);
    expect(parts.length, 2);
    expect(joinDocumentChunks(parts), raw);
  });

  test('oltre 10 MiB rifiuta', () {
    expect(
      () => splitContabilitaBytes(Uint8List(documentMaxBytes + 1)),
      throwsA(isA<DocumentTooLarge>()),
    );
  });

  test('un file vuoto rifiuta', () {
    expect(() => splitContabilitaBytes(Uint8List(0)), throwsArgumentError);
  });
}
