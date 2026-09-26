# Contabilità: archivio annuale spese e documenti

Data: 2026-09-26
Progetto: Amici per la Coda
Stato: da rileggere

## Problema

L'associazione deve archiviare nell'app fatture, scontrini, ricevute, preventivi e altri documenti contabili, divisi per anno solare, e a fine esercizio scaricare tutto in un unico ZIP da mandare al commercialista.

Le spese già presenti sulla scheda del cane (importo, categoria, nessun file) restano quelle. Questa sezione è l'archivio dell'associazione, non il registro spese del singolo animale.

## Decisioni bloccate

- Approccio 1: collezioni nuove `anniContabili` e `contabilita`. I byte stanno in Firestore a pezzi, come i documenti del cane. Niente Firebase Storage. Piano Spark invariato.
- File accettati in ingresso: PDF, JPG, JPEG, PNG. JPG e PNG passano dalla compressione immagini già usata per i documenti e vengono salvati come JPEG. Il PDF è salvato così com'è. Word, Excel, ZIP e ogni altro formato sono rifiutati.
- Tetto per file: 10 MiB (`10 * 1024 * 1024` byte) sui byte salvati, dopo la compressione. Stesso messaggio già in app (`DocumentTooLarge`).
- Tetto archivio: somma di `dimensione` su tutti i documenti contabili. Oltre 400 MiB un avviso, senza bloccare. Oltre 700 MiB un caricamento nuovo è rifiutato. Sostituire un file resta consentito sopra i 700 MiB se il nuovo file non è più grande del vecchio.
- Chi è volontario attivo vede, scarica, condivide e carica. Creare un anno (automatico o con «Aggiungi anno») è consentito a ogni volontario attivo. Modificare, eliminare ed esportare lo ZIP è solo di presidente e referente. Le azioni negate non si mostrano disabilitate: non compaiono.
- L'anno in corso si crea da solo all'apertura della sezione, se manca. Gli anni già presenti restano e accettano ancora documenti. «Aggiungi anno» crea un anno assente, dal 1990 all'anno solare prossimo (fuso del dispositivo). Un anno non si modifica e non si cancella.
- La cartella è una scelta di chi carica. La data del documento può cadere in un altro anno: un documento datato 2025 si può archiviare nella cartella 2026. Lo ZIP e il nome file usano la data del documento; il raggruppamento in elenco usa `anno` della cartella.
- Lo ZIP di un anno contiene tutti i documenti di quella cartella, anche se la lista è filtrata. Zero documenti: l'esportazione non è usabile. Nome: `Amici_per_la_Coda_Contabilita_{anno}.zip`. Dentro, un file per documento più `riepilogo.csv`.
- Il + centrale non guadagna una voce. «Spesa» nel + resta la spesa del cane.
- Unica dipendenza nuova: il pacchetto Dart `archive`, solo per costruire lo ZIP sul dispositivo o nel browser.
- Android e web usano le stesse schermate. Scarica e condividi passano dalle azioni file già presenti.

## Fuori da questo lavoro

- Collegare un documento a un cane, a un fornitore o a una spesa esistente.
- Word, Excel, HEIC, WEBP e qualsiasi formato oltre PDF, JPG, JPEG, PNG.
- Firebase Storage, piano Blaze, Functions.
- Cancellare una cartella anno.
- Voce nel foglio del +.
- Bilancio, categorie economiche, prima nota.
- Inviare l'email al commercialista. Lo ZIP si scarica o si condivide.

## Vincoli

1. Niente Storage. Niente scroll orizzontale. Tab e barre restano `isScrollable: false`.
2. Misure solo da `lib/ui/tokens.dart`. Icone di schermata solo da `AppIcons`. In barra inferiore l'icona di sistema è ammessa, come Home e Calendario.
3. Testi in italiano. Date `dd/MM/yyyy` con `formatItalianDate`. Importi in interfaccia con `formatEuro` (`€ 1240,50`, senza separatore delle migliaia).
4. Campi Firestore in italiano. Date come `Timestamp`. Ogni documento ha `createdAt`, `createdBy`, `updatedAt`, `updatedBy`.
5. Aree toccabili almeno 40 dp. Ricerca alta 38 dp, senza etichetta sopra. Ricerca + filtri + riga di riepilogo dell'anno entro 120 dp.
6. Le cinque tipologie in scheda sono un selettore segmentato a larghezza piena, segmenti uguali, un solo valore. A 320 dp il testo del segmento si riduce e resta su una riga.
7. I documenti dei cani, `DocumentRepository` e la collezione `documents` non cambiano schema né semantica.

---

## 1. Barra e schermate

Ordine della barra: Home, Animali, +, Calendario, Contabilità, Altro.

Indici del ramo: Home 0, Animali 1, Calendario 2, Contabilità 3, Altro 4. Il + non è un indice.

Etichetta «Contabilità». A 320 dp il testo si rimpicciolisce (`FittedBox`) e non va a capo e non scorre. Icona di barra: `Icons.receipt_long_rounded`. In schermata: `AppIcons.contabilita` (`Icons.receipt_long_rounded`, fondo verde soft, glifo verde), distinta da `AppIcons.spese`.

Percorsi:

- `/contabilita` elenco anni
- `/contabilita/{anno}` archivio di quell'anno
- `/contabilita/{anno}/{id}` anteprima

Il ramo resta montato come gli altri.

### Elenco anni

Righe dall'anno più alto al più basso. Ogni riga: anno, numero documenti, somma degli importi presenti (`formatEuro`). Gli importi assenti non entrano nella somma e non contano come zero.

In testa, una riga con la somma delle `dimensione` di tutta la contabilità, in MB con una cifra decimale e la virgola (1 MiB = 1024 * 1024 byte). Esempio: «Archivio: 120,5 MB». Se la somma supera 400 MiB, sotto compare l'avviso, non al posto della riga.

«Aggiungi anno» sta nell'intestazione, non è un bottone a tutta larghezza impilato. Chiede quattro cifre. Se l'anno esiste: «Il {anno} è già presente.» (esempio: «Il 2024 è già presente.»). Se è fuori intervallo: «L'anno deve essere fra il 1990 e il {massimo}.» con `{massimo}` = anno solare del dispositivo + 1.

All'apertura, se manca l'anno solare corrente, l'app lo crea. Se esiste già, l'apertura non mostra errore. Errore di rete in creazione: si mostra l'errore e gli anni già in cache restano visibili.

Un anno senza documenti resta in elenco.

### Archivio dell'anno

Lista di tutti i documenti della cartella, data decrescente, a parità di data per nome. La lista usa solo i metadati.

In testa, entro 120 dp:

- campo con segnaposto «Cerca per nome», altezza 38 dp
- pulsante «Filtri»
- riga di riepilogo sui documenti visibili dopo ricerca e filtri: conteggio e somma importi

Il foglio filtri ha la tipologia (chip in `Wrap`: Tutte, Fattura, Scontrino, Ricevuta, Preventivo, Altro) e un intervallo date «dal» / «al», estremi inclusi, ciascuno facoltativo. «Azzera» toglie tipologia e date. La ricerca è una sottostringa del nome, senza distinzione di maiuscole, in AND con i filtri.

Ogni riga: nome (una riga, ellissi), data, tipologia, importo se presente, nota su una riga con ellissi.

Pulsante principale in fondo: «Aggiungi documento», per ogni volontario attivo.

«Esporta documentazione annuale» è nell'intestazione, solo presidente e referente. È disabilitato se la cartella ha zero documenti. Resta abilitato se i filtri nascondono tutto ma la cartella ha documenti, perché l'export ignora i filtri.

### Scheda documento

Foglio `AppSheet`, in inserimento e in modifica.

- Nome, obbligatorio, trimmato, da 1 a 120 caratteri. Vuoto: «Indica il nome del documento.»
- Data, obbligatoria, default oggi, `dd/MM/yyyy`. Può essere fuori dall'anno della cartella.
- Tipologia, obbligatoria, default Fattura. Segmenti: Fattura, Scontrino, Ricevuta, Preventivo, Altro.
- Nota, facoltativa, al massimo 1000 caratteri. In Firestore il campo c'è sempre: stringa vuota se assente.
- Importo, facoltativo. Virgola decimale. Zero ammesso. Negativo o non numerico: «Importo non valido.» Campo assente in Firestore se l'utente lo lascia vuoto. Non si scrive zero al posto del vuoto.
- File. In inserimento obbligatorio. Azioni: Scatta, Galleria, File. In modifica si vede il nome del file salvato; si può tenerlo o sostituirlo.

Pulsante del foglio: «Salva».

### Anteprima

Pagina nel ramo. PDF e JPEG si aprono nell'app. Sempre disponibili scarica e condividi, per ogni volontario attivo. Modifica, solo presidente e referente, apre il foglio. Elimina, solo presidente e referente, apre la conferma.

Conferma elimina: «Eliminare questo documento? Il file verrà cancellato. Non si può annullare.»

Id assente: «Documento non trovato.»

---

## 2. Dati

### `anniContabili/{anno}`

L'id è l'anno in decimale, senza zeri iniziali (`2026`).

| Campo | Tipo | Note |
|---|---|---|
| anno | int | Uguale all'id |
| createdAt, createdBy, updatedAt, updatedBy | audit | In creazione `updatedAt` = `createdAt`, `updatedBy` = `createdBy` |

Nessun altro campo. Niente contatori denormalizzati: conteggio e somme si calcolano dai documenti.

### `contabilita/{id}`

Id generato dal client, univoco, non riusato.

| Campo | Tipo | Note |
|---|---|---|
| anno | int | Cartella, non necessariamente l'anno di `data` |
| nome | string | 1–120, già trimmato |
| data | timestamp | Data del documento |
| tipologia | string | `fattura`, `scontrino`, `ricevuta`, `preventivo`, `altro` |
| descrizione | string | 0–1000 |
| importo | number | Assente se non applicabile. Se presente, `>= 0` |
| mime | string | `application/pdf` o `image/jpeg` |
| nomeFile | string | Nome originale di scelta, dopo l'eventuale suffisso `.jpg` della compressione. Serve all'interfaccia, non allo ZIP |
| dimensione | int | Byte salvati, dopo compressione, `1 … 10 * 1024 * 1024` |
| chunkCount | int | `>= 1` |
| generation | int | Parte da 1. Ogni sostituzione del file la incrementa di 1 |
| createdAt, createdBy, updatedAt, updatedBy | audit | |

Il padre non contiene `contenutoB64` né altri byte. I byte stanno solo nei pezzi della generazione indicata dal padre. L'ascolto della lista non legge i pezzi. Anteprima, scarica ed export leggono solo `g/{generation}`.

### `contabilita/{id}/g/{generation}/chunks/{n}`

`generation` e `n` sono decimali. `n` va da `0` a `chunkCount - 1` di quella generazione.

| Campo | Tipo |
|---|---|
| index | int, uguale a `n` |
| b64 | string, base64 del pezzo |

Si riusano `documentChunkBytes` (600 KiB sul binario, prima del base64) e `splitDocumentBytes` / `joinDocumentChunks`. Per la contabilità `chunkCount` è sempre almeno 1: anche un file piccolo va in un pezzo, così la lista non scarica i byte. Non si usa la soglia inline da 700 KiB dei documenti cane.

Un commit Firestore sta sotto i 10 MiB. I pezzi di una generazione si scrivono a gruppi di al massimo 8.

Nuovo documento:

1. Scrivere tutti i pezzi di `generation` 1.
2. Scrivere il padre.
3. Se un gruppo di pezzi fallisce, cancellare i pezzi di quella generazione già scritti, non scrivere il padre, mostrare l'errore.

Sostituzione del file:

1. Scrivere tutti i pezzi di `generation + 1`.
2. Aggiornare il padre (`generation`, `chunkCount`, `dimensione`, `mime` e gli altri campi della scheda).
3. Cancellare i pezzi della generazione precedente. Se questa pulizia fallisce, il salvataggio resta riuscito: il padre punta già ai byte nuovi. I pezzi vecchi sono orfani e si ritentano alla cancellazione del documento.

Se il passo 1 o il passo 2 fallisce, il padre resta sulla generazione precedente. I pezzi incompleti della generazione nuova si cancellano. L'utente vede l'errore.

Cancellazione documento: cancellare i pezzi delle generazioni da 1 a `generation + 1` (così si prende anche una generazione nuova rimasta a metà), poi il padre. Se un pezzo della generazione corrente non si cancella, l'operazione fallisce in modo visibile e non si dice che il documento è eliminato.

### Indice

`contabilita`: `anno` ASC, `data` DESC. Va in `backend/firestore.indexes.json`.

### Regole

`anniContabili` e `contabilita` si aggiungono all'elenco di esclusione già presente nel catch-all `/{col}/{id}`. Senza questa esclusione quel catch-all rimetterebbe a presidente update e delete sull'anno, e una create senza i vincoli sui campi. I permessi veri stanno solo nei match sotto.

`anniContabili/{anno}`:

- read: `attivo()`
- create: `attivo()`, `anno` int uguale all'id numerico, `anno` fra 1990 e 2100 inclusi, chiavi ammesse solo `anno` e i quattro campi audit
- update, delete: nessun allow

Il tetto «anno prossimo» è dell'app. Le regole si fermano a 2100 per non dipendere dall'estrazione dell'anno da `request.time`. Se l'orologio del dispositivo è fuori da 1990–2100, l'app non crea l'anno in corso e mostra l'errore di intervallo.

`contabilita/{id}`:

- read: `attivo()`
- create: `attivo()`, con gli stessi vincoli di campo della update
- update: `puoScrivere()`, `tipologia` nell'elenco, `mime` solo i due valori, `chunkCount >= 1`, `generation >= 1`, niente chiave `contenutoB64`, `dimensione` nel tetto 10 MiB, `importo` assente oppure numero `>= 0`, `nome` e `descrizione` entro le lunghezze
- delete: `puoScrivere()`

`contabilita/{id}/g/{generation}/chunks/{n}`:

- read: `attivo()`
- create: `attivo()`, `b64` stringa sotto 900000 caratteri, `index` int
- update, delete: `puoScrivere()`

La regola ricorsiva già presente sui `chunks` concede comunque la scrittura a `puoScrivere()`. Il create esplicito serve al volontario, che oggi quella regola ricorsiva non copre.

Un volontario può creare pezzi anche sotto un id altrui. È accettato: gli account sono i 3–4 volontari dell'associazione. Non può modificare né cancellare pezzi esistenti.

Anonimo: nessuna lettura e nessuna scrittura, come sul resto del database.

---

## 3. Caricamento, tetti, export

### Preparazione file

Un solo file per documento.

- PDF (`mime` che contiene `pdf`, o nome che finisce con `.pdf`): byte invariati, `mime` salvato `application/pdf`.
- JPG, JPEG, PNG: `compressDocumentImage`, `mime` salvato `image/jpeg`, `nomeFile` con estensione `.jpg` come già fa `_asJpegName`.
- Altro: «Usa un PDF, JPG o PNG.» Nessuna scrittura.

Poi `ensureDocumentSizeAllowed` sui byte salvati. Sopra i 10 MiB: messaggio di `DocumentTooLarge`, nessuna scrittura.

### Tetti dell'archivio

`usato` = somma di `dimensione` di tutti i documenti `contabilita`.

- `usato > 400 * 1024 * 1024`: avviso «L'archivio contabile supera i 400 MB. Resta spazio, ma conviene non accumulare file inutili.» Il salvataggio procede.
- Nuovo documento: se `usato + dimensioneNuova > 700 * 1024 * 1024`, rifiuto «Archivio contabile pieno (oltre 700 MB). Libera spazio eliminando documenti vecchi.» Nessuna scrittura.
- Sostituzione: sia `vecchia` la `dimensione` del documento aperto. Se `dimensioneNuova <= vecchia`, il salvataggio è consentito anche quando `usato` supera già 700 MiB. Se `dimensioneNuova > vecchia` e `usato - vecchia + dimensioneNuova > 700 * 1024 * 1024`, stesso rifiuto dei 700 MB.

Il controllo usa i metadati già ascoltati. Non interroga la console Firebase.

### Nome nello ZIP

Per ogni documento, in ordine di `data` crescente e, a parità, di `id` crescente:

`{yyyy-MM-dd}_{tipologia}_{slug}{suffisso}.{ext}`

- Data della `data` del documento, in locale, `yyyy-MM-dd`.
- `tipologia` è il valore wire (`fattura`, non «Fattura»).
- `ext` è `pdf` o `jpg` in base al `mime` salvato.
- `slug`: nome trimmato; si porta in minuscolo; poi à→a, è→e, é→e, ì→i, ò→o, ù→u; ogni carattere che non è `a-z` o cifra diventa `_`; i `_` ripetuti diventano uno; si tolgono `_` in testa e in coda; al massimo 40 caratteri. Se resta vuoto: `documento`. Le altre lettere accentate restano fuori da `a-z` e diventano `_`.
- Il primo nome di un gruppo è senza suffisso. Dal secondo duplicato: `_2`, `_3`, … prima dell'estensione.

Esempio: `2026-03-12_fattura_veterinario.pdf`, poi `2026-03-12_fattura_veterinario_2.pdf`.

### `riepilogo.csv`

Primo file dello ZIP, nome esatto `riepilogo.csv`. UTF-8 con BOM. Separatore `;`. Fine riga `\r\n`.

Intestazione:

`Nome;Data;Tipologia;Importo;Nota;File`

- Data: `dd/MM/yyyy`.
- Tipologia: etichetta italiana (Fattura, Scontrino, Ricevuta, Preventivo, Altro).
- Importo: vuoto se assente. Se presente, parte intera senza separatore delle migliaia, virgola, due decimali (`1240,50`). Senza simbolo €.
- Nota: `descrizione`. Se contiene `"` o `;` o a capo, il campo è fra virgolette doppie e le virgolette interne sono raddoppiate.
- File: nome dell'entry nello ZIP.
- Stesso ordine dei file.

Gli entry dei documenti seguono il CSV. I byte estratti sono quelli salvati, senza una seconda compressione applicativa. La libreria `archive` può usare deflate nel contenitore: in estrazione i byte coincidono con quelli salvati.

Export con rete assente e pezzi non in cache: si interrompe prima di consegnare il file, messaggio «Connessione assente: l'esportazione richiede i file.» Non si consegna uno ZIP parziale.

Consegna: azioni file già in app (condivisione su Android, download sul web).

---

## 4. Codice

Zona nuova. I documenti cane non si riusano come modello.

- Modelli: anno contabile e documento contabile, con `fromMap` / `toMap`.
- Repository dedicato, interfaccia più implementazione Firestore e finto per i test. Metodi minimi: ascolto anni, ascolto documenti di un anno, creazione anno, salvataggio con byte, caricamento byte, cancellazione.
- Funzioni pure, senza Firebase: slug e nomi ZIP, CSV, filtri (nome, tipologia, intervallo), somme importi, decisione 400/700, validazione anno.
- Feature `lib/features/contabilita/`: elenco anni, archivio, foglio, anteprima, export.
- `AppIcons.contabilita` in `lib/ui/icons.dart`.
- Ramo in `lib/router.dart` e voce in `lib/ui/components/app_bottom_nav.dart`.
- Regole e indice come sopra.
- `archive` in `pubspec.yaml`.

Il foglio «Cosa vuoi creare?» non si modifica.

---

## 5. Test

Unitari, senza Firebase:

- slug, collisione `_2`, slug vuoto → `documento`, tetto 40 caratteri
- CSV: BOM, `;`, virgolette, importo vuoto, `1240,50`, data `dd/MM/yyyy`, etichetta tipologia
- filtri in AND, ricerca senza distinzione di maiuscole
- somma che ignora l'importo assente e include lo zero
- rifiuto sopra 10 MiB; avviso sopra 400 MiB; rifiuto nuovo sopra 700 MiB; sostituzione con file non più grande consentita sopra i 700 MiB; sostituzione più grande che sfora i 700 MiB rifiutata
- anno 1989 e anno successivo al massimo rifiutati; 1990 e anno prossimo accettati; doppione segnalato
- data del documento fuori dall'anno della cartella accettata

Regole (emulatore, stesso stile di `backend/tests/`):

- anonimo non legge `anniContabili` né `contabilita`
- volontario crea anno, documento e pezzo in `g/1/chunks`
- volontario non aggiorna e non cancella documento, pezzo, anno
- presidente aggiorna e cancella documento e pezzo
- presidente non cancella e non aggiorna l'anno, neanche via catch-all
- create anno con id diverso dal campo `anno` negato
- create e update di un documento con `contenutoB64` negati anche al presidente

Widget:

- la barra mostra Home, Animali, Calendario, Contabilità, Altro
- a 320 dp la barra e l'archivio anno non vanno in overflow orizzontale
- il volontario non vede Esporta, Modifica, Elimina
- presidente li vede; con zero documenti Esporta è presente e non usabile
- golden nuovi per elenco anni e archivio anno a 360 dp, creati con la prima UI approvata. Un golden esistente non si rigenera per far passare un test

`flutter analyze` pulito sui file toccati. I test delle altre sezioni che fissano l'indice 3 su Altro si aggiornano all'indice 4.

## Fatto quando

Un volontario apre Contabilità, trova l'anno in corso, aggiunge un JPG scattato e un PDF, li rivede nell'anno. Un presidente corregge l'importo, esporta lo ZIP, dentro ci sono i due file con i nomi stabili e `riepilogo.csv`. Il volontario non vede elimina né export. Un file da ufficio è rifiutato. L'APK e il sito mostrano la stessa sezione.
