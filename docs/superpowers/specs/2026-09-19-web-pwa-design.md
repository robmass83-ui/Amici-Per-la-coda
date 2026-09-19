# Versione web (PWA) di Amici per la Coda

Data: 2026-09-19
Progetto: Amici per la Coda
Stato: approvato in brainstorming (approccio 1)

## Problema

L’app gira solo come APK Android installata a mano. Alcuni volontari hanno iPhone. Non si pubblica su App Store e non si aprono account o abbonamenti nuovi. Serve la stessa app su Firebase Hosting, da aggiungere alla Home di Safari, senza cambiare il comportamento dell’APK già installata e senza indebolire la protezione dei dati personali (CF, indirizzi, telefoni) ora che l’indirizzo diventa pubblico.

## Decisioni bloccate

- Target: **web**, non app desktop nativa. Decisione chiusa.
- Approccio 1: stesso progetto Flutter, target web affiancato. Niente secondo repo, niente sostituzione di plugin Android con versioni “vanno ovunque”.
- Chi usa cosa: Android resta sull’APK; iPhone e computer usano il web. Stesso Firestore, stesse funzioni, stessi dati.
- Perimetro: tutte le funzioni possibili senza librerie nuove. Se una funzione sul web è sproporzionata (es. preview PDF pesante), si degrada in modo visibile e si dice prima di toccare codice condiviso.
- Notifiche web: fuori dalla prima versione.
- Offline web: cache Firestore richiesta esplicitamente; caso d’uso wifi/4G. Offline da giorni/settimane resta sull’APK. Safari può cancellare lo storage.
- Layout computer: colonna centrale con larghezza massima, resto sfondo. Non stirare le schermate a tutto schermo.
- URL: `amici-per-la-coda.web.app` (o `.firebaseapp.com`). Niente dominio a pagamento, niente hosting terzo.
- Barriera dati: non loggato = zero letture e zero scritture. Test emulator su tutte le collezioni. Non si testano in questa versione gli account Auth creati in autonomia, né si spegne `signUp` in console (romperebbe la creazione volontari dal presidente).
- `firestore.rules`: intatto se i test anonimi sono verdi. Se un test trova un buco da anonimo, stop e si valuta insieme (potrebbe servire un’APK nuova).
- Accorgimenti pubblici: `robots.txt` + meta noindex; in console Auth, protezione enumerazione email.
- Fatto quando: iPhone vero (Safari → Home → login → cani); una foto iPhone compare su Android; APK dello stesso branch provata a mano (login, elenco, scheda, foto); test anonimo verde; portatile non stirato.

## Vincoli

1. L’APK non cambia comportamento. Se un pacchetto Android oggi funziona, non si toglie e non si sostituisce: si affianca un’implementazione web e si sceglie a runtime.
2. Ogni modifica a codice condiviso si dichiara **prima** di farla.
3. Schema Firestore solo additivo. Semantica dei campi esistenti invariata. Se non è compatibile con l’APK vecchia: stop.
4. Budget zero. Progetto Firebase `amici-per-la-coda`, piano Spark. Niente Storage, niente Functions, niente servizi nuovi.
5. Niente librerie fuori da `pubspec.yaml` attuale.
6. Token di layout solo da `lib/ui/tokens.dart`. Testi in italiano.
7. Non si pubblica l’indirizzo finché i test anonimi delle regole non sono verdi.

## Fuori da questa versione

- Notifiche push web (FCM, VAPID, service worker dedicato alle push).
- Dominio personalizzato.
- Offline da settimane / coda di scritture web nuova.
- Spegnere la registrazione pubblica Auth.
- Test o hardening contro account Auth orfani (self-signup): le regole già li tengono fuori via `attivo()`, ma non è il paletto di questa versione.
- Dialog “nuova versione” copiato dall’updater APK.
- Simulatore iOS al posto del telefono vero.
- Golden test per ogni schermata web.

---

## 1. Architettura

Un solo progetto Flutter. Si aggiunge il target web. Si pubblica `flutter build web` su Firebase Hosting del progetto già esistente.

```
Safari / Chrome PC
    → Firebase Hosting (build/web, HTTPS)
        → Flutter web (stesso lib/ dell'APK)
            → Firebase Auth (email/password)
            → Cloud Firestore (stesso database dell'APK)
```

Android continua a parlare con Auth e Firestore come oggi. Nessun campo nuovo obbligatorio. Nessuna collezione nuova.

**Scelta a runtime.** Dove il codice Android usa `dart:io`, canali nativi, `open_filex`, `gal`, `flutter_local_notifications`, updater APK: si aggiunge un’implementazione web (no-op o API del browser) dietro le interfacce già esistenti. I file Android restano. Preferire import condizionali (`*_io.dart` / `*_web.dart`) o `kIsWeb` nei provider, non un fork delle schermate.

**File condivisi che si dovranno toccare** (dichiarare di nuovo al momento):

| File | Perché |
|---|---|
| `lib/firebase_options.dart` | Aggiungere solo il blocco `web`. Il blocco `android` non si tocca. |
| `lib/main.dart` | Oggi inizializza timezone e notifiche native. Sul web: no-op. |
| `lib/data/data_providers.dart` | Agganciare le implementazioni web delle interfacce esistenti. |
| `lib/data/firestore/firestore_repositories.dart` (`enableFirestoreOffline`) o un wrapper | Persistenza web esplicita. |
| `lib/data/firestore/identity_toolkit_api.dart` | Oggi `dart:io` `HttpClient`. Split condizionale, contratto invariato. |
| `lib/ui/tokens.dart` | Un token nuovo per la larghezza massima della colonna. |
| `lib/app.dart` o lo shell | Wrapper colonna centrale, attivo solo su schermi larghi / web. |
| `lib/features/auth/login_page.dart` | Due righe “Aggiungi a Home”, solo web/Safari non standalone. |
| `lib/features/settings/altro_page.dart` e listener updater | Nascondere “condividi APK” e non invocare il MethodChannel sul web. |
| `backend/firebase.json` | Aggiungere `hosting`. Non toccare `firestore.rules`. |
| `pubspec.yaml` | Solo se Flutter richiede un tocco di tooling web. Vietato aggiungere/rimuovere/sostituire pacchetti. |

File nuovi ammessi: `web/` (index, manifest, icone, robots), implementazioni `*_web.dart`, test regole anonimo, eventuale script di deploy in `tool/`.

**Hosting.** Configurazione in `backend/firebase.json` (già file del progetto Firebase), `public` = `../build/web`. Il `firebase.json` in radice resta il mapping FlutterFire: non si mescola con Hosting. Deploy: `firebase deploy --only hosting` dal contesto `backend/`.

---

## 2. Sicurezza (prima di pubblicare)

Le regole attuali già richiedono `request.auth != null` **e** `volunteers/{uid}.attivo == true` per quasi ogni lettura. `mustChangePassword` non entra nelle regole.

**Test da scrivere per primi** in `backend/tests/`, stesso stile di `roles.rules.test.mjs`. Contesto `unauthenticatedContext()`. Per ogni collezione sotto: `get` di un documento noto, `list`/`get` della collezione, `set`/`update`. Tutti `assertFails`.

Collezioni e path obbligatori:

- `dogs`
- `photos` e `photos/{id}/full/data`
- `health`, `weights`, `sponsorships`, `expenses`
- `adopters`, `vendors`, `adoptions`
- `documents` e `documents/{id}/chunks/{n}`
- `templates`, `notes`, `appointments`
- `volunteers`, `authTokens`, `boxes`
- `settings/association`
- `dogDrafts`, `searchRecents`

I test ruoli/note/foto/volontari già esistenti restano verdi. `firestore.rules` non si modifica se questi test passano. Se uno fallisce: stop, niente deploy, si valuta se una regola nuova è compatibile con l’APK vecchia.

**Console Firebase (operazioni, non codice):**

1. Aggiungere `amici-per-la-coda.web.app` e `amici-per-la-coda.firebaseapp.com` ai domini autorizzati di Auth. Senza, login e reset password sul web non partono.
2. Attivare la protezione contro l’enumerazione delle email. Effetto possibile anche sull’APK: messaggi login meno distinti (“email o password non corretti”). Non è una modifica di codice; va detto al momento dell’attivazione se i testi sull’APK cambiano.

**Non è un segreto.** La apiKey nel bundle web è pubblica per progetto. La barriera sono le regole, dimostrate dai test.

**Non-sicurezza, da fare comunque:** `web/robots.txt` (`User-agent: *` / `Disallow: /`) e meta `noindex` in `web/index.html`.

---

## 3. Componenti

Niente interfacce nuove. Si implementano quelle già usate e si scelgono in `data_providers.dart`.

| Interfaccia | Android (invariato) | Web |
|---|---|---|
| `DocumentFilePicker` | `device_document_file_picker.dart` | Stesso `file_picker` / `image_picker` se il plugin gira in browser; altrimenti implementazione web sulla stessa interfaccia (`<input type=file>`). Niente pacchetto nuovo. |
| `FileShare` / `FileOpener` | `device_file_actions.dart` (`share_plus`, `open_filex`, `dart:io`) | Download o scheda nuova. Zero `dart:io`. |
| `GallerySaver` | `gal` | Download del file o no-op con messaggio chiaro. |
| `LocalNotifications` | plugin nativo | `NoopLocalNotifications` già esistente. |
| Identity Toolkit | `HttpClient` `dart:io` | Stessa REST, client HTTP del browser, stesso contratto `createUserAccount`. |
| Updater APK / condividi APK | MethodChannel + file locali | Non si mostrano, non si chiamano. |

`photo_codec.dart` ha già `kIsWeb` e non usa il plugin nativo sul web: non si riscrive.

**PWA**

- `manifest.json`: nome “Amici per la Coda”, nome breve, icone 192 e 512 anche maskable, `theme_color` / `background_color` = verde `#157A3C` e sfondo `#F5F7F3`, `display: standalone`.
- `index.html`: `apple-touch-icon`, `apple-mobile-web-app-capable` / standalone, viewport, noindex.
- Service worker: quello generato da `flutter build web`. La versione/hash cambia a ogni build, così un deploy nuovo non lascia la shell vecchia. Non si aggiunge un secondo SW (servirebbe alle push, che sono fuori scope).
- Installazione: solo manuale da Safari (Condividi → Aggiungi a Home). Niente prompt automatico. Sulla login, solo se web e non già standalone: due righe di istruzione.

**Colonna computer**

Nuovo token `AppDim.webMaxContentWidth = 430` (la larghezza massima già verificata sulle schermate telefono). Wrapper che su viewport più larga centra la colonna e riempie i lati con `AppColor.bg`. Su viewport ≤ 430: larghezza piena, identica all’APK. Nessuno scroll orizzontale.

**Creazione volontari e reset password**

Stesso flusso della spec 14-ter.8: seconda app Firebase temporanea / Identity Toolkit, sessione del presidente intatta. Test: dopo `createUserAccount`, `currentUser` è ancora il creatore. Reset: pagina Firebase, dominio nuovo in lista autorizzati.

---

## 4. Flusso dati

1. Hosting serve `build/web`. Eventuale SW serve la shell in cache.
2. `bootstrapFirebase` usa `DefaultFirebaseOptions.web`. Persistenza Firestore richiesta in modo esplicito; se il browser rifiuta, l’app resta online-only e non crasha.
3. Senza sessione: solo login. Nessuna query Firestore dall’UI.
4. Login email/password. Le regole ammettono i dati solo se esiste `volunteers/{uid}` con `attivo == true`.
5. Letture/scritture: stessi repository di oggi. Ruoli invariati (volontario legge e crea note; presidente/referente scrivono).
6. Foto: picker → `photo_codec` (ramo web) → `photos/{id}` + `photos/{id}/full/data` nello stesso database. L’APK in ascolto mostra la thumb in pochi secondi. Stessi tetti di size già in regole. Niente Storage.
7. Documenti/moduli: byte in memoria → stesso schema. Apertura web = download o scheda nuova.
8. Offline breve: cache Firestore. Se Safari svuota lo storage, al login successivo si riscarica. Nessuna coda write nuova sul web. La coda Android non si tocca.

Schema: vietato cambiare significato di campi esistenti. Vietato rendere obbligatorio un campo che l’APK vecchia non scrive. Campi nuovi solo se additivi e ignorati dall’APK: in questa versione non ne servono.

---

## 5. Errori

| Caso | Comportamento |
|---|---|
| Non autenticato, console browser | `permission-denied` su ogni path. UI = login. |
| Volontario inattivo | Zero dati, come oggi. |
| Password sbagliata | Testi italiani esistenti. Con enumerazione email protetta: messaggio unico “email o password non corretti”, anche sull’APK (effetto backend). |
| Niente rete, cache presente | Si mostra la cache. |
| Niente rete, cache assente | Errore rete già previsto. Non si finge l’offline lungo. |
| Persistenza rifiutata | Online-only, no crash. |
| Picker annullato | Nessuna write. |
| Foto/file oltre i limiti o write negata | Errore/toast come oggi, niente documento a metà. |
| PDF/share web fallisce | Fallback scarica / apri scheda. Se serve toccare la preview condivisa: stop e si dice prima. |
| Creazione volontario che ruba la sessione | Test rosso → non si pubblica. |
| SW su build vecchia | Nuovo deploy = nuovo hash Flutter. L’utente ricarica o riapre dalla Home. Niente dialog updater in v1. |
| Test anonimo rosso | Niente deploy. Si valuta una regola nuova solo se compatibile con l’APK vecchia. |

Non si allargano i messaggi di errore delle schermate Android “per il web”.

---

## 6. Test e definizione di finito

**Ordine.** Prima i test regole anonimo. Poi il resto. Rossi → niente codice web, niente URL pubblico.

**Automatici**

- `backend/tests/` anonimo su tutti i path della sezione 2.
- Test ruoli/note/foto/volontari esistenti verdi.
- `flutter analyze` pulito, `flutter test` verde.
- `flutter build apk --release` compila alla fine di **ogni** task di implementazione, non solo alla fine.
- Golden Android: non si rigenerano. Il wrapper 430 è web/viewport larga; i pixel telefono restano quelli approvati.
- Persistenza web: il percorso esplicito esiste; rifiuto browser non crasha.
- `main` sul web non inizializza il plugin notifiche nativo; si usa `NoopLocalNotifications`.
- Dopo `createUserAccount`, sessione = presidente.
- Implementazioni file web senza `import 'dart:io'`.

Non si aggiunge un golden per ogni pagina web.

**Manuali, obbligatori prima del link ai volontari**

1. iPhone vero: Safari → Aggiungi a Home → login → elenco cani.
2. Una foto caricata da quell’iPhone compare sull’APK in pochi secondi.
3. APK ricompilata da questo branch, telefono vero: login, elenco, scheda, upload foto.
4. Portatile: colonna 430, sfondo ai lati, niente stiramento.
5. Console PC senza login: una `get` Firestore fallisce.

**Fuori dai test di questa versione:** push web; “riapro tra tre settimane e i dati ci sono”; simulatore al posto dell’iPhone.

---

## 7. Metodo di lavoro (per il piano)

- Branch o worktree separato. `main` non si tocca finché il lavoro non è approvato.
- Prima di iniziare l’implementazione: una build APK release dal codice attuale, tenuta da parte come via di fuga.
- Inventario completo dei punti `dart:io` / file / notifiche / MethodChannel **prima** di programmare gli adattatori, non a metà.
- Ogni volta che si sta per modificare un file della tabella in sezione 1: dirlo prima.
- Procedura di deploy in tre righe, ripetibile a mano: `flutter build web` → `firebase deploy --only hosting` dal contesto `backend/` → verifica URL.
- Dopo una modifica da provare sul telefono Android: `tool/publish_test_release.ps1` solo se il binario Android è cambiato. Se il task è solo `web/` + Hosting e l’APK non è cambiata, non si pubblica una release GitHub nuova.

---

## 8. Criterio di accettazione (checklist)

- [ ] Test anonimo verde su tutte le collezioni elencate; `firestore.rules` invariato (oppure stop concordato).
- [ ] Dominio Hosting in Auth; enumerazione email protetta; robots + noindex.
- [ ] PWA: manifest, icone, standalone iOS; installazione manuale da Safari.
- [ ] Login, elenco cani, scheda, lavoro quotidiano sul web senza librerie nuove.
- [ ] Foto iPhone → Android sullo stesso Firestore.
- [ ] Creazione volontario: sessione presidente intatta (test).
- [ ] Updater/condividi APK assenti sul web; notifiche web assenti; plugin notifiche non inizializzato sul web.
- [ ] Portatile: colonna `AppDim.webMaxContentWidth`.
- [ ] APK dallo stesso branch: analyze, test, build release, prova a mano invariata.
- [ ] URL `.web.app` raggiungibile solo dopo i punti sopra.
