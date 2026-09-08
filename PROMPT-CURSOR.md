# Prompt di avvio per Cursor

> **Come si usa.** Crea una cartella vuota, aprila in Cursor, metti dentro i due file:
> `AMICI-PER-LA-CODA_SPEC.md` (nella radice) e `design/reference.html`.
> Poi apri la chat in modalità **Agent**, scegli un modello forte (Claude Opus/Sonnet più
> recente o GPT-5 class) e incolla il testo qui sotto. Ripeti il "prompt di continuazione"
> a ogni step successivo.

---

## 📋 PROMPT INIZIALE — copia da qui

```
Devi costruire un'applicazione Android in Flutter chiamata "Amici per la Coda":
un gestionale per un rifugio cani, usato internamente da 3-4 volontari
dell'associazione. Non verrà pubblicata su nessuno store.

## Documenti da leggere PRIMA di scrivere qualsiasi codice

1. `AMICI-PER-LA-CODA_SPEC.md` — la specifica completa e vincolante.
   Leggila tutta, dall'inizio alla fine, adesso.
2. `design/reference.html` — il prototipo visivo di riferimento con 29 schermate.
   Aprilo e guardalo: l'app finita deve assomigliargli il più possibile
   (stessi colori, stesse proporzioni, stessa densità di informazione).

## Come devi lavorare

Il lavoro è diviso in 20 step, elencati nella sezione 8 della specifica.
Devi procedere **UNO STEP ALLA VOLTA**, in ordine:

1. Annunci quale step stai facendo e cosa comprende.
2. Scrivi il codice di quello step e i test di quello step.
3. Esegui `flutter analyze` e `flutter test` e mi mostri l'output.
4. Mi fai un riepilogo di 5 righe: cosa hai creato, quali file, cosa devo
   verificare a mano io.
5. **TI FERMI E ASPETTI LA MIA APPROVAZIONE.**
   Non iniziare mai lo step successivo di tua iniziativa.

Uno step si considera concluso solo se: `flutter analyze` dà 0 problemi,
`flutter test` è tutto verde, e nessuna schermata va in overflow.

## Vincoli di interfaccia — i più importanti, non violarli mai

Ho già visto agenti AI produrre interfacce enormi e sprecone. Qui NO:

- **Mai scroll orizzontale**, in nessuna schermata, per nessun motivo.
  Se un contenuto non ci sta in larghezza: va a capo, si accorcia,
  o si rimpicciolisce il font. Non si scorre di lato.
- **Le TabBar non sono mai scorrevoli**: tutte e 7 le tab della scheda cane
  devono stare insieme sullo schermo anche a 320 dp di larghezza.
- **Font piccolo è OK**: meglio 10 sp e vedere tutti i dati, che 16 sp e
  tagliare le informazioni. Queste schermate hanno molto contenuto:
  privilegia sempre la densità, purché resti leggibile.
- **Lo scroll verticale invece è permesso** e previsto: le pagine sono lunghe.
- Tutte le misure, i colori e le dimensioni del testo si prendono SOLO dalle
  costanti in `lib/ui/tokens.dart` (definite nella sezione 3 della specifica).
  Nessun numero scritto a mano dentro le schermate.
- Niente padding di default di Material: `ListTile`, `Card`, `AppBar` e
  `TextFormField` vanno ridefiniti compatti nel tema.
- Ogni schermata va verificata a 320, 360, 411 e 430 dp di larghezza.

## Tecnologie — già decise, non proporre alternative

Flutter · solo Android (APK, minSdk 24) · Firebase con piano gratuito Spark ·
Firebase Auth email/password · Cloud Firestore · Riverpod · go_router.

**Le foto NON vanno su Firebase Storage** (dal 2024 richiede il piano a pagamento):
si comprimono e si salvano dentro Firestore, dietro un'interfaccia
`PhotoRepository` come descritto nella sezione 6 della specifica.

## Cosa fare adesso

1. Conferma che hai letto la specifica e il file HTML, riassumendomi in 10 righe
   cosa hai capito del progetto e dei vincoli di dimensione.
2. Elencami eventuali punti che ti sembrano ambigui o contraddittori: se ce ne
   sono, chiedimeli invece di decidere da solo.
3. Poi esegui **solo lo Step 1** (Fondamenta del progetto) e fermati.
```

## 📋 fine del prompt iniziale

---

## 🔁 PROMPT DI CONTINUAZIONE — da riusare a ogni step

```
Approvato. Procedi con lo Step N della sezione 8 della specifica.

Ricorda i vincoli: nessuno scroll orizzontale, TabBar non scorrevoli, misure
solo da tokens.dart, densità alta e font piccolo se serve, verifica a
320/360/411/430 dp. Scrivi anche i test previsti per questo step.

Al termine: output di `flutter analyze` e `flutter test`, riepilogo di 5 righe,
poi fermati e aspetta.
```

---

## 🛠 PROMPT DI CORREZIONE — quando qualcosa esce troppo grande

```
Questa schermata è troppo grande e dispersiva. Correggila così:

- riduci di un livello tutte le dimensioni del testo, usando la scala di AppText
- riduci i padding usando AppDim (pagina 12, card 10, distanza fra card 9)
- accorpa le informazioni su meno righe (etichetta piccola sopra, valore sotto)
- verifica che tutto stia in larghezza a 320 dp senza scroll orizzontale
- confrontala di nuovo con la schermata corrispondente in design/reference.html

Mostrami lo screenshot del risultato a 320 dp e a 360 dp.
```

---

## 🧪 PROMPT DI VERIFICA — ogni 5 step

```
Fermati e fai una revisione trasversale:

1. Esegui l'app e passa su TUTTE le schermate realizzate finora, a 320 dp.
   Segnalami ogni overflow, ogni testo tagliato, ogni scroll orizzontale.
2. Cerca nel codice i numeri scritti a mano (padding, fontSize, radius) che
   non passano da AppDim/AppText e sostituiscili.
3. Verifica che nessuna schermata contenga dati finti scritti nel widget:
   tutto deve arrivare dai repository.
4. `flutter analyze` e `flutter test`: entrambi devono essere puliti.

Dammi un elenco puntato dei problemi trovati e correggili uno per uno.
```

---

## Note pratiche

- **Se Cursor "dimentica" i vincoli** dopo qualche step (succede): riapri la
  specifica nel contesto con `@AMICI-PER-LA-CODA_SPEC.md` e usa il prompt di
  verifica qui sopra.
- **Metti la sezione 2 della specifica anche in `.cursorrules`** nella radice del
  progetto: così i vincoli di dimensione entrano automaticamente in ogni
  richiesta, senza doverli ripetere.
- **Fai un commit git a fine di ogni step approvato.** Se uno step va storto,
  torni indietro di uno invece di ricominciare.
- **Non chiedere due step insieme.** È la cosa che fa peggiorare di più la qualità.
