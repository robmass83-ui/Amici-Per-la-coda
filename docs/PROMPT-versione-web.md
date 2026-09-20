# Prompt per Cursor + Superpowers — versione web di Amici per la Coda

Superpowers non esegue e basta: parte dal **brainstorming**, ti fa domande una alla volta,
poi apre un worktree, scrive il piano, e solo dopo programma con i test davanti. Quindi qui
non c'è un ordine da eseguire: c'è un **brief** da dare in pasto al brainstorming, le risposte
già pronte alle domande che ti farà, e i paletti da consegnare a chi scriverà il piano.

Usa i blocchi nell'ordine in cui stanno.

---

## 1 · Il brief — incollalo per primo

```
Ho un'app Flutter per la gestione di un rifugio per cani, "Amici per la Coda".
Oggi gira su Android come APK installata a mano, fuori dal Play Store. Usa Firebase
(Firestore + Auth) e la usano una decina di volontari.

Il problema: alcuni volontari hanno l'iPhone. Non posso pubblicare su App Store e non
voglio pagare né aprire account nuovi. La soluzione che ho scelto è compilare la stessa
app per il web e pubblicarla su Firebase Hosting, così su iPhone la si aggiunge alla
schermata Home da Safari e si comporta come un'app. Chi ha Android continua con l'APK
che ha già.

Voglio usare il brainstorming prima di toccare il codice, ma partiamo da qui: la
decisione web-invece-che-app-desktop è presa e non la rimetto in discussione. Quello su
cui voglio ragionare con te è COME farlo senza rompere niente.

VINCOLO NUMERO UNO, quello che conta più di tutti gli altri messi insieme:
l'app Android non deve cambiare comportamento. Stesso codice, due piattaforme. Se per
far girare qualcosa sul web ti viene voglia di sostituire un pacchetto che su Android
oggi funziona, la risposta è no: si affianca un'implementazione web e si sceglie a
runtime, lasciando il ramo Android intatto. Ogni volta che stai per toccare codice
condiviso me lo dici prima.

Il secondo vincolo è il database. Android e web parlano allo stesso Firestore, e sui
telefoni dei volontari resta installata la VECCHIA APK. Quindi le modifiche ai dati
devono essere additive: campi nuovi sì, semantica dei campi esistenti non si tocca. Se
una cosa non si può fare in modo compatibile, fermati e dimmelo: valuterò se distribuire
un'APK aggiornata.

Terzo: a budget zero. Firebase Hosting piano gratuito, il progetto Firebase esiste già.
Niente servizi nuovi, niente abbonamenti, niente dipendenze a pagamento.

Cose che so già e che non devi scoprire da capo:
- su iPhone l'installazione è manuale e solo da Safari (Condividi > Aggiungi a Home);
  da Chrome iOS non si può, e non esiste il prompt automatico di installazione
- le notifiche push su iOS funzionano solo se l'app è stata aggiunta alla Home, da
  iOS 16.4 in su
- l'offline nel browser è più fragile che su Android: Safari può liberare lo spazio se
  l'app non viene aperta per settimane

C'è un punto che per me è bloccante e voglio affrontarlo per primo nel brainstorming:
oggi l'APK è protetta dal fatto che nessuno la trova. Con un indirizzo web pubblico
quella protezione sparisce, e nel database ci sono codici fiscali, indirizzi di casa e
numeri di telefono di privati cittadini. Prima di pubblicare qualsiasi cosa voglio essere
sicuro che le regole di sicurezza di Firestore reggano davvero, cioè che uno che conosce
l'indirizzo e apre la console del browser non legga niente senza essere autenticato.

Parti dal brainstorming. Una domanda alla volta.
```

## 2 · Le risposte che ti chiederà — tienile qui e copia quella che serve

Il brainstorming fa domande una per volta. Queste sono quelle che arriveranno quasi
sicuramente, con la risposta già pronta, così non devi improvvisare dal telefono.

**«Chi usa cosa, dopo?»** — Android tiene l'APK, che offline e con le notifiche va meglio.
iPhone e computer usano il web. Stesso Firestore, stesse funzioni, stessi dati. Fra sei mesi
valuterò se tenere solo il web.

**«Tutte le funzioni sul web, o un sottoinsieme?»** — Tutte quelle che si possono fare senza
inventare dipendenze nuove. Se una funzione sul web costa sproporzionatamente (per esempio un
visualizzatore PDF pesante), la degradiamo elegantemente e me lo dici: meglio "questa cosa sul
web si apre in una scheda nuova" che tre megabyte di libreria in più.

**«Le notifiche?»** — Fuori dalla prima versione. Su iOS servono FCM web push, una chiave VAPID
e un service worker dedicato, e comunque funzionano solo ad app installata. Prima mettiamo online
qualcosa che funziona, le notifiche web le valutiamo dopo con calma.

**«L'offline?»** — Cache di Firestore attiva anche sul web, con la persistenza richiesta
esplicitamente. Ma non progettiamo per giorni senza rete: il caso d'uso web è "sono in rifugio
col wifi o in 4G". L'offline serio resta su Android.

**«Il layout?»** — L'app è disegnata per 360 dp di larghezza. Su un portatile non deve
spalmarsi a tutto schermo diventando illeggibile: contenuto centrato con una larghezza massima,
e il resto sfondo. È la differenza fra "sembra un'app" e "sembra un sito fatto male".

**«Dominio personalizzato?»** — No, va benissimo l'indirizzo `.web.app` che dà Firebase.
Gratis e già in HTTPS.

**«Come faccio a sapere che funziona su iPhone?»** — Test su un iPhone vero prima di dirlo ai
volontari. Non il simulatore, non Chrome con la finestra stretta: un iPhone in mano, installato
dalla Home, con il login fatto.

## 3 · I paletti per il piano — consegnali quando passa a writing-plans

```
Prima che il piano vada in esecuzione, queste devono essere voci del piano, non
buone intenzioni.

PROTEZIONE DI ANDROID
- Si lavora in un git worktree separato. Il branch principale resta com'è.
- Prima di iniziare: build dell'APK release dal codice attuale, e quel file lo
  metto da parte. È la mia via di fuga.
- "flutter build apk --release" deve compilare alla fine di OGNI task del piano,
  non solo alla fine di tutto. Se un task lo rompe, quel task non è finito.
- Nessun pacchetto esistente viene rimosso o sostituito senza che io dica di sì.
  Dove il web ha bisogno di una strada diversa si usano import condizionali o
  kIsWeb, e il ramo Android resta byte per byte quello di prima.
- Prima di unire qualsiasi cosa: APK installata su un telefono vero e provata a
  mano su login, elenco cani, scheda cane, caricamento di una foto.

SICUREZZA — PRIMA DI PUBBLICARE, NON DOPO
- Le regole di Firestore si scrivono e si testano con l'emulatore prima che
  l'indirizzo sia raggiungibile: lettura e scrittura negate a chi non è
  autenticato, su tutte le collezioni, compresi documenti e allegati.
- Test automatico che prova a leggere senza autenticazione e si aspetta un rifiuto.
  Questo test si scrive per primo, prima del codice web.
- Il dominio nuovo va aggiunto ai domini autorizzati di Firebase Auth, altrimenti
  il login sul web non parte proprio.
- La chiave API di Firebase nel bundle web è pubblica per progetto, è normale e non
  è un segreto: quello che protegge i dati sono le regole. Assicurati che sia vero.
- robots.txt e meta noindex, così l'indirizzo non finisce nei risultati di Google.
  Non è sicurezza — la sicurezza sono le regole — ma evita che il rifugio compaia
  nelle ricerche di chi non lo sta cercando.

GESTIONE UTENTI — DEVE CONTINUARE A FUNZIONARE DALL'APP
- Gli account li crea il presidente dalle Impostazioni dell'app, mai dalla console
  Firebase. Il meccanismo è già progettato (sezione 14-ter.8): creazione su una
  seconda istanza Firebase temporanea, così la sessione di chi sta creando non
  viene sostituita da quella del nuovo utente.
- Verifica che quel meccanismo funzioni anche sul web: Firebase.initializeApp con
  un nome secondario è supportato, ma voglio un test che crei un utente e controlli
  che la sessione del presidente sia ancora quella di prima. Non darlo per scontato.
- Il reset password via email deve funzionare dal web: il link arriva da Firebase e
  apre una pagina sua, quindi serve solo che il dominio nuovo sia fra quelli
  autorizzati in Auth.
- Nella console Firebase, sezione Authentication, attiva la protezione contro
  l'enumerazione delle email. Senza, chiunque dalla pagina di login capisce quali
  indirizzi sono registrati provandoli uno a uno, e con un indirizzo pubblico è un
  regalo che non serve fare. È un interruttore, gratis.
- Le regole Firestore non devono dipendere da mustChangePassword: quello è un
  controllo di interfaccia, non una barriera. La barriera è l'autenticazione più
  il campo attivo.

COSE DA METTERE NEL PIANO ESPLICITAMENTE
- manifest PWA con nome, nome breve, icone 192 e 512 anche maskable, colore tema
  verde dell'app, display standalone
- i meta tag che servono a iOS in index.html: apple-touch-icon e la modalità
  standalone, altrimenti l'icona sulla Home viene brutta e l'app si apre dentro
  Safari con la barra
- service worker con la versione che cambia a ogni deploy, così chi ha già aperto
  l'app si ritrova la versione nuova invece di una vecchia in cache
- persistenza della cache di Firestore sul web, richiesta esplicitamente al browser
- larghezza massima del contenuto sui schermi grandi
- inventario dei punti dove il codice usa dart:io, percorsi di file, apertura di
  file esterni o notifiche locali: sono quelli che sul web esplodono, e vanno
  elencati PRIMA di programmare, non scoperti a metà
- procedura di deploy in tre righe che possa rifare anche io da solo

QUANDO CONSIDERARLO FINITO
- l'app web si apre su Safari di un iPhone vero, si installa dalla Home, fa il
  login e mostra i cani
- si carica una foto dall'iPhone e compare su Android entro pochi secondi
- l'APK Android, ricompilata da questo branch, funziona esattamente come prima
- un utente non autenticato non legge nulla, e c'è un test che lo dimostra
- su un portatile l'app è leggibile e non spalmata
```

---

## Un'avvertenza su come tenerlo corto

Superpowers è bravo ma prolisso: se lo lasci fare, il brainstorming ti porta a progettare
anche le notifiche push, il tema chiaro e scuro del web e la sincronizzazione offline perfetta.
Quando lo vedi allargarsi, riportalo con una riga:

> Questo è fuori dalla prima versione. Mettilo in una lista "dopo" e torniamo al minimo che
> serve: iPhone che apre l'app, fa login e lavora.

La prima versione che vale è quella che i volontari con l'iPhone possono usare lunedì. Tutto
il resto viene dopo, e viene meglio, perché a quel punto avrai gente vera che la usa e ti dice
cosa manca davvero.
