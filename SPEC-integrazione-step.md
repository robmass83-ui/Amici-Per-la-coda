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

- **Gestione**: Anagrafe cani · Richieste e adozioni · Box e settori · Volontari e turni · Calendario
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

Leggi @SPEC-integrazione-step.md ed esegui SOLO lo "Step 9-bis — Home / Dashboard".

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
Approvato. Esegui lo "Step 17-bis" di @SPEC-integrazione-step.md: menu Altro,
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

### 3. Il volontario deve poter iscriversi a un turno (Step 16 e 18)

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
lacune nel modello dati. Leggi la PARTE 2 di @SPEC-integrazione-step.md ed
esegui SOLO i tre punti urgenti, quelli marcati in rosso:

1. Storico dei pesi: aggiungi la collezione weights, il modello, il repository
   e l'azione "registra peso" nella tab Salute. Il grafico del peso deve leggere
   la serie reale: se adesso usa dati scritti a mano nel widget, toglili.
   dogs.pesoKg resta come copia dell'ultimo peso registrato.

2. Adozione a distanza: aggiungi la collezione sponsorships con modello e
   repository, e collega il riquadro della tab Spese ai dati veri, con lo stato
   vuoto quando non ci sono sostenitori. Niente numeri finti.

3. Regole di sicurezza: aggiungi la regola che permette a un volontario attivo
   di aggiungere o togliere solo il proprio uid da appointments.volontariIds,
   senza poter modificare altri campi. Copia la regola dal documento.

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
