# Amici per la Coda — Specifica di costruzione per Cursor

**Documento unico e vincolante.** Tutto ciò che serve per costruire l'app dall'inizio alla fine.
L'agente deve leggerlo per intero prima di scrivere una riga di codice e rileggere la sezione
pertinente all'inizio di ogni step.

- **Versione:** 1.0
- **Riferimento visivo obbligatorio:** `design/reference.html` (prototipo HTML di 29 schermate, aprirlo nel browser)
- **Committente:** associazione *Amici per la Coda ODV* — rifugio cani
- **Utenti reali:** 3-4 volontari. Non è un'app pubblica, non va su nessuno store.

---

## 0. Contesto e obiettivo

Gestionale per un rifugio cani. Sostituisce quaderni e fogli Excel. Le funzioni centrali sono:

1. **Anagrafe dei cani presenti in rifugio** (creazione profilo completo, foto, microchip, box)
2. **Stato del cane** (in rifugio, stallo, preaffido, adottato, in cura, restituito, deceduto)
3. **Salute** (vaccini, sterilizzazione, terapie, scadenze automatiche)
4. **Adozioni e documenti di affido** (richieste, iter, moduli PDF, firma)
5. **Spese** per cane e bilancio
6. Contorno: calendario, box/settori, volontari e turni, note, statistiche

Tutto deve funzionare con **connessione lenta o assente** (il rifugio ha campo scarso) e
sincronizzarsi appena torna la rete.

---

## 1. Stack tecnico — decisioni già prese, non discuterle

| Ambito | Scelta | Note |
|---|---|---|
| Framework | **Flutter** (stable più recente), Dart 3 | |
| Piattaforma | **Solo Android** | minSdk 24, targetSdk più recente |
| Distribuzione | **APK firmato**, installato a mano sui 3-4 telefoni | niente Play Store |
| Backend | **Firebase** — progetto **nuovo e dedicato**, piano gratuito Spark | |
| Auth | Firebase Authentication, **email + password** | account creati a mano dalla console |
| Database | **Cloud Firestore** | unico database gratuito del progetto |
| Foto | **dentro Firestore in base64 compresso** — NON Firebase Storage | vedi §6 |
| Stato | `flutter_riverpod` | |
| Routing | `go_router` | |
| Offline | persistenza Firestore attiva + cache locale | |
| PDF | `pdf` + `printing` | moduli di affido |
| Firma | `signature` | firma con il dito |
| Immagini | `image_picker` + `flutter_image_compress` | |
| Test | `flutter_test`, `mocktail`, `fake_cloud_firestore` | |

**Perché niente Firebase Storage:** da settembre 2024 Cloud Storage for Firebase non è più
disponibile sul piano Spark, richiede il piano Blaze con carta di credito collegata. Le foto
vengono quindi compresse e salvate in Firestore (1 GiB gratuiti, ampiamente sufficienti).
Il codice deve però passare da un'interfaccia `PhotoRepository` per poter migrare a Storage
in futuro senza toccare la UI.

### Dipendenze `pubspec.yaml` (base)

```yaml
dependencies:
  flutter: {sdk: flutter}
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  cloud_firestore: ^5.0.0
  flutter_riverpod: ^2.5.0
  go_router: ^14.0.0
  image_picker: ^1.1.0
  flutter_image_compress: ^2.3.0
  intl: ^0.19.0
  pdf: ^3.11.0
  printing: ^5.13.0
  signature: ^5.5.0
  flutter_local_notifications: ^17.0.0
  csv: ^6.0.0
  share_plus: ^10.0.0
  collection: ^1.18.0
dev_dependencies:
  flutter_test: {sdk: flutter}
  flutter_lints: ^4.0.0
  mocktail: ^1.0.0
  fake_cloud_firestore: ^3.0.0
```

Usa le versioni stabili più recenti compatibili tra loro; se una risoluzione fallisce, allinea
le versioni e **non** cambiare libreria.

---

## 2. ⚠️ REGOLE DI DIMENSIONE — la parte più importante

Il committente ha già visto agenti AI produrre UI enormi e sprecone. Queste regole sono
**vincolanti** e ogni step viene rifiutato se non le rispetta.

### 2.1 Divieti assoluti

1. **Nessuno scroll orizzontale, mai, in nessuna schermata.** Nessun `SingleChildScrollView`
   con `scrollDirection: Axis.horizontal` per contenuti principali. Nessun `ListView`
   orizzontale che tagli informazioni. Se un contenuto non ci sta in larghezza, si **manda a
   capo, si accorcia o si riduce il font** — non si scorre.
   *Unica eccezione tollerata:* nessuna. Anche le fasce di "card statistiche" e i gruppi di
   chip filtro devono andare a capo con `Wrap`.
2. **Le TabBar non sono mai scorrevoli.** `TabBar(isScrollable: false)`. Tutte e 7 le tab della
   scheda cane devono stare contemporaneamente sullo schermo, anche a 320 dp di larghezza.
3. **Niente widget Material a dimensioni di default.** `ListTile`, `Card`, `AppBar`,
   `ElevatedButton`, `TextFormField` hanno padding di default troppo generosi: vanno sempre
   ridefiniti nel tema o sostituiti con i componenti di `lib/ui/`.
4. **Nessun `RenderFlex overflowed` e nessuna striscia gialla e nera**, in nessuna schermata,
   a nessuna delle larghezze di test.
5. **Nessun valore numerico scritto a mano nel codice delle schermate.** Padding, raggi,
   dimensioni testo e icone si prendono **solo** dalle costanti di `lib/ui/tokens.dart`.

### 2.2 Permessi

- Lo **scroll verticale è consentito e previsto**: le schermate sono lunghe, va benissimo.
- Il **font piccolo è consentito**: meglio 10 sp e vedere tutto, che 16 sp e tagliare i dati.
  La densità informativa ha la precedenza sull'ariosità.
- Le **aree toccabili minime sono 40×40 dp** (non 48): è un gestionale da tavolo, usato da
  persone che inseriscono molti dati.

### 2.3 Larghezze di riferimento per il test

Ogni schermata va verificata a **320, 360, 411 e 430 dp** di larghezza logica.
360 dp è il caso normale, 320 dp è il caso peggiore da superare comunque.

---

## 3. Design system

Ricalca esattamente `design/reference.html`. Colori e misure sono già tarati lì.

### 3.1 File `lib/ui/tokens.dart`

```dart
import 'package:flutter/material.dart';

/// Colori — identici al riferimento HTML.
abstract final class AppColor {
  static const green      = Color(0xFF157A3C); // primario
  static const greenDark  = Color(0xFF0F5C2C);
  static const greenSoft  = Color(0xFFE7F4EB); // sfondo chip/icona
  static const greenTint  = Color(0xFFF2FAF4); // sfondo box citazione

  static const ink        = Color(0xFF16211B); // testo principale
  static const ink2       = Color(0xFF2C3A32);
  static const muted      = Color(0xFF6E7B72); // etichette
  static const faint      = Color(0xFF9AA69E); // placeholder

  static const bg         = Color(0xFFF5F7F3); // sfondo schermata
  static const card       = Color(0xFFFFFFFF);
  static const line       = Color(0xFFE9EBE4); // bordo card
  static const line2      = Color(0xFFF1F3EC); // separatori

  static const blue       = Color(0xFF2E7FD6); static const blueSoft   = Color(0xFFE7F1FC);
  static const red        = Color(0xFFE04552); static const redSoft    = Color(0xFFFDECEE);
  static const purple     = Color(0xFF7B4CC0); static const purpleSoft = Color(0xFFF2EAFC);
  static const orange     = Color(0xFFDE8A22); static const orangeSoft = Color(0xFFFDF1DF);
  static const pinkSoft   = Color(0xFFFCE9F1);
  static const neutralSoft= Color(0xFFEFF1ED);
}

/// Dimensioni testo, in sp. NON inventarne altre.
abstract final class AppText {
  static const display = 26.0; // nome del cane nella scheda
  static const title   = 15.0; // titolo di schermata / cifre grandi
  static const h2      = 13.0; // titolo di sezione
  static const body    = 12.0; // testo corrente
  static const value   = 11.5; // valori nelle righe chiave/valore
  static const label   = 10.5; // etichette, sottotitoli
  static const caption = 10.0; // date, note secondarie
  static const micro   =  9.0; // badge, label delle tab
}

/// Spaziature, raggi, misure fisse.
abstract final class AppDim {
  static const gapXs = 4.0;
  static const gapS  = 6.0;
  static const gapM  = 9.0;   // distanza standard fra card
  static const gapL  = 12.0;  // padding di pagina
  static const gapXl = 16.0;

  static const pagePad   = EdgeInsets.all(12);
  static const cardPad   = EdgeInsets.all(10);
  static const inputPad  = EdgeInsets.symmetric(horizontal: 11, vertical: 10);

  static const radCard   = 12.0;
  static const radInput  = 10.0;
  static const radChip   = 20.0;
  static const radSheet  = 20.0;
  static const radIconBox=  8.0;

  static const iconInline = 14.0;
  static const iconTab    = 16.0;
  static const iconNav    = 18.0;
  static const iconBox    = 27.0; // quadratino colorato dietro l'icona

  static const tabBarH    = 46.0;
  static const bottomNavH = 58.0;
  static const fabSize    = 52.0;
  static const appBarH    = 44.0;
  static const minTouch   = 40.0;

  static const lineH = 1.28; // altezza riga standard
}
```

### 3.2 Componenti riusabili obbligatori — `lib/ui/`

Da creare allo Step 1 e da usare **sempre** al posto dei widget Material grezzi:

| Widget | Descrizione |
|---|---|
| `AppScaffold` | scaffold con sfondo `AppColor.bg`, header logo o titolo, bottom nav opzionale |
| `AppHeader` | header con logo centrato + pulsanti rotondi 34 dp (indietro, modifica, condividi, ⋮) |
| `AppCard` | contenitore bianco, bordo `line`, raggio 12, ombra tenue, padding 10 |
| `SectionTitle` | titolo di sezione 13 sp bold + icona + link "Vedi tutti ›" opzionale |
| `InfoRow` | riga con quadratino icona colorato + etichetta piccola + valore (usata nella scheda) |
| `KeyValueRow` | riga chiave a sinistra (muted) / valore a destra, 10.8 sp, senza overflow |
| `MiniBadge` | pillola 9 sp con varianti verde/blu/rosso/arancio/viola/neutro |
| `AppChip` | chip filtro selezionabile, altezza 28 |
| `AppButton` | primario / ghost / grigio, altezza 40, testo 13 sp |
| `AppTextField` | campo compatto, label 11 sp sopra, altezza 40 |
| `AppSegmented` | selettore a segmenti (Sì / No / Da testare), altezza 34 |
| `StatTile` | card statistica compatta con icona quadrata e due righe di testo |
| `TimelineList` | lista verticale con linea e pallini (storico sanitario, iter adozione) |
| `AppSheet` | bottom sheet con maniglia + titolo + lista opzioni |
| `OptionRow` | riga di menu: icona quadrata + titolo + sottotitolo + chevron |
| `EmptyState` | stato vuoto compatto con icona, frase e azione |
| `AppToast` | messaggio effimero in fondo (SnackBar ridisegnato, non quello di default) |

### 3.3 Tipografia e tema

- Font: **Roboto** di sistema. Niente Google Fonts scaricati a runtime.
- Il tema deve impostare `visualDensity: VisualDensity.compact` e ridefinire
  `cardTheme`, `inputDecorationTheme`, `appBarTheme`, `tabBarTheme`, `chipTheme`
  con le costanti sopra.
- **Solo tema chiaro** nella v1. Il tema scuro è fuori perimetro (voce presente ma disattivata
  nelle impostazioni).

### 3.4 Iconografia

Usa `Icons` di Material, non emoji, **tranne** dove il riferimento HTML usa emoji dentro un
quadratino colorato: lì usa icone Material equivalenti sullo stesso sfondo colorato.

| Concetto | Icona | Sfondo |
|---|---|---|
| In rifugio / box | `home_rounded` | greenSoft |
| Sanitario / vaccino | `vaccines_rounded` | blueSoft |
| Adozione | `favorite_rounded` | redSoft |
| Spese | `savings_rounded` | orangeSoft |
| Documenti | `description_rounded` | purpleSoft |
| Note | `edit_note_rounded` | neutralSoft |
| Cane | `pets_rounded` | greenSoft |
| Calendario | `calendar_month_rounded` | blueSoft |
| Provenienza | `place_rounded` | redSoft |
| Microchip | `qr_code_2_rounded` | neutralSoft |
| Peso | `monitor_weight_rounded` | neutralSoft |
| Volontari | `groups_rounded` | purpleSoft |

---

## 4. Struttura delle cartelle

```
lib/
  main.dart
  app.dart                    # MaterialApp.router + tema
  router.dart                 # go_router
  ui/
    tokens.dart
    theme.dart
    components/               # un file per componente della §3.2
  core/
    result.dart               # Result<T> per errori tipizzati
    formatters.dart           # date it_IT, euro, età del cane
    validators.dart
    permissions.dart          # ruoli
  data/
    models/                   # dog.dart, health_record.dart, ...
    repositories/             # interfacce astratte
    firestore/                # implementazioni Firestore
    seed/seed_data.dart
  features/
    auth/
    dashboard/
    dogs/                     # lista, scheda, tab, wizard, stato
    photos/
    adoptions/
    documents/
    calendar/
    boxes/
    volunteers/
    stats/
    settings/
test/
  ui/                         # test di overflow e componenti
  data/                       # test di modelli e repository
  features/                   # test di flusso
design/
  reference.html              # prototipo di riferimento
```

---

## 5. Modello dati Firestore

Date sempre come `Timestamp`. Ogni documento ha `createdAt`, `createdBy`, `updatedAt`,
`updatedBy`. Nomi dei campi in italiano, coerenti con la UI.

### `dogs/{dogId}`
```
nome: string
sesso: 'F' | 'M'
dataNascita: Timestamp | null
nascitaPresunta: bool
razza: string                  // "Meticcia"
taglia: 'piccola'|'media'|'grande'
pesoKg: number | null
mantello: string
microchip: string              // 15 cifre
iscrittoAnagrafe: 'si'|'no'|'da_verificare'
provenienza: string            // "Corleto Perticara (PZ)"
modalitaIngresso: 'vagante'|'sequestro'|'rinuncia'|'nato_in_rifugio'|'trasferimento'
dataIngresso: Timestamp
settore: string                // "B"
box: string                    // "7"
stato: 'in_rifugio'|'in_stallo'|'preaffido'|'adottato'|'in_cura'|'restituito'|'deceduto'
statoDal: Timestamp
adottabile: bool
sterilizzato: bool
dataSterilizzazione: Timestamp | null
slogan: string                 // 2 righe sotto il nome
descrizione: string            // testo dell'annuncio
carattere: string[]            // ["Dolce","Socievole","Equilibrata"]
conPersone: 'molto_socievole'|'selettivo'|'diffidente'
conCani: 'si'|'selettivo'|'no'|'da_testare'
conGatti: 'si'|'no'|'da_testare'
conBambini: 'si'|'solo_grandi'|'no'|'da_testare'
noteCarattere: string
fotoCopertinaId: string | null
referenteId: string | null     // volunteers/{id}
pubblicato: bool
archiviato: bool
storicoStati: [{stato, dal, note, autoreId}]   // max 30 voci, poi si taglia
```

### `photos/{photoId}` — metadati + miniatura
```
dogId: string
isCover: bool
w, h: number
mime: 'image/jpeg'
thumbB64: string     // ~160 px lato lungo, qualità 60 → ≤ 15 KB
bytesFull: number    // dimensione del full, per diagnostica
createdAt, createdBy
```
### `photos/{photoId}/full/data`
```
b64: string          // ~900 px lato lungo, qualità 72 → target ≤ 180 KB, limite duro 700 KB
```
> Il documento Firestore ha un limite di 1 MiB: la compressione deve garantire di stare sotto.
> Se dopo la compressione si supera 700 KB, si riduce la qualità a passi di 5 fino a rientrare.

### `health/{id}`
```
dogId, tipo: 'vaccino'|'sterilizzazione'|'sverminazione'|'antiparassitario'|'visita'|'esame'|'terapia'|'altro'
data: Timestamp
descrizione: string
veterinario: string
lotto: string
prossimaScadenza: Timestamp | null
costo: number | null       // se valorizzato genera anche una expense
```

### `expenses/{id}`
```
dogId: string | null       // null = spesa generale del rifugio
categoria: 'visita'|'sterilizzazione'|'farmaci'|'esami'|'cibo'|'altro'
importo: number
data: Timestamp
descrizione, fornitore: string
```

### `adoptions/{id}`
```
dogId: string
richiedente: {nome, cognome, telefono, email, citta, indirizzo, docTipo, docNumero, eta}
questionario: {abitazione, giardinoRecintato, altezzaRecinzione, altriAnimali, bambini,
               oreDaSolo, esperienzaCani, doveDormira, note}
stato: 'ricevuta'|'colloquio'|'visita'|'preaffido'|'adottato'|'respinta'|'ritirata'
storicoStati: [{stato, data, note, autoreId}]
preaffidoDal, preaffidoAl: Timestamp | null
referenteId: string
dataRichiesta: Timestamp
```

### `documents/{id}`
```
dogId | adoptionId: string | null
tipo: 'libretto'|'anagrafe'|'verbale'|'preaffido'|'adozione'|'microchip'|'altro'
nome: string
mime: string
pdfB64: string | null      // solo per i PDF generati dall'app (< 700 KB)
firmaAffidatarioB64: string | null
firmaReferenteB64: string | null
createdAt, createdBy
```

### `notes/{id}`
```
dogId, tipo: 'generale'|'comportamento'|'alimentazione'|'attenzione'
testo: string
autoreId: string
createdAt
```

### `appointments/{id}`
```
tipo: 'visita'|'colloquio'|'turno'|'verifica_preaffido'|'scadenza'|'altro'
titolo: string
dogId | adoptionId: string | null
inizio: Timestamp
fine: Timestamp | null
tuttoIlGiorno: bool
luogo: string
volontariIds: string[]
stato: 'previsto'|'fatto'|'annullato'
```

### `volunteers/{uid}` — l'id è l'UID di Firebase Auth
```
nome: string
email: string
ruolo: 'presidente'|'referente'|'volontario'
attivo: bool
coloreAvatar: string   // hex
```

### `boxes/{id}`
```
settore: string, numero: string, capienza: number, note: string, inManutenzione: bool
```

### `settings/association` — documento singolo
```
denominazione, codiceFiscale, sede, capienzaAutorizzata, logoB64
```

### Regole di sicurezza (`firestore.rules`)

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {
    function attivo() {
      return request.auth != null &&
        exists(/databases/$(db)/documents/volunteers/$(request.auth.uid)) &&
        get(/databases/$(db)/documents/volunteers/$(request.auth.uid)).data.attivo == true;
    }
    function ruolo() {
      return get(/databases/$(db)/documents/volunteers/$(request.auth.uid)).data.ruolo;
    }
    function puoScrivere() { return attivo() && ruolo() in ['presidente','referente']; }

    match /volunteers/{id} {
      allow read: if attivo();
      allow write: if attivo() && ruolo() == 'presidente';
    }
    match /notes/{id}   { allow read: if attivo(); allow create: if attivo();
                          allow update, delete: if puoScrivere(); }
    match /settings/{id}{ allow read: if attivo(); allow write: if attivo() && ruolo()=='presidente'; }
    match /{col}/{id}   { allow read: if attivo(); allow write: if puoScrivere(); }
    match /{path=**}/full/{doc} { allow read: if attivo(); allow write: if puoScrivere(); }
  }
}
```

### Indici compositi da creare
- `dogs`: `archiviato ASC, stato ASC, dataIngresso DESC`
- `dogs`: `archiviato ASC, adottabile ASC, nome ASC`
- `health`: `dogId ASC, data DESC`
- `health`: `prossimaScadenza ASC` (per le scadenze)
- `expenses`: `dogId ASC, data DESC`
- `adoptions`: `stato ASC, dataRichiesta DESC`
- `photos`: `dogId ASC, createdAt DESC`
- `appointments`: `inizio ASC`

---

## 6. Gestione delle foto — dettaglio

Interfaccia obbligatoria, così la migrazione a Firebase Storage sarà una sola classe da scrivere:

```dart
abstract interface class PhotoRepository {
  Future<Photo> upload(String dogId, XFile file, {bool asCover = false});
  Stream<List<Photo>> watchByDog(String dogId);     // solo metadati + thumb
  Future<Uint8List> loadFull(String photoId);       // caricata su richiesta, con cache in memoria
  Future<void> setCover(String dogId, String photoId);
  Future<void> delete(String photoId);
}
```

Pipeline di upload:
1. `image_picker` (fotocamera o galleria, selezione multipla)
2. compressione a **900 px lato lungo, qualità 72, JPEG** → `full`
3. compressione a **160 px lato lungo, qualità 60** → `thumb`
4. se `full` > 700 KB, riduci qualità di 5 e ripeti (max 6 tentativi)
5. scrivi `photos/{id}` (metadati + thumb) e `photos/{id}/full/data` in un **batch**
6. massimo **20 foto per cane**: oltre, l'app blocca con messaggio chiaro

Nelle liste si mostra **solo la thumb**. Il full si carica solo aprendo la galleria.
Cache in memoria LRU da 20 immagini.

---

## 7. Le schermate

Elenco completo, tutte presenti in `design/reference.html` — apri il file e replica.

| # | Schermata | Contenuto essenziale |
|---|---|---|
| 1 | Login | logo, email, password, "resta collegato", errori chiari |
| 2 | Home / Dashboard | saluto, 2 contatori (cani in rifugio + adozioni anno), "da fare oggi", ultimi arrivi, richieste, 4 scorciatoie |
| 3 | Elenco cani | ricerca (nome/microchip/box), chip filtro, card con foto, nome, sottotitolo, badge stato |
| 4 | Scheda cane — Tab Scheda | foto, nome + pill stato, 7 righe info, box citazione, 4 stat, griglia 2×2: carattere / stato adozione / ultime attività sanitarie / spese |
| 5 | Tab Salute | prossime scadenze, libretto sanitario in timeline, grafico peso, "aggiungi trattamento" |
| 6 | Tab Adozione | banner adottabile, iter a 5 tappe, stato pubblicazione, condividi scheda |
| 7 | Tab Spese | totale, ripartizione con barre, elenco movimenti, adozione a distanza |
| 8 | Tab Documenti | documenti del cane, modulistica da generare, carica documento |
| 9 | Tab Note | note colorate per tipo con autore e data, aggiungi nota |
| 10 | Tab Altro | galleria, cambia stato, box, referente, storico completo, esporta PDF, archivia |
| 11 | Galleria foto | foto grande, griglia miniature, upload, imposta copertina, video (fuori v1: nascondi) |
| 12 | Cambio stato | stato attuale, 7 opzioni, data, motivazione, chi registra |
| 13 | Nuovo cane 1/3 | anagrafica, identificazione, provenienza e ingresso |
| 14 | Nuovo cane 2/3 | foto, slogan, descrizione, carattere e compatibilità |
| 15 | Nuovo cane 3/3 | sanitario, test, adozione, referente, riepilogo |
| 16 | Richieste di adozione | filtri per stato, card con avatar iniziali, badge |
| 17 | Iter richiesta | anagrafica richiedente, cane, avanzamento, questionario, documenti, azioni |
| 18 | Documenti di affido | scelta modulo, dati precompilati, firme, genera PDF, invia |
| 19 | Calendario | mese, eventi del giorno, prossimi giorni, nuovo appuntamento |
| 20 | Box e settori | contatori posti, griglia box per settore, infermeria, sposta cane |
| 21 | Volontari e turni | elenco volontari, turni settimanali, turni scoperti |
| 22 | Statistiche | 4 contatori, adozioni per mese, composizione, bilancio, esporta report |
| 23 | Ricerca globale | risultati per cani/documenti, ricerche recenti, ricerca per microchip |
| 24 | Notifiche | raggruppate per giorno, bordo colorato per gravità |
| 25 | Menu Altro | profilo, gestione, archivio, app, esci |
| 26 | Impostazioni | dati associazione, notifiche con switch, aspetto e dati, permessi |
| 27 | Bottom sheet "+" | nuovo cane / richiesta / trattamento / spesa / appuntamento / foto |
| 28 | Bottom sheet filtri | stato, taglia, sesso ed età, sanitario, compatibilità, ordinamento |
| 29 | Bottom sheet azioni (⋮) | modifica, foto, stato, modulo affido, PDF, link, duplica, archivia |

**Navigazione principale (bottom nav, 5 voci):** Home · Animali · **+** (FAB) · Calendario · Altro.

---

## 8. Piano di lavoro — 20 step, ognuno con il suo test

**Regola di ferro:** al termine di ogni step l'agente si ferma, mostra cosa ha fatto,
esegue i test e **aspetta l'approvazione** prima di passare allo step successivo.

**Definizione di "step completato"** (vale per tutti, sempre):
- `flutter analyze` → **0 issue**
- `flutter test` → **tutto verde**
- Nessun `RenderFlex overflowed` in console
- Nessuno scroll orizzontale in nessuna schermata toccata
- Le schermate toccate rese a **320 / 360 / 411 / 430 dp** senza tagli

---

### Step 1 — Fondamenta del progetto
Crea il progetto Flutter, imposta `analysis_options.yaml` severo (`flutter_lints` + `prefer_const`),
struttura cartelle della §4, `main.dart` che mostra una schermata vuota con lo sfondo corretto.
Git init e primo commit.

**TEST 1:** `flutter analyze` pulito · `flutter run` avvia l'app su emulatore Android ·
un widget test verifica che l'app parte senza eccezioni.

---

### Step 2 — Design system e catalogo componenti
Implementa `tokens.dart`, `theme.dart` e **tutti** i componenti della §3.2.
Crea una schermata di debug `/debug/ui` che li mostra tutti insieme.

**TEST 2:** widget test che renderizza `/debug/ui` a **320, 360, 411, 430 dp** e verifica che
`tester.takeException()` sia nullo (nessun overflow) · verifica automatica che nessun componente
usi valori numerici fuori da `AppDim`/`AppText` (test che fa grep sui file di `ui/components`) ·
ispezione visiva contro `design/reference.html`.

---

### Step 3 — Firebase e autenticazione
Collega il progetto Firebase (`flutterfire configure`), abilita Auth email/password,
schermata di login del riferimento, gestione errori in italiano, sessione persistente,
guardia di rotta: se non autenticato → login.

**TEST 3:** login con credenziali corrette entra · credenziali sbagliate mostrano il messaggio
giusto in italiano · chiusa e riaperta l'app resta loggato · logout riporta al login ·
test unitario del mapping degli errori Firebase → messaggi italiani.

---

### Step 4 — Modelli, repository e dati di prova
Modelli della §5 con `fromMap`/`toMap`, repository astratti + implementazioni Firestore,
persistenza offline attiva, script di seed con **6 cani** (Fenice, Brando, Nina, Zeus, Luna, Otto),
3 volontari, 8 box, 5 richieste.

**TEST 4:** test di round-trip `toMap`/`fromMap` per ogni modello (comprese le date e i null) ·
test dei repository con `fake_cloud_firestore` · il seed gira e in console Firebase compaiono
i documenti attesi.

---

### Step 5 — Shell dell'app e navigazione
`AppScaffold`, bottom nav a 5 voci con il FAB centrale sporgente, `go_router` con
`StatefulShellRoute` per mantenere lo stato di ogni ramo, header con logo.

**TEST 5:** widget test di navigazione fra le 5 voci · lo scroll di una lista si conserva
tornando su quella voce · il FAB apre il bottom sheet · la bottom nav non va in overflow a 320 dp.

---

### Step 6 — Elenco cani
Lista con foto, ricerca (nome, microchip, box), chip filtro rapidi, contatore risultati,
stato vuoto, indicatore di caricamento, paginazione a 20 elementi.

**TEST 6:** cercando "fen" resta 1 risultato · cercando il microchip completo resta 1 risultato ·
il filtro "In stallo" mostra solo Nina · lista vuota mostra `EmptyState` · nessun overflow con
un nome lungo 40 caratteri (test con dato limite).

---

### Step 7 — Scheda cane: intestazione e tab
Header con azioni, foto, nome + pill stato, slogan, 7 righe info, citazione, 4 stat card
(in `Wrap`, non scorrevoli), **TabBar con 7 tab non scorrevole**.

**TEST 7 (critico):** widget test che a **320 dp** verifica che tutte e 7 le tab siano visibili
e che `takeException()` sia nullo · il microchip lungo non manda in overflow la riga ·
tap su ogni tab cambia contenuto · nessuno scroll orizzontale.

---

### Step 8 — Tab Scheda e Tab Salute
Griglia 2×2 della tab Scheda con dati reali dai repository. Tab Salute con scadenze calcolate,
timeline del libretto, grafico peso (disegnato a mano con `CustomPainter`, niente librerie),
form "aggiungi trattamento".

**TEST 8:** aggiungendo un vaccino con `prossimaScadenza` fra 3 giorni compare in "prossime
scadenze" in rosso · test unitario della funzione di calcolo scadenze (scaduto / entro 7 gg /
entro 30 gg / lontano) · la griglia 2×2 non va in overflow con testi lunghi.

---

### Step 9 — Tab Adozione, Spese, Documenti, Note, Altro
Le cinque tab restanti con dati reali. Spese: totale, ripartizione percentuale, elenco.
Note: creazione con tipo e colore. Altro: menu + storico completo.

**TEST 9:** la somma delle spese mostrata coincide con la somma dei documenti (test unitario) ·
le percentuali della ripartizione sommano 100 · creando una nota compare in cima con autore e
data corretti · tutte e 5 le tab rese senza overflow alle 4 larghezze.

---

### Step 10 — Foto
`PhotoRepository` completo secondo la §6, galleria, upload da fotocamera e galleria,
imposta copertina, elimina, limite 20 foto, cache LRU.

**TEST 10 (critico):** test unitario della compressione — un JPEG 4000×3000 da ~4 MB produce
un `full` ≤ 700 KB e una `thumb` ≤ 15 KB · caricando una foto e riaprendo la scheda la copertina
è quella nuova · alla 21ª foto compare il messaggio di limite · la lista cani carica solo thumb
(verificato contando le letture del repository).

---

### Step 11 — Creazione profilo cane (wizard 3 passaggi)
I tre passaggi della §7 (13-15), indicatore di avanzamento, validazione per campo,
salvataggio bozza, riepilogo finale, creazione del documento.

**TEST 11:** microchip non di 15 cifre → errore sotto il campo · nome vuoto blocca l'avanzamento ·
completando i 3 passaggi il cane compare in elenco · la bozza sopravvive alla chiusura dell'app ·
nessun campo tagliato a 320 dp.

---

### Step 12 — Stato del cane e storico
Schermata cambio stato con i 7 stati, data, motivazione, autore. Aggiorna `stato`, `statoDal`
e appende a `storicoStati`. Il cambio a "adottato" o "deceduto" chiede conferma.

**TEST 12:** cambiando stato la pill nella scheda cambia colore e testo · lo storico mostra la
voce nuova in cima · il filtro dell'elenco riflette subito il nuovo stato · test unitario delle
transizioni ammesse.

---

### Step 13 — Richieste di adozione
Elenco con filtri per stato, dettaglio con questionario, avanzamento dell'iter a 5 tappe,
azioni respingi/avanza, collegamento bidirezionale con il cane.

**TEST 13:** avanzando una richiesta a "preaffido" il cane passa in stato preaffido · respingendo
la richiesta il cane torna adottabile · il contatore "Richieste" nella scheda cane è corretto ·
il questionario si salva integralmente.

---

### Step 14 — Documenti di affido e PDF
Generazione dei 3 moduli (preaffido, contratto di adozione, passaggio microchip) precompilati
con dati cane + adottante + associazione, firma con il dito, PDF salvato in `documents`,
condivisione via `share_plus`.

**TEST 14:** il PDF generato contiene nome del cane, microchip, nome dell'adottante e le due
firme (test che verifica il testo estratto) · il PDF pesa < 700 KB · il documento compare nella
tab Documenti del cane · funziona senza rete e si sincronizza dopo.

---

### Step 15 — Calendario e scadenze
Vista mensile compatta, pallini per tipo evento, eventi del giorno, prossimi giorni,
creazione appuntamento. Le scadenze sanitarie generano voci automatiche.

**TEST 15:** un vaccino con scadenza al 15/09 crea un evento il 15/09 · cambiando mese la griglia
resta di 6 righe fisse senza saltare · nessun overflow della griglia a 320 dp · il giorno corrente
è evidenziato.

---

### Step 16 — Box, settori, volontari e turni
Griglia box con occupazione, spostamento di un cane fra box con controllo di capienza,
elenco volontari, turni settimanali con evidenza dei turni scoperti.

**TEST 16:** spostando Fenice dal box B7 al B8 entrambi i box si aggiornano · non si può superare
la capienza (messaggio chiaro) · il contatore posti liberi è coerente.

---

### Step 17 — Statistiche ed export
4 contatori, adozioni per mese (`CustomPainter`), composizione con barre, bilancio,
export CSV dell'anagrafe e report annuale in PDF.

**TEST 17:** i totali coincidono con i dati Firestore (test unitario sugli aggregatori) ·
il CSV esportato ha una riga per cane e le intestazioni corrette · l'export si apre correttamente.

---

### Step 18 — Ruoli, permessi e impostazioni
Applica i 3 ruoli lato app (nascondendo le azioni non permesse) coerentemente con
`firestore.rules`. Impostazioni: dati associazione, switch notifiche, backup, export.

**TEST 18:** un utente con ruolo `volontario` non vede i pulsanti di modifica e, se forzato,
la scrittura viene rifiutata dalle regole · test delle regole con l'emulatore Firestore
(`firebase emulators:exec`) per ognuno dei 3 ruoli.

---

### Step 19 — Offline, notifiche e rifinitura
Persistenza offline verificata, banner "sei offline", coda di scritture, notifiche locali per
scadenze sanitarie e preaffidi, icona e nome app, splash.

**TEST 19:** in modalità aereo si può creare un cane e aggiungere una nota; riattivando la rete
i dati compaiono in console Firebase · la notifica di scadenza vaccino arriva alle 8:00 ·
nessuna schermata dell'app va in overflow (passata completa su tutte e 29).

---

### Step 20 — Build di rilascio e consegna
Keystore di firma, `flutter build apk --release --split-per-abi`, riduzione dimensione,
istruzioni di installazione per i volontari, `README.md` con setup Firebase e creazione utenti.

**TEST 20:** l'APK si installa su un telefono Android reale · login con un account vero ·
creazione di un cane con foto end-to-end · l'APK pesa meno di 30 MB · disinstallando e
reinstallando i dati sono ancora lì (perché stanno su Firestore).

---

## 9. Setup Firebase — istruzioni operative

1. Console Firebase → **Aggiungi progetto** → nome `amici-per-la-coda`.
   *È un progetto nuovo e separato da quello che già esiste: non condividere il database.*
2. Disattiva Google Analytics (non serve, semplifica).
3. **Authentication** → Sign-in method → abilita **Email/Password**.
4. **Firestore Database** → Crea database → modalità produzione → regione `eur3 (europe-west)`.
5. Incolla le regole della §5 e pubblicale.
6. Crea a mano i 3-4 utenti in Authentication (email + password), poi per ciascuno crea il
   documento `volunteers/{uid}` con nome, email, ruolo, `attivo: true`.
7. Nel progetto Flutter: `dart pub global activate flutterfire_cli` poi `flutterfire configure`.
8. **Non attivare Firebase Storage** — non serve e richiederebbe il piano Blaze.
9. Crea gli indici della §5 (Firestore li propone al primo errore di query: clicca il link).

**Quote gratuite per progetto** (piano Spark): 1 GiB di dati, 50.000 letture, 20.000 scritture
e 20.000 cancellazioni al giorno. Con 4 utenti e ~50 cani non ci si avvicina nemmeno.

---

## 10. Regole di lavoro per l'agente Cursor

**Fai sempre:**
- Lavora **uno step alla volta**, in ordine. A fine step: riepilogo, output dei test, poi ti fermi.
- Apri `design/reference.html` e confronta il risultato prima di dichiarare finito uno step.
- Usa solo le costanti di `tokens.dart` per misure e colori.
- Scrivi i test **insieme** al codice dello step, non alla fine di tutto.
- Testi in italiano, date in formato `dd/MM/yyyy`, importi in euro con la virgola.
- Ogni schermata nuova va aggiunta al test di overflow alle 4 larghezze.

**Non fare mai:**
- Non introdurre librerie non elencate nella §1 senza chiedere.
- Non usare scroll orizzontale, per nessun motivo.
- Non rendere scorrevole una TabBar.
- Non usare i padding di default di Material.
- Non inventare campi del modello dati: se manca qualcosa, chiedi.
- Non passare allo step successivo con test rossi o `flutter analyze` sporco.
- Non generare dati finti dentro le schermate: i dati vengono sempre dai repository.
- Non aggiungere splash screen animate, onboarding, gamification o altre funzioni non richieste.

**Quando qualcosa non è chiaro:** fermati e fai una domanda specifica invece di inventare.
