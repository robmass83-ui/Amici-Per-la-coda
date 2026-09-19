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
