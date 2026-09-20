# Evidenza merge web-pwa

Branch: `feature/web-pwa`
Data: 20/09/2026

## 1. APK di questo branch su telefono vero

- Comando: `flutter build apk --release` (questo branch, non `main`)
- Esito build: **FAIL** (exit code 1)
- Errore reale:

```text
android\app\src\main\java\io\flutter\plugins\GeneratedPluginRegistrant.java:79: error: cannot find symbol
flutterEngine.getPlugins().add(new dev.steenbakker.mobile_scanner.MobileScannerPlugin());
symbol: class MobileScannerPlugin
location: package dev.steenbakker.mobile_scanner
Execution failed for task ':app:compileReleaseJavaWithJavac'.
Gradle task assembleRelease failed with exit code 1
```

- Telefono: **NOT RUN**
- Login: **NOT RUN**
- Elenco cani: **NOT RUN**
- Scheda cane: **NOT RUN**
- Upload foto: **NOT RUN**
- Diverso da prima?: **NOT RUN**

La build APK non è stata prodotta; non è quindi possibile attestare la condizione 1.

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

Esito: **FAIL** (exit code 1).

```text
warning - Unused import: 'package:amici_per_la_coda/ui/components.dart' - test\features\dogs\step14_ter4_test.dart:13:8 - unused_import
warning - Unused import: 'package:flutter/material.dart' - test\features\vendors\vendors_page_test.dart:8:8 - unused_import
2 issues found. (ran in 117.4s)
```

### Flutter test

Esito: **FAIL** (exit code 1).

```text
01:17 +583 ~3 -4: Some tests failed.

Failing tests:
  test/data/firestore_rules_appointments_test.dart: le regole Firestore passano con l'emulatore
  test/features/dogs/dog_detail_page_test.dart: tap su ogni tab cambia contenuto
  test/golden/dogs_list_golden_test.dart: Elenco cani — aspetto bloccato a 360×640
  test/golden/edit_dog_golden_test.dart: Modifica cane — aspetto bloccato a 360×640
```

La condizione 2 non è soddisfatta: la suite regole dedicata passa, ma `flutter analyze` e `flutter test` sono rossi.

### Flutter build web

Esito: **PASS** (exit code 0).

```text
Compiling lib\main.dart for the Web... 135,4s
√ Built build\web
```

## 3. iPhone vero

- Safari → Condividi → Aggiungi a Home: **NOT RUN**
- Apertura da icona (standalone): **NOT RUN**
- Login: **NOT RUN**
- Elenco cani visibile: **NOT RUN**
- Foto iPhone → compare su Android: **NOT RUN**

La condizione 3 non è attestata.

## 4. Portatile

- Viewport > 430: colonna centrata, `AppColor.bg` ai lati: **NOT RUN**
- Nessuno scroll orizzontale: **NOT RUN**

## 5. Console senza login

- `get` su `dogs/{id}` → `permission-denied`: **NOT RUN**

Nota: la verifica manuale in console non è sostituita dalla suite automatica delle regole.

## Verdetto

- [ ] Tutte e tre le condizioni del cancello sono vere
- [ ] Il committente ha detto esplicitamente di unire a main

**STOP — vietato unire.** Sono passati i 99 test delle regole Firestore e la build web; APK, analisi e test Flutter sono rossi, mentre tutte le verifiche su dispositivi reali, portatile e console sono non eseguite.
