# Contabilità Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Aggiungere la sezione Contabilità: cartelle per anno solare, documenti PDF/JPEG in Firestore e uno ZIP annuale con `riepilogo.csv`.

**Architecture:** Collezioni nuove `anniContabili` e `contabilita`, separate dai documenti dei cani. I byte stanno solo in `contabilita/{id}/g/{generation}/chunks/{n}`. La logica di nomi, filtri, tetti e CSV è pura e testata senza Firebase. Le schermate stanno nel ramo della barra fra Calendario e Altro.

**Tech Stack:** Flutter, Riverpod, go_router, Cloud Firestore (Spark, niente Storage), `fake_cloud_firestore`, regole in `backend/tests`, pacchetto nuovo `archive` solo per lo ZIP.

**Spec:** `docs/superpowers/specs/2026-09-26-contabilita-design.md`

## Global Constraints

- Niente Firebase Storage. Piano Spark invariato. Niente Functions.
- File in ingresso: solo PDF, JPG, JPEG, PNG. JPG e PNG salvati come `image/jpeg` dopo `compressDocumentImage`. PDF salvato com'è, `application/pdf`.
- Tetto file: `10 * 1024 * 1024` byte sui byte salvati. Messaggio `DocumentTooLarge`.
- Avviso se la somma `dimensione` supera `400 * 1024 * 1024`. Rifiuto di un nuovo file se la somma supererebbe `700 * 1024 * 1024`. Sostituzione consentita sopra i 700 MiB se il nuovo file non è più grande del vecchio.
- Volontario attivo: vede, scarica, condivide, carica, crea anno. Presidente e referente: anche modifica, elimina, ZIP. Le azioni negate non compaiono.
- Anno corrente creato all'apertura se manca. «Aggiungi anno» dal 1990 all'anno prossimo del dispositivo, e comunque non oltre il 2100 delle regole. Un anno non si modifica e non si cancella.
- La data del documento può cadere fuori dall'anno della cartella.
- ZIP: `Amici_per_la_Coda_Contabilita_{anno}.zip`, tutti i documenti della cartella anche se la lista è filtrata, più `riepilogo.csv`. Zero documenti: export non usabile.
- Il foglio del + non si modifica. «Spesa» resta la spesa del cane.
- Unica dipendenza nuova: `archive`.
- Android e web usano le stesse schermate. Scarica e condividi passano da `FileShare` e `FileOpener`.
- `documents` / `DocumentRepository` non cambiano schema né semantica.
- Testi in italiano. Date `formatItalianDate`. Importi in UI `formatEuro`.
- Misure solo da `lib/ui/tokens.dart`. Icone di schermata solo da `AppIcons`. In barra è ammessa l'icona di sistema.
- Nessuno scroll orizzontale. Ricerca alta `AppDim.searchH` (38), senza etichetta sopra. Ricerca + filtri + riepilogo entro 120 dp. Tocco minimo `AppDim.minTouch` (40).
- Tipologie in scheda: `AppSegmented` a 5 segmenti, default Fattura. Il segmento usa già `FittedBox`.
- Campi Firestore in italiano. Date `Timestamp`. Audit `createdAt`, `createdBy`, `updatedAt`, `updatedBy`.
- `flutter analyze` pulito sui file toccati prima del task successivo. I golden esistenti non si rigenerano.

## File map

| File | Ruolo |
|---|---|
| `lib/data/models/documento_contabile.dart` | `TipologiaContabile`, `AnnoContabile`, `DocumentoContabile` |
| `lib/features/contabilita/contabilita_logic.dart` | Anno, tetti, filtri, slug, CSV, nomi ZIP |
| `lib/features/contabilita/contabilita_bytes.dart` | Spezzamento sempre in almeno un pezzo |
| `lib/data/repositories/contabilita_repository.dart` | Interfaccia |
| `lib/data/firestore/firestore_contabilita_repository.dart` | Firestore, generazioni, batch da 8 |
| `lib/features/contabilita/contabilita_file.dart` | PDF invariato, immagini JPEG, altri rifiutati |
| `lib/features/contabilita/contabilita_zip.dart` | ZIP con `archive` |
| `lib/features/contabilita/anni_page.dart` | Elenco anni |
| `lib/features/contabilita/anno_page.dart` | Archivio, ricerca, export |
| `lib/features/contabilita/filtri_sheet.dart` | Tipologia e intervallo date |
| `lib/features/contabilita/documento_sheet.dart` | Inserimento e modifica |
| `lib/features/contabilita/documento_page.dart` | Anteprima, scarica, condividi, elimina |
| `lib/data/data_providers.dart` | `contabilitaRepositoryProvider` |
| `lib/ui/icons.dart` | `AppIcons.contabilita` |
| `lib/ui/components/app_bottom_nav.dart` | Voce Contabilità |
| `lib/router.dart` | Ramo indice 3 |
| `backend/firestore.rules` | Match espliciti, catch-all escluso |
| `backend/firestore.indexes.json` | `anno` ASC, `data` DESC |
| `pubspec.yaml` | `archive` |
| `test/helpers/fake_contabilita_repository.dart` | Repository in memoria |
| `test/helpers/pump_app.dart` | Override del provider |

`AppIcons.movimento` usa già `Icons.receipt_long_rounded` in blu. `AppIcons.contabilita` usa lo stesso glifo in verde, come dice la specifica. Non cambiare `movimento`.

---

### Task 1: Modelli

**Files:**
- Create: `lib/data/models/documento_contabile.dart`
- Test: `test/data/documento_contabile_test.dart`

**Interfaces:**
- Consumes: `Audit`, `dateTimeRequired`, `dateTimeTo`, `numberFrom` in `lib/core/firestore_codec.dart`
- Produces:
  - `enum TipologiaContabile { fattura, scontrino, ricevuta, preventivo, altro }` con `String get wire`, `String get etichetta`, `static TipologiaContabile parse(String? raw)` (sconosciuto → `altro`)
  - `class AnnoContabile` campi `id`, `anno`, `audit`
  - `class DocumentoContabile` campi `id`, `anno`, `nome`, `data`, `tipologia`, `descrizione`, `importo` (`double?`), `mime`, `nomeFile`, `dimensione`, `chunkCount`, `generation`, `audit`
  - `toMap()` omette la chiave `importo` se è null. `fromMap` tratta la chiave assente come null, non come zero

- [ ] **Step 1: Write the failing test**

Create `test/data/documento_contabile_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/documento_contabile_test.dart`

Expected: FAIL, `documento_contabile.dart` non esiste.

- [ ] **Step 3: Write minimal implementation**

Create `lib/data/models/documento_contabile.dart` seguendo `Expense` in `lib/data/models/expense.dart`: `toMap` usa `dateTimeTo` e `...audit.toMap()`. `fromMap` usa `dateTimeRequired` e `Audit.fromMap`. `importo` si scrive solo se non null. `copyWith` con `bool clearImporto = false`. `TipologiaContabile.parse` non usa `DocumentTipo`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/documento_contabile_test.dart`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/documento_contabile.dart test/data/documento_contabile_test.dart
git commit -m "feat: modelli anno e documento contabile"
```

---

### Task 2: Logica pura

**Files:**
- Create: `lib/features/contabilita/contabilita_logic.dart`
- Test: `test/features/contabilita/contabilita_logic_test.dart`

**Interfaces:**
- Consumes: `DocumentoContabile`, `TipologiaContabile`, `Audit` dal Task 1. `formatItalianDate` non serve qui: il CSV formatta la data da solo.
- Produces:
  - `const contabilitaAvviso400 = "L'archivio contabile supera i 400 MB. Resta spazio, ma conviene non accumulare file inutili."`
  - `const contabilitaPieno = 'Archivio contabile pieno (oltre 700 MB). Libera spazio eliminando documenti vecchi.'`
  - `const contabilitaExportOffline = 'Connessione assente: l\'esportazione richiede i file.'`
  - `const contabilitaFileRifiutato = 'Usa un PDF, JPG o PNG.'`
  - `const contabilitaNomeVuoto = 'Indica il nome del documento.'`
  - `const contabilitaImportoNonValido = 'Importo non valido.'`
  - `const contabilitaFileMancante = 'Allega un PDF, JPG o PNG.'`
  - `const contabilitaElimina = 'Eliminare questo documento? Il file verrà cancellato. Non si può annullare.'`
  - `String messaggioAnnoDuplicato(int anno)` → `Il $anno è già presente.`
  - `String messaggioAnnoFuori(int massimo)` → `L'anno deve essere fra il 1990 e il $massimo.`
  - `int massimoAnno(DateTime now)` → `now.year + 1`. Se `now.year` è fuori da 1990–2100, lancia `StateError`.
  - `String? erroreAnno(String raw, {required DateTime now, required Set<int> esistenti})` — null se valido
  - `bool orologioAnnoUsabile(DateTime now)` — `now.year` fra 1990 e 2100
  - `class QuotaEsito { final bool avviso; final String? rifiuto; }`
  - `QuotaEsito valutaQuota({required int usato, required int nuova, int? vecchia})`
  - `int sommaDimensioni(Iterable<DocumentoContabile> docs)`
  - `double sommaImporti(Iterable<DocumentoContabile> docs)` — ignora null, include 0
  - `String formatArchivioMb(int bytes)` → `Archivio: 120,5 MB`
  - `class FiltriContabilita { final String nome; final TipologiaContabile? tipologia; final DateTime? dal; final DateTime? al; }`
  - `List<DocumentoContabile> filtraDocumenti(List<DocumentoContabile> docs, FiltriContabilita filtri)`
  - `List<DocumentoContabile> ordinaArchivio(List<DocumentoContabile> docs)` — data decrescente, poi nome
  - `String? erroreNome(String raw)` — vuoto dopo trim, o oltre 120
  - `String? erroreNota(String raw)` — oltre 1000; vuoto è valido
  - `String? erroreImporto(String raw)` — vuoto valido; `12,5` e `0` validi; negativo e testo no
  - `double? leggiImporto(String raw)` — null se vuoto; chiamare solo se `erroreImporto` è null
  - `String slugContabile(String nome)`
  - `String nomeFileZip(DocumentoContabile doc, int occorrenza)` — occorrenza 1 senza suffisso, da 2 `_2`
  - `List<({DocumentoContabile doc, String fileName})> assegnaNomiZip(List<DocumentoContabile> docs)` — ordine data crescente, poi id
  - `String riepilogoCsv(List<({DocumentoContabile doc, String fileName})> rows)` — BOM, `;`, `\r\n`

- [ ] **Step 1: Write the failing test**

Create `test/features/contabilita/contabilita_logic_test.dart`. Helper locale `doc(...)` che costruisce un `DocumentoContabile` con audit fisso `Audit.seed(DateTime.utc(2026, 1, 1))`. Coprire:

```dart
test('anno 1989 e anno troppo avanti rifiutati, 1990 e anno prossimo accettati', () {
  final now = DateTime(2026, 9, 26);
  expect(erroreAnno('1989', now: now, esistenti: {}), messaggioAnnoFuori(2027));
  expect(erroreAnno('2028', now: now, esistenti: {}), messaggioAnnoFuori(2027));
  expect(erroreAnno('1990', now: now, esistenti: {}), isNull);
  expect(erroreAnno('2027', now: now, esistenti: {}), isNull);
  expect(erroreAnno('2024', now: now, esistenti: {2024}), 'Il 2024 è già presente.');
  expect(orologioAnnoUsabile(DateTime(1880, 1, 1)), isFalse);
  expect(orologioAnnoUsabile(DateTime(2200, 1, 1)), isFalse);
});

test('tetti 400 e 700', () {
  const mib = 1024 * 1024;
  expect(valutaQuota(usato: 400 * mib, nuova: 1).avviso, isFalse);
  expect(valutaQuota(usato: 400 * mib + 1, nuova: 1).avviso, isTrue);
  expect(valutaQuota(usato: 400 * mib + 1, nuova: 1).rifiuto, isNull);
  expect(valutaQuota(usato: 700 * mib - 10, nuova: 10).rifiuto, isNull);
  expect(valutaQuota(usato: 700 * mib - 10, nuova: 11).rifiuto, contabilitaPieno);
  expect(valutaQuota(usato: 800 * mib, nuova: 50, vecchia: 80).rifiuto, isNull);
  expect(valutaQuota(usato: 800 * mib, nuova: 90, vecchia: 80).rifiuto, contabilitaPieno);
});

test('somma importi ignora i null e include lo zero', () {
  final docs = [
    doc(id: 'a', importo: null, dimensione: 3),
    doc(id: 'b', importo: 0, dimensione: 4),
    doc(id: 'c', importo: 10.5, dimensione: 5),
  ];
  expect(sommaImporti(docs), 10.5);
  expect(sommaDimensioni(docs), 12);
  expect(formatArchivioMb(120 * 1024 * 1024 + 512 * 1024), 'Archivio: 120,5 MB');
});

test('filtri in AND e archivio ordinato', () {
  final docs = [
    doc(id: '1', nome: 'Fattura Vet', data: DateTime(2026, 3, 2), tipologia: TipologiaContabile.fattura),
    doc(id: '2', nome: 'scontrino pane', data: DateTime(2026, 3, 2), tipologia: TipologiaContabile.scontrino),
    doc(id: '3', nome: 'Fattura vecchia', data: DateTime(2025, 1, 1), tipologia: TipologiaContabile.fattura),
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
  final primo = doc(id: 'b', nome: 'Veterinario', data: DateTime(2026, 3, 12), mime: 'application/pdf');
  final secondo = doc(id: 'a', nome: 'Veterinario', data: DateTime(2026, 3, 12), mime: 'application/pdf');
  final nomi = assegnaNomiZip([secondo, primo]);
  expect(nomi.map((e) => e.fileName), [
    '2026-03-12_fattura_veterinario.pdf',
    '2026-03-12_fattura_veterinario_2.pdf',
  ]);
  final csv = riepilogoCsv([
    (doc: primo.copyWith(importo: 1240.5, descrizione: 'dice "ciao";\nok'), fileName: nomi.first.fileName),
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
```

`doc` nel test accetta i named argument usati sopra e mette i default: `anno: 2026`, `nome: 'Doc'`, `data: DateTime(2026, 3, 12)`, `tipologia: fattura`, `descrizione: ''`, `importo: null`, `mime: 'application/pdf'`, `nomeFile: 'a.pdf'`, `dimensione: 1`, `chunkCount: 1`, `generation: 1`.

Messaggi di nome e importo, nello stesso file:

```dart
test('nome, nota e importo', () {
  expect(erroreNome('  '), contabilitaNomeVuoto);
  expect(erroreNome('a' * 121), 'Il nome può avere al massimo 120 caratteri.');
  expect(erroreNome('  Fattura  '), isNull);
  expect(erroreNota(''), isNull);
  expect(erroreNota('a' * 1001), 'La nota può avere al massimo 1000 caratteri.');
  expect(erroreImporto(''), isNull);
  expect(erroreImporto('0'), isNull);
  expect(erroreImporto('12,50'), isNull);
  expect(erroreImporto('-1'), contabilitaImportoNonValido);
  expect(erroreImporto('abc'), contabilitaImportoNonValido);
  expect(leggiImporto(''), isNull);
  expect(leggiImporto('12,5'), 12.5);
  expect(leggiImporto('0'), 0);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/contabilita/contabilita_logic_test.dart`

Expected: FAIL, libreria non trovata.

- [ ] **Step 3: Write minimal implementation**

`slugContabile`: trim, `toLowerCase`, mappa àèéìòù, ogni altro carattere che non è `a-z` o cifra diventa `_`, comprimi `_`, togli `_` in testa e in coda, taglia a 40, se vuoto `documento`. Non rimappare altre accentate.

`assegnaNomiZip`: ordina per `data.toUtc()` poi `id`. Conta i nomi base già emessi. Il primo usa occorrenza 1.

`riepilogoCsv`: parte con `\uFEFF`, intestazione, poi una riga per documento nello stesso ordine. Campo con `"`, `;` o a capo fra virgolette doppie, virgolette interne raddoppiate. Importo vuoto se null; altrimenti centesimi con virgola e senza separatore delle migliaia (`1240,50`). Data con giorno e mese a due cifre. Tipologia = `etichetta`. Ultima riga finisce con `\r\n`.

`valutaQuota`: `avviso` se `usato > 400 * 1024 * 1024`. `rifiuto` è `contabilitaPieno` quando il nuovo supera il tetto. Se `vecchia` è null, il tetto è `usato + nuova > 700 * 1024 * 1024`. Se `vecchia` non è null e `nuova <= vecchia`, `rifiuto` è null. Se `nuova > vecchia`, il tetto è `usato - vecchia + nuova > 700 * 1024 * 1024`.

`filtraDocumenti`: nome trimmato in minuscolo, sottostringa; tipologia null = tutte; `dal` e `al` confrontano solo la data locale (anno, mese, giorno), estremi inclusi. AND.

`erroreAnno`: `int.tryParse` dopo trim; deve essere di 4 cifre; `anno >= 1990 && anno <= now.year + 1 && anno <= 2100`; se l'orologio non è usabile, stesso messaggio fuori intervallo con massimo `now.year + 1`; se è in `esistenti`, `messaggioAnnoDuplicato`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/contabilita/contabilita_logic_test.dart`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/contabilita/contabilita_logic.dart test/features/contabilita/contabilita_logic_test.dart
git commit -m "feat: regole pure di anni, tetti, filtri e csv contabile"
```

---

### Task 3: Spezzamento byte e repository in memoria

**Files:**
- Create: `lib/features/contabilita/contabilita_bytes.dart`
- Create: `lib/data/repositories/contabilita_repository.dart`
- Create: `test/helpers/fake_contabilita_repository.dart`
- Test: `test/features/contabilita/contabilita_bytes_test.dart`
- Test: `test/helpers/fake_contabilita_repository_test.dart`

**Interfaces:**
- Consumes: `documentChunkBytes`, `documentMaxBytes`, `ensureDocumentSizeAllowed`, `joinDocumentChunks` da `lib/data/documents/document_codec.dart`. Non chiamare `splitDocumentBytes`: sotto i 700 KiB restituisce lista vuota, e la contabilità non usa quella soglia.
- Produces:
  - `List<Uint8List> splitContabilitaBytes(Uint8List bytes)` — sempre almeno un pezzo se i byte non sono vuoti; pezzi da `documentChunkBytes`; sopra `documentMaxBytes` lancia `DocumentTooLarge`; vuoto lancia `ArgumentError`
  - `abstract interface class ContabilitaRepository` con:
    - `Stream<List<AnnoContabile>> watchAnni()`
    - `Stream<List<DocumentoContabile>> watchTutti()`
    - `Stream<List<DocumentoContabile>> watchAnno(int anno)`
    - `Future<void> createAnno({required int anno, required String uid, required DateTime now})`
    - `Future<void> saveNuovo(DocumentoContabile doc, Uint8List bytes)`
    - `Future<void> saveMeta(DocumentoContabile doc)` — non tocca i byte né `generation`
    - `Future<void> replaceFile(DocumentoContabile doc, Uint8List bytes)` — incrementa `generation` solo dopo i pezzi nuovi
    - `Future<Uint8List> loadBytes(String id)`
    - `Future<void> deleteDocumento(String id)`
  - `class AnnoGiaPresente implements Exception` con `int anno` e `toString()` = `messaggioAnnoDuplicato(anno)`
  - `class InMemoryContabilitaRepository implements ContabilitaRepository`

- [ ] **Step 1: Write the failing tests**

`test/features/contabilita/contabilita_bytes_test.dart`:

```dart
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
```

`test/helpers/fake_contabilita_repository_test.dart` con `InMemoryContabilitaRepository`:

- `createAnno` due volte sullo stesso anno lancia `AnnoGiaPresente` e `watchAnni` ha ancora un solo anno.
- `saveNuovo` con 4 byte: `loadBytes` restituisce quei byte; `watchAnno` non contiene chiavi di byte; `generation` è 1; `chunkCount` è 1.
- `saveMeta` cambia `nome` e lascia i byte identici e `generation` 1.
- `replaceFile` con byte diversi: `loadBytes` è il file nuovo, `generation` è 2. Se si forza il fallimento con un flag `failNextReplaceWrite` sul fake, `loadBytes` resta il file vecchio.
- `deleteDocumento` toglie il documento e `loadBytes` lancia `StateError`.

Il fake tiene `Map<String, Map<int, List<Uint8List>>>` pezzi per id e generazione. `saveNuovo` rifiuta se `doc.generation != 1`. `chunkCount` salvato è il numero di pezzi. `dimensione` salvata resta quella del modello: i test possono dichiarare una dimensione grande passando pochi byte. In produzione la scheda passa `dimensione: bytes.length`. `loadBytes` restituisce i byte passati a `saveNuovo` / `replaceFile`, anche se sono più corti di `dimensione`. `replaceFile` scrive la generazione `doc.generation + 1`, poi pubblica il documento con `generation` incrementata, `chunkCount` nuovo e `dimensione` del modello passato. `failNextReplaceWrite` lancia prima di pubblicare il padre e non cambia i byte visibili.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/contabilita/contabilita_bytes_test.dart test/helpers/fake_contabilita_repository_test.dart`

Expected: FAIL, file mancanti.

- [ ] **Step 3: Write minimal implementation**

`splitContabilitaBytes` fa un ciclo con passo `documentChunkBytes` e `sublist`. Non usa `splitDocumentBytes`.

`watchAnno` filtra `watchTutti` per `doc.anno`. Gli stream del fake sono `StreamController.broadcast` aggiornati a ogni scrittura, più un event subito in `onListen`.

`createAnno` usa id `'$anno'`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/contabilita/contabilita_bytes_test.dart test/helpers/fake_contabilita_repository_test.dart`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/contabilita/contabilita_bytes.dart lib/data/repositories/contabilita_repository.dart test/helpers/fake_contabilita_repository.dart test/features/contabilita/contabilita_bytes_test.dart test/helpers/fake_contabilita_repository_test.dart
git commit -m "feat: repository contabile in memoria e pezzi sempre presenti"
```

---

### Task 4: Repository Firestore

**Files:**
- Create: `lib/data/firestore/firestore_contabilita_repository.dart`
- Modify: `lib/data/data_providers.dart` (accanto a `documentRepositoryProvider`)
- Test: `test/data/firestore_contabilita_repository_test.dart`

**Interfaces:**
- Consumes: `ContabilitaRepository`, `splitContabilitaBytes`, `joinDocumentChunks`, `FakeFirebaseFirestore`
- Produces: `class FirestoreContabilitaRepository implements ContabilitaRepository` e `final contabilitaRepositoryProvider = Provider<ContabilitaRepository?>`

- [ ] **Step 1: Write the failing test**

`test/data/firestore_contabilita_repository_test.dart` con `FakeFirebaseFirestore` e `FirestoreContabilitaRepository`. Helper nello stesso file:

```dart
DocumentoContabile sample({
  String id = 'c1',
  int generation = 1,
  int dimensione = 4,
  int chunkCount = 1,
  String nome = 'Fattura',
}) {
  return DocumentoContabile(
    id: id,
    anno: 2026,
    nome: nome,
    data: DateTime.utc(2026, 3, 12),
    tipologia: TipologiaContabile.fattura,
    descrizione: '',
    importo: null,
    mime: 'application/pdf',
    nomeFile: 'f.pdf',
    dimensione: dimensione,
    chunkCount: chunkCount,
    generation: generation,
    audit: Audit.seed(DateTime.utc(2026, 3, 12), by: 'uid-1'),
  );
}
```

```dart
test('il padre non contiene i byte', () async {
  final db = FakeFirebaseFirestore();
  final repo = FirestoreContabilitaRepository(db);
  final doc = sample(id: 'c1', generation: 1, dimensione: 4, chunkCount: 1);
  await repo.saveNuovo(doc, Uint8List.fromList([9, 8, 7, 6]));
  final parent = await db.collection('contabilita').doc('c1').get();
  expect(parent.data()!.containsKey('contenutoB64'), isFalse);
  expect(parent.data()!['chunkCount'], 1);
  final chunk = await db
      .collection('contabilita')
      .doc('c1')
      .collection('g')
      .doc('1')
      .collection('chunks')
      .doc('0')
      .get();
  expect(chunk.data()!['index'], 0);
  expect(repo.loadBytes('c1'), completion(Uint8List.fromList([9, 8, 7, 6])));
});

test('la sostituzione lascia il file vecchio se il padre non si aggiorna', () async {
  final db = FakeFirebaseFirestore();
  final repo = FirestoreContabilitaRepository(db, failBeforeParentUpdate: true);
  await repo.saveNuovo(sample(id: 'c1'), Uint8List.fromList([1, 1]));
  await expectLater(
    repo.replaceFile(sample(id: 'c1', nome: 'nuovo'), Uint8List.fromList([2, 2, 2])),
    throwsA(isA<StateError>()),
  );
  final parent = await db.collection('contabilita').doc('c1').get();
  expect(parent.data()!['generation'], 1);
  expect(await repo.loadBytes('c1'), Uint8List.fromList([1, 1]));
});
```

`failBeforeParentUpdate` è un parametro del costruttore, default false, usato solo dal test: dopo aver scritto i pezzi della generazione nuova lancia `StateError('stop')` e cancella quei pezzi. Il test verifica che `g/2/chunks/0` non esista.

Altro test: `deleteDocumento` cancella padre e `g/1`. `createAnno` due volte lancia `AnnoGiaPresente`. `watchAnno(2026)` non emette un documento del 2025.

Un file di `documentChunkBytes + 1` byte ha due documenti chunk sotto `g/1`.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/firestore_contabilita_repository_test.dart`

Expected: FAIL, classe mancante.

- [ ] **Step 3: Write minimal implementation**

Percorsi:

- anni: `collection('anniContabili').doc('$anno')`
- padre: `collection('contabilita').doc(id)`
- pezzi: `collection('contabilita').doc(id).collection('g').doc('$generation').collection('chunks').doc('$n')` con `{index: n, b64: base64Encode(chunk)}`

`saveNuovo`: `splitContabilitaBytes`, scrivi i pezzi a gruppi di 8 con `batch.commit`, poi `set` del padre. Se un gruppo fallisce, cancella i pezzi della generazione 1 già scritti e non scrivere il padre.

`replaceFile`: generazione nuova = `doc.generation + 1`. Scrivi quei pezzi. Se `failBeforeParentUpdate`, cancella la generazione nuova e lancia. Altrimenti `set` del padre con i campi del modello, `chunkCount` uguale al numero di pezzi appena scritti e `dimensione` uguale a `doc.dimensione` (la scheda ci mette `bytes.length`). Poi cancella la generazione precedente. Se la pulizia fallisce, non rilanciare: il padre punta già al file nuovo. `saveNuovo` fa lo stesso sul padre: `chunkCount` dai pezzi, `dimensione` dal modello.

`deleteDocumento`: leggi `generation` dal padre. Cancella i pezzi da 1 a `generation + 1`. Se un pezzo della generazione corrente non si cancella, lancia e non cancellare il padre. Poi cancella il padre.

`createAnno`: `doc('$anno').get()`. Se esiste, `AnnoGiaPresente`. Altrimenti `set` con `anno` e audit (`updatedAt` = `createdAt`).

`watchTutti` e `watchAnni` sono `snapshots()`. `watchAnno` è `where('anno', isEqualTo: anno)`.

In `data_providers.dart`:

```dart
final contabilitaRepositoryProvider = Provider<ContabilitaRepository?>((ref) {
  final db = ref.watch(firestoreProvider);
  return db == null ? null : FirestoreContabilitaRepository(db);
});
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/firestore_contabilita_repository_test.dart`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/data/firestore/firestore_contabilita_repository.dart lib/data/data_providers.dart test/data/firestore_contabilita_repository_test.dart
git commit -m "feat: salva i documenti contabili a generazioni in Firestore"
```

---

### Task 5: Regole e indice

**Files:**
- Modify: `backend/firestore.rules`
- Modify: `backend/firestore.indexes.json`
- Create: `backend/tests/contabilita.rules.test.mjs`

**Interfaces:**
- Consumes: `attivo()` e `puoScrivere()` già in `backend/firestore.rules`
- Produces: match `anniContabili`, `contabilita`, `contabilita/{id}/g/{generation}/chunks/{n}`. Il catch-all `/{col}/{id}` esclude anche queste due collezioni.

- [ ] **Step 1: Write the failing test**

Create `backend/tests/contabilita.rules.test.mjs` sullo stile di `backend/tests/notes.rules.test.mjs`. `projectId: 'demo-amici-contabilita'`. Prima, con le regole disattivate, crea `volunteers/vol-marco` (`ruolo: 'volontario'`) e `volunteers/presidente` (`ruolo: 'presidente'`), entrambi `attivo: true`, con i campi che le altre regole dei volontari già usano (`nome`, `email`, `coloreAvatar`, audit).

Documento valido `contabileOk`:

```js
const contabileOk = {
  anno: 2026,
  nome: 'Fattura',
  data: new Date('2026-03-12T00:00:00Z'),
  tipologia: 'fattura',
  descrizione: '',
  mime: 'application/pdf',
  nomeFile: 'f.pdf',
  dimensione: 4,
  chunkCount: 1,
  generation: 1,
  createdAt: new Date('2026-03-12T00:00:00Z'),
  createdBy: 'vol-marco',
  updatedAt: new Date('2026-03-12T00:00:00Z'),
  updatedBy: 'vol-marco',
};
```

Anno valido `annoOk`: `{ anno: 2026, createdAt, createdBy: 'vol-marco', updatedAt, updatedBy: 'vol-marco' }`.

Test, tutti con `assertFails` / `assertSucceeds`:

- anonimo `get` su `anniContabili/2026` e `contabilita/c1` fallisce
- volontario `set` di `anniContabili/2026` con `annoOk` riesce
- volontario `set` di `anniContabili/2024` con `anno: 2026` fallisce
- volontario `update` e `delete` di `anniContabili/2026` falliscono
- presidente `delete` di `anniContabili/2026` fallisce
- volontario `set` di `contabilita/c1` con `contabileOk` riesce
- volontario `set` di `contabilita/c1/g/1/chunks/0` con `{ index: 0, b64: 'YQ==' }` riesce
- volontario `update` di `contabilita/c1` fallisce
- volontario `delete` del pezzo e del padre fallisce
- presidente `update` di `nome` su `contabilita/c1` riesce
- presidente `delete` del pezzo e poi del padre riesce
- presidente `set` di un documento che contiene `contenutoB64: 'YQ=='` fallisce
- presidente `update` che aggiunge `contenutoB64` fallisce

- [ ] **Step 2: Run test to verify it fails**

Run da `backend`: `node --test tests/contabilita.rules.test.mjs`

Expected: FAIL, le create del volontario sono negate dal catch-all attuale.

- [ ] **Step 3: Write minimal implementation**

Nel catch-all, aggiungi `'anniContabili'` e `'contabilita'` all'elenco `col in [...]`.

Prima del catch-all, aggiungi:

```
function contabileOk() {
  let d = request.resource.data;
  return d.keys().hasOnly([
      'anno', 'nome', 'data', 'tipologia', 'descrizione', 'importo',
      'mime', 'nomeFile', 'dimensione', 'chunkCount', 'generation',
      'createdAt', 'createdBy', 'updatedAt', 'updatedBy'
    ])
    && d.keys().hasAll([
      'anno', 'nome', 'data', 'tipologia', 'descrizione', 'mime',
      'nomeFile', 'dimensione', 'chunkCount', 'generation',
      'createdAt', 'createdBy', 'updatedAt', 'updatedBy'
    ])
    && d.anno is int
    && d.tipologia in ['fattura', 'scontrino', 'ricevuta', 'preventivo', 'altro']
    && d.mime in ['application/pdf', 'image/jpeg']
    && d.nome is string && d.nome.size() > 0 && d.nome.size() <= 120
    && d.descrizione is string && d.descrizione.size() <= 1000
    && d.chunkCount is int && d.chunkCount >= 1
    && d.generation is int && d.generation >= 1
    && d.dimensione is int && d.dimensione > 0 && d.dimensione <= 10485760
    && (!('importo' in d) || (d.importo is number && d.importo >= 0))
    && !('contenutoB64' in d);
}

match /anniContabili/{anno} {
  allow read: if attivo();
  allow create: if attivo()
    && anno.matches('^[0-9]{4}$')
    && int(anno) == request.resource.data.anno
    && request.resource.data.anno >= 1990
    && request.resource.data.anno <= 2100
    && request.resource.data.keys().hasOnly([
      'anno', 'createdAt', 'createdBy', 'updatedAt', 'updatedBy'
    ]);
  allow update, delete: if false;
}

match /contabilita/{id} {
  allow read: if attivo();
  allow create: if attivo() && contabileOk();
  allow update: if puoScrivere() && contabileOk();
  allow delete: if puoScrivere();
  match /g/{generation}/chunks/{n} {
    allow read: if attivo();
    allow create: if attivo()
      && request.resource.data.keys().hasOnly(['index', 'b64'])
      && request.resource.data.index is int
      && request.resource.data.b64 is string
      && request.resource.data.b64.size() < 900000;
    allow update, delete: if puoScrivere();
  }
}
```

In `backend/firestore.indexes.json`, aggiungi un indice `collectionGroup: "contabilita"`, `queryScope: "COLLECTION"`, campi `anno` ASCENDING e `data` DESCENDING.

- [ ] **Step 4: Run test to verify it passes**

Run da `backend`: `node --test tests/contabilita.rules.test.mjs`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add backend/firestore.rules backend/firestore.indexes.json backend/tests/contabilita.rules.test.mjs
git commit -m "feat: regole Firestore dell'archivio contabile"
```

---

### Task 6: Preparazione file

**Files:**
- Create: `lib/features/contabilita/contabilita_file.dart`
- Test: `test/features/contabilita/contabilita_file_test.dart`

**Interfaces:**
- Consumes: `PickedDocumentFile`, `compressDocumentImage` in `lib/data/photos/photo_codec.dart`, `ensureDocumentSizeAllowed`, `contabilitaFileRifiutato`
- Produces: `class FileContabilePreparato { final Uint8List bytes; final String mime; final String nomeFile; }` e `Future<FileContabilePreparato> preparaFileContabile(PickedDocumentFile file)`

- [ ] **Step 1: Write the failing test**

`compressDocumentImage` è async e usa il codec immagini. Per il PDF e per il rifiuto non serve un'immagine vera.

```dart
test('il pdf resta pdf', () async {
  final out = await preparaFileContabile(
    PickedDocumentFile(bytes: Uint8List.fromList([1, 2]), name: 'Fattura.PDF', mime: 'application/octet-stream'),
  );
  expect(out.mime, 'application/pdf');
  expect(out.bytes, [1, 2]);
  expect(out.nomeFile, 'Fattura.PDF');
});

test('un docx è rifiutato', () async {
  expect(
    () => preparaFileContabile(
      PickedDocumentFile(bytes: Uint8List.fromList([1]), name: 'a.docx', mime: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'),
    ),
    throwsA(predicate((e) => e.toString() == contabilitaFileRifiutato)),
  );
});
```

Esporta anche `bool fileContabileAccettato(String mime, String name)`. Il test di quella funzione: `.pdf`, `.jpg`, `.jpeg`, `.png` e i mime `application/pdf`, `image/jpeg`, `image/png` sono true; `.docx` è false. `preparaFileContabile` la usa e, per un'immagine, chiama `compressDocumentImage` e rinomina come `_asJpegName` di `document_upload.dart` (stessa regola, funzione locale `nomeJpeg`: se c'è un punto toglie l'estensione e aggiunge `.jpg`, altrimenti aggiunge `.jpg`). Non aggiungere il pacchetto `image`. Un PNG di un solo byte non è un'immagine decodificabile: il test del percorso immagine si ferma a `fileContabileAccettato`. Il test del PDF copre i byte che restano invariati.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/contabilita/contabilita_file_test.dart`

Expected: FAIL

- [ ] **Step 3: Write minimal implementation**

PDF se il mime contiene `pdf` o il nome, in minuscolo, finisce con `.pdf`. Immagine se il mime contiene `jpeg`, `jpg` o `png`, o il nome finisce con `.jpg`, `.jpeg`, `.png`. Altrimenti `throw StateError(contabilitaFileRifiutato)` — il test confronta `toString()`. Dopo la compressione, `ensureDocumentSizeAllowed`. Il mime salvato dell'immagine è `image/jpeg`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/contabilita/contabilita_file_test.dart`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/contabilita/contabilita_file.dart test/features/contabilita/contabilita_file_test.dart
git commit -m "feat: accetta solo pdf e immagini per la contabilità"
```

---

### Task 7: ZIP

**Files:**
- Modify: `pubspec.yaml` (aggiungi `archive: ^3.6.1` nelle dependencies)
- Create: `lib/features/contabilita/contabilita_zip.dart`
- Test: `test/features/contabilita/contabilita_zip_test.dart`

**Interfaces:**
- Consumes: `riepilogoCsv`, `assegnaNomiZip`, `DocumentoContabile`, `package:archive/archive.dart`
- Produces:
  - `Uint8List zipContabilita(List<({DocumentoContabile doc, Uint8List bytes})> files)`
  - `String nomeZipAnno(int anno)` → `Amici_per_la_Coda_Contabilita_$anno.zip`
  - `Future<Uint8List> esportaZipAnno({required ContabilitaRepository repo, required List<DocumentoContabile> documenti, required bool offline})` — se `documenti` è vuoto lancia `StateError`; se un `loadBytes` fallisce e `offline` è true lancia `StateError(contabilitaExportOffline)` e non restituisce byte

- [ ] **Step 1: Write the failing test**

```dart
test('lo zip ha il csv per primo e i byte originali', () {
  final a = doc(id: 'a', nome: 'Vet', data: DateTime(2026, 3, 12));
  final bytes = zipContabilita([(doc: a, bytes: Uint8List.fromList([1, 2, 3, 4]))]);
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
```

`StateError.toString()` è `Bad state: ...`, non il messaggio nudo. Lancia invece una classe `ExportContabileException implements Exception` con `toString()` che restituisce solo `contabilitaExportOffline`. Il test usa quella.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/contabilita/contabilita_zip_test.dart`

Expected: FAIL

- [ ] **Step 3: Write minimal implementation**

`flutter pub add archive` non va usato se fissa una versione diversa: scrivi `archive: ^3.6.1` in `pubspec.yaml` e lancia `flutter pub get`.

```dart
Uint8List zipContabilita(List<({DocumentoContabile doc, Uint8List bytes})> files) {
  final named = assegnaNomiZip([for (final file in files) file.doc]);
  final byId = {for (final file in files) file.doc.id: file.bytes};
  final rows = [for (final row in named) (doc: row.doc, fileName: row.fileName)];
  final archive = Archive();
  final csvBytes = utf8.encode(riepilogoCsv(rows));
  archive.addFile(ArchiveFile('riepilogo.csv', csvBytes.length, csvBytes));
  for (final row in rows) {
    final data = byId[row.doc.id]!;
    archive.addFile(ArchiveFile(row.fileName, data.length, data));
  }
  final encoded = ZipEncoder().encode(archive);
  if (encoded == null) {
    throw StateError('ZIP non creato.');
  }
  return Uint8List.fromList(encoded);
}
```

`esportaZipAnno` ordina con `assegnaNomiZip` solo per sapere quali id caricare, ma lo ZIP lo costruisce `zipContabilita` che riassegna i nomi. Carica tutti i byte prima di chiamare `zipContabilita`. Al primo errore, se `offline` è true, lancia `ExportContabileException` senza costruire lo ZIP.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/contabilita/contabilita_zip_test.dart`

Expected: PASS. `ZipDecoder` e `ArchiveFile.content` sono l'API di `archive` 3.6.

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/features/contabilita/contabilita_zip.dart test/features/contabilita/contabilita_zip_test.dart
git commit -m "feat: zip annuale della contabilità con riepilogo csv"
```

---

### Task 8: Barra e percorsi

**Files:**
- Modify: `lib/ui/icons.dart` (accanto al blocco spese)
- Modify: `lib/ui/components/app_bottom_nav.dart`
- Modify: `lib/router.dart` (`AppRoutes` e il `StatefulShellBranch` prima di Altro)
- Create: `lib/features/contabilita/anni_page.dart` (solo il guscio vuoto `AnniContabiliPage`, il contenuto è il Task 9)
- Modify: `test/features/shell/shell_navigation_test.dart`
- Modify: `test/helpers/pump_app.dart`

**Interfaces:**
- Consumes: `AppBottomNav.currentIndex` oggi 0 Home, 1 Animali, 2 Calendario, 3 Altro
- Produces:
  - `AppIcons.contabilita` = `AppIconSpec(Icons.receipt_long_rounded, AppColor.greenSoft, _green)`
  - `AppRoutes.contabilita = '/contabilita'`
  - `static String contabilitaAnno(int anno) => '/contabilita/$anno'`
  - `static String contabilitaDocumento(int anno, String id) => '/contabilita/$anno/$id'`
  - Indici: Home 0, Animali 1, Calendario 2, Contabilità 3, Altro 4
  - `class AnniContabiliPage extends ConsumerWidget` con un `Text('Contabilità')` finché il Task 9 non la riempie
  - `pumpApp` accetta `ContabilitaRepository? contabilita`

- [ ] **Step 1: Write the failing test**

In `shell_navigation_test.dart`, nel test delle larghezze, aggiungi `expect(find.text('Contabilità'), findsOneWidget)` e inserisci `'Contabilità'` nel ciclo di tap, fra Calendario e Altro. Nel test di navigazione, dopo Calendario e prima di Altro:

```dart
await tester.tap(find.text('Contabilità'));
await tester.pumpAndSettle();
expect(find.byType(AnniContabiliPage), findsOneWidget);
```

Nel test del +, aggiungi `expect(find.text('Documento contabile'), findsNothing);` e lascia gli `expect` di «Spesa». `pumpApp` deve poter ricevere il repository: aggiungi il parametro e l'override `contabilitaRepositoryProvider`. Se è null, non override (il provider reale è null nei test senza Firebase) e la pagina vuota si costruisce lo stesso.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/shell/shell_navigation_test.dart`

Expected: FAIL, testo Contabilità assente.

- [ ] **Step 3: Write minimal implementation**

In `AppBottomNav`, la riga diventa: Home, Animali, `Expanded` vuoto, Calendario (`currentIndex == 2`), Contabilità (`currentIndex == 3`, icona `Icons.receipt_long_rounded`, label `Contabilità`), Altro (`currentIndex == 4`). Il commento dell'indice si aggiorna. `FittedBox` sul testo c'è già.

In `router.dart`, il nuovo `StatefulShellBranch` sta subito prima del branch di `AppRoutes.altro`. Rotta `AppRoutes.contabilita` → `AnniContabiliPage`. Le rotte figlie `:anno` e `:anno/:id` si aggiungono nel Task 9 e 11; in questo task la pagina è solo l'elenco.

`AnniContabiliPage.build` ritorna un `Center` con `Text('Contabilità')` se non hai ancora la lista. Il Task 9 sostituisce questo build.

Aggiorna il commento in `app_shell.dart` da «4 sezioni» a «5 sezioni». Non cambiare `new_item_sheet.dart`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/shell/shell_navigation_test.dart`

Expected: PASS, anche a 320 dp, `tester.takeException()` null.

- [ ] **Step 5: Commit**

```bash
git add lib/ui/icons.dart lib/ui/components/app_bottom_nav.dart lib/router.dart lib/features/shell/app_shell.dart lib/features/contabilita/anni_page.dart test/features/shell/shell_navigation_test.dart test/helpers/pump_app.dart
git commit -m "feat: voce Contabilità nella barra"
```

---

### Task 9: Elenco anni

**Files:**
- Modify: `lib/features/contabilita/anni_page.dart`
- Test: `test/features/contabilita/anni_page_test.dart`

**Interfaces:**
- Consumes: `InMemoryContabilitaRepository`, `erroreAnno`, `messaggioAnnoDuplicato`, `formatArchivioMb`, `sommaDimensioni`, `sommaImporti`, `formatEuro`, `contabilitaAvviso400`, `orologioAnnoUsabile`, `AppIcons.contabilita`, `canCreateNotes` come «è un volontario attivo» (è vero per presidente, referente e volontario attivi)
- Produces:
  - `AnniContabiliPage.aggiungiKey = Key('contabilita-aggiungi-anno')`
  - `AnniContabiliPage.avvisoKey = Key('contabilita-avviso-400')`
  - `AnniContabiliPage.archivioKey = Key('contabilita-archivio-mb')`
  - All'apertura, se l'orologio è usabile e l'anno `DateTime.now().year` manca, `createAnno`. Se esiste, niente messaggio. Se `createAnno` lancia e non è `AnnoGiaPresente`, il testo dell'errore resta visibile e gli anni in cache anche.

- [ ] **Step 1: Write the failing test**

`pumpApp` con `contabilita: InMemoryContabilitaRepository()`, `initialLocation: AppRoutes.contabilita`, `size: Size(360, 900)`.

```dart
testWidgets('crea l anno in corso e mostra la riga', (tester) async {
  final repo = InMemoryContabilitaRepository();
  await pumpApp(tester, contabilita: repo, initialLocation: AppRoutes.contabilita);
  expect(find.text('${DateTime.now().year}'), findsWidgets);
  expect(find.byKey(AnniContabiliPage.aggiungiKey), findsOneWidget);
  expect(find.byKey(AnniContabiliPage.archivioKey), findsOneWidget);
});

testWidgets('aggiungere un anno doppio mostra il messaggio', (tester) async {
  final repo = InMemoryContabilitaRepository();
  await repo.createAnno(anno: 2024, uid: 'uid-1', now: DateTime.utc(2024, 1, 1));
  await pumpApp(tester, contabilita: repo, initialLocation: AppRoutes.contabilita);
  await tester.tap(find.byKey(AnniContabiliPage.aggiungiKey));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).last, '2024');
  await tester.tap(find.text('Crea'));
  await tester.pumpAndSettle();
  expect(find.text('Il 2024 è già presente.'), findsOneWidget);
});

testWidgets('sopra 400 MB compare l avviso', (tester) async {
  final repo = InMemoryContabilitaRepository();
  await repo.createAnno(anno: 2026, uid: 'uid-1', now: DateTime.utc(2026, 1, 1));
  await repo.saveNuovo(
    documentoGrande(),
    Uint8List.fromList([1]),
  );
  await pumpApp(tester, contabilita: repo, initialLocation: AppRoutes.contabilita);
  expect(find.byKey(AnniContabiliPage.avvisoKey), findsOneWidget);
  expect(find.text(contabilitaAvviso400), findsOneWidget);
});
```

Nello stesso file di test, `documentoGrande()` ritorna un `DocumentoContabile` con `id: 'grande'`, `anno: 2026`, `nome: 'Archivio'`, `data: DateTime.utc(2026, 1, 2)`, `tipologia: TipologiaContabile.fattura`, `descrizione: ''`, `importo: null`, `mime: 'application/pdf'`, `nomeFile: 'a.pdf'`, `dimensione: 400 * 1024 * 1024 + 1`, `chunkCount: 1`, `generation: 1`, audit di test. Il fake del Task 3 conserva quella `dimensione`. La riga dell'archivio usa `sommaDimensioni`, non la lunghezza dei byte.

La riga anno mostra l'anno, il conteggio e `formatEuro` della somma. Un anno senza documenti resta, con somma `€ 0,00` e conteggio 0. Ordine: anno numerico decrescente.

«Aggiungi anno» è `AppButton` con `expand: false`, variante `ghost`, nell'intestazione, non un bottone a tutta larghezza. Il foglio è `AppSheet.show` titolo `Aggiungi anno`, un `AppTextField` hint `2026`, bottone `Crea`.

Contratto in cima al file:

```
// AnniContabiliPage
// Column
//   riga intestazione: titolo Contabilità | AppButton ghost «Aggiungi anno» h=40
//   testo archivio MB  caption 1 riga
//   se avviso: testo avviso  caption  maxLines 3
//   lista: riga anno Expanded + conteggio + formatEuro
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/contabilita/anni_page_test.dart`

Expected: FAIL

- [ ] **Step 3: Write minimal implementation**

`ConsumerStatefulWidget`. In `initState`, `addPostFrameCallback` chiama `createAnno` per `DateTime.now().year` se manca e `orologioAnnoUsabile`. `AnnoGiaPresente` si ignora. Altri errori finiscono in uno `String? _errore` mostrato sopra la lista.

Se `contabilitaRepositoryProvider` è null: testo `Archivio contabile non disponibile.`

Tap sulla riga: `context.push(AppRoutes.contabilitaAnno(anno))`. La pagina anno arriva nel Task 10; il tap può già chiamare la rotta.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/contabilita/anni_page_test.dart test/features/shell/shell_navigation_test.dart`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/contabilita/anni_page.dart test/features/contabilita/anni_page_test.dart test/helpers/fake_contabilita_repository.dart
git commit -m "feat: elenco degli anni contabili"
```

---

### Task 10: Archivio dell'anno

**Files:**
- Create: `lib/features/contabilita/filtri_sheet.dart`
- Create: `lib/features/contabilita/anno_page.dart`
- Modify: `lib/router.dart` (figlio `:anno`)
- Test: `test/features/contabilita/anno_page_test.dart`

**Interfaces:**
- Consumes: `filtraDocumenti`, `ordinaArchivio`, `sommaImporti`, `FiltriContabilita`, `canWriteRecords`
- Produces:
  - `AnnoContabilePage({required int anno})`
  - `AnnoContabilePage.esportaKey = Key('contabilita-esporta')`
  - `AnnoContabilePage.aggiungiKey = Key('contabilita-aggiungi-doc')`
  - `AnnoContabilePage.cercaKey = Key('contabilita-cerca')`
  - `AnnoContabilePage.filtriKey = Key('contabilita-filtri')`
  - `class FiltriContabilitaSheet` con chip Tutte + le cinque etichette, campi dal/al, bottone `Azzera`, bottone `Applica`
  - Export: `onPressed: documentiDellAnno.isEmpty ? null : _esporta`. Il Task 11 collega `_esporta` allo ZIP; in questo task `_esporta` può essere un no-op che non parte se la lista è vuota. Il bottone c'è solo se `canWriteRecords`.
  - `Aggiungi documento` c'è per ogni volontario attivo (`canCreateNotes`). Il Task 11 apre il foglio; qui il bottone è visibile.

- [ ] **Step 1: Write the failing test**

Due documenti nello stesso anno, date diverse. La pagina a `AppRoutes.contabilitaAnno(2026)`.

- Il nome del più recente sta sopra.
- Digitare nel campo `Cerca per nome` nasconde l'altro. Il riepilogo conta 1.
- Presidente: `find.byKey(AnnoContabilePage.esportaKey)` è enabled se c'è almeno un documento, anche quando la ricerca non lascia righe. Con repository senza documenti del 2026, il bottone c'è e `tester.widget<AppButton>(...).onPressed` è null.
- Volontario (`testVolunteer(ruolo: VolunteerRuolo.volontario)`): niente chiave esporta. C'è `aggiungiKey`.
- `Size(320, 900)`: `tester.takeException()` è null. Il campo cerca ha altezza `AppDim.searchH` (il widget è `AppTextField` con `fieldHeight: AppDim.searchH` e `label: null`).

Contratto in cima a `anno_page.dart`:

```
// Column
//   riga: anno Expanded | AppButton ghost «Esporta documentazione annuale» solo se canWriteRecords
//   Row h=40: Expanded AppTextField h=38 hint «Cerca per nome» | gapS | bottone Filtri 40x40
//   SizedBox gapS
//   riepilogo 1 riga: conteggio e formatEuro dei visibili
//   Expanded ListView
//   AppButton primary «Aggiungi documento»
// La riga cerca+filtri+riepilogo sta sotto i 120 dp: 40 + gapS + una riga caption.
```

Ogni riga documento: nome `maxLines: 1` ellissi, data, etichetta tipologia, importo se non null, nota `maxLines: 1` ellissi. Tap: `context.push(AppRoutes.contabilitaDocumento(anno, id))`.

Il foglio filtri: `AppChip` in `Wrap`. `Azzera` rimette tipologia null e date null. `Applica` chiude e la pagina usa i filtri. Date dal/al con `formatItalianDate` in campi read-only che aprono `showDatePicker`.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/contabilita/anno_page_test.dart`

Expected: FAIL

- [ ] **Step 3: Write minimal implementation**

Rotta figlia di `/contabilita`:

```dart
GoRoute(
  path: ':anno',
  builder: (context, state) {
    final anno = int.tryParse(state.pathParameters['anno'] ?? '');
    if (anno == null) {
      return const Center(child: Text('Anno non valido.'));
    }
    return AnnoContabilePage(anno: anno);
  },
),
```

`watchAnno`. Lista ordinata con `ordinaArchivio` poi `filtraDocumenti`. L'export, quando il Task 11 lo collega, legge `watchAnno` prima del filtro. In questo task tieni in stato la lista non filtrata per decidere se il bottone è usabile.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/contabilita/anno_page_test.dart`

Expected: PASS, anche a 320 dp.

- [ ] **Step 5: Commit**

```bash
git add lib/features/contabilita/anno_page.dart lib/features/contabilita/filtri_sheet.dart lib/router.dart test/features/contabilita/anno_page_test.dart
git commit -m "feat: archivio documenti di un anno con ricerca e filtri"
```

---

### Task 11: Scheda, anteprima, export

**Files:**
- Create: `lib/features/contabilita/documento_sheet.dart`
- Create: `lib/features/contabilita/documento_page.dart`
- Modify: `lib/features/contabilita/anno_page.dart` (apre il foglio e lancia l'export)
- Modify: `lib/router.dart` (figlio `:id`)
- Test: `test/features/contabilita/documento_sheet_test.dart`
- Test: `test/features/contabilita/documento_page_test.dart`

**Interfaces:**
- Consumes: `preparaFileContabile`, `valutaQuota`, `esportaZipAnno`, `nomeZipAnno`, `FileShare`, `FileOpener`, `DocumentFilePicker`, `PhotoPicker`, `homeOfflineProvider`, `PdfPreview` da `package:printing/printing.dart` (già in pubspec)
- Produces:
  - `DocumentoContabileSheet.open(BuildContext, {required int anno, DocumentoContabile? existing})`
  - `DocumentoContabilePage({required int anno, required String id})`
  - chiavi `DocumentoContabilePage.modificaKey`, `eliminaKey`, `condividiKey`, `scaricaKey`
  - salva con `saveNuovo` o `saveMeta` / `replaceFile`
  - export chiama `fileShareProvider.shareFile` con il nome ZIP e mime `application/zip`

- [ ] **Step 1: Write the failing test**

Scheda, pompata dentro `MaterialApp` come gli altri sheet del progetto (`AppSheet.show` da un bottone nel test):

- Salva senza nome: testo `Indica il nome del documento.`
- Salva senza file in inserimento: `Allega un PDF, JPG o PNG.`
- Importo `-1`: `Importo non valido.`
- Nome, data, tipologia default Fattura, file PDF finto via un `DocumentFilePicker` di test che `pickPdf` ritorna `PickedDocumentFile(bytes: Uint8List.fromList([1, 2]), name: 'a.pdf', mime: 'application/pdf')`: dopo Salva il repository ha un documento con `importo` null se il campo è vuoto.
- In modifica, Salva senza riselezionare il file cambia solo il nome e `generation` resta 1.
- Sostituire con un file che farebbe superare i 700 MiB mostra `contabilitaPieno` e non cambia i byte.

Pagina anteprima:

- JPEG: `find.byType(Image)`.
- PDF: `find.byType(PdfPreview)`.
- Id assente: `Documento non trovato.`
- Volontario: niente `modificaKey` e niente `eliminaKey`. C'è `condividiKey`.
- Presidente: le due chiavi ci sono. Tap elimina mostra `contabilitaElimina`. Conferma `Elimina` toglie il documento.
- Export dalla pagina anno: un `FileShare` fake registra `fileName == nomeZipAnno(2026)` e i byte del decoder contengono `riepilogo.csv`. I filtri attivi non cambiano il numero di file nello ZIP: due documenti, ricerca che ne nasconde uno, lo ZIP ha due entry più il csv.

Scatta usa `PhotoPicker.pickFromCamera`. Galleria usa `DocumentFilePicker.pickImages` e prende solo il primo. File usa `pickPdf`. Un nome `.docx` non arriva da questi picker; il rifiuto è già coperto dal Task 6. Se `pickPdf` ritorna un mime non pdf, `preparaFileContabile` mostra `contabilitaFileRifiutato`.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/contabilita/documento_sheet_test.dart test/features/contabilita/documento_page_test.dart`

Expected: FAIL

- [ ] **Step 3: Write minimal implementation**

Foglio `AppSheet` titolo `Nuovo documento` o `Modifica documento`. Campi nell'ordine della specifica. `AppSegmented` con i cinque `etichetta`, indice iniziale 0. Data: campo read-only con `formatItalianDate`, default `DateTime.now()`, tap apre `showDatePicker`. Importo `keyboardType: TextInputType.number`. Nota `maxLines: 3`.

Prima di scrivere, `erroreNome`, `erroreNota`, `erroreImporto`. Poi `valutaQuota` con `usato = sommaDimensioni(watchTutti)` escluso il documento in modifica (togli la sua `dimensione` passando `vecchia`). `nuova` è la `dimensione` del file preparato, o la vecchia se il file non si sostituisce. Se `rifiuto` non è null, mostralo e non chiamare il repository.

Id nuovo: `'${DateTime.now().microsecondsSinceEpoch}'`. `uid` da `ref.read(currentVolunteerProvider)?.id ?? ''`. Audit `Audit.seed(DateTime.now(), by: uid)` in creazione; in modifica `audit.copyWith(updatedAt: DateTime.now(), updatedBy: uid)`.

La scheda, dopo `preparaFileContabile`, mette sul modello `dimensione: preparato.bytes.length` e `chunkCount: splitContabilitaBytes(preparato.bytes).length`. Il repository conserva quella `dimensione` e ricalcola solo `chunkCount` dal numero di pezzi scritti, come nel Task 3 e nel Task 4. Non passare una dimensione diversa dalla lunghezza dei byte preparati.

Anteprima: `loadBytes`. `image/jpeg` → `Image.memory`. `application/pdf` → `PdfPreview(build: (_) async => bytes, allowPrinting: false, allowSharing: false, canChangePageFormat: false)`. Scarica chiama `fileOpenerProvider.openFile`. Condividi chiama `fileShareProvider.shareFile` con il `nomeFile` del documento. Modifica riapre il foglio con `existing`. Elimina: `showDialog` con il testo `contabilitaElimina` e azione `Elimina`, poi `deleteDocumento` e `context.pop`.

Export in `anno_page.dart`: documenti di `watchAnno` non filtrati. `offline: ref.read(homeOfflineProvider)`. Poi `shareFile` con `nomeZipAnno(anno)`, mime `application/zip`, text `Documentazione contabile $anno`. Errori in un `Text` sotto l'intestazione, incluso `contabilitaExportOffline`.

Rotta:

```dart
GoRoute(
  path: ':id',
  builder: (context, state) => DocumentoContabilePage(
    anno: int.parse(state.pathParameters['anno']!),
    id: state.pathParameters['id']!,
  ),
),
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/contabilita/documento_sheet_test.dart test/features/contabilita/documento_page_test.dart test/features/contabilita/anno_page_test.dart test/data/firestore_contabilita_repository_test.dart`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/contabilita/documento_sheet.dart lib/features/contabilita/documento_page.dart lib/features/contabilita/anno_page.dart lib/router.dart test/features/contabilita/documento_sheet_test.dart test/features/contabilita/documento_page_test.dart test/helpers/fake_contabilita_repository.dart
git commit -m "feat: carica, modifica ed esporta i documenti contabili"
```

---

### Task 12: Golden e analyze

**Files:**
- Create: `test/golden/contabilita_golden_test.dart`
- Create: `test/golden/goldens/contabilita_anni_360.png` (solo con `--update-goldens` di questo file)
- Create: `test/golden/goldens/contabilita_anno_360.png`

**Interfaces:**
- Consumes: `pumpGolden` in `test/golden/golden_support.dart`, `skipUntilPng`, `AppRoutes.contabilita`, `AppRoutes.contabilitaAnno`
- Produces: due golden a 360×640. Non toccare i PNG già in `test/golden/goldens/` oltre a questi due nomi nuovi.

- [ ] **Step 1: Write the failing test**

`pumpGolden` oggi non passa `contabilita`. Aggiungi un parametro opzionale `ContabilitaRepository? contabilita` a `pumpGolden` e inoltralo a `pumpApp`. Il test crea un repository con l'anno 2026 e un documento «Fattura veterinario», data 12/03/2026, importo 1240.50, poi:

```dart
testWidgets('elenco anni 360', (tester) async {
  await pumpGolden(tester, location: AppRoutes.contabilita, contabilita: repo);
  await expectLater(
    find.byType(AnniContabiliPage),
    matchesGoldenFile('goldens/contabilita_anni_360.png'),
  );
}, skip: skipUntilPng('contabilita_anni_360.png'));

testWidgets('archivio anno 360', (tester) async {
  await pumpGolden(
    tester,
    location: AppRoutes.contabilitaAnno(2026),
    contabilita: repo,
  );
  await expectLater(
    find.byType(AnnoContabilePage),
    matchesGoldenFile('goldens/contabilita_anno_360.png'),
  );
}, skip: skipUntilPng('contabilita_anno_360.png'));
```

Il repository va creato nel test, non in `golden_support`, così gli altri golden restano uguali. `pumpGolden` con il parametro nuovo default null non cambia Home e Cani.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/golden/contabilita_golden_test.dart`

Expected: i test sono skipped finché i PNG non esistono (`skipUntilPng`). Questo è il comportamento di `home_golden_test.dart`, non un fallimento. Il passo di verifica è il comando di aggiornamento qui sotto, che deve creare i due PNG e poi passare senza skip.

- [ ] **Step 3: Genera solo questi golden**

Run: `flutter test test/golden/contabilita_golden_test.dart --update-goldens`

Expected: PASS e i due PNG nuovi. Non lanciare `--update-goldens` sulla cartella `test/golden` intera.

- [ ] **Step 4: Analyze e suite dei file toccati**

Run:

```
flutter analyze lib/features/contabilita lib/data/models/documento_contabile.dart lib/data/repositories/contabilita_repository.dart lib/data/firestore/firestore_contabilita_repository.dart lib/ui/components/app_bottom_nav.dart lib/router.dart
flutter test test/features/contabilita test/data/documento_contabile_test.dart test/data/firestore_contabilita_repository_test.dart test/features/shell/shell_navigation_test.dart test/golden/contabilita_golden_test.dart
```

Da `backend`: `node --test tests/contabilita.rules.test.mjs`

Expected: analyze senza issue, test PASS.

- [ ] **Step 5: Commit**

```bash
git add test/golden/contabilita_golden_test.dart test/golden/golden_support.dart test/golden/goldens/contabilita_anni_360.png test/golden/goldens/contabilita_anno_360.png
git commit -m "test: golden dell'elenco anni e dell'archivio contabile"
```

## Spec coverage

- Barra, indici, icona, niente voce nel +: Task 8
- Elenco anni, anno automatico, aggiungi anno, avviso 400 MB: Task 9
- Archivio, ricerca, filtri, riepilogo, export disabilitato, volontario senza export: Task 10
- Scheda, anteprima, elimina, tetto 700, ZIP e condivisione: Task 11
- Modelli, importo null, data fuori cartella: Task 1 e 2
- Pezzi, generazioni, padre senza byte: Task 3 e 4
- Regole e indice: Task 5
- PDF/JPEG e rifiuto altri formati: Task 6
- Nomi ZIP, CSV, offline: Task 2 e 7
- Golden nuovi, analyze: Task 12
