# Integrazione alla specifica — schermate senza step

Documento da affiancare a `AMICI-PER-LA-CODA_SPEC.md`. Aggiunge gli step mancanti
**senza rinumerare quelli esistenti**, così i riferimenti già usati restano validi.

Contiene due parti:

- **Parte 1** — gli step mancanti: Step 9-bis (Home) e Step 17-bis (schermate di contorno).
- **Parte 2** — le lacune del modello dati emerse dal confronto elemento per elemento
  fra il riferimento HTML e la specifica. **Alcune riguardano step già conclusi
  e vanno sistemate prima di andare avanti.**

## Cosa mancava

Ho ricontrollato le 29 schermate della sezione 7 contro i 20 step della sezione 8.
Cinque schermate non erano coperte da nessuno step:

| Schermata | Situazione | Nuovo step |
|---|---|---|
| 2 · Home / Dashboard | lo Step 5 costruisce solo la navigazione, mai il contenuto | **Step 9-bis** |
| 25 · Menu Altro | mai costruita | **Step 17-bis** |
| 24 · Notifiche (schermata) | lo Step 19 fa le notifiche di sistema, non la schermata | **Step 17-bis** |
| 23 · Ricerca globale | mai costruita | **Step 17-bis** |
| 29 · Bottom sheet azioni (⋮) | mai costruito | **Step 17-bis** |

Collocazione: lo **Step 9-bis va fatto adesso**, appena concluso lo Step 9, perché tutti i
dati che la home mostra esistono già dopo lo Step 9. Lo **Step 17-bis** va dopo lo Step 17,
perché ricerca e notifiche hanno bisogno di documenti, richieste e appuntamenti.

## Una correzione al riferimento HTML

Nel `design/reference.html` la fascia «Ultimi arrivi» della home è una striscia che scorre
in orizzontale. **Nell'app non si fa**: viola la regola 1. Diventa una riga di **tre card di
larghezza uguale**, con il link «Vedi tutti ›» che porta all'elenco completo. Il riferimento
su questo punto è superato da questa integrazione.

---

# Step 9-bis — Home / Dashboard

Schermata 2 della sezione 7. È la prima cosa che i volontari vedono ogni mattina: deve
rispondere a «cosa devo fare oggi» in tre secondi, senza scorrere.

## Contratto di layout

```
SCHERMATA HOME
AppScaffold(bottomNav: home)
└ AppHeader(logo centrato, nessun pulsante indietro)
└ ListView  padding=12  (scroll verticale)
   │
   ├ Text  "Ciao <nome volontario> 👋"      17sp w800  letterSpacing=-0.3  AppColor.ink
   ├ SizedBox h=2
   ├ Text  "<data estesa> · <n> cose da fare oggi"   11.5sp w400  AppColor.muted
   │        formato data: "martedì 8 settembre"  (intl, locale it_IT)
   ├ SizedBox h=12
   │
   ├ Row  (due card gemelle)  gap=9
   │   ├ Expanded → AppCard padding=12
   │   │    ├ Text "<n>"                    26sp w800  letterSpacing=-1  AppColor.ink
   │   │    ├ Text "Cani in rifugio"        10.5sp  AppColor.muted
   │   │    ├ SizedBox h=8
   │   │    ├ Bar h=7 radius=6  fondo #EDF0EB  riempimento AppColor.green
   │   │    └ Text "<p>% dei <tot> posti"   9.5sp  AppColor.muted
   │   └ Expanded → AppCard padding=12
   │        ├ Text "<n>"                    26sp w800  AppColor.green
   │        ├ Text "Adozioni nel <anno>"    10.5sp  AppColor.muted
   │        ├ SizedBox h=12
   │        └ Text "▲ +<n> rispetto al <anno-1>"  9.5sp w700  AppColor.green
   │             (se il delta è negativo: "▼ −<n>", colore AppColor.red)
   │
   ├ SectionTitle  "Da fare oggi"   icona AppIcons.scadenza
   ├ AppCard padding=10
   │   └ per ogni voce (max 4):  Row  h=auto  padding verticale 3.5
   │        ├ IconBadge(spec della voce, size=IconBadge.inRow)
   │        ├ SizedBox w=7
   │        ├ Expanded  Text  10.8sp  maxLines=1  ellipsis
   │        │    (il nome del cane in w700, il resto w400 — usa Text.rich)
   │        └ Text trailing  10.2sp  AppColor.muted   (ora, "⚠️", "→")
   │      separatore fra le righe: 1px tratteggiato AppColor.line2, non dopo l'ultima
   │   stato vuoto: EmptyState compatto "Nessuna scadenza per oggi 🎉"  h=56
   │
   ├ SectionTitle  "Ultimi arrivi"  icona AppIcons.carattere
   │      azione a destra: "Vedi tutti ›" → naviga a /animali
   ├ Row  gap=9   ← TRE card di larghezza uguale, MAI una lista orizzontale
   │   └ 3 × Expanded → AppCard padding=7
   │        ├ AspectRatio 1:1 → foto radius=9 (thumb; segnaposto se assente)
   │        ├ SizedBox h=6
   │        ├ Text nome     11.5sp w700  maxLines=1 ellipsis
   │        └ Text età      9.5sp  AppColor.muted  maxLines=1 ellipsis
   │      se i cani sono meno di 3, le card mancanti NON si disegnano
   │      e le rimanenti restano della loro larghezza (usa Spacer per riempire)
   │
   ├ SectionTitle  "Richieste di adozione"  icona AppIcons.richieste
   │      azione a destra: "<n> nuove ›" → naviga a /richieste
   ├ AppCard padding=10
   │   └ per ogni richiesta (max 2):  Row
   │        ├ Avatar 34×34 radius=full, iniziali 12sp w800, colore dal volontario/richiedente
   │        ├ SizedBox w=9
   │        ├ Expanded Column
   │        │    ├ Text "<richiedente> → <cane>"   12sp w700  maxLines=1 ellipsis
   │        │    └ Text "<stato descrittivo>"      10.5sp AppColor.muted maxLines=1 ellipsis
   │        └ MiniBadge stato
   │      separatore fra le due: divider 1px AppColor.line2 con margine verticale 9
   │      stato vuoto: EmptyState "Nessuna richiesta in sospeso"
   │
   ├ SectionTitle  "Scorciatoie"
   └ GridView 2 colonne  gap=9  shrinkWrap  physics=Never  childAspectRatio≈2.05
       4 × AppCard padding=12  (bottone)
        ├ IconBadge(spec, size=IconBadge.inStat)
        ├ SizedBox h=6
        ├ Text titolo       11.5sp w700
        └ Text sottotitolo  9.5sp AppColor.muted maxLines=1 ellipsis
       Le quattro scorciatoie:
        1. Nuovo cane        · AppIcons.carattere    · "Crea profilo completo" → /nuovo
        2. Modulo affido     · AppIcons.modulo       · "Genera e firma"        → /affido
        3. Box e settori     · AppIcons.box          · "<liberi> box liberi"   → /box
        4. Statistiche       · AppIcons.statistiche  · "Report annuale"        → /statistiche
```

## Dati e aggregatori

Crea `lib/features/dashboard/home_providers.dart` con un solo provider `homeSummaryProvider`
che espone un record immutabile. La schermata non fa conti: legge e disegna.

```dart
typedef HomeSummary = ({
  int caniInRifugio,
  int postiTotali,
  int adozioniAnnoCorrente,
  int adozioniAnnoPrecedente,
  int boxLiberi,
  List<TodoItem> daFareOggi,     // max 4, già ordinate per urgenza
  List<Dog> ultimiArrivi,        // max 3, dataIngresso desc
  List<Adoption> richiesteAperte,// max 2, stato ricevuta|colloquio
});
```

Regole di calcolo, da implementare in funzioni pure e testabili a parte:

- **caniInRifugio** = cani con `archiviato == false` e `stato == 'in_rifugio'`
- **postiTotali** = somma di `capienza` dei box con `inManutenzione == false`
- **percentuale occupazione** = `caniInRifugio / postiTotali`, arrotondata all'intero;
  se `postiTotali == 0` la barra non si disegna e il testo diventa "posti non configurati"
- **adozioni dell'anno** = `adoptions` con `stato == 'adottato'` e anno dell'ultima voce di
  `storicoStati` uguale all'anno corrente
- **daFareOggi**, in questo ordine di priorità:
  1. scadenze sanitarie **scadute** (`prossimaScadenza < oggi`) → icona `AppIcons.scadenza`,
     trailing "⚠️", testo «<cane> · <tipo> scaduto da <n> gg»
  2. appuntamenti di oggi → icona per tipo, trailing l'ora
  3. preaffidi in scadenza entro 7 giorni → `AppIcons.preaffido`, trailing "→"
  4. richieste ferme da più di 7 giorni in stato `ricevuta` → `AppIcons.richieste`
- **ultimiArrivi** = cani non archiviati, `dataIngresso` desc, primi 3
- **boxLiberi** = box con occupanti < capienza e non in manutenzione

## Stati non felici da gestire

- **In caricamento**: scheletri grigi al posto dei numeri, non uno spinner a centro pagina.
- **Senza rete**: si usano i dati dalla cache Firestore e compare una riga sottile in cima
  «Dati non aggiornati · sei offline», h=22, fondo `AppColor.orangeSoft`, testo 10sp.
- **Database vuoto** (prima installazione): al posto delle sezioni, un unico `EmptyState`
  con «Nessun cane ancora registrato» e il pulsante «Aggiungi il primo cane».

## Test dello Step 9-bis

1. Widget test a **320, 360, 411, 430 dp**: nessun overflow, nessuno scroll orizzontale.
2. Test che verifica che nella home **non esista alcuno `Scrollable` con
   `Axis.horizontal`** (`find.byWidgetPredicate` su `Scrollable` con quell'asse: zero
   risultati). È il test che impedisce il ritorno della striscia scorrevole.
3. Unit test degli aggregatori con dati finti: 42 cani in rifugio su 54 posti → 78%;
   `postiTotali == 0` non manda in errore e nasconde la barra.
4. Unit test dell'ordinamento di `daFareOggi`: una scadenza scaduta precede sempre un
   appuntamento di oggi, che precede un preaffido in scadenza.
5. Con zero richieste aperte compare l'`EmptyState`, non una card vuota.
6. Con un solo cane in archivio, «Ultimi arrivi» mostra una card sola senza deformarla.
7. Tap su «Vedi tutti ›» porta a `/animali`; tap su ognuna delle 4 scorciatoie porta alla
   rotta giusta.
8. Golden test a 360×640 dp, da bloccare solo dopo approvazione visiva.

---

# Step 17-bis — Menu Altro, Notifiche, Ricerca globale, azioni scheda

Le quattro schermate di contorno rimaste scoperte. Da fare dopo lo Step 17.

## A · Menu Altro (schermata 25)

Card profilo in alto (avatar iniziale, nome, ruolo, → impostazioni), poi tre gruppi di
`OptionRow` con intestazione 10sp maiuscoletto `AppColor.muted`:

- **Gestione**: Anagrafe cani · Richieste e adozioni · Box e settori · Calendario
  *(«Volontari e turni» rimossa il 10/09/2026: l'elenco volontari è in Impostazioni → Utenti)*
- **Archivio**: Documenti e modulistica · Famiglie adottanti · Veterinari e fornitori · Cani archiviati
- **App**: Statistiche e report · Notifiche · Impostazioni · Esci (in `AppColor.red`)

Ogni riga: `IconBadge(size: IconBadge.inMenu)` + titolo 12.5sp w600 + chevron.
Altezza riga 46, separatore 1px fra le righe dello stesso gruppo.

## B · Notifiche (schermata 24)

Elenco raggruppato per giorno («Oggi», «Ieri», poi la data). Ogni notifica è una `AppCard`
con **bordo sinistro spesso 3** colorato per gravità: rosso urgente, arancione da fare,
verde informativa. Dentro: emoji/icona 16 + titolo 12sp w700 + testo 10.8sp muted +
orario 9.5sp faint. Tap → naviga all'oggetto (cane, richiesta, appuntamento).
In alto a destra «Segna lette». Le notifiche si generano dagli stessi aggregatori della home.

## C · Ricerca globale (schermata 23)

Campo di ricerca in cima (38 dp) con «Annulla» a destra. Risultati raggruppati per tipo,
con l'intestazione che riporta il conteggio: Cani · Documenti · Adottanti.
Sotto: chip delle ricerche recenti (max 6, salvate localmente) e tre `OptionRow` «Cerca
anche per»: numero microchip · box o settore · adottante o volontario.
La ricerca parte da 2 caratteri, con debounce di 300 ms, e cerca su nome, microchip, box.

## D · Bottom sheet azioni ⋮ (schermata 29)

`AppSheet` richiamato dal pulsante ⋮ della scheda cane, con otto `OptionRow`:
Modifica scheda · Gestisci foto · Cambia stato · Genera modulo di affido · Esporta scheda PDF ·
Copia link scheda pubblica · Duplica scheda · Archivia (in rosso).
Le voci non permesse dal ruolo dell'utente **non si disegnano**, non si disabilitano.

## Test dello Step 17-bis

1. Le quattro schermate rese a 320/360/411/430 dp senza overflow.
2. Ricerca: digitando un microchip completo si ottiene esattamente un cane; con una sola
   lettera non parte nessuna query (test sul debounce).
3. Le ricerche recenti sopravvivono alla chiusura dell'app e sono al massimo 6.
4. Notifiche: una scadenza sanitaria scaduta genera una notifica con bordo rosso; toccandola
   si arriva alla scheda del cane giusto.
5. Menu Altro: con ruolo `volontario` le voci riservate non compaiono nell'albero dei widget
   (`findsNothing`), non sono semplicemente grigie.
6. Sheet azioni: si apre dal ⋮, ogni voce naviga o esegue, «Archivia» chiede conferma.

---

# Prompt da dare a Cursor

Da usare adesso, appena concluso lo Step 9.

```
Nella specifica mancavano alcune schermate: la home non veniva costruita da
nessuno step. Ho aggiunto un documento di integrazione.

Leggi @docs/SPEC-integrazione-step.md ed esegui SOLO lo "Step 9-bis — Home / Dashboard".

Punti su cui non voglio interpretazioni:

- Segui il contratto di layout come sta scritto, e riportalo come commento in
  cima al file della schermata prima di programmare, come per le altre.
- La fascia "Ultimi arrivi" è una Row di TRE card di larghezza uguale, NON una
  lista orizzontale scorrevole. Il riferimento HTML su questo punto è superato
  dal documento di integrazione.
- Tutti i numeri vengono da homeSummaryProvider: nessun conto dentro i widget,
  nessun dato scritto a mano.
- Le icone si prendono da AppIcons con IconBadge, come da regola 12.
- Gestisci i tre stati non felici descritti: caricamento, offline, database vuoto.

Scrivi anche i test elencati nel documento, in particolare il numero 2: il test
che verifica che nella home non esista nessuno Scrollable orizzontale.

Al termine: flutter analyze, flutter test, screenshot dell'app vera a 360 dp
(non il render dei test), riepilogo di 5 righe, poi fermati.
```

Poi, quando arriverai in fondo allo Step 17:

```
Approvato. Esegui lo "Step 17-bis" di @docs/SPEC-integrazione-step.md: menu Altro,
notifiche, ricerca globale e bottom sheet delle azioni, con i test elencati.
Contratto di layout in cima a ogni file prima del codice.
Al termine: analyze, test, screenshot, riepilogo, fermati.
```

---

# PARTE 2 — Lacune del modello dati e delle funzionalità

Confronto elemento per elemento fra `design/reference.html` (20 schermate, 5 bottom sheet,
7 tab, 49 azioni) e la sezione 5 della specifica. Undici cose erano rimaste al caso.

Sono ordinate per urgenza: le prime tre toccano step **già fatti** e vanno sistemate subito,
prima di procedere, perché ogni step successivo ci costruisce sopra.

## 🔴 Urgenti — toccano step già conclusi

### 1. Storico dei pesi (Step 8 · tab Salute)

Il riferimento mostra un grafico dell'andamento del peso, e la specifica lo chiede come test
dello Step 8. Ma nel modello `dogs` c'è **un solo campo `pesoKg`**: un numero, non una serie.
Con un numero solo il grafico non esiste, e infatti va verificato cosa ha fatto Cursor —
probabilmente dati finti dentro il widget.

Aggiungi la collezione:

```
weights/{id}
  dogId: string
  data: Timestamp
  kg: number
  autoreId: string
  note: string          // "pesato in ambulatorio", "stima"
```

`dogs.pesoKg` resta, come **copia dell'ultimo peso registrato**, aggiornata a ogni nuova
pesata: serve per l'elenco e la scheda senza dover leggere la serie.
Il grafico legge `weights` ordinato per data. Registrare un peso è un'azione della tab Salute.

### 2. Adozione a distanza (Step 9 · tab Spese)

Il riferimento mostra nella tab Spese un riquadro «Adozione a distanza: 2 sostenitori,
€ 30/mese, copre il 61% delle spese». **Non esiste nel modello.** È anche una funzione a cui
un'associazione tiene molto, perché è entrata ricorrente.

```
sponsorships/{id}
  dogId: string
  sostenitore: {nome, cognome, email, telefono}
  importoMensile: number
  attiva: bool
  dal: Timestamp
  al: Timestamp | null
  note: string
```

Calcoli derivati per la tab Spese: contributo mensile totale = somma degli `importoMensile`
delle attive; copertura = contributo totale × mesi di permanenza ÷ spese totali del cane,
limitata a 100%. Se non ci sono sostenitori il riquadro mostra uno stato vuoto con
«Attiva un'adozione a distanza», non un riquadro con degli zeri.

### 3. ~~Il volontario deve poter iscriversi a un turno~~ — SUPERATO il 10/09/2026

> **I turni non fanno più parte dell'app, e nemmeno i volontari sugli appuntamenti.**
> Il campo `appointments.volontariIds` va **rimosso** dal modello, dal foglio di creazione e
> dalle regole Firestore (la regola speciale su `volontariIds` e il suo test si cancellano).
> Un appuntamento è: tipo, titolo, cane o richiesta, data, luogo, stato. Chi ci va non è
> affar dell'app. Il testo sotto resta solo per riferimento storico.

#### (testo originale, superato)

Le regole di sicurezza della sezione 5 danno scrittura solo a `presidente` e `referente`.
Ma il riferimento ha il pulsante «Iscriviti a un turno» nella schermata Volontari, che un
volontario semplice deve poter usare. Così com'è, la regola glielo impedisce.

Aggiungi questa regola, che permette a un utente attivo di aggiungere o togliere **solo il
proprio uid** dai volontari di un appuntamento, senza toccare nient'altro:

```js
match /appointments/{id} {
  allow read: if attivo();
  allow create, delete: if puoScrivere();
  allow update: if puoScrivere() || (
    attivo()
    && request.resource.data.diff(resource.data).affectedKeys()
         .hasOnly(['volontariIds'])
    && request.resource.data.volontariIds.toSet()
         .difference(resource.data.volontariIds.toSet())
         .hasOnly([request.auth.uid])
  );
}
```

Stessa logica al contrario per la cancellazione dal turno. Va testata con l'emulatore
nello Step 18.

## 🟠 Da sistemare quando arrivi allo step relativo

### 4. Anagrafica delle famiglie adottanti (Step 13 e 17-bis)

Il menu Altro ha la voce «Famiglie adottanti», ma i dati del richiedente sono **annegati
dentro `adoptions.richiedente`**: non sono consultabili come archivio, e se la stessa
famiglia adotta due cani i dati vengono duplicati e possono divergere.

```
adopters/{id}
  nome, cognome, telefono, email, citta, indirizzo: string
  docTipo, docNumero: string
  dataNascita: Timestamp | null
  note: string
  adozioniIds: string[]        // storico
  affidabilita: 'ok'|'da_verificare'|'non_idoneo'
```

`adoptions.adopterId` sostituisce `adoptions.richiedente`. Quando si registra una richiesta,
se il telefono o l'email corrispondono a un adottante esistente l'app lo propone invece di
crearne uno nuovo. La schermata «Famiglie adottanti» elenca gli adopters con lo storico.

### 5. Veterinari e fornitori (Step 8 e 17-bis)

`health.veterinario` è testo libero, ma il menu Altro promette una voce «Veterinari e
fornitori» e nella pratica sono sempre gli stessi tre o quattro nomi, scritti ogni volta in
modo diverso. Diventano una collezione semplice:

```
vendors/{id}
  nome: string
  tipo: 'veterinario'|'clinica'|'farmacia'|'negozio'|'toelettatura'|'altro'
  telefono, email, indirizzo: string
  convenzionato: bool
  note: string
```

Nei form sanitari e nelle spese il campo diventa un menu a tendina con «+ aggiungi nuovo».
`health.veterinarioId` affianca il testo libero, che resta per i casi occasionali.

### 6. Trasferimento ad altra struttura (Step 12)

La tab Altro ha l'azione «Trasferisci ad altra struttura», ma nell'enum degli stati non
c'è. Aggiungi `'trasferito'` all'elenco degli stati di `dogs.stato`, e nella voce di
`storicoStati` il campo `strutturaDestinazione: string`. Un cane trasferito è escluso dai
conteggi del rifugio esattamente come un adottato.

### 7. Tipo di box e infermeria (Step 16)

La schermata Box mostra «Box degenza 1» e «Box isolamento», ma `boxes` ha solo settore,
numero e capienza. Aggiungi:

```
tipo: 'normale'|'degenza'|'isolamento'|'quarantena'
```

L'occupazione resta **derivata** da `dogs.settore` + `dogs.box`: non duplicare l'elenco degli
occupanti dentro il box, si disallineerebbe. I box di degenza e isolamento non entrano nel
conteggio dei posti disponibili mostrato nella home.

### 8. Cane preferito (Step 7)

Nella scheda, accanto al nome, c'è un cuore. Non corrisponde a nessun campo. Due strade:
aggiungere `dogs.preferito: bool` (uno per tutta l'associazione), oppure toglierlo.
**Consiglio di toglierlo**: «adottabile» comunica già l'informazione utile, e un preferito
condiviso fra volontari genera discussioni inutili. Se lo tieni, che sia per volontario:
`volunteers/{uid}.preferitiIds: string[]`.

### 9. Scanner del microchip (Step 11)

Il wizard ha l'icona della fotocamera accanto al campo microchip, ma nelle dipendenze non c'è
nessun lettore di codici e nessuno step lo implementa. I microchip sono spesso stampati come
codice a barre sul libretto o sull'etichetta adesiva. Aggiungi la dipendenza
`mobile_scanner` e, allo Step 11, la lettura: apre la fotocamera, legge il codice, valida che
siano 15 cifre e compila il campo. Se non funziona bene sul campo si toglie: è due ore di
lavoro, non un rischio.

### 10. Cani archiviati (Step 17-bis)

Il menu Altro promette «Cani archiviati: 87». Aggiungi alla parte A dello Step 17-bis la
schermata: stessa card dell'elenco cani, filtro per motivo di uscita (adottato, deceduto,
trasferito, restituito), ricerca per nome e microchip, e l'azione «Ripristina» che riporta il
cane in rifugio registrandolo nello storico.

## 🟡 Decisioni da prendere, non lacune

### 11. Tab Adozione — pubblicazione e visualizzazioni

Il riferimento mostra «Sito associazione: pubblicato · Facebook/Instagram: pubblicato ·
Visualizzazioni: 1.284». L'app non ha un sito e non può contare le visualizzazioni di
Facebook. Semplifica: resta `dogs.pubblicato` con `dataPubblicazione`, e l'azione «Condividi
scheda» che genera un testo pronto da incollare sui social con nome, età, carattere e foto.
**Togli il contatore delle visualizzazioni**: sarebbe un numero inventato.

### 12. Backup dei dati (Step 17)

Le impostazioni mostrano «Backup dati · ultimo: oggi 07:00». Con Firestore il backup
automatico sul piano gratuito non esiste. Definiscilo come quello che è: un **export
manuale** completo (tutte le collezioni in un file JSON + le foto in una cartella) che il
presidente lancia quando vuole e salva dove preferisce. Il testo diventa «Ultimo export» con
la data reale dell'ultimo eseguito, oppure «Mai eseguito».

### 13. Logo dell'associazione

L'HTML ha un logo disegnato da me come segnaposto. Il logo vero di Amici per la Coda va messo
in `assets/logo.png` (e `logo@2x`, `logo@3x`), dichiarato nel `pubspec.yaml`, e usato
nell'header e nella schermata di accesso. `settings.logoB64` serve solo per stamparlo sui PDF
dei moduli di affido.

### 14. Login con codice associazione

La schermata di accesso del riferimento ha un secondo pulsante «Accedi con codice
associazione». Non è previsto da nessuno step e complica l'autenticazione senza vantaggi per
quattro persone. **Togli il pulsante.**

---

# Prompt per la Parte 2

Da dare **prima** dello Step 9-bis, perché sistema cose su cui gli step successivi
costruiscono.

```
Ho verificato la specifica contro il riferimento HTML e sono emerse alcune
lacune nel modello dati. Leggi la PARTE 2 di @docs/SPEC-integrazione-step.md ed
esegui SOLO i tre punti urgenti, quelli marcati in rosso:

1. Storico dei pesi: aggiungi la collezione weights, il modello, il repository
   e l'azione "registra peso" nella tab Salute. Il grafico del peso deve leggere
   la serie reale: se adesso usa dati scritti a mano nel widget, toglili.
   dogs.pesoKg resta come copia dell'ultimo peso registrato.

2. Adozione a distanza: aggiungi la collezione sponsorships con modello e
   repository, e collega il riquadro della tab Spese ai dati veri, con lo stato
   vuoto quando non ci sono sostenitori. Niente numeri finti.

3. ~~Regole di sicurezza su appointments.volontariIds~~ — SUPERATO il 10/09/2026:
   il campo e la regola vanno rimossi, non aggiunti.

Aggiorna anche la sezione 5 di AMICI-PER-LA-CODA_SPEC.md con le due collezioni
nuove e la regola, così la specifica resta la fonte unica.

Scrivi i test: round-trip dei due modelli nuovi, il grafico peso con 3 pesate
mostra 3 punti, la copertura dell'adozione a distanza è limitata a 100%, e il
test delle regole con l'emulatore per l'iscrizione al turno (permessa) e per la
modifica di un altro campo da parte di un volontario (rifiutata).

Al termine: flutter analyze, flutter test, riepilogo di 5 righe, poi fermati.
Non fare gli altri punti del documento: li faremo agli step relativi.
```

Gli altri punti si affrontano quando arrivi allo step indicato. Tienili come lista di
controllo: quando Cursor ti dice «Step 13 completato», controlla che abbia fatto anche il
punto 4, e così via.

---

# PARTE 3 — Revisione dello Step 14: moduli di affido

**Decisione del committente, sostituisce integralmente lo Step 14 della sezione 8.**

L'app **non genera** i moduli e **non raccoglie firme**. I moduli sono due PDF già pronti,
scritti dall'associazione. Il flusso reale è:

1. I due moduli in bianco (preaffido e adozione) stanno dentro l'app.
2. Quando si registra un possibile adottante, la volontaria apre il modulo e lo **condivide**
   con il foglio di condivisione del telefono: WhatsApp, email, Telegram, quello che serve.
3. L'adottante compila e firma **fuori dall'app**, su carta o sul PDF, e lo rimanda indietro.
4. La volontaria **carica il file compilato e firmato** nell'app, e quel documento resta
   attaccato sia alla scheda del cane sia a quella dell'adottante.

Niente compilazione guidata, niente firma con il dito, niente generazione di PDF.

## 14.1 Dove stanno i moduli in bianco

**Non come asset dentro l'APK.** I moduli cambiano — cambia una clausola, cambia
l'intestazione — e ogni volta servirebbe ricompilare e reinstallare l'app sui telefoni.
Stanno in Firestore, sostituibili dalle impostazioni:

```
templates/{id}          // due soli documenti: 'preaffido' e 'adozione'
  nome: string          // "Modulo di preaffido"
  descrizione: string
  fileName: string      // "modulo-preaffido.pdf"
  mime: 'application/pdf'
  pdfB64: string        // il PDF in bianco, < 700 KB
  versione: int
  aggiornatoIl: Timestamp
  aggiornatoDa: string
```

In **Impostazioni** compare una sezione «Moduli»: le due voci con nome, versione e data,
e l'azione «Sostituisci file» riservata al presidente. Al primo avvio, se i documenti non
esistono, l'app carica i due PDF inclusi in `assets/moduli/` come versione 1: così l'app
funziona subito e i moduli restano comunque aggiornabili senza reinstallare niente.

## 14.2 Condividere il modulo

Dalla schermata della richiesta di adozione e dalla tab Documenti del cane:
azione **«Invia modulo»** → si sceglie quale dei due → si apre il foglio di condivisione
di sistema (`share_plus`), con il PDF allegato e un testo predefinito già pronto, del tipo:

> Ciao <nome>, in allegato il modulo di preaffido per <cane>. Compilalo, firmalo e
> rimandacelo quando puoi. Grazie! — Amici per la Coda

L'invio **si registra**: nello `storicoStati` della richiesta si appende una voce
`modulo_inviato` con quale modulo, la data e chi l'ha mandato. Serve perché fra due
settimane nessuno si ricorda se il modulo è stato spedito o no, e nella schermata della
richiesta compare «Modulo preaffido inviato il 12/09 da Giovanna · in attesa di ritorno».

## 14.3 Caricare il modulo compilato — il punto delicato

Un modulo firmato torna indietro come **PDF scansionato o come foto**, e pesa quasi sempre
**più di 1 MB**: il limite di un documento Firestore. Senza gestirlo, il caricamento fallisce
e basta. Regole:

- Si accettano PDF (`file_picker`) e immagini (`image_picker`, anche più pagine).
- Le **immagini** passano dalla stessa pipeline delle foto: 1600 px lato lungo, qualità 70.
  Una pagina A4 fotografata scende sotto i 300 KB e resta perfettamente leggibile.
- I **PDF** si salvano a pezzi: il base64 viene spezzato in blocchi da 600 KB in una
  sottocollezione `documents/{id}/chunks/{n}`, con `chunkCount` nel documento padre, e
  ricomposto alla lettura. Limite massimo 10 MB per file, oltre il quale l'app dice
  chiaramente di ridurre la scansione.
- Il documento risultante:

```
documents/{id}
  tipo: 'preaffido_firmato' | 'adozione_firmato' | 'documento_identita' | 'altro'
  adoptionId: string        // il legame che tiene insieme cane e adottante
  dogId: string             // ridondante ma comodo per le query della scheda cane
  adopterId: string
  nome: string
  mime: string
  chunkCount: int           // 0 se il contenuto sta tutto nel padre
  contenutoB64: string|null // usato solo quando sta in un documento solo
  caricatoIl: Timestamp
  caricatoDa: string
```

**Un solo file, non due copie.** Lo stesso documento compare nella tab Documenti del cane
e nella scheda dell'adottante perché entrambe lo cercano per `dogId` e per `adopterId`.
Duplicarlo significherebbe raddoppiare lo spazio e ritrovarsi due versioni che divergono.

Al caricamento del preaffido firmato, l'app propone di far avanzare la richiesta allo stato
`preaffido` — propone, non lo fa da sola.

## 14.4 Conseguenze sul resto del progetto

- **Si toglie** la dipendenza `signature`: non serve più.
- **Restano** `pdf` e `printing`, che servono ancora per l'export del report annuale
  (Step 17) e per «Esporta scheda PDF».
- **Si aggiunge** `file_picker` per scegliere un PDF dal telefono, e `open_filex` per
  aprire un documento con il visualizzatore del telefono.
- Nella sezione 7, la schermata 18 «Documenti di affido» cambia natura: non più scelta
  del modulo + dati precompilati + firme, ma **due elenchi** — i moduli da inviare
  (con «Invia») e i documenti ricevuti (con «Apri», «Condividi», «Elimina»).
- Il riferimento HTML su questa schermata è superato da questa parte del documento.

## 14.5 Test dello Step 14 rivisto

1. Al primo avvio, senza documenti in `templates`, l'app li crea dai PDF in `assets/moduli/`
   e le due voci compaiono in Impostazioni con versione 1.
2. Sostituendo un modulo dalle impostazioni, la versione passa a 2 e la condivisione manda
   il file nuovo.
3. «Invia modulo» apre il foglio di condivisione con il PDF allegato e il testo precompilato
   contenente il nome dell'adottante e quello del cane.
4. Dopo l'invio, la richiesta mostra «Modulo preaffido inviato il <data> da <nome>» e la voce
   compare nello storico.
5. Caricando un PDF da 4 MB il documento viene salvato in 7 blocchi e riletto identico
   (confronto byte a byte del base64 ricomposto).
6. Caricando una foto da 6 MB, viene compressa sotto i 300 KB e salvata in un documento solo.
7. Un file da 12 MB viene rifiutato con un messaggio chiaro, non con un errore tecnico.
8. Lo stesso documento compare sia nella tab Documenti del cane sia nella scheda
   dell'adottante, ed è **un solo** documento in Firestore.
9. Funziona senza rete: il caricamento va in coda e si sincronizza al ritorno del segnale.

---

# PARTE 4 — Step 14-bis: modificare quello che è già stato inserito

**Lacuna del piano originale.** Nessuno dei 20 step costruisce la modifica. Si può creare un
cane, un trattamento, una spesa, una nota — e poi niente si può correggere. Il pulsante ✏️
nell'header della scheda e la voce «Modifica scheda» nel menu ⋮ sono disegnati nel
riferimento ma non implementati da nessuna parte.

Va fatto **subito dopo lo Step 14**, prima di proseguire, per un motivo pratico: i 49 cani
reali entrano nell'app con solo nome, sesso, data di nascita e sterilizzazione. Tutto il
resto — razza, taglia, peso, microchip, box, carattere, provenienza — si compila a mano
cane per cane. Senza questa schermata l'anagrafe vera non è utilizzabile.

## 14-bis.1 · Modifica del profilo del cane

**Non riusare il wizard.** Creare un cane è un percorso guidato in tre passaggi; correggere
un dato è un'altra cosa. Chi entra per cambiare il peso non deve attraversare tre schermate
con avanti-avanti-salva: è esattamente il attrito che fa smettere le persone di tenere
aggiornati i dati.

Una schermata unica, con le stesse sezioni del wizard messe una sotto l'altra.

```
SCHERMATA MODIFICA CANE   (rotta /cane/:id/modifica)
└ AppBar compatta h=44
   ├ ← indietro   (se ci sono modifiche non salvate: chiede conferma)
   ├ Titolo "Modifica <nome>"  15sp w700
   └ Azione "Salva"  13sp w700 AppColor.green
        DISABILITATA finché non cambia almeno un campo
└ ListView padding=12
   ├ SectionTitle "Anagrafica"
   │   nome · sesso · data di nascita + presunta · razza · taglia · mantello
   ├ SectionTitle "Identificazione"
   │   microchip (con validazione 15 cifre) · iscritto in anagrafe
   ├ SectionTitle "Provenienza e ingresso"
   │   provenienza · modalità di ingresso · data di ingresso · settore · box
   ├ SectionTitle "Presentazione"
   │   slogan · descrizione per l'annuncio
   ├ SectionTitle "Carattere e compatibilità"
   │   chip del carattere · con persone · con cani · con gatti · con bambini · note
   ├ SectionTitle "Adozione"
   │   adottabile · pubblicato · volontario referente
   └ Riga finale, 10sp AppColor.muted:
       "Ultima modifica: <nome>, <data>"      da updatedBy / updatedAt
```

I campi sono **gli stessi widget del wizard** dello Step 11: si riusano, non si riscrivono.
Se un widget del wizard non è estraibile perché legato al flusso a passaggi, va estratto
adesso — e il wizard usa quello estratto.

**Fuori da questa schermata**, perché hanno già la loro: lo stato del cane (Step 12), le
foto (Step 10), i trattamenti sanitari, le spese e le note (paragrafo seguente).

### Due comportamenti che sembrano dettagli e non lo sono

**Salva attivo solo se qualcosa è cambiato.** Si confronta l'oggetto in modifica con quello
originale. Evita scritture inutili su Firestore e, soprattutto, evita di sovrascrivere il
lavoro di un altro volontario con dati identici ma `updatedAt` nuovo.

**Guardia sulle modifiche concorrenti.** L'app è usata da 3-4 persone sugli stessi cani.
Firestore fa vincere l'ultimo che salva, in silenzio. Al salvataggio si rilegge `updatedAt`
dal server: se è più recente di quando il form è stato aperto, non si scrive — si mostra
«<nome> ha modificato questa scheda mentre la stavi aprendo» con due scelte, *Ricarica* e
*Sovrascrivi comunque*.

## 14-bis.2 · Modificare e cancellare le voci già inserite

Stessa lacuna per tutto il resto. Ogni elemento di queste liste deve poter essere corretto o
eliminato, con una pressione lunga oppure con un ⋮ sulla riga:

| Voce | Dove | Modifica | Elimina |
|---|---|---|---|
| Trattamento sanitario | tab Salute | sì | sì, con conferma |
| Pesata | tab Salute | sì | sì |
| Spesa | tab Spese | sì | sì, con conferma |
| Nota | tab Note | sì, solo l'autore o il presidente | sì, stesse regole |
| Documento | tab Documenti | solo il nome | sì, con conferma |
| Appuntamento | Calendario | sì | sì |
| Adozione a distanza | tab Spese | sì | no: si chiude, non si cancella |

Le eliminazioni **non sono mai silenziose**: chiedono conferma nominando la cosa che sparisce
(«Eliminare la vaccinazione del 10/02/2025?»), e non c'è annulla. Chi elimina e quando
restano in `updatedBy`/`updatedAt` del documento padre, dove esistono.

Le modifiche riusano il **form di creazione già esistente**, aperto precompilato: non si
scrivono due volte gli stessi campi.

## 14-bis.3 · Permessi

Coerente con lo Step 18: `presidente` e `referente` modificano ed eliminano tutto; il ruolo
`volontario` può creare note e modificare o eliminare **solo le proprie**, e nient'altro.
Le azioni non permesse **non si disegnano**, non si disabilitano.

## 14-bis.4 · Test

1. Aprendo la modifica di un cane, «Salva» è disabilitato; cambiando un campo si attiva.
2. Cambiando la taglia e salvando, l'elenco cani e la scheda mostrano subito il valore nuovo.
3. Uscendo con modifiche non salvate compare la richiesta di conferma; annullando si resta.
4. Microchip di 14 cifre: errore sotto il campo, salvataggio bloccato.
5. Guardia sulle concorrenti: simulando un `updatedAt` sul server più recente di quello
   letto all'apertura, il salvataggio non avviene e compare la scelta ricarica/sovrascrivi.
6. Modificando la data di un trattamento, l'ordine della timeline si aggiorna.
7. Eliminando una spesa, il totale della tab Spese si ricalcola.
8. Un utente `volontario` non vede le azioni di modifica sulle note altrui (`findsNothing`);
   forzando la scrittura, le regole Firestore la rifiutano.
9. La schermata di modifica non va in overflow a 320/360/411/430 dp.
10. `updatedBy` e `updatedAt` vengono scritti a ogni salvataggio e mostrati in fondo.

---

# PARTE 5 — Step 14-ter: consolidamento

**Origine:** rapporto sullo stato dell'app del 9 settembre 2026 (`docs/archive/RAPPORTO-STATO-APP.md`).
**Quando:** subito dopo lo Step 14-bis, prima dello Step 15.
**Natura:** nessuna funzione nuova. Solo cablaggio di ciò che esiste già, correzione di buchi
di sicurezza e di integrità dei dati, rimozione dei segnaposto lasciati dagli step iniziali.

Il rapporto ha mostrato un fenomeno preciso: le cose costruite ai primi step — FAB, header
della scheda, tab Altro — sono rimaste ai toast «disponibile negli step successivi» anche
dopo che le funzioni vere sono arrivate nelle tab. Questo step le ricollega.

**Non fa parte di questo step** (ha il suo step, non anticiparlo): griglia mensile del
calendario (15), schermate Box e Volontari (16), Statistiche ed export (17), menu Altro
completo, notifiche, ricerca, famiglie adottanti, cani archiviati, `vendors` (17-bis),
impostazioni associazione e test completi dei ruoli (18), notifiche di sistema (19).

## 14-ter.1 · Sicurezza — da fare per primo

1. `canWriteRecords(null)` deve restituire **false**, non true. Un utente senza documento
   in `volunteers` non ha alcun diritto di scrittura, e l'app deve mostrargli un avviso
   chiaro «Il tuo account non è ancora abilitato: chiedi al presidente» al posto della home.
2. La galleria foto e la pagina cambio stato usano lo stesso gate delle altre schermate:
   upload, elimina, imposta copertina e salva stato **non si disegnano** per chi non può
   scrivere.
3. Test: con `currentVolunteerProvider` nullo, nessun pulsante di scrittura è nell'albero
   dei widget in scheda, galleria, cambio stato, tab Salute, Spese, Note, Documenti.

## 14-ter.2 · Integrità dei dati

1. **Archiviati fuori dall'elenco.** `filterDogs` esclude `archiviato == true` in tutti i
   segmenti. Gli archiviati si vedranno solo nella schermata dedicata dello Step 17-bis.
   Anche gli aggregatori della home devono già escluderli (verificare, il rapporto dice di sì
   per `caniInRifugio`).
2. **«Archivia» diventa vero.** Dalla tab Altro: conferma nominando il cane → `archiviato =
   true`, voce in `storicoStati`, ritorno all'elenco. Aggiungi `ripristina` nel repository
   (lo userà il 17-bis).
3. **Stato `trasferito`.** Aggiungilo all'enum e alla pagina cambio stato, con il campo
   «Struttura di destinazione» obbligatorio quando è selezionato; va in
   `storicoStati.strutturaDestinazione`. Un trasferito è escluso dai conteggi come un
   adottato. «Trasferisci» nella tab Altro apre la pagina cambio stato con quello stato
   preselezionato.
4. **«Carica documento» dalla scheda cane carica un file davvero.** Riusa esattamente il
   picker, la compressione e il salvataggio a blocchi già scritti per `affido_page`. Non
   esistono due modi di caricare un documento: uno solo, condiviso. Un documento senza
   contenuto non deve poter essere creato.
5. **Tap su un documento** nella tab Documenti apre il file (`open_filex`), come già avviene
   in Affido. Le azioni Apri / Condividi / Rinomina / Elimina sono le stesse nei due posti.

## 14-ter.3 · Cablaggio di ciò che esiste già

| Dove | Adesso | Deve fare |
|---|---|---|
| FAB «+» → Richiesta | toast | apre `/richieste/nuova` |
| FAB «+» → Trattamento | toast | apre un selettore del cane, poi `AddTreatmentSheet` |
| FAB «+» → Spesa | toast | selettore del cane (con «Spesa generale» in cima), poi `AddExpenseSheet` |
| FAB «+» → Appuntamento | toast | `AddAppointmentSheet` |
| FAB «+» → Foto rapida | toast | selettore del cane, poi il foglio foto della galleria |
| Header scheda → Condividi | toast | stessa azione di «Condividi scheda» della tab Adozione |
| Header scheda → ⋮ | 1 voce | Modifica · Gestisci foto · Cambia stato · Invia modulo · Condividi · Archivia (rosso). Le altre due voci del 17-bis arrivano con il 17-bis. |
| Tab Altro → Box e collocazione | toast | apre la modifica del cane posizionata sulla sezione Provenienza e ingresso (dove sta il box) |
| Tab Altro → Volontario referente | toast | foglio con l'elenco dei volontari attivi, salva `referenteId` |
| Tab Altro → Esporta PDF | toast | **resta disattivato ma non mente**: la voce non si disegna finché lo Step 17 non esiste |
| Home → righe «Da fare oggi» | nessun tap | tap apre il cane, l'appuntamento o la richiesta a cui la voce si riferisce |
| Home → card contatori | nessun tap | «Cani in rifugio» apre l'elenco filtrato; «Adozioni» apre le richieste con filtro Concluse |
| Tab Salute → righe scadenze | nessun tap | tap apre il trattamento in modifica |
| Dettaglio richiesta → Chiama | copia | `url_launcher` con `tel:`; la copia resta come pressione lunga |
| Dettaglio richiesta → Email | copia | `mailto:` con oggetto precompilato «Adozione di <cane>» |
| Elenco cani → Filtri e ordina | toast | il bottom sheet 28 della sezione 7: stato, taglia, sesso, età, sanitario, compatibilità, ordinamento. È già disegnato nel riferimento, mancava solo il collegamento |
| Galleria → Usa per annuncio | toast | imposta la foto come copertina **e** apre «Condividi scheda». È tutto ciò che significava |
| Login → Password dimenticata | toast | `sendPasswordResetEmail` di Firebase Auth, con conferma |
| Login → Resta collegato | inerte | rimuovere la casella: Firebase Auth su Android mantiene già la sessione. Una casella che non fa nulla è peggio di nessuna casella |

## 14-ter.4 · Segnaposto e dati di prova

1. **Versione:** il testo nel login legge `package_info_plus`, non una stringa fissa.
2. **`[PROVA]` in elenco:** `dog_list_tile` usa `dogDisplayName` come la scheda.
3. **«Rimuovi dati di prova»:** voce in Impostazioni, solo presidente, chiede conferma
   contando i documenti che sparirebbero, chiama `deleteSeedData`. Dopo l'esecuzione la voce
   non si mostra più se non c'è nulla con prefisso `seed_`.
4. **Banner offline:** o si collega davvero (`connectivity_plus`, oppure lo stato
   `hasPendingWrites` / `isFromCache` degli snapshot Firestore) oppure **si toglie**. Un
   indicatore che non può mai accendersi va rimosso, non lasciato. Consigliato: collegarlo,
   è mezza giornata.
5. **Iter di adozione nella tab Adozione:** le cinque tappe leggono lo stato reale della
   richiesta aperta per quel cane — tappa raggiunta in verde, corrente evidenziata, future in
   grigio. Se non c'è nessuna richiesta, si mostra l'iter tutto in grigio con la scritta
   «Nessuna richiesta in corso».
6. **Appuntamenti:** il foglio di creazione ha il campo «Cane» (opzionale) e «Richiesta»
   (opzionale, filtrata per cane), così le voci del calendario sanno a cosa si riferiscono e
   la home può aprirle.

## 14-ter.5 · Test

1. `canWriteRecords(null)` è false; con volontario nullo nessun pulsante di scrittura in
   sette schermate (`findsNothing`).
2. Un cane con `archiviato == true` non compare in nessun segmento dell'elenco.
3. «Archivia» chiede conferma con il nome del cane; dopo, il cane sparisce dall'elenco e
   compare nello storico la voce.
4. Cambio stato a `trasferito` senza struttura di destinazione è bloccato.
5. «Carica documento» dalla tab cane con un PDF da 3 MB produce un documento a blocchi
   identico a quello prodotto da Affido con lo stesso file (stesso `chunkCount`, stesso hash).
6. Non è possibile salvare un documento con `contenutoB64` nullo e `chunkCount` zero.
7. Ognuna delle sei voci del FAB apre qualcosa che non è un toast (test per voce).
8. Le voci del ⋮ della scheda sono sei e ognuna naviga o agisce.
9. «Filtri e ordina» apre il foglio; applicando «Taglia grande» la lista cambia.
10. Il login mostra la versione del `pubspec`, non una costante.
11. Con il volontario `presidente`, «Rimuovi dati di prova» è visibile; con `volontario` no;
    dopo l'esecuzione i documenti `seed_*` sono zero.
12. Le tappe dell'iter riflettono lo stato della richiesta: con stato `preaffido` le prime
    quattro sono verdi e la quinta grigia.
13. Nessun toast «disponibile negli step successivi» resta nel codice, tranne quelli
    esplicitamente ammessi (Esporta PDF fino allo Step 17, Box e Statistiche fino a 16/17):
    test che fa grep sulla stringa e ammette solo i file elencati.
14. Tutte le schermate toccate a 320/360/411/430 dp senza overflow; golden aggiornati solo
    dopo approvazione visiva.

## 14-ter.6 · Dipendenze da aggiungere

`url_launcher`, `package_info_plus`, `connectivity_plus` (se si sceglie di collegare il
banner). Nient'altro.

## 14-ter.7 · Form compatti — modifica cane e wizard

**Origine:** screenshot della schermata Modifica cane del 9 settembre. È un modulo disperso,
non una pagina dell'app: i campi galleggiano sullo sfondo senza card, ogni campo occupa una
riga intera anche per due caratteri, i selettori a due opzioni sono larghi 336 dp, e la barra di
navigazione con il FAB resta visibile coprendo l'ultimo campo. Circa 1.650 dp di altezza.

**Obiettivo:** ~980 dp, con l'aspetto delle altre schermate. Il riferimento visivo è
`design/confronto-modifica-cane.html`. Le stesse regole valgono per il **wizard** dello Step 11,
che ha lo stesso difetto: i tre passaggi usano gli stessi componenti di form.

### Grammatica dei form — vale per tutti i form dell'app

Aggiungi a `lib/ui/components/` quattro componenti e usali ovunque ci sia un form:

| Componente | Misure |
|---|---|
| `FormCard` | AppCard con `SectionTitle` in testa (IconBadge 20 + titolo 12.5 sp w700), padding 10, gap fra card 9 |
| `FormField` | etichetta 10 sp w600 maiuscoletto `AppColor.muted`, 3 dp sotto, campo alto **34** (non 40), radius 9, testo 12 sp |
| `FormRow2` | due `FormField` affiancati con `Expanded`, gap 8. Accetta `flex` diverso (es. 1.6 / 1) |
| `CompatRow` | riga alta 30: etichetta a sinistra larga 92 dp, `AppSegmented` a destra alta 28 |

`AppSegmented` scende a **32 dp** (28 dentro `CompatRow`), testo 11 sp. Con più di tre opzioni
in mezza larghezza le etichette diventano abbreviazioni con `FittedBox`: «P / M / G»,
«♀ F / ♂ M», «Sì / No / ?». La forma estesa resta nel tooltip e nel valore salvato.

I campi a più righe (`slogan`, `descrizione`, `noteCarattere`) partono da **una riga** (34 dp)
e crescono digitando fino a 4. Non si presentano vuoti alti 64 o 80 dp.

### Contratto — schermata Modifica cane

```
MODIFICA CANE   rotta a schermo intero (parentNavigatorKey: root)
                → NESSUNA bottom nav, NESSUN FAB
└ AppBar h=40: ← · "Modifica <nome>" 13sp w700 (nome senza prefisso [PROVA])
               · "Salva" a destra: testo AppColor.faint se non ci sono modifiche,
                 pillola verde piena 11sp w700 quando il form è dirty
└ ListView padding=12, gap 9 fra le card
   ├ FormCard "Anagrafica"  AppIcons.carattere
   │   ├ FormField  NOME *
   │   ├ FormRow2   SESSO (seg ♀F/♂M)        | DATA DI NASCITA (date picker)
   │   ├ FormRow2   PRECISIONE (seg)         | TAGLIA (seg P/M/G)
   │   └ FormRow2   RAZZA / TIPO             | MANTELLO
   ├ FormCard "Identificazione"  AppIcons.microchip
   │   └ FormRow2   MICROCHIP + icona scanner (flex 1.6) | ANAGRAFE (seg Sì/No/?)
   ├ FormCard "Provenienza e ingresso"  AppIcons.provenienza
   │   ├ FormField  LUOGO DI PROVENIENZA
   │   ├ FormRow2   MODALITÀ (dropdown)      | INGRESSO * (date picker)
   │   └ FormRow2   BOX (dropdown)           | REFERENTE (dropdown volontari)
   ├ FormCard "Presentazione"  AppIcons.annuncio
   │   ├ FormField  SLOGAN            (multilinea, 1→2 righe)
   │   └ FormField  DESCRIZIONE       (multilinea, 1→4 righe)
   ├ FormCard "Carattere e compatibilità"  AppIcons.carattere
   │   ├ Wrap di AppChip h=26 (carattere) + chip "+"
   │   ├ CompatRow  Con persone   | Socievole / Selettivo / Diffidente
   │   ├ CompatRow  Con cani      | Sì / Solo ♀ / No / ?
   │   ├ CompatRow  Con gatti     | Sì / ? / No
   │   ├ CompatRow  Con bambini   | Sì / Grandi / No / ?
   │   └ FormField  NOTE SUL CARATTERE (multilinea)
   ├ FormCard "Adozione"  AppIcons.adottabile
   │   └ FormRow2   ADOTTABILE (seg 3, flex 1.5) | PUBBLICATO (seg Sì/No)
   └ Text "Ultima modifica: <nome>, <data>"  10sp muted centrato
```

Il referente si sposta da «Adozione» a «Provenienza e ingresso», accanto al box: sono
entrambi dati di collocazione del cane nel rifugio, e così la card Adozione resta di una riga.

### Cosa vale anche per il wizard

I tre passaggi usano `FormCard`, `FormRow2`, `CompatRow` e le stesse altezze. Il passaggio 2
(foto e carattere) e il 3 (sanitario e riepilogo) seguono lo stesso raggruppamento. Anche il
wizard è a schermo intero senza bottom nav e senza FAB.

### Test

1. L'altezza totale del contenuto scorrevole di Modifica cane a 360 dp è sotto i 1.050 dp
   (misura con `tester.getSize` sul `ListView` espanso, o sommando le card).
2. In Modifica cane e nel wizard non esiste nessuna `AppBottomNav` né FAB nell'albero
   (`findsNothing`).
3. Nessun `AppSegmented` supera i 32 dp di altezza; nessun campo a riga singola supera i 34.
4. Un campo multilinea vuoto è alto 34; con quattro righe di testo cresce fino a 4 righe.
5. Overflow a 320/360/411/430 dp: nessuno, in particolare sulle `FormRow2` con etichette
   lunghe e sulle `CompatRow` a quattro opzioni.
6. Golden di Modifica cane a 360×640 dopo approvazione visiva.

## 14-ter.8 · Gestione utenti dall'app e saluto personale

**Richiesta del committente.** Oggi gli account si creano solo dalla console Firebase e la
home saluta sempre «Giovanna». **Questa sezione sostituisce la schermata 21 «Volontari e
turni», rimossa il 10/09/2026: i turni non fanno parte dell'app.** Da qui in poi il presidente crea i volontari **dall'app**, e la
home saluta **chi ha fatto l'accesso**.

### Due vincoli tecnici che decidono il progetto

1. **Creare un utente dal client fa il login del nuovo utente.** `createUserWithEmailAndPassword`
   di Firebase Auth, chiamata dall'app, sostituisce la sessione corrente con quella del nuovo
   account: il presidente verrebbe buttato fuori mentre crea un volontario. La soluzione
   standard, che funziona sul piano gratuito senza server, è creare l'utente su una **seconda
   istanza Firebase temporanea**:

   ```dart
   final secondary = await Firebase.initializeApp(
     name: 'creazione-utente',
     options: DefaultFirebaseOptions.currentPlatform,
   );
   final auth = FirebaseAuth.instanceFor(app: secondary);
   final cred = await auth.createUserWithEmailAndPassword(email: e, password: p);
   final uid = cred.user!.uid;
   await auth.signOut();
   await secondary.delete();
   ```

   La sessione principale non viene toccata. Il documento `volunteers/{uid}` si scrive
   subito dopo con la sessione principale (quella del presidente, che ha i permessi).

2. **Un utente Auth non si può eliminare dal client.** Serve l'Admin SDK, cioè un server, cioè
   il piano Blaze. Quindi non esiste «Elimina utente»: esiste **«Disattiva»**, che mette
   `attivo = false`. Le regole Firestore controllano già `attivo`, l'utente disattivato non può
   più leggere né scrivere nulla e al login vede «Account disattivato». Resta in elenco,
   in grigio, e le sue note e modifiche restano attribuite a lui.

### Modello — `volunteers/{uid}` esteso

```
nome: string
cognome: string                      // nuovo
email: string
ruolo: 'presidente'|'referente'|'volontario'
attivo: bool
coloreAvatar: string
mustChangePassword: bool             // nuovo: true alla creazione, false dopo il primo cambio
createdAt, createdBy                 // nuovo
ultimoAccesso: Timestamp | null      // nuovo: aggiornato al login
```

Le regole restano: solo `presidente` scrive su `volunteers`. Eccezione da aggiungere: ogni
utente attivo può aggiornare **sul proprio documento** soltanto `mustChangePassword`,
`ultimoAccesso` e `coloreAvatar` (stessa tecnica `affectedKeys().hasOnly([...])` usata per
i turni).

### Impostazioni → sezione «Utenti»

Solo per il presidente. Per gli altri ruoli la sezione non si disegna.

```
IMPOSTAZIONI (schermata 26)
├ FormCard "Associazione"    (arriva con lo Step 18, per ora non c'è)
├ FormCard "Moduli"          (già esistente, resta com'è)
└ FormCard "Utenti"          ← NUOVA
    ├ per ogni volontario:  Row h=44
    │    ├ Avatar 30 iniziali, colore coloreAvatar (grigio se disattivato)
    │    ├ Expanded: "Nome Cognome" 12sp w700 · sotto "email · ruolo" 10sp muted
    │    │           se disattivato: nome barrato, badge "Disattivato"
    │    │           se mustChangePassword: badge "Password da cambiare"
    │    └ chevron
    │  ordinati: attivi prima, poi per nome
    └ AppButton ghost "➕ Nuovo volontario"
```

**Nuovo volontario** — bottom sheet con `FormField`/`FormRow2` del blocco 14-ter.7:

```
NUOVO VOLONTARIO
├ FormRow2   NOME *            | COGNOME *
├ FormField  EMAIL *            (validazione formato; unicità verificata da Auth)
├ FormField  PASSWORD INIZIALE *  (min 8, mostra/nascondi, pulsante "Genera"
│                                  che produce 10 caratteri leggibili senza ambiguità)
├ FormField  RUOLO              (seg Presidente / Referente / Volontario, default Volontario)
├ testo 10sp muted: "Il volontario dovrà cambiare la password al primo accesso.
│                    Comunicagli email e password a voce o di persona."
└ AppButton "Crea account"
```

Al salvataggio: creazione su istanza secondaria → scrittura `volunteers/{uid}` con
`mustChangePassword: true` → toast «Account creato per <Nome>». Errori Auth tradotti in
italiano: email già in uso, email non valida, password debole, nessuna rete.

**Dettaglio volontario** — tocco su una riga:

```
├ stessi campi in modifica: NOME, COGNOME, RUOLO (email in sola lettura)
├ "Invia email di reset password"  → sendPasswordResetEmail; conferma con toast
├ "Disattiva account" (rosso) / "Riattiva account"
│    Disattiva chiede conferma nominando la persona. Il presidente non può
│    disattivare sé stesso, né cambiare il proprio ruolo: le voci non si disegnano.
└ "Ultimo accesso: <data>" 10sp muted in fondo
```

Deve esistere **sempre almeno un presidente attivo**: il salvataggio che porterebbe a zero
viene rifiutato con messaggio chiaro.

### Primo accesso con password da cambiare

Dopo il login, se `mustChangePassword == true`, prima della home compare una schermata a
schermo intero «Scegli la tua password»: nuova password ×2, min 8, `updatePassword`, poi
`mustChangePassword = false`. Non si può saltare (nessun pulsante indietro).

### Saluto nella home

`"Ciao <nome> 👋"` legge `volunteers/{uid}.nome` dell'utente **autenticato**, dal
`currentVolunteerProvider`. Ordine di ripiego: `nome` → parte prima della `@` dell'email
con iniziale maiuscola → «Ciao 👋» senza nome. Mai un nome scritto a mano, mai il nome del
seed. Il nome va **con l'iniziale maiuscola** anche se salvato in minuscolo.

Stessa fonte per «Volontario referente», per l'autore delle note, per `createdBy` e
`updatedBy` mostrati nelle schermate: ovunque compare un nome di volontario, viene da
`volunteers`, non da stringhe locali.

### Sicurezza — coerenza con 14-ter.1

L'auto-registrazione non esiste nell'app. Se qualcuno crea un account Auth dall'esterno,
non ha il documento `volunteers/{uid}` e vede la schermata «Il tuo account non è ancora
abilitato», come previsto dal blocco 1. Il presidente può abilitarlo solo creando il
documento — cioè tramite «Nuovo volontario», che crea anche l'account: non c'è una via
per abilitare un account estraneo, ed è voluto.

### Test

1. Creando un volontario dalla sezione Utenti, l'utente **corrente** resta autenticato
   (l'uid di `FirebaseAuth.instance.currentUser` è lo stesso prima e dopo).
2. Dopo la creazione esiste `volunteers/{nuovoUid}` con `mustChangePassword: true`,
   `attivo: true`, `createdBy` = uid del presidente.
3. Email già in uso → messaggio italiano, nessun documento creato.
4. Un `referente` non vede la sezione Utenti (`findsNothing`); una scrittura forzata su
   `volunteers` è rifiutata dalle regole (emulatore).
5. Disattivare un volontario: `attivo = false`, la riga si ingrigisce, e al login quell'utente
   vede «Account disattivato» e non la home.
6. Tentare di disattivare l'ultimo presidente attivo viene rifiutato.
7. Il presidente non vede su sé stesso «Disattiva» né il selettore del ruolo.
8. Login con `mustChangePassword: true` porta alla schermata cambio password; dopo il cambio
   il flag è false e si arriva alla home.
9. Home: con l'utente «marco@…» il cui documento ha `nome: "marco"`, il saluto è «Ciao Marco».
   Con un utente senza documento il saluto non contiene il nome di nessun seed.
10. Un utente attivo può aggiornare `mustChangePassword` e `ultimoAccesso` sul proprio
    documento e **non** `ruolo` né `attivo` (emulatore).
11. Nessun overflow delle schermate nuove a 320/360/411/430 dp.

---

# PARTE 6 — Step 18-bis: i form di inserimento diventano popup centrali

**Richiesta del committente (10/09/2026), da fare prima dello Step 19.** Tutti i form brevi
oggi sono fogli che salgono dal basso, costruiti prima dei componenti del blocco 14-ter.7 e
mai adeguati: campi da 40 dp, etichette a 12 sp, un campo per riga, nessuna card, e con la
tastiera aperta il pulsante Salva finisce sotto il bordo.

Diventano **popup centrali**, tutti fatti con **un solo componente**, con gli stessi campi
compatti di Modifica cane. Riferimento visivo: `design/confronto-popup.html`.

## 18-bis.1 · Il componente `AppDialog`

Un solo widget in `lib/ui/components/app_dialog.dart`, usato da tutti i form. Nessun form
costruisce il proprio contenitore.

```
AppDialog
├ posizione: centrato; larghezza = schermo − 24 (12 per lato); maxHeight = 82% dell'altezza
│            disponibile SOPRA la tastiera (MediaQuery.viewInsets.bottom sottratto)
├ aspetto: fondo bianco, radius 14, bordo AppColor.line, ombra morbida, barrier scuro al 45%
├ Header  h=42  FISSO
│    IconBadge(20) · titolo 13sp w700 · × a destra (26 dp, fondo neutralSoft)
├ Body    scorrevole, padding 12, gap 8 fra i campi
│    usa SOLO FormField / FormRow2 / CompatRow / AppChip / AppSegmented del 14-ter.7
│    il campo con il focus viene portato in vista (Scrollable.ensureVisible)
└ Footer  h=46  FISSO, bordo superiore line2
     [🗑 32dp, solo in modifica]  [Annulla ghost]  [Salva primario]   — Annulla e Salva 50/50
     Salva è disabilitato (verde chiaro) finché il form non è valido
```

Comportamento:
- **Tastiera:** il dialog sale con `AnimatedPadding` su `viewInsets.bottom`; il footer resta
  sempre visibile. Questo è il punto che rende accettabile un popup centrale su un telefono.
- **Chiusura:** × o tap fuori. Se il form è stato modificato, conferma «Scartare le
  modifiche?». Il tasto indietro del telefono fa la stessa cosa.
- **Crea e modifica sono lo stesso dialog**: `AppDialog.show(context, form: X(existing: y))`.
  In modifica cambia il titolo («Modifica trattamento»), i campi sono precompilati, e nel
  footer compare il cestino, che chiede conferma nominando la cosa che sparisce.
- **Errori:** sotto il campo, 10 sp `AppColor.red`; mai in un toast.
- **Salvataggio:** Salva mostra uno spinner da 16 dp al posto del testo, poi chiude e la lista
  sottostante si aggiorna. In caso di errore il dialog resta aperto con il messaggio.

## 18-bis.2 · I form, uno per uno

Tutti con il contratto in cima al file. Le etichette sono maiuscolette da 10 sp.

**Trattamento** (`AppIcons.vaccino`)
```
TIPO            Wrap di AppChip: Vaccino · Sterilizzazione · Sverminazione · Antiparassitario ·
                Visita · Esame · Terapia · Altro
DESCRIZIONE     FormField
DATA            | PROSSIMA SCADENZA          FormRow2, entrambi date picker
VETERINARIO     | LOTTO                      veterinario: dropdown da vendors con "+ nuovo",
                                             testo libero ammesso
COSTO (€)       | nota 9.5sp "Se inserito, crea anche la spesa"
```

**Pesata** (`AppIcons.peso`) — `PESO (KG) | DATA` · `NOTE`. Tre righe, dialog minimo.

**Spesa** (`AppIcons.spese`)
```
CATEGORIA       Wrap di AppChip: Visite veterinarie · Sterilizzazione · Farmaci · Esami ·
                Cibo · Altro
IMPORTO (€)     | DATA
DESCRIZIONE
FORNITORE       dropdown da vendors con "+ nuovo", testo libero ammesso
```
Aperto dal FAB senza cane: in cima una riga `CANE` con il selettore e la voce «Spesa generale
del rifugio».

**Adozione a distanza** (`AppIcons.aDistanza`)
```
NOME            | COGNOME
EMAIL           | TELEFONO
IMPORTO MENSILE (€) | DAL
NOTE
```
In modifica il cestino è sostituito da «Chiudi adozione» (imposta `al` e `attiva = false`).

**Documento** (`AppIcons.documenti`)
```
TIPO            Wrap di AppChip (i dieci tipi attuali)
NOME            FormField, opzionale
FILE            due pulsanti affiancati 50/50: "Scegli PDF" · "Scegli foto"
                dopo la scelta compare una riga: icona · nome file · dimensione · ✕
                Salva si attiva SOLO con un file scelto. Nessun documento senza contenuto.
```

**Nota** (`AppIcons.note`)
```
TIPO            AppSegmented 4: Generale · Comportam. · Aliment. · Attenzione  (FittedBox)
TESTO           multilinea, parte da 3 righe, cresce fino a 8
riga finale 9.5sp: "<autore> · <data>"  (solo in modifica)
```

**Appuntamento** (`AppIcons.data`)
```
TIPO            Wrap di AppChip: Visita · Colloquio · Verifica preaffido · Scadenza · Altro
TITOLO
DATA            | ORA          (ORA disabilitata se "tutto il giorno")
CANE            | RICHIESTA    entrambi opzionali; RICHIESTA filtrata per cane
LUOGO
☐ Tutto il giorno   (riga 30 dp, checkbox a sinistra)
```

**Nuovo volontario** e **Modifica volontario** (blocco 14-ter.8): stesso `AppDialog`, stessi
campi già specificati lì.

**Cambio stato**: resta la pagina che è, non è un form breve.

## 18-bis.3 · Nuova richiesta di adozione — resta una pagina, ma compatta

Quindici campi più il questionario: come popup sarebbe un tubo da scorrere. Resta a schermo
intero come Modifica cane, con la stessa grammatica, senza bottom nav né FAB:

```
NUOVA RICHIESTA   (e MODIFICA RICHIESTA: stessa pagina precompilata)
├ AppBar h=40: ← · titolo · "Salva" pillola verde quando valido
├ FormCard "Cane"           riga con thumb 28 + nome + chevron → selettore
├ FormCard "Richiedente"    AppIcons.richieste
│    NOME | COGNOME
│    TELEFONO | EMAIL
│    CITTÀ | ETÀ
│    INDIRIZZO
│    DOCUMENTO (seg CI / Patente / Passaporto) | NUMERO
│    riga 10sp: "Trovato: Marta Rossi, 2 richieste precedenti" quando telefono o email
│    corrispondono a un adottante esistente → tap per usare i suoi dati
└ FormCard "Questionario"   AppIcons.modulo
     ABITAZIONE (seg Casa / Appartamento / Altro) | ORE DA SOLO (numero)
     CompatRow  Giardino recintato  | Sì / No        + ALTEZZA (m) se Sì
     CompatRow  Altri animali       | Sì / No        + QUALI se Sì
     CompatRow  Bambini in casa     | Sì / No        + ETÀ se Sì
     CompatRow  Esperienza con cani | Sì / No
     DOVE DORMIRÀ (seg In casa / Fuori / Entrambi)
     NOTE  multilinea
```
Da ~1.500 dp a ~900 dp. Stessa pagina per la modifica del questionario (oggi è un foglio a
parte).

## 18-bis.4 · Test

1. Ogni form brevе apre un `AppDialog` centrato (il widget è `Center`-ato, non ancorato in
   basso: `tester.getTopLeft` ha `dy` > 0 e il dialog non tocca il bordo inferiore).
2. Con `viewInsets.bottom = 300` il footer con Salva resta visibile e il dialog non va in
   overflow.
3. Salva è disabilitato a form vuoto e si attiva quando i campi obbligatori sono validi.
4. Chiudere con modifiche non salvate chiede conferma; senza modifiche chiude subito.
5. Lo stesso form aperto con `existing:` mostra il titolo «Modifica …», i valori precompilati
   e il cestino; senza `existing:` non c'è cestino.
6. Documento: Salva resta disabilitato finché non c'è un file; dopo la scelta compare la riga
   con nome e dimensione.
7. Nota: le quattro etichette del segmentato stanno su una riga a 320 dp senza overflow.
8. Nuova richiesta: altezza del contenuto sotto i 950 dp a 360 dp; nessuna bottom nav né FAB.
9. Nessun `showModalBottomSheet` resta nel codice dei form (grep): i fogli dal basso restano
   ammessi solo per i menu di scelta (FAB, ⋮, filtri, selettore cane).
10. Tutti i dialog a 320/360/411/430 dp senza overflow; golden di trattamento e nota dopo
    approvazione.

## 18-bis.5 · Cosa NON cambia

I **menu di scelta** — FAB «+», ⋮ della scheda, filtri dell'elenco, selettore del cane, foto
(fotocamera/galleria) — restano fogli dal basso: sono liste di azioni, non form, e dal basso
sono più comodi da raggiungere con il pollice. Cambiano solo i form.

---

# PARTE 7 — Step 18-ter: scheda di adozione esportabile (PDF e immagine)

**Richiesta del committente (10/09/2026), da fare dopo lo Step 18-bis e prima dello Step 19.**
L'associazione deve poter mandare il profilo di un cane a chi vuole adottarlo, e pubblicarlo
sui social. L'export attuale è testo nudo: va sostituito con una **scheda progettata**, in due
formati, dal menu ⋮ della scheda cane. Riferimento visivo: `design/scheda-adozione-export.html`.

## 18-ter.1 · Un solo profilo pubblico per entrambi i formati

Crea `lib/features/dogs/export/adoption_profile.dart` con una classe immutabile
`AdoptionProfile` e una funzione pura `AdoptionProfile.fromDog(dog, health, weights, photos,
association)`. È l'**unica** sorgente per PDF e immagine: quello che non c'è qui non può
finire in nessun export.

**Campi ammessi (allowlist):**
```
nome, slogan, descrizione
sesso, etaTesto ("Circa 1 anno e mezzo"), razza, taglia, pesoTesto
provenienza (solo il comune), inRifugioDa (mese e anno: "Giugno 2024")
stato pubblico: 'cerca_famiglia' | 'in_preaffido' | 'adottato'
sterilizzato + data · vaccinatoInRegola (bool) + data ultimo vaccino/richiamo
antiparassitarioInRegola (bool) · testLeishmania ('negativo'|'positivo'|null)
carattere[] · conPersone · conCani · conGatti · conBambini · noteCarattere
fotoCopertina (bytes) · altreFoto (max 4, bytes)
associazione: nome, citta, telefono, email, logo (da settings/association)
dataGenerazione
```

**Esclusi per contratto, mai presenti nell'oggetto:** microchip, box e settore, spese,
adozione a distanza, richieste ricevute e nomi di adottanti, note interne, referente,
storico stati, documenti, `createdBy`/`updatedBy`, qualsiasi id.

`vaccinatoInRegola` = esiste un trattamento di tipo vaccino con `prossimaScadenza` futura o
assente e data negli ultimi 12 mesi. `antiparassitarioInRegola` = ultimo antiparassitario
negli ultimi 45 giorni. Sono le uniche due regole di calcolo; il resto è copia.

## 18-ter.2 · PDF — «Scheda di adozione», A4

Costruito con il pacchetto `pdf` già presente, **font Roboto incorporato** (aggiungi i TTF
Regular, Italic, Bold in `assets/fonts/` e dichiarali: senza font incorporato accenti e
simboli escono male). Colori da `AppColor`, tradotti in `PdfColor`.

```
PAGINA 1  (A4, margini 18 mm)
├ Testata   **il LOGO dell'associazione come immagine** (assets/logo.png: il marchio con il
│           cane e la scritta) a sinistra, altezza 14 mm, proporzioni originali · "SCHEDA DI
│           ADOZIONE" 7pt maiuscolo verde a destra · filo verde 2pt sotto
│           NON il nome scritto in un font: il logo vero, lo stesso dell'header dell'app
├ Hero      foto copertina 62×78 mm radius 3 mm a sinistra
│           a destra: NOME 30pt w800 · slogan 9pt corsivo · pillola stato ("CERCA FAMIGLIA"
│           verde / "IN PREAFFIDO" arancio / "ADOTTATO" grigio) · griglia 2×3 di fatti:
│           sesso · età · razza e taglia · peso · arrivata da · in rifugio da
├ Salute    4 riquadri in riga: Sterilizzata (data) · Vaccinata (data richiamo) ·
│           Antiparassitario (in regola / da fare) · Leishmania (negativa / —)
│           se un dato manca il riquadro dice "non registrato", non sparisce
├ Colonne   sinistra "CARATTERE": chip + tabella compatibilità (persone/cani/gatti/bambini
│           con valore colorato: verde sì, arancio selettivo/da testare, rosso no) + note
│           destra "LA SUA STORIA": descrizione, giustificata, 8pt interlinea 1.5
├ Galleria  fino a 4 foto in riga, 4:3, radius 2 mm  (assente se non ci sono altre foto)
└ Piè       "Vuoi conoscere <nome>?" + nome associazione, città, telefono, email
            + logo piccolo (8 mm) a sinistra del blocco contatti
            a destra: "Scheda generata il <data> · i dati sanitari sono aggiornati a questa data"

PAGINA 2  solo se la descrizione o le foto non stanno in pagina 1: continua storia + galleria
          fino a 8 foto. Mai una terza pagina.
```
Nome file: `Scheda-<Nome>-AmiciPerLaCoda.pdf`. Peso obiettivo < 2 MB: le foto vanno
ridimensionate a 1200 px lato lungo, qualità 80, prima di entrare nel PDF.

## 18-ter.3 · Immagine — «Card per i social», JPEG 1080×1350

Formato 4:5, quello che Facebook e Instagram mostrano per intero nel feed. **Non** è la
pagina PDF rasterizzata: è un poster, con la foto protagonista.

Costruzione: un widget Flutter `AdoptionCardWidget(profile)` di 1080×1350 px logici, reso
**fuori schermo** con `RepaintBoundary` + `toImage(pixelRatio: 1)`, convertito in JPEG
qualità 90 con `flutter_image_compress`. Così usa gli stessi `AppColor`, `AppText`,
`IconBadge` dell'app e non serve un secondo sistema grafico.

```
CARD 1080×1350
├ Foto      58% dell'altezza, copertina in cover-fit
│           gradiente scuro dal basso (trasparente → 72% nero) e leggero dall'alto
│           badge in alto a sinistra: "CERCA FAMIGLIA" pillola verde, 26px w800 spaziato
│           **il LOGO come immagine** in alto a destra, altezza 90 px, su un riquadro bianco
│           semitrasparente (bianco 85%, radius 16, padding 12) così resta leggibile su
│           qualsiasi foto — mai il nome scritto in un font al posto del logo
│           NOME sovrapposto in basso a sinistra: 110px w800 bianco con ombra · slogan 30px corsivo
├ 4 fatti   riga di 4 riquadri su fondo AppColor.bg: età/sesso · taglia/peso ·
│           sterilizzat* · vaccini in regola   (icona 36px, valore 26px w800, etichetta 19px)
├ Chip      carattere + compatibilità positive come chip verdi ("Ok cani", "Ok gatti", "Ok
│           bambini" solo se sì) — max 6, i restanti si omettono
├ Testo     descrizione troncata a ~220 caratteri sull'ultimo punto fermo, 24px interlinea 1.45
└ CTA       barra verde: "Vuoi conoscerl*? Scrivici" + telefono e città in bianco

Il logo si legge da `assets/logo.png` (già nel progetto). Se il presidente carica un logo
diverso in `settings/association.logoB64`, vince quello. Se per errore nessuno dei due esiste,
l'export usa il nome dell'associazione in testo e lo segnala nel log: non fallisce, ma non
deve capitare.
```
Nome file: `<Nome>-AmiciPerLaCoda.jpg`.

Insieme all'immagine si condivide anche un **testo per il post**, così Giovanna non deve
riscriverlo: nome, età, taglia, due righe di carattere, "sterilizzat* e vaccinat*",
"Per informazioni: <telefono>", e gli hashtag `#adozione #<città> #amiciperlacoda`.
`share_plus` manda file e testo insieme.

## 18-ter.4 · Dove sta nell'app

Menu ⋮ della scheda cane, sostituendo «Esporta scheda PDF»:

```
📄  Scheda di adozione (PDF)     → genera, mostra anteprima a schermo intero
                                   (printing: PdfPreview) con "Condividi" e "Salva"
🖼  Card per i social (immagine) → genera, mostra anteprima, "Condividi" (immagine + testo)
                                   e "Salva nella galleria"
```
Entrambe le voci si vedono per tutti i ruoli, volontario compreso: condividere un cane non
è una scrittura. La generazione mostra un indicatore («Preparo la scheda…») e va fatta fuori
dal thread UI (`compute`) per le foto.

Le stesse due azioni compaiono nella **tab Adozione** del cane, sotto il banner «adottabile»,
al posto dell'attuale «Condividi scheda» testuale, che diventa una terza voce «Copia testo
dell'annuncio».

**Rimuovi dal menu ⋮:** «Copia link scheda pubblica» — non esiste un sito, il link non
porta da nessuna parte (Parte 2, punto 11). **Rimuovi anche «Elimina definitivamente»**:
la specifica prevede solo «Archivia» (14-ter.2). Un cane con foto, trattamenti, spese e
richieste non si cancella con un tap; se serve davvero, si fa dalla console. Se vuoi tenerla,
va limitata al presidente e a cani senza nessun record collegato, con conferma che chiede di
riscrivere il nome.

## 18-ter.5 · Test

1. `AdoptionProfile.fromDog` con un cane completo: l'oggetto **non ha** nessun campo
   contenente microchip, box, settore, id, referente (test per riflessione/serializzazione:
   `toJson()` non contiene le chiavi né i valori).
2. Il testo estratto dal PDF generato non contiene il microchip, il box, nessun importo in
   euro, nessun nome di adottante, nessuna nota interna (dati di prova con valori sentinella
   riconoscibili, es. microchip `999999999999999`, nota «SENTINELLA-NOTA»).
3. Il PDF ha 1 pagina con descrizione breve e ≤ 4 foto; 2 pagine con descrizione lunga o
   8 foto; mai 3.
4. Il PDF pesa meno di 2 MB con 8 foto da 4 MB in ingresso.
5. La card è esattamente 1080×1350 px, JPEG, sotto 600 KB.
6. Con `conCani == 'no'` la chip «Ok cani» non compare nella card; con `'si'` compare.
7. Cane senza foto: PDF e card usano un segnaposto con l'iniziale (come l'elenco), non
   falliscono.
8. Cane senza vaccini registrati: il riquadro dice «non registrato», la card dice «—».
9. Il testo per il post contiene nome, telefono e almeno un hashtag.
10. Il menu ⋮ non contiene più «Copia link scheda pubblica» né «Esporta scheda PDF»; contiene
    le due voci nuove per ogni ruolo, «Elimina definitivamente» non c'è più (o è limitata
    come sopra, se scelto).
11. Il PDF contiene un'immagine nella testata (estrazione delle immagini dal PDF: almeno
    una oltre alle foto del cane, con le proporzioni del logo); la card ha il logo in alto a
    destra (golden).
12. Golden della card a 1080×1350 dopo approvazione visiva: è l'unico modo per bloccare
    l'aspetto di un'immagine esportata.

## 18-ter.6 · Dipendenze

`flutter_image_compress` (già presente), `printing` (già presente, per l'anteprima PDF),
`share_plus` (già presente), `gal` o `image_gallery_saver_plus` per «Salva nella galleria».
Font Roboto TTF in `assets/fonts/`.

## 18-ter.7 · Impaginazione delle foto e delle sezioni vuote — correzione del 10/09/2026

**Problema rilevato sul PDF reale di Pongo (2 pagine, 9 foto):** la galleria è ancorata in
fondo alla pagina, quindi fra il testo e le foto resta un buco grande quanto lo spazio non
usato; la pagina 2 ripete il titolo «La sua storia» senza contenuto, con altre 4 foto in fondo.
E per un cane appena inserito, senza descrizione e senza trattamenti, la scheda mostra «—» e
quattro riquadri «non registrato»: sembra abbandonata. Riferimento visivo:
`design/scheda-adozione-foto.html`.

### Regola 1 — il contenuto scorre, niente è ancorato in fondo

La pagina si costruisce dall'alto verso il basso: testata, hero, salute, carattere e storia,
**poi subito la griglia delle foto**, senza spazio elastico in mezzo. Il piè di pagina è
l'unico elemento fisso in basso. Con il pacchetto `pdf` questo significa `MultiPage` con
`header`/`footer` e un flusso di widget: **nessun `Spacer`, nessun `Expanded`, nessun
`Positioned` in basso** nel corpo.

### Regola 2 — la griglia delle foto

- Griglia a **3 colonne**, celle di ugual misura, rapporto **1,1 : 1** (quasi quadrate: le
  foto in verticale e in orizzontale si tagliano poco, e le righe restano uniformi), spazio
  fra le celle 4 mm, angoli 2 mm, foto in `cover`-fit centrata.
- La copertina **non** compare nella griglia. Ordine: quello della galleria dell'app.
- Titolo «Le foto di <nome>» 8,5 pt maiuscolo verde sopra la prima riga, una volta sola.
- **Pagina 1:** dopo la storia si calcola lo spazio verticale rimasto sopra il piè di pagina;
  si inseriscono **tante righe complete quante ne stanno** (0, 1, 2 o 3). Se non ci sta
  nemmeno una riga, la pagina 1 non ha foto e la griglia inizia in pagina 2.
- **Pagine successive:** pagine galleria con solo testata (etichetta «LE FOTO DI <NOME>»),
  griglia e piè di pagina: **12 foto per pagina** (3×4). L'ultima pagina, se parziale, è
  compatta in alto, con l'ultima riga che parte da sinistra.
- Con il limite di 20 foto per cane il massimo assoluto è **3 pagine**. Non esistono casi
  oltre.
- Foto della griglia ridimensionate a **700 px lato lungo, qualità 75** prima di entrare nel
  PDF; la copertina a 1200 px, qualità 80. Così 20 foto pesano ~1,5 MB.

### Regola 3 — le sezioni vuote non si mostrano vuote

| Caso | Adesso | Deve fare |
|---|---|---|
| Descrizione assente | «—» sotto «La sua storia» | testo **generato dai dati**, senza segnalarlo: «<Nome> è un<a> <razza> di taglia <taglia>, <sesso>, arrivat<o/a> a <comune> nel <mese anno>. <Con le persone …>. <Sterilizzat* e vaccinat*.>» Due-tre frasi, solo con i dati che ci sono. |
| Nessun trattamento registrato | 4 riquadri «non registrato» | una riga sola: «Dati sanitari non ancora registrati: chiedici pure.» Se anche uno solo dei quattro esiste, tornano i 4 riquadri. |
| Età, peso o razza sconosciuti | «—» nella griglia dei fatti | la cella **non si disegna**; la griglia si compatta |
| Slogan assente | riga vuota | la riga non si disegna |
| Carattere senza chip | «—» | la riga delle chip non si disegna; resta la tabella di compatibilità |
| Compatibilità tutta «da testare» | quattro «Da testare» | resta com'è: è un'informazione vera e utile |

Nessuna sezione ripete il proprio titolo in una pagina successiva. Solo la galleria continua,
con la sua etichetta in testata.

### Regola 4 — piè di pagina

Su ogni pagina: contatti a sinistra, «pagina n di N» e data di generazione a destra. Il
piè di pagina della pagina 1 tiene «Vuoi conoscere <nome>?»; le pagine galleria tengono solo
il nome dell'associazione e i contatti.

### Test aggiuntivi

12. Cane con 1 foto: 1 pagina, nessuna griglia, nessun titolo «Le foto di».
13. Cane con 5 foto e descrizione breve: 1 pagina, 4 foto sotto il testo in due righe.
14. Cane con 20 foto: 3 pagine esatte; pagina 2 ha 12 foto; pagina 3 le rimanenti compatte in
    alto; nessuna pagina contiene il titolo «La sua storia» oltre la prima.
15. Cane con descrizione molto lunga (1.500 caratteri) e 20 foto: la storia resta intera in
    pagina 1 (font a 7,5 pt se serve, mai troncata), la griglia inizia dove c'è spazio; mai
    più di 3 pagine.
16. Cane senza descrizione: il PDF contiene il testo generato con nome, razza e comune; non
    contiene «—» né «non registrato» ripetuto quattro volte.
17. Nessun `Spacer`/`Expanded` nel corpo del documento PDF (grep sul file del builder).
18. Il file con 20 foto pesa meno di 2 MB.

---

# PARTE 8 — Step 18-quater: tema scuro

**Richiesta del committente (11/09/2026).** La specifica originale (§3.3) diceva «solo tema
chiaro nella v1»: superata. Il tema scuro va fatto **prima dello Step 19**, perché tocca ogni
schermata e va bloccato con i golden prima delle rifiniture finali. Riferimento visivo con la
palette e i contrasti misurati: `design/tema-scuro.html`.

## 18-quater.1 · Perché è un intervento strutturale

Oggi ogni colore arriva da costanti statiche (`AppColor.green`). Una costante non può cambiare
con il tema. Quindi: `AppColor` diventa una **palette per tema** letta dal contesto, con gli
**stessi nomi di campo** di oggi, così la migrazione è meccanica.

```dart
// lib/ui/palette.dart
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  // stessi nomi di AppColor, più i nuovi:
  final Color bg, card, card2, line, line2, ink, ink2, muted, faint;
  final Color green, greenDark, greenSoft, greenTint, greenSoftFg;
  final Color accent;              // NUOVO: verde per testi/icone attive (in chiaro = green)
  final Color blue, blueSoft, blueSoftFg, red, redSoft, redSoftFg,
              purple, purpleSoft, purpleSoftFg, orange, orangeSoft, orangeSoftFg,
              pinkSoft, pinkSoftFg, neutralSoft, neutralSoftFg;
  final Color onPrimary;           // testo sui pulsanti verdi: bianco in entrambi
  final List<BoxShadow> cardShadow;// ombra in chiaro, nessuna in scuro
  final Brightness brightness;
  static const light = AppPalette(/* valori attuali di AppColor */);
  static const dark  = AppPalette(/* tabella 18-quater.2 */);
  // lerp, copyWith
}
extension PaletteX on BuildContext {
  AppPalette get c => Theme.of(this).extension<AppPalette>()!;
}
```

Migrazione: `AppColor.xxx` → `context.c.xxx` in tutti i widget. Nei pochi punti senza
contesto (painter del grafico peso, aggregatori che restituiscono un colore) la palette si
passa come parametro. `AppIcons` smette di avere colori costanti: ogni voce indica un **ruolo**
(`green`, `blue`, `red`, `purple`, `orange`, `pink`, `neutral`) e `IconBadge` risolve sfondo
e colore del simbolo dalla palette corrente.

**Il tema chiaro non deve cambiare di un pixel.** I golden chiari esistenti sono il test della
migrazione: se dopo il blocco 1 restano verdi, la migrazione è corretta.

## 18-quater.2 · Palette scura

| Campo | Chiaro (invariato) | Scuro |
|---|---|---|
| `bg` | #F5F7F3 | #0F1412 |
| `card` | #FFFFFF | #171D1A |
| `card2` (segmentati, input dentro card) | #EFF1ED | #1F2622 |
| `line` / `line2` | #E9EBE4 / #F1F3EC | #2B332E / #232A26 |
| `ink` / `ink2` | #16211B / #2C3A32 | #EEF2EE / #D3DAD5 |
| `muted` / `faint` | #6E7B72 / #9AA69E | #9AA69E / #6F7B73 |
| `green` (riempimenti, pulsanti) | #157A3C | #157A3C |
| `greenDark` (pressed) | #0F5C2C | #0F5C2C |
| `accent` (testo e icone attive) | #157A3C | **#4FC57E** |
| `greenSoft` / `greenSoftFg` | #E7F4EB / #136135 | #1B3A28 / #8BE0AB |
| `greenTint` (box citazione) | #F2FAF4 | #16261D |
| `blue` / `blueSoft` / `blueSoftFg` | #2E7FD6 / #E7F1FC / #1D5F9E | #6AAAF2 / #1A2C42 / #9CC6F5 |
| `red` / `redSoft` / `redSoftFg` | #E04552 / #FDECEE / #B0303B | #F26B75 / #3F2024 / #F5A0A6 |
| `purple` / `purpleSoft` / `purpleSoftFg` | #7B4CC0 / #F2EAFC / #5C33A0 | #B08FE8 / #2D2542 / #C9B3F0 |
| `orange` / `orangeSoft` / `orangeSoftFg` | #DE8A22 / #FDF1DF / #9D6212 | #F2AD4E / #3E2F18 / #F5C67F |
| `pinkSoft` / `pinkSoftFg` | #FCE9F1 / #C2185B | #3F2331 / #F2A6C8 |
| `neutralSoft` / `neutralSoftFg` | #EFF1ED / #5F6B62 | #262E29 / #B9C3BC |
| `onPrimary` | #FFFFFF | #FFFFFF |
| `cardShadow` | ombra tenue | **nessuna** (solo bordo) |

Contrasti misurati nel tema scuro: testo principale 15,1:1, etichette 6,8:1, accent 7,8:1,
bianco su verde pieno 5,4:1, ogni badge fra 7,2 e 8,2:1. Il segnaposto è 3,9:1: accettabile
per un segnaposto, non per un testo.

**Dove va `accent` e dove `green`:** i riempimenti (pulsante primario, FAB, barra di
occupazione, tab attiva della bottom nav come sfondo, segmento selezionato) restano `green`
con testo `onPrimary`. I **testi e le icone** che oggi sono verdi (titoli di sezione, «Vedi
tutti ›», tab attiva, prezzo in evidenza, link, icona della bottom nav attiva) diventano
`accent`. In chiaro i due coincidono, quindi la regola non cambia nulla nel tema chiaro.

## 18-quater.3 · Casi particolari

- **Logo.** Il logo è nero su trasparente: sullo sfondo scuro sparisce. Nell'header, nel login
  e nella card profilo si mostra su una **targhetta bianca** (radius 14, padding 6×12, bianco
  pieno) quando il tema è scuro. Se in futuro l'associazione fornisce `assets/logo_dark.png`,
  l'app lo usa al posto della targhetta. Nessuna inversione automatica dei colori: il cuore
  rosso diventerebbe ciano.
- **Foto e segnaposto con l'iniziale**: invariati; il segnaposto usa `greenSoft`/`greenSoftFg`.
- **Barra di stato e di navigazione di sistema**: icone chiare su scuro
  (`SystemUiOverlayStyle`), sfondo della nav bar = `card`.
- **Dialog e bottom sheet**: fondo `card`, barrier al 60% invece che 45%.
- **Scheletri di caricamento**: `card2` con shimmer verso `line`.
- **Grafico peso e barre delle statistiche**: colori dalla palette, griglia `line`.
- **Export PDF e card social: sempre chiari.** Sono carta, non schermo. Il builder riceve
  `AppPalette.light` esplicitamente, mai `context.c`.
- **Golden test**: ogni golden esistente viene affiancato dalla versione scura
  (`home_dark_360.png`, ecc.). Stessi widget, `ThemeMode.dark`.

## 18-quater.4 · Impostazione

Impostazioni → Aspetto e dati → **Tema**: foglio con tre scelte, `Chiaro · Scuro · Sistema`.
Predefinito **Sistema**. Salvato localmente (`shared_preferences`), applicato subito senza
riavvio (`MaterialApp.themeMode` da un provider). Il toast «Disponibile solo il tema chiaro»
sparisce.

## 18-quater.5 · Ordine di lavoro — due blocchi, con lo stop in mezzo

**Blocco A — migrazione a palette, tema chiaro identico.** `AppPalette` con solo `light`,
`context.c`, migrazione meccanica di tutti i file, `AppIcons` a ruoli, `IconBadge` che risolve
dalla palette. Nessun colore nuovo. **Criterio di accettazione: tutti i golden chiari
esistenti passano senza rigenerarli.** Se uno fallisce, la migrazione ha cambiato qualcosa e
va capito perché — non si rigenera il golden.

**Blocco B — tema scuro.** `AppPalette.dark`, il token `accent` applicato secondo la regola
sopra, la targhetta del logo, l'impostazione con persistenza, i golden scuri, il test dei
contrasti.

## 18-quater.6 · Test

1. **Test dei contrasti (unit).** Per la palette scura, per ogni coppia della tabella
   (`ink`/`card`, `muted`/`card`, `accent`/`card`, `accent`/`bg`, `onPrimary`/`green`, ogni
   `xSoftFg`/`xSoft`, `red`/`card`, `blue`/`card`, `orange`/`card`) il rapporto WCAG calcolato
   nel test è ≥ 4,5. Stesso test sulla palette chiara. Se qualcuno in futuro ritocca un colore
   e rompe la leggibilità, il test lo dice.
2. Dopo il blocco A, tutti i golden chiari esistenti passano **senza** `--update-goldens`.
3. `grep` su `lib/`: nessuna occorrenza di `AppColor.` fuori da `palette.dart`; nessun
   `Color(0x` nei widget delle feature (i colori esistono solo nella palette).
4. Con `ThemeMode.dark`, nessuna schermata usa un colore della palette chiara: test che
   renderizza le schermate principali in scuro e verifica che lo sfondo del `Scaffold` sia
   `AppPalette.dark.bg` e il testo del titolo `AppPalette.dark.ink`.
5. Nel tema scuro il logo è dentro la targhetta bianca (widget presente); nel chiaro no.
6. Cambiando il tema dalle impostazioni la home cambia senza riavvio; chiusa e riaperta l'app
   il tema scelto è ricordato; «Sistema» segue la modalità del telefono.
7. PDF e card social generati con il tema scuro attivo sono identici (byte a byte, a parità di
   dati) a quelli generati con il chiaro.
8. Golden scuri di home, elenco cani, scheda cane, modifica cane, un dialog e le impostazioni,
   bloccati dopo approvazione visiva.
9. Nessun overflow in scuro alle quattro larghezze (le stringhe non cambiano, ma il test
   costa nulla).

---

# PARTE 9 — Step 19-bis: importazione dei dati reali (49 cani + archivio Facebook + foto)

**Richiesta del committente (11/09/2026).** Caricare nell'app tutti i cani veri con le loro
foto: i 49 in rifugio e i 106 dell'archivio Facebook. I file sono nella cartella `import/`
del progetto (`import/README.md`). **Solo profili e foto**: niente altro.

## 19-bis.1 · Uno script una tantum dal PC, non una schermata

Script Node.js in `tool/import/` con `firebase-admin` (funziona sul piano Spark: è Cloud
Functions a richiedere Blaze, non l'Admin SDK) e `sharp` per le foto. Nessuna modifica
all'app, tranne una: `Dog.fromMap` deve accettare `sesso` nullo (i cani Facebook non ce
l'hanno; la UI mostra «—»).

Chiave: console Firebase → Impostazioni progetto → Account di servizio → «Genera nuova chiave
privata» → salvare come `tool/import/serviceAccount.json` → **in `.gitignore`**.

```
node import.mjs --dry-run                          # stampa cosa farebbe, non scrive
node import.mjs --backup                           # scarica tutte le collezioni in backup-<data>/
node import.mjs --dogs                             # cani_rifugio.csv poi cani_facebook.csv
node import.mjs --photos --dir "<cartella foto>"   # foto_facebook.csv
node import.mjs --verify
node import.mjs --restore backup-<data>/
```

## 19-bis.2 · Regole

**Idempotenza.** Id deterministici: `csv_<slug>` per i 49, `fb_<n>_<slug>` per i Facebook,
`fbphoto_<slug-file>` per le foto. Rilanciare aggiorna, non duplica.

**Ordine.** Prima `cani_rifugio.csv` (49), poi `cani_facebook.csv` (106), poi le foto.

**`azione = crea`** (98 cani): documento `dogs` con nome, stato, archiviato, statoDal,
descrizione; campi assenti `null`; `createdBy: 'import'`; una voce in `storicoStati`
(`note: "Importato da Facebook, data approssimativa"`); la colonna `nota` diventa un
documento `notes` di tipo `generale`, autore `import`.

**`azione = solo_foto`** (8 cani: Aramis, Diana, Duca, Flora, Max, Mirtillo, Molly, Totò):
il cane **esiste già** fra i 49. Si cerca per nome normalizzato (minuscolo, senza accenti) e
si aggiungono **solo le foto**. Non si tocca nessun altro campo, non si crea nessun documento
`dogs`, nessuna nota. Se il cane non si trova, lo script si ferma e lo dice.

**Foto** (`foto_facebook.csv`, colonna `caneNellApp` = il cane a cui appartiene):
- orientamento EXIF applicato, metadati rimossi;
- **full**: lato lungo **1400 px**, JPEG qualità 82; se supera **650 KB** si scende di 5 punti
  di qualità fino a rientrare;
- **thumb**: lato lungo 160 px, qualità 60;
- struttura **copiata dal codice Dart di `PhotoRepository`**, campo per campo: `photos/{id}`
  con `dogId, isCover, w, h, mime, thumbB64, bytesFull, createdAt, createdBy: 'import'` e
  `photos/{id}/full/data` con `b64`;
- `copertina = SI` → `isCover: true` e `dogs.fotoCopertinaId`; per i `solo_foto`, se il cane
  ha già una copertina, quella resta e la foto Facebook entra come foto normale;
- massimo 20 foto per cane: le eccedenti finiscono nel rapporto;
- file mancante: si registra nel rapporto e si va avanti.

**Non si importano** le foto della sottocartella `foto_di_gruppo`.

**Rapporto** `tool/import/report-<data>.md`: cani creati / aggiornati solo foto / errori; foto
importate / mancanti / oltre limite; MB scritti; tempo.

## 19-bis.3 · Sicurezza

- La prima esecuzione su un progetto che ha già documenti `fb_*` o `csv_*` richiede `--force`.
- `--backup` prima dell'import vero; `--restore` per tornare indietro.
- Le regole Firestore non cambiano.

## 19-bis.4 · Test

1. `--dry-run` sui CSV reali: 49 + 98 creazioni, 8 «solo foto», 267 foto, 0 errori, nessuna
   scrittura (conteggio documenti prima/dopo identico).
2. Dopo `--dogs`: `dogs` ha 147 documenti (49 + 98); gli 8 `solo_foto` non hanno creato nulla
   e hanno tutti i campi **invariati** (confronto prima/dopo).
3. Rilanciare `--dogs` non cambia il numero di documenti.
4. Foto: ogni `full` ≤ 650 KB e ≥ 900 px sul lato lungo; ogni `thumb` ≤ 15 KB; l'app le mostra
   in elenco e galleria (verifica manuale su 5 cani, incluso Duca con 10 foto).
5. Gli 8 `solo_foto` hanno le foto in più e la stessa copertina di prima, se ne avevano una.
6. `--verify`: nessuna foto orfana, nessun cane con `fotoCopertinaId` che non esiste.
7. `--restore` riporta un cane cancellato a mano.
