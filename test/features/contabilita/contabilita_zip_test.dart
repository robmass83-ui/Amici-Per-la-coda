import 'dart:typed_data';

import 'package:amici_per_la_coda/core/firestore_codec.dart';
import 'package:amici_per_la_coda/data/models/documento_contabile.dart';
import 'package:amici_per_la_coda/features/contabilita/contabilita_logic.dart';
import 'package:amici_per_la_coda/features/contabilita/contabilita_zip.dart';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_contabilita_repository.dart';

void main() {
  test('lo zip ha il csv per primo e i byte originali', () {
    final a = doc(
      id: 'a',
      nome: 'Vet',
      data: DateTime(2026, 3, 12),
      tipologia: TipologiaContabile.fattura,
      mime: 'application/pdf',
    );
    final bytes = zipContabilita([
      (doc: a, bytes: Uint8List.fromList([1, 2, 3, 4])),
    ]);
    final decoded = ZipDecoder().decodeBytes(bytes);
    expect(decoded.files.first.name, 'riepilogo.csv');
    final file = decoded.findFile('2026-03-12_fattura_vet.pdf')!;
    expect(file.content, [1, 2, 3, 4]);
    expect(nomeZipAnno(2026), 'Amici_per_la_Coda_Contabilita_2026.zip');
  });

  test('offline senza byte non consegna uno zip', () async {
    final repo = InMemoryContabilitaRepository();
    final a = doc(id: 'manca');
    await expectLater(
      esportaZipAnno(repo: repo, documenti: [a], offline: true),
      throwsA(predicate((e) => '$e' == contabilitaExportOffline)),
    );
  });
}

DocumentoContabile doc({
  required String id,
  String nome = 'Doc',
  DateTime? data,
  TipologiaContabile tipologia = TipologiaContabile.fattura,
  String mime = 'application/pdf',
}) {
  return DocumentoContabile(
    id: id,
    anno: 2026,
    nome: nome,
    data: data ?? DateTime(2026, 3, 12),
    tipologia: tipologia,
    descrizione: '',
    importo: null,
    mime: mime,
    nomeFile: 'a.pdf',
    dimensione: 4,
    chunkCount: 1,
    generation: 1,
    audit: Audit.seed(DateTime.utc(2026, 3, 12), by: 'uid-1'),
  );
}
