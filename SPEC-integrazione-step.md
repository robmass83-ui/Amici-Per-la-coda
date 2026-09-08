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
