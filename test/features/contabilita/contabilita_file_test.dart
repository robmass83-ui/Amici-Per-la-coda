import 'dart:typed_data';

import 'package:amici_per_la_coda/data/documents/document_file_picker.dart';
import 'package:amici_per_la_coda/features/contabilita/contabilita_file.dart';
import 'package:amici_per_la_coda/features/contabilita/contabilita_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('il pdf resta pdf', () async {
    final out = await preparaFileContabile(
      PickedDocumentFile(
        bytes: Uint8List.fromList([1, 2]),
        name: 'Fattura.PDF',
        mime: 'application/octet-stream',
      ),
    );

    expect(out.mime, 'application/pdf');
    expect(out.bytes, [1, 2]);
    expect(out.nomeFile, 'Fattura.PDF');
  });

  test('un docx è rifiutato', () async {
    expect(
      () => preparaFileContabile(
        PickedDocumentFile(
          bytes: Uint8List.fromList([1]),
          name: 'a.docx',
          mime:
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        ),
      ),
      throwsA(predicate((e) => e.toString() == contabilitaFileRifiutato)),
    );
  });

  test('accetta estensioni e mime pdf, jpeg e png', () {
    for (final name in ['a.pdf', 'a.jpg', 'a.jpeg', 'a.png']) {
      expect(
        fileContabileAccettato('application/octet-stream', name),
        isTrue,
        reason: name,
      );
    }
    for (final mime in ['application/pdf', 'image/jpeg', 'image/png']) {
      expect(
        fileContabileAccettato(mime, 'file'),
        isTrue,
        reason: mime,
      );
    }
    expect(
      fileContabileAccettato(
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'a.docx',
      ),
      isFalse,
    );
    expect(fileContabileAccettato('application/notpdf', 'a.bin'), isFalse);
    expect(fileContabileAccettato('image/png-template', 'a.bin'), isFalse);
  });
}
