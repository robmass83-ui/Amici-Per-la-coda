import 'package:amici_per_la_coda/core/firestore_codec.dart';
import 'package:amici_per_la_coda/data/models/documento_contabile.dart';
import 'package:amici_per_la_coda/features/contabilita/contabilita_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'anno 1989 e anno troppo avanti rifiutati, 1990 e anno prossimo accettati',
    () {
      final now = DateTime(2026, 9, 26);
      expect(
        erroreAnno('1989', now: now, esistenti: {}),
        messaggioAnnoFuori(2027),
      );
      expect(
        erroreAnno('2028', now: now, esistenti: {}),
        messaggioAnnoFuori(2027),
      );
      expect(erroreAnno('1990', now: now, esistenti: {}), isNull);
      expect(erroreAnno('2027', now: now, esistenti: {}), isNull);
      expect(
        erroreAnno('2024', now: now, esistenti: {2024}),
        'Il 2024 è già presente.',
      );
      expect(orologioAnnoUsabile(DateTime(1880, 1, 1)), isFalse);
      expect(orologioAnnoUsabile(DateTime(2200, 1, 1)), isFalse);
    },
  );

  test('tetti 400 e 700', () {
    const mib = 1024 * 1024;
    expect(valutaQuota(usato: 400 * mib, nuova: 1).avviso, isFalse);
    expect(valutaQuota(usato: 400 * mib + 1, nuova: 1).avviso, isTrue);
    expect(valutaQuota(usato: 400 * mib + 1, nuova: 1).rifiuto, isNull);
    expect(valutaQuota(usato: 700 * mib - 10, nuova: 10).rifiuto, isNull);
    expect(
      valutaQuota(usato: 700 * mib - 10, nuova: 11).rifiuto,
      contabilitaPieno,
    );
    expect(
      valutaQuota(usato: 800 * mib, nuova: 50, vecchia: 80).rifiuto,
      isNull,
    );
    expect(
      valutaQuota(usato: 800 * mib, nuova: 90, vecchia: 80).rifiuto,
      contabilitaPieno,
    );
  });

  test('somma importi ignora i null e include lo zero', () {
    final docs = [
      doc(id: 'a', importo: null, dimensione: 3),
      doc(id: 'b', importo: 0, dimensione: 4),
      doc(id: 'c', importo: 10.5, dimensione: 5),
    ];
    expect(sommaImporti(docs), 10.5);
    expect(sommaDimensioni(docs), 12);
    expect(
      formatArchivioMb(120 * 1024 * 1024 + 512 * 1024),
      'Archivio: 120,5 MB',
    );
  });

  test('filtri in AND e archivio ordinato', () {
    final docs = [
      doc(
        id: '1',
        nome: 'Fattura Vet',
        data: DateTime(2026, 3, 2),
        tipologia: TipologiaContabile.fattura,
      ),
      doc(
        id: '2',
        nome: 'scontrino pane',
        data: DateTime(2026, 3, 2),
        tipologia: TipologiaContabile.scontrino,
      ),
      doc(
        id: '3',
        nome: 'Fattura vecchia',
        data: DateTime(2025, 1, 1),
        tipologia: TipologiaContabile.fattura,
      ),
    ];
    final filtrati = filtraDocumenti(
      docs,
      FiltriContabilita(
        nome: 'FATTURA',
        tipologia: TipologiaContabile.fattura,
        dal: DateTime(2026, 1, 1),
        al: DateTime(2026, 12, 31),
      ),
    );
    expect(filtrati.map((d) => d.id), ['1']);
    expect(ordinaArchivio(docs).map((d) => d.id), ['2', '1', '3']);
  });

  test('slug, collisione e csv', () {
    expect(slugContabile('  '), 'documento');
    expect(slugContabile('Visita àèéìòù'), 'visita_aeeiou');
    expect(slugContabile('Città / Nord'), 'citta_nord');
    expect(slugContabile('a' * 50).length, 40);
    final primo = doc(
      id: 'b',
      nome: 'Veterinario',
      data: DateTime(2026, 3, 12),
      mime: 'application/pdf',
    );
    final secondo = doc(
      id: 'a',
      nome: 'Veterinario',
      data: DateTime(2026, 3, 12),
      mime: 'application/pdf',
    );
    final nomi = assegnaNomiZip([secondo, primo]);
    expect(nomi.map((e) => e.fileName), [
      '2026-03-12_fattura_veterinario.pdf',
      '2026-03-12_fattura_veterinario_2.pdf',
    ]);
    final csv = riepilogoCsv([
      (
        doc: primo.copyWith(importo: 1240.5, descrizione: 'dice "ciao";\nok'),
        fileName: nomi.first.fileName,
      ),
    ]);
    expect(csv.codeUnitAt(0), 0xFEFF);
    expect(csv.contains('Nome;Data;Tipologia;Importo;Nota;File\r\n'), isTrue);
    expect(csv.contains('12/03/2026'), isTrue);
    expect(csv.contains('Fattura'), isTrue);
    expect(csv.contains('1240,50'), isTrue);
    expect(csv.contains('"dice ""ciao"";\nok"'), isTrue);
  });

  test('la data fuori dalla cartella non è un errore di modello', () {
    final fuori = doc(id: 'x', anno: 2026, data: DateTime(2025, 12, 31));
    expect(fuori.anno, 2026);
    expect(fuori.data.year, 2025);
  });

  test('nome, nota e importo', () {
    expect(erroreNome('  '), contabilitaNomeVuoto);
    expect(
      erroreNome('a' * 121),
      'Il nome può avere al massimo 120 caratteri.',
    );
    expect(erroreNome('  Fattura  '), isNull);
    expect(erroreNota(''), isNull);
    expect(
      erroreNota('a' * 1001),
      'La nota può avere al massimo 1000 caratteri.',
    );
    expect(erroreImporto(''), isNull);
    expect(erroreImporto('0'), isNull);
    expect(erroreImporto('12,50'), isNull);
    expect(erroreImporto('-1'), contabilitaImportoNonValido);
    expect(erroreImporto('abc'), contabilitaImportoNonValido);
    expect(leggiImporto(''), isNull);
    expect(leggiImporto('12,5'), 12.5);
    expect(leggiImporto('0'), 0);
  });
}

DocumentoContabile doc({
  required String id,
  int anno = 2026,
  String nome = 'Doc',
  DateTime? data,
  TipologiaContabile tipologia = TipologiaContabile.fattura,
  String descrizione = '',
  double? importo,
  String mime = 'application/pdf',
  String nomeFile = 'a.pdf',
  int dimensione = 1,
  int chunkCount = 1,
  int generation = 1,
}) {
  return DocumentoContabile(
    id: id,
    anno: anno,
    nome: nome,
    data: data ?? DateTime(2026, 3, 12),
    tipologia: tipologia,
    descrizione: descrizione,
    importo: importo,
    mime: mime,
    nomeFile: nomeFile,
    dimensione: dimensione,
    chunkCount: chunkCount,
    generation: generation,
    audit: Audit.seed(DateTime.utc(2026, 1, 1)),
  );
}
