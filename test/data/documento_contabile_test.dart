import 'package:amici_per_la_coda/core/firestore_codec.dart';
import 'package:amici_per_la_coda/data/models/documento_contabile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final audit = Audit.seed(DateTime.utc(2026, 3, 12), by: 'uid-1');

  test('tipologia wire ed etichetta', () {
    expect(TipologiaContabile.fattura.wire, 'fattura');
    expect(TipologiaContabile.fattura.etichetta, 'Fattura');
    expect(TipologiaContabile.scontrino.etichetta, 'Scontrino');
    expect(TipologiaContabile.ricevuta.etichetta, 'Ricevuta');
    expect(TipologiaContabile.preventivo.etichetta, 'Preventivo');
    expect(TipologiaContabile.altro.etichetta, 'Altro');
    expect(TipologiaContabile.parse('scontrino'), TipologiaContabile.scontrino);
    expect(TipologiaContabile.parse('nope'), TipologiaContabile.altro);
  });

  test('importo assente non diventa zero', () {
    final doc = DocumentoContabile(
      id: 'd1',
      anno: 2026,
      nome: 'Fattura vet',
      data: DateTime.utc(2026, 3, 12),
      tipologia: TipologiaContabile.fattura,
      descrizione: '',
      importo: null,
      mime: 'application/pdf',
      nomeFile: 'f.pdf',
      dimensione: 10,
      chunkCount: 1,
      generation: 1,
      audit: audit,
    );
    expect(doc.toMap().containsKey('importo'), isFalse);
    final round = DocumentoContabile.fromMap('d1', doc.toMap());
    expect(round.importo, isNull);
    expect(round.nome, 'Fattura vet');
    expect(round.anno, 2026);
    expect(round.generation, 1);
  });

  test('importo zero resta zero', () {
    final doc = DocumentoContabile(
      id: 'd2',
      anno: 2026,
      nome: 'Zero',
      data: DateTime.utc(2026, 1, 2),
      tipologia: TipologiaContabile.altro,
      descrizione: 'nota',
      importo: 0,
      mime: 'image/jpeg',
      nomeFile: 'a.jpg',
      dimensione: 4,
      chunkCount: 1,
      generation: 1,
      audit: audit,
    );
    expect(doc.toMap()['importo'], 0);
    expect(DocumentoContabile.fromMap('d2', doc.toMap()).importo, 0);
  });

  test('anno contabile id e campo anno', () {
    final anno = AnnoContabile(id: '2026', anno: 2026, audit: audit);
    expect(anno.toMap()['anno'], 2026);
    expect(AnnoContabile.fromMap('2026', anno.toMap()).anno, 2026);
  });
}
