# Pulizia della cartella di progetto

Data: 2026-09-19
Progetto: Amici per la Coda
Stato: approvato in brainstorming (approccio 2)

## Problema

La radice del repository è piena di file e cartelle che non fanno parte dell’app in esecuzione: prompt di costruzione, rapporti superati, PDF/zip/xlsx di import già eseguiti, duplicati dei moduli, output di test, cartelle vuote. In più, sul PC locale `build/` e `.dart_tool/` occupano circa 7,8 GB.

Questi file **non entrano nell’APK**. Flutter spedisce solo `lib/` e gli asset dichiarati in `pubspec.yaml`. La pulizia alleggerisce e ordina la cartella di lavoro; non cambia il binario sui telefoni.

## Decisioni bloccate

- Obiettivo: **A + B** — radice ordinata e spazio disco liberato, senza rompere app, test o un import futuro.
- Metodo: **split** — si cancella solo lo scarto ovvio; i documenti storici vanno in `docs/archive/`; gli script e i dati di import restano.
- Foto: **si tiene** `import/foto/` (circa 40 MB). Il guadagno disco arriva da `build/` e `.dart_tool/`.
- Approccio 2: radice = prodotto e lavoro quotidiano. Storia e one-off sotto `docs/`.
- Nessuno stub in radice dopo i due spostamenti live.
- Nessuna pubblicazione APK. Nessuna modifica di feature/UI. Nessun cambio agli asset di `pubspec.yaml`.

## Vincoli

- Non toccare un path che non è in questo documento.
- Non toccare `lib/` salvo commenti di path su `cani.csv`.
- Non toccare `assets/`, `android/` (codice/risorse), `test/`.
- Non cancellare `import/` (CSV, `README.md`, `anagrafe_src/`, `foto/`).
- Non cancellare `tool/import/*.mjs`, `package.json`, `package-lock.json`.
- Non toccare i segreti: `tool/import/serviceAccount.json`, `android/key.properties`.
- Testi dei file di progetto restano in italiano dove già lo sono.
- `flutter analyze` pulito e `flutter test` verde prima di dichiarare finito.

---

## 1. Radice dopo la pulizia

Restano in radice, invariati di ruolo:

| Path | Ruolo |
|---|---|
| `lib/`, `android/`, `assets/`, `test/` | App e test |
| `backend/` | Regole, indici, script (incluso `cani.csv` dopo lo spostamento) |
| `tool/` | `publish_test_release.ps1` e script di import |
| `import/` | Kit import, comprese le foto |
| `design/` | Riferimento visivo (`reference.html` + HTML di confronto) |
| `docs/` | Spec, plan, archivio, `documenti-cani.zip` |
| `.cursor/`, `.github/` | Regole e CI |
| `README.md` | Documentazione utente/sviluppatore |
| `AMICI-PER-LA-CODA_SPEC.md` | Specifica vincolante |
| `pubspec.yaml`, `pubspec.lock` | Pacchetto Flutter |
| `analysis_options.yaml` | Analyzer |
| `firebase.json` | Mapping FlutterFire |
| `.cursorrules`, `.gitignore`, `.metadata` | Tooling |

`design/` tiene anche i confronti HTML non tracciati (`confronto-popup.html`, `confronto-modifica-cane.html`, `scheda-adozione-export.html`, `scheda-adozione-foto.html`): sono riferimenti visivi, non scarto.

---

## 2. Inventario chiuso

### 2.1 Cancellare

| Path | Motivo |
|---|---|
| `New folder/` | Cartella vuota |
| `Moduli/` | Duplicato di `assets/moduli/` (`modulo-adozione.pdf`, `modulo-preaffido.pdf`) |
| `tmp/` | Output di `step18_ter`; i test ricreano la cartella se serve |
| `build/` | Cache Flutter, circa 5,4 GB, rigenerabile |
| `.dart_tool/` | Cache Dart/Flutter, circa 2,4 GB, rigenerabile |
| `tool/import/node_modules/` | Dipendenze npm, rigenerabili con `npm install` in `tool/import/` |

Non si usa `git clean` sull’intero albero.

### 2.2 Archiviare in `docs/archive/` (stesso nome file)

| Path attuale |
|---|
| `PROMPT-CURSOR.md` |
| `PROMPT-icone-e-precisione.md` |
| `PROMPT-import-anagrafe.md` |
| `RAPPORTO-STATO-APP.md` |
| `Scheda-Pongo-AmiciPerLaCoda.pdf` |
| `Cani_Amici_per_la_Coda_IMPORT.xlsx` |
| `csv-anagrafe.zip` |
| `tool/import/report-2026-09-11.md` |
| `tool/import/report-2026-09-11-1912.md` |
| `tool/import/report-2026-09-11-1914.md` |

I prompt archiviati **non** si aggiornano se citano path vecchi.

`docs/archive/` si crea se manca. Si aggiunge un `README.md` breve: cartella di documenti storici, non usata a runtime.

### 2.3 Spostare e tenere live

| Da | A | Riferimenti da aggiornare |
|---|---|---|
| `SPEC-integrazione-step.md` | `docs/SPEC-integrazione-step.md` | Le tre citazioni in `AMICI-PER-LA-CODA_SPEC.md` (righe circa 8, 678, 777) diventano `` `docs/SPEC-integrazione-step.md` ``. Le auto-citazioni `@SPEC-integrazione-step.md` **dentro** il file spostato diventano `@docs/SPEC-integrazione-step.md`. La citazione di `RAPPORTO-STATO-APP.md` nello stesso file diventa `docs/archive/RAPPORTO-STATO-APP.md`. Nessun file in radice con il vecchio nome. |
| `cani.csv` | `backend/scripts/cani.csv` | `backend/scripts/replace_dogs_from_csv.mjs` legge `join(scriptDir, 'cani.csv')` (stessa cartella dello script), non `join(root, 'cani.csv')`. I commenti in `lib/data/seed/cani_csv.dart` e `lib/data/seed/seed_data.dart` restano sulla copia embedded e nominano `backend/scripts/cani.csv` come originale. |

**Non** cambiare i `fileName` di export in `settings_page.dart` / `stats_page.dart` (`anagrafe-cani.csv`, `anagrafe_cani.csv`): sono nomi del file condiviso dall’app, non il CSV di progetto.

**Non** cambiare `tool/import/anagrafe.mjs`: legge `import/anagrafe_src/cani.csv`, già nel kit import.

`docs/documenti-cani.zip` resta dove è. `tool/import/documenti_cani.mjs` lo punta già.

### 2.4 Tenere (niente move, niente delete)

- Tutto ciò che è in sezione 1.
- `import/` intero, incluso `import/foto/`.
- `tool/import/*.mjs`, test Node, `package.json`, `package-lock.json`.
- `tool/import/backup-2026-09-11/` (già in `.gitignore`; backup locale dell’import, non cache).
- `tool/import/serviceAccount.json` (segreto, già ignorato).
- `docs/prompt-ottimizzazione-foto-firestore.md` e `docs/superpowers/` (già sotto `docs/`).
- `AMICI-PER-LA-CODA_SPEC.md` in radice.

Se un path non è in 2.1, 2.2 o 2.3, non si tocca.

---

## 3. `.gitignore`

Aggiungere, senza togliere le regole esistenti:

```
/tmp/
/Moduli/
/New folder/
/Scheda-Pongo*.pdf
/csv-anagrafe.zip
/Cani_Amici_per_la_Coda_IMPORT.xlsx
```

Già presenti, invariate: `/build/`, `.dart_tool/`, `import/foto/`, `tool/import/node_modules/`, `tool/import/backup-*/`, `tool/import/serviceAccount.json`.

---

## 4. Aggiornamenti di documentazione vincolante

Oltre ai path in 2.3:

- In `AMICI-PER-LA-CODA_SPEC.md` si aggiornano solo i path della sezione 2.3. L’albero della sezione 4 non si allarga a `docs/archive/`.
- `README.md` non si modifica: cita già `AMICI-PER-LA-CODA_SPEC.md` e `design/reference.html`.
- `.cursorrules` e `.cursor/rules/` restano puntati a `AMICI-PER-LA-CODA_SPEC.md` in radice.

---

## 5. Verifica e rollback

Ordine dopo le mosse:

1. Grep di `PROMPT-CURSOR.md`, `Moduli/`, `` `cani.csv` `` in radice, `SPEC-integrazione-step.md` senza prefisso `docs/`. Ogni hit live (non in `docs/archive/`) si corregge o si giustifica (export filename, `import/anagrafe_src/cani.csv`).
2. `flutter analyze` senza issue.
3. `flutter test` verde. `step18_ter` può ricreare `tmp/step18-ter/`.
4. Controllo a mano: `pubspec.yaml` ha gli stessi asset di prima; `backend/scripts/replace_dogs_from_csv.mjs` risolve `backend/scripts/cani.csv`.

Rollback:

- File tracciati: `git checkout` / revert del commit di pulizia.
- File archiviati: restano in `docs/archive/`.
- Cache cancellate: si rigenerano al prossimo build o `npm install`.

Non si pubblica un APK. La pulizia non cambia il binario; `tool/publish_test_release.ps1` non si lancia per questo lavoro.

---

## 6. Fuori scope

- Slim dell’APK (Dart unused, font, asset).
- Cancellazione di `import/foto/`.
- Riscrivere o “aggiornare” `AMICI-PER-LA-CODA_SPEC.md` oltre i path.
- Cancellare o zippare i CSV di `import/`.
- `git clean` globale.
- Commit di `serviceAccount.json` o di `import/foto/`.

---

## 7. Criterio di fatto

Fatto quando:

- la radice corrisponde alla sezione 1 più i file Flutter generati innocui (es. `.flutter-plugins-dependencies`);
- ogni path di 2.1 è assente;
- ogni path di 2.2 esiste in `docs/archive/` e non più nella posizione vecchia;
- i due path di 2.3 esistono nelle destinazioni e i riferimenti live sono aggiornati;
- `.gitignore` include le regole della sezione 3;
- analyze e test passano.

Il guadagno disco atteso sul PC è circa 7,8 GB (cache). L’APK non cambia di peso.
