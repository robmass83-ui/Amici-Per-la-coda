# Evidenza merge web-pwa

Branch: `feature/web-pwa`
Data: 20/09/2026

## 1. APK di questo branch su telefono vero

- Comando: `flutter build apk --release` (questo branch, non `main`)
- Esito build: **FAIL** (exit code 1) — 20/09 prima del clean
- Esito build dopo `flutter clean` + `flutter build apk --release` (20/09 sera): **PASS** `√ Built build\app\outputs\flutter-apk\app-release.apk (40.4MB)`
- Causa del fail precedente: compile incrementale di `mobile_scanner` 7.4.0 senza `MobileScannerPlugin.class` nel jar (AGP 9.1 / `android.builtInKotlin=false`). Dopo `compileReleaseKotlin --rerun-tasks` e un clean, la classe c’è e l’APK esce.
- Errore reale:

```text
android\app\src\main\java\io\flutter\plugins\GeneratedPluginRegistrant.java:79: error: cannot find symbol
flutterEngine.getPlugins().add(new dev.steenbakker.mobile_scanner.MobileScannerPlugin());
symbol: class MobileScannerPlugin
location: package dev.steenbakker.mobile_scanner
Execution failed for task ':app:compileReleaseJavaWithJavac'.
Gradle task assembleRelease failed with exit code 1
```

- Telefono: **OK** (20/09/2026, committente: installata `1.0.5+46`, funziona come prima)
- Release: https://github.com/robmass83-ui/Amici-Per-la-coda/releases/tag/v1.0.5%2B46 (`1.0.5+46`, Latest, SHA-256 PC = GitHub)
- Login / elenco / scheda / foto: **OK** (stessa conferma: «funziona bene come prima»)
- Diverso da prima?: **no**

Condizione 1 attestata.

## 2. Test automatici, compreso anonimo

### Regole Firestore

Comando eseguito da `backend/` con il JBR di Android Studio (OpenJDK 25):

```text
npx --yes firebase-tools emulators:exec --only firestore --project amici-per-la-coda "npm run test:rules"
```

Esito: **PASS** (exit code 0).

Output reale conclusivo:

```text
✔ anonimo non legge dogs/fenice
✔ anonimo non aggiorna dogs/fenice
✔ anonimo non legge photos/p1
✔ anonimo non aggiorna photos/p1
✔ anonimo non legge photos/p1/full/data
✔ anonimo non aggiorna photos/p1/full/data
✔ anonimo non legge health/h1
✔ anonimo non aggiorna health/h1
✔ anonimo non legge weights/w1
✔ anonimo non aggiorna weights/w1
✔ anonimo non legge sponsorships/s1
✔ anonimo non aggiorna sponsorships/s1
✔ anonimo non legge expenses/e1
✔ anonimo non aggiorna expenses/e1
✔ anonimo non legge adopters/a1
✔ anonimo non aggiorna adopters/a1
✔ anonimo non legge vendors/v1
✔ anonimo non aggiorna vendors/v1
✔ anonimo non legge adoptions/ad1
✔ anonimo non aggiorna adoptions/ad1
✔ anonimo non legge documents/d1
✔ anonimo non aggiorna documents/d1
✔ anonimo non legge documents/d1/chunks/0
✔ anonimo non aggiorna documents/d1/chunks/0
✔ anonimo non legge templates/t1
✔ anonimo non aggiorna templates/t1
✔ anonimo non legge notes/n1
✔ anonimo non aggiorna notes/n1
✔ anonimo non legge appointments/ap1
✔ anonimo non aggiorna appointments/ap1
✔ anonimo non legge volunteers/vol-1
✔ anonimo non aggiorna volunteers/vol-1
✔ anonimo non legge authTokens/vol-1
✔ anonimo non aggiorna authTokens/vol-1
✔ anonimo non legge boxes/b1
✔ anonimo non aggiorna boxes/b1
✔ anonimo non legge settings/association
✔ anonimo non aggiorna settings/association
✔ anonimo non legge dogDrafts/vol-1
✔ anonimo non aggiorna dogDrafts/vol-1
✔ anonimo non legge searchRecents/vol-1
✔ anonimo non aggiorna searchRecents/vol-1
✔ anonimo non elenca dogs
✔ anonimo non crea in dogs
✔ anonimo non elenca photos
✔ anonimo non crea in photos
✔ anonimo non elenca health
✔ anonimo non crea in health
✔ anonimo non elenca weights
✔ anonimo non crea in weights
✔ anonimo non elenca sponsorships
✔ anonimo non crea in sponsorships
✔ anonimo non elenca expenses
✔ anonimo non crea in expenses
✔ anonimo non elenca adopters
✔ anonimo non crea in adopters
✔ anonimo non elenca vendors
✔ anonimo non crea in vendors
✔ anonimo non elenca adoptions
✔ anonimo non crea in adoptions
✔ anonimo non elenca documents
✔ anonimo non crea in documents
✔ anonimo non elenca templates
✔ anonimo non crea in templates
✔ anonimo non elenca notes
✔ anonimo non crea in notes
✔ anonimo non elenca appointments
✔ anonimo non crea in appointments
✔ anonimo non elenca volunteers
✔ anonimo non crea in volunteers
✔ anonimo non elenca authTokens
✔ anonimo non crea in authTokens
✔ anonimo non elenca boxes
✔ anonimo non crea in boxes
✔ anonimo non elenca settings
✔ anonimo non crea in settings
✔ anonimo non elenca dogDrafts
✔ anonimo non crea in dogDrafts
✔ anonimo non elenca searchRecents
✔ anonimo non crea in searchRecents
ℹ tests 99
ℹ suites 0
ℹ pass 99
ℹ fail 0
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 22438.7066
+  Script exited successfully (code 0)
```

Le righe `PERMISSION_DENIED` emesse durante la suite corrispondono ai rifiuti attesi verificati dai test anonimi.

### Differenza regole

Comando:

```text
git diff -- backend/firestore.rules
```

Output: vuoto. Exit code 0.

### Flutter analyze

Esito (20/09 sera, dopo pulizia import + formal router): **PASS** (`No issues found`).

### Flutter test

Suite intera 20/09 sera, prima del merge:

```text
01:01 +595 ~3: All tests passed!
```

`flutter analyze`: No issues found.

Parziale precedente (storico):

- `firestore_rules_appointments_test` **PASS** (JDK 21+: si usa JBR 25 invece di `JAVA_HOME` 17)
- `dog_detail_page_test` **PASS** (tab Adozione ora cerca `Annuncio pubblico`; `Iter di adozione` è stato rimosso in un task precedente)
- `dogs_list_golden_test` **PASS** (PNG aggiornato 20/09 dopo ok visivo committente)
- `edit_dog_golden_test` **PASS** (stesso ok visivo)

La suite Flutter completa non è stata rilanciata in questo aggiornamento. Analyze è pulito; i 4 fail noti sono verdi.

### Flutter build web

Esito: **PASS** (exit code 0).

```text
Compiling lib\main.dart for the Web... 135,4s
√ Built build\web
```

## 3. iPhone vero

- Safari → Condividi → Aggiungi a Home: **OK** (20/09/2026)
- Apertura da icona (standalone): **OK** (stessa conferma)
- Login: **OK**
- Elenco cani visibile: **OK**
- Foto iPhone → compare su Android: **OK** (committente: visti cani e foto)

Condizione 3 attestata su iPhone vero (Home + standalone + login + cani + foto).

### 3b. Android PWA (extra, non sostituisce il cancello)

- Chrome → sito → Aggiungi a Home / Installa: **OK** (confermato dal committente il 20/09/2026)
- Apertura da icona, login, elenco cani: **OK** (stessa conferma, senza dettaglio foto)
- Non è un’installazione APK di questo branch

## 4. Portatile

- Viewport > 430: colonna centrata, `AppColor.bg` ai lati: **NOT RUN**
- Nessuno scroll orizzontale: **NOT RUN**

## 5. Console senza login

- `get` su `dogs/{id}` → `permission-denied`: **NOT RUN**

Nota: la verifica manuale in console non è sostituita dalla suite automatica delle regole.

## Verdetto

- [x] Tutte e tre le condizioni del cancello sono vere
- [x] Il committente ha detto esplicitamente di unire a main

**OK unire.** 20/09 committente: «ok unisci a main». Condizione 1 APK `1.0.5+46` sul telefono come prima. Condizione 2: regole 99/99, `flutter analyze` pulito, `flutter test` +595 ~3. Condizione 3 iPhone ok. Portatile e console Firestore restano NOT RUN (non bloccano le tre).
