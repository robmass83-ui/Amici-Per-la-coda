# Amici per la Coda

Gestionale interno del rifugio cani **Amici per la Coda ODV**.
App Android (Flutter), backend Firebase Auth + Cloud Firestore sul piano gratuito Spark.
Non va su nessuno store: si installa l'APK a mano sui 3–4 telefoni dei volontari.

La specifica vincolante è [`AMICI-PER-LA-CODA_SPEC.md`](AMICI-PER-LA-CODA_SPEC.md).
Il riferimento visivo è `design/reference.html`.

- **Frontend:** progetto Flutter in radice (`lib/`)
- **Backend:** regole e indici in `backend/`
- **Pacchetto Android:** `it.amiciperlacoda.amici_per_la_coda`
- **Versione:** vedi `version:` in `pubspec.yaml` (nome+codice, es. `1.0.5+25`)

---

## Per i volontari — installazione

Non serve un computer. Serve solo l'APK e l'email che ti ha dato il presidente.

### Prima installazione

1. Ricevi il file `app-arm64-v8a-release.apk` (telefoni recenti) oppure
   `app-armeabi-v7a-release.apk` (telefoni più vecchi) da un altro volontario
   (**Altro → Condividi app**) oppure dal presidente.
2. Aprilo. Android chiede di **consentire l'installazione da origini sconosciute**
   per l'app da cui l'hai aperto (WhatsApp, Files, Gmail, Chrome…). Accetta solo per quella.
3. Installa **Amici per la Coda**. Non disinstallare se l'avevi già: i dati restano.
4. All'avvio inserisci **email** e **password** ricevute dal presidente. Al primo
   accesso l'app può chiederti di cambiare la password.
5. Se compare «Il tuo account non è ancora attivo», il documento volontario non è
   stato creato: scrivi al presidente.

### Aggiornamenti successivi

All'apertura l'app controlla GitHub Releases. Se c'è una versione nuova compare
il foglio **Installa**. Non serve scaricare a mano.

In alternativa: **Altro → Aggiornamenti**, oppure fai installare di nuovo l'APK
condiviso da un telefono già aggiornato.

### Disinstallare e reinstallare

I cani, le foto, le richieste e le note stanno su Firestore, non sul telefono.
Disinstallando perdi solo la sessione e la cache locale: dopo il login i dati
ricompaiono. Utile se Android rifiuta un aggiornamento per firma diversa
(in quel caso disinstalla **una volta sola** e reinstalla).

---

## Per chi sviluppa — setup Firebase

Progetto dedicato `amici-per-la-coda`, regione Firestore `eur3` (europe-west).
**Non attivare Firebase Storage**: dal 2024 richiede il piano Blaze. Le foto
si comprimono e stanno in Firestore.

1. Console Firebase → **Aggiungi progetto** → nome `amici-per-la-coda`.
   È un progetto nuovo: non condividere il database con altri prodotti.
2. Disattiva Google Analytics (non serve).
3. **Authentication** → Sign-in method → abilita **Email/Password**.
4. **Firestore Database** → Crea database → modalità produzione → regione `eur3`.
5. Pubblica regole e indici dalla cartella `backend/`:

   ```bash
   firebase deploy --only firestore:rules,firestore:indexes --project amici-per-la-coda
   ```

   I file sono `backend/firestore.rules` e `backend/firestore.indexes.json`.
6. Crea il **primo utente presidente** (gli altri si creano dall'app):
   - Authentication → Add user → email + password.
   - Copia l'**UID**.
   - Firestore → collezione `volunteers` → documento con ID = UID:

   ```
   nome:               (string)
   cognome:            (string)
   email:              (string, stessa dell'Auth)
   ruolo:              "presidente"   |  "referente"  |  "volontario"
   attivo:             true
   coloreAvatar:       "#157A3C"
   mustChangePassword: false
   createdAt / updatedAt: Timestamp
   createdBy / updatedBy: UID
   ```

   Senza `volunteers/{uid}` con `attivo: true` l'app mostra il blocco account.
7. Nel progetto Flutter (già fatto in questo repo):
   `dart pub global activate flutterfire_cli` poi `flutterfire configure`.
   Il file `android/app/google-services.json` deve restare nel repo.
8. Gli indici della specifica: se una query fallisce, Firestore propone un link.
   Quelli noti sono già in `backend/firestore.indexes.json`.

**Quote Spark:** 1 GiB dati, 50.000 letture / 20.000 scritture / 20.000
cancellazioni al giorno. Con 4 utenti e ~50 cani si sta larghi.

### Altri volontari dopo il primo presidente

Dall'app: **Altro → Impostazioni → Utenti**. Il presidente crea email, password
temporanea e ruolo (volontario o responsabile). L'app scrive Auth + `volunteers/{uid}`
con `mustChangePassword: true`. Non serve più la console, tranne per sbloccare
un account o reimpostare una password persa.

---

## Firma di rilascio (keystore)

I telefoni hanno già l'app firmata con **questa** chiave. Non generarne un'altra.

| | |
|---|---|
| File locale | `%USERPROFILE%\.android\debug.keystore` |
| Alias | `androiddebugkey` |
| Password store/chiave | `android` (default Android) |
| SHA-256 del certificato | `1aa1211e900e794873ea1632ed09f5ce116e20f87010d96a9ecbf699c9d68fe2` |

- Copia di backup del `.keystore` su una chiavetta / password manager del presidente.
  Se si perde, l'unico modo per aggiornare è disinstallare e reinstallare.
- Modello locale: copia `android/key.properties.example` → `android/key.properties`
  (gitignored). La CI usa il secret `ANDROID_DEBUG_KEYSTORE_BASE64` e le env
  `ANDROID_KEYSTORE_PATH` / `ANDROID_KEYSTORE_PASSWORD` / `ANDROID_KEY_ALIAS` /
  `ANDROID_KEY_PASSWORD`.
- Il workflow `.github/workflows/release-apk.yml` rifiuta un APK con certificato
  diverso da quello in tabella.

---

## Build di rilascio

APK **split per ABI**, firmati, ciascuno sotto **30 MB**:

```bash
flutter build apk --release --split-per-abi
```

Escono in `build/app/outputs/flutter-apk/`:

- `app-arm64-v8a-release.apk` — quasi tutti i telefoni attuali (~18 MB)
- `app-armeabi-v7a-release.apk` — 32 bit (~17 MB)
- `app-x86_64-release.apk` — emulatore; non si distribuisce ai volontari

Per mettere **lo stesso** binario su GitHub Latest e sul telefono collegato (ADB),
senza `flutter run` e senza un secondo `versionCode`:

```powershell
powershell -File tool/publish_test_release.ps1
```

Se pubspec e GitHub Latest coincidono ma il binario è cambiato (minify, firma, risorse):

```powershell
powershell -File tool/publish_test_release.ps1 -Force
```

`flutter run` (debug) ha un `versionCode` più basso: Android rifiuta l'installazione
sopra la release e l'updater in-app mostrerebbe «Nuova versione».

La release abilita R8 (`minify` + `shrinkResources`) in `android/app/build.gradle.kts`.

---

## Test

```bash
flutter analyze
flutter test
```

Regole Firestore (emulatore, da `backend/`):

```bash
npm test --prefix backend
```

Uno step della specifica è chiuso solo con analyze a 0 issue e test verdi.

---

## Cartelle utili

| Percorso | Contenuto |
|---|---|
| `lib/` | App Flutter |
| `android/` | Progetto Android, firma, splash, `google-services.json` |
| `backend/` | `firestore.rules`, indici, test regole |
| `assets/` | Logo, moduli PDF, font Roboto |
| `tool/publish_test_release.ps1` | Un solo APK su pubspec, GitHub e ADB |
