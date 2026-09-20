# Pulizia cartella di progetto — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (recommended: the six tasks are sequential and share one inventory) or superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ordinare la radice del repository e liberare le cache Flutter locali senza cambiare l’APK, gli asset, l’import kit o il comportamento dell’app.

**Architecture:** Inventario chiuso dalla spec. Prima si archivia e si spostano i due path live (con riferimenti), poi si cancella lo scarto ovvio, poi si verifica `flutter analyze` / `flutter test`, infine si cancellano le cache rigenerabili. Nessun `git clean`. Nessun `publish_test_release.ps1`.

**Tech Stack:** Git, PowerShell, Flutter 3 / Dart SDK del progetto, `rg`. Nessuna libreria nuova.

**Spec:** `docs/superpowers/specs/2026-09-19-repo-cleanup-design.md`

## Global Constraints

- Non toccare un path che non è in questa spec.
- Non toccare `lib/` salvo i due commenti su `cani.csv` in `lib/data/seed/cani_csv.dart` e `lib/data/seed/seed_data.dart`.
- Non toccare `assets/`, `android/` (codice/risorse), `test/`.
- Non cancellare `import/` (CSV, `README.md`, `anagrafe_src/`, `foto/`).
- Non cancellare `tool/import/*.mjs`, `package.json`, `package-lock.json`.
- Non toccare i segreti: `tool/import/serviceAccount.json`, `android/key.properties`.
- Non modificare `README.md`, `.cursorrules`, `.cursor/rules/`.
- In `AMICI-PER-LA-CODA_SPEC.md` si aggiornano solo i path di `SPEC-integrazione-step.md`. L’albero della sezione 4 non si allarga a `docs/archive/`.
- Non cambiare i `fileName` di export `anagrafe-cani.csv` / `anagrafe_cani.csv`.
- Non cambiare `tool/import/anagrafe.mjs` (legge `import/anagrafe_src/cani.csv`).
- `docs/documenti-cani.zip` resta in `docs/`.
- Nessuno stub in radice dopo gli spostamenti.
- I prompt archiviati non si aggiornano se citano path vecchi.
- Non si usa `git clean` sull’intero albero.
- Non si pubblica un APK; non si lancia `tool/publish_test_release.ps1`.
- Non committare `serviceAccount.json` né `import/foto/`.
- `flutter analyze` pulito e `flutter test` verde prima di dichiarare finito.

## File map

| File | Ruolo |
|---|---|
| `docs/archive/README.md` | Indice dell’archivio storico |
| `docs/archive/*` | Destinazione dei 10 file di spec §2.2 |
| `docs/SPEC-integrazione-step.md` | Spec di integrazione (spostata dalla radice) |
| `backend/scripts/cani.csv` | CSV anagrafe per `replace_dogs_from_csv.mjs` |
| `backend/scripts/replace_dogs_from_csv.mjs` | Path del CSV |
| `AMICI-PER-LA-CODA_SPEC.md` | Tre citazioni del file di integrazione |
| `lib/data/seed/cani_csv.dart` | Commento: originale in `backend/scripts/cani.csv` |
| `lib/data/seed/seed_data.dart` | Commento: stesso path |
| `.gitignore` | Impedisce il ritorno di scarto in radice |

**Non toccare:** `pubspec.yaml` assets, `import/foto/`, `design/`, `tool/publish_test_release.ps1`, `tool/import/*.mjs` (salvo i tre report da archiviare), `README.md`.

**Working tree:** la working copy può già avere modifiche estranee (feature, `.gitignore`, `AMICI-PER-LA-CODA_SPEC.md`). Ogni `git add` di questo piano è per path e hunk della pulizia. Usare `git add -p` su file già sporchi. Non committare il resto del worktree.

---

### Task 1: Archivio storico e `.gitignore`

**Files:**
- Create: `docs/archive/README.md`
- Create (by move): `docs/archive/PROMPT-CURSOR.md`
- Create (by move): `docs/archive/PROMPT-icone-e-precisione.md`
- Create (by move): `docs/archive/PROMPT-import-anagrafe.md`
- Create (by move): `docs/archive/RAPPORTO-STATO-APP.md`
- Create (by move): `docs/archive/Scheda-Pongo-AmiciPerLaCoda.pdf`
- Create (by move): `docs/archive/Cani_Amici_per_la_Coda_IMPORT.xlsx`
- Create (by move): `docs/archive/csv-anagrafe.zip`
- Create (by move): `docs/archive/report-2026-09-11.md`
- Create (by move): `docs/archive/report-2026-09-11-1912.md`
- Create (by move): `docs/archive/report-2026-09-11-1914.md`
- Modify: `.gitignore` (append only, after the last existing line `import/foto/`)

**Interfaces:**
- Consumes: file in radice e `tool/import/report-2026-09-11*.md` come sono oggi
- Produces: cartella `docs/archive/` con gli stessi nomi file (i report perdono solo il prefisso di cartella `tool/import/`)

- [ ] **Step 1: Prove that the archive does not exist yet**

From the repo root, in PowerShell:

```powershell
Test-Path 'docs/archive/README.md'
Test-Path 'docs/archive/PROMPT-CURSOR.md'
Test-Path 'PROMPT-CURSOR.md'
```

Expected: `False`, `False`, `True`.

- [ ] **Step 2: Create the archive folder and README**

```powershell
New-Item -ItemType Directory -Force -Path 'docs/archive' | Out-Null
```

Write `docs/archive/README.md` with exactly:

```markdown
# Archivio storico

Documenti di costruzione, rapporti e file one-off. Non usati a runtime.
L’app legge solo `lib/`, `assets/` e quanto dichiarato in `pubspec.yaml`.
```

- [ ] **Step 3: Move tracked prompts with git**

```powershell
git mv PROMPT-CURSOR.md docs/archive/PROMPT-CURSOR.md
git mv PROMPT-icone-e-precisione.md docs/archive/PROMPT-icone-e-precisione.md
```

- [ ] **Step 4: Move untracked archive files**

```powershell
Move-Item -LiteralPath 'PROMPT-import-anagrafe.md' 'docs/archive/PROMPT-import-anagrafe.md'
Move-Item -LiteralPath 'RAPPORTO-STATO-APP.md' 'docs/archive/RAPPORTO-STATO-APP.md'
Move-Item -LiteralPath 'Scheda-Pongo-AmiciPerLaCoda.pdf' 'docs/archive/Scheda-Pongo-AmiciPerLaCoda.pdf'
Move-Item -LiteralPath 'Cani_Amici_per_la_Coda_IMPORT.xlsx' 'docs/archive/Cani_Amici_per_la_Coda_IMPORT.xlsx'
Move-Item -LiteralPath 'csv-anagrafe.zip' 'docs/archive/csv-anagrafe.zip'
Move-Item -LiteralPath 'tool/import/report-2026-09-11.md' 'docs/archive/report-2026-09-11.md'
Move-Item -LiteralPath 'tool/import/report-2026-09-11-1912.md' 'docs/archive/report-2026-09-11-1912.md'
Move-Item -LiteralPath 'tool/import/report-2026-09-11-1914.md' 'docs/archive/report-2026-09-11-1914.md'
```

Do not edit the moved prompt bodies.

- [ ] **Step 5: Append ignore rules**

Append these lines to the end of `.gitignore`. Do not delete or rewrite existing rules (`/build/`, `.dart_tool/`, `import/foto/`, `tool/import/node_modules/`, `tool/import/backup-*/`, `tool/import/serviceAccount.json` stay).

```
# Scarto di radice — non reintrodurre
/tmp/
/Moduli/
/New folder/
/Scheda-Pongo*.pdf
/csv-anagrafe.zip
/Cani_Amici_per_la_Coda_IMPORT.xlsx
```

- [ ] **Step 6: Verify archive and absence from old paths**

```powershell
$need = @(
  'docs/archive/README.md',
  'docs/archive/PROMPT-CURSOR.md',
  'docs/archive/PROMPT-icone-e-precisione.md',
  'docs/archive/PROMPT-import-anagrafe.md',
  'docs/archive/RAPPORTO-STATO-APP.md',
  'docs/archive/Scheda-Pongo-AmiciPerLaCoda.pdf',
  'docs/archive/Cani_Amici_per_la_Coda_IMPORT.xlsx',
  'docs/archive/csv-anagrafe.zip',
  'docs/archive/report-2026-09-11.md',
  'docs/archive/report-2026-09-11-1912.md',
  'docs/archive/report-2026-09-11-1914.md'
)
$gone = @(
  'PROMPT-CURSOR.md',
  'PROMPT-icone-e-precisione.md',
  'PROMPT-import-anagrafe.md',
  'RAPPORTO-STATO-APP.md',
  'Scheda-Pongo-AmiciPerLaCoda.pdf',
  'Cani_Amici_per_la_Coda_IMPORT.xlsx',
  'csv-anagrafe.zip',
  'tool/import/report-2026-09-11.md',
  'tool/import/report-2026-09-11-1912.md',
  'tool/import/report-2026-09-11-1914.md'
)
$need | ForEach-Object { if (-not (Test-Path $_)) { throw "manca $_" } }
$gone | ForEach-Object { if (Test-Path $_) { throw "ancora presente $_" } }
Select-String -Path .gitignore -Pattern '/tmp/','/Moduli/','/New folder/' | ForEach-Object { $_.Line }
```

Expected: no throw. `.gitignore` prints the three new folder rules.

Confirm import kit still present:

```powershell
Test-Path 'import/cani_rifugio.csv'
Test-Path 'import/foto'
Test-Path 'tool/import/import.mjs'
Test-Path 'docs/documenti-cani.zip'
```

Expected: `True` four times.

- [ ] **Step 7: Commit**

```powershell
git add -- docs/archive
git add -p -- .gitignore
git commit -m @"
chore: archive leftover root docs and ignore local junk.

"@
```

In `git add -p` stage only the appended “Scarto di radice” block. Leave any other `.gitignore` hunks unstaged.

Do not `git add` `import/foto/` or `tool/import/serviceAccount.json`.

---

### Task 2: Spostare `SPEC-integrazione-step.md`

**Files:**
- Move: `SPEC-integrazione-step.md` → `docs/SPEC-integrazione-step.md`
- Modify: `AMICI-PER-LA-CODA_SPEC.md` lines 8, 678, 777
- Modify: `docs/SPEC-integrazione-step.md` lines 244, 268, 489, 754

**Interfaces:**
- Consumes: file di integrazione in radice
- Produces: `docs/SPEC-integrazione-step.md` (nessun file omonimo in radice)

- [ ] **Step 1: Prove the destination is missing**

```powershell
Test-Path 'SPEC-integrazione-step.md'
Test-Path 'docs/SPEC-integrazione-step.md'
```

Expected: `True`, `False`.

- [ ] **Step 2: Move with git**

```powershell
git mv SPEC-integrazione-step.md docs/SPEC-integrazione-step.md
```

- [ ] **Step 3: Update the three citations in `AMICI-PER-LA-CODA_SPEC.md`**

Replace only these strings. Do not edit the section 4 tree (`design/reference.html` stays as-is).

Line 8, from:

```markdown
- **Integrazione obbligatoria:** `SPEC-integrazione-step.md` (Step 9-bis e Step 17-bis)
```

to:

```markdown
- **Integrazione obbligatoria:** `docs/SPEC-integrazione-step.md` (Step 9-bis e Step 17-bis)
```

Line 678, from:

```markdown
`SPEC-integrazione-step.md`**, che fa parte di questa specifica a tutti gli effetti.
```

to:

```markdown
`docs/SPEC-integrazione-step.md`**, che fa parte di questa specifica a tutti gli effetti.
```

Line 777, from:

```markdown
step. **Dettaglio e test in `SPEC-integrazione-step.md`.**
```

to:

```markdown
step. **Dettaglio e test in `docs/SPEC-integrazione-step.md`.**
```

- [ ] **Step 4: Update self-citations inside the moved file**

In `docs/SPEC-integrazione-step.md`, replace exactly:

```
@SPEC-integrazione-step.md
```

with:

```
@docs/SPEC-integrazione-step.md
```

There are three occurrences (around lines 244, 268, 489).

Replace the report citation (around line 754) from:

```markdown
**Origine:** rapporto sullo stato dell'app del 9 settembre 2026 (`RAPPORTO-STATO-APP.md`).
```

to:

```markdown
**Origine:** rapporto sullo stato dell'app del 9 settembre 2026 (`docs/archive/RAPPORTO-STATO-APP.md`).
```

- [ ] **Step 5: Verify no live stale path**

```powershell
rg -n "SPEC-integrazione-step\.md" --glob '!docs/archive/**'
```

Expected live hits, all with the `docs/` prefix:

- `AMICI-PER-LA-CODA_SPEC.md` (3)
- `docs/SPEC-integrazione-step.md` (the three `@docs/...` lines)
- this plan and the design spec (already say `docs/SPEC-integrazione-step.md`)

Forbidden: a root file named `SPEC-integrazione-step.md`.

```powershell
Test-Path 'SPEC-integrazione-step.md'
Test-Path 'docs/SPEC-integrazione-step.md'
```

Expected: `False`, `True`.

```powershell
rg -n "RAPPORTO-STATO-APP\.md" --glob '!docs/archive/**'
```

Expected: `docs/SPEC-integrazione-step.md` cites `docs/archive/RAPPORTO-STATO-APP.md`. Hits inside `docs/archive/` prompts are allowed and ignored by the glob.

- [ ] **Step 6: Commit**

```powershell
git add -- docs/SPEC-integrazione-step.md
git add -p -- AMICI-PER-LA-CODA_SPEC.md
git commit -m @"
chore: move integration spec under docs.

"@
```

In `git add -p` stage only the three `docs/SPEC-integrazione-step.md` path hunks.

---

### Task 3: Spostare `cani.csv` e aggiornare lo script

**Files:**
- Move: `cani.csv` → `backend/scripts/cani.csv`
- Modify: `backend/scripts/replace_dogs_from_csv.mjs` lines 14–15
- Modify: `lib/data/seed/cani_csv.dart` line 1
- Modify: `lib/data/seed/seed_data.dart` line 53

**Interfaces:**
- Consumes: `cani.csv` in radice; `dirname(fileURLToPath(import.meta.url))` dello script
- Produces: `csvPath = join(scriptDir, 'cani.csv')` dove `scriptDir` è la cartella dello script

- [ ] **Step 1: Prove the current script points at the repo root**

```powershell
Select-String -Path 'backend/scripts/replace_dogs_from_csv.mjs' -Pattern 'cani.csv'
Test-Path 'cani.csv'
Test-Path 'backend/scripts/cani.csv'
```

Expected: a line `const csvPath = join(root, 'cani.csv');`. `True`, `False`.

- [ ] **Step 2: Write the path assertion that fails before the move**

From repo root:

```powershell
node --input-type=module -e "import { existsSync } from 'node:fs'; import { dirname, join } from 'node:path'; import { fileURLToPath } from 'node:url'; const scriptDir = dirname(fileURLToPath(new URL('./backend/scripts/replace_dogs_from_csv.mjs', import.meta.url))); const csvPath = join(scriptDir, 'cani.csv'); if (!existsSync(csvPath)) { console.error('MISSING', csvPath); process.exit(1); } console.log('OK', csvPath);"
```

Expected: exit 1, `MISSING` … `backend\scripts\cani.csv` (or `/` on Unix).

- [ ] **Step 3: Move the CSV**

```powershell
git mv cani.csv backend/scripts/cani.csv
```

If `git mv` fails because `cani.csv` is already staged elsewhere, use:

```powershell
git mv -f cani.csv backend/scripts/cani.csv
```

- [ ] **Step 4: Point the script at its own folder**

In `backend/scripts/replace_dogs_from_csv.mjs` replace only lines 14–15.

From:

```javascript
const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const csvPath = join(root, 'cani.csv');
```

to:

```javascript
const scriptDir = dirname(fileURLToPath(import.meta.url));
const csvPath = join(scriptDir, 'cani.csv');
```

Leave every other line of that file unchanged. Do not print or commit secrets.

- [ ] **Step 5: Update seed comments only**

`lib/data/seed/cani_csv.dart` line 1, from:

```dart
/// Copia embedded di cani.csv, usata dal seed (anche nei test senza asset).
```

to:

```dart
/// Copia embedded dell'anagrafe; originale in backend/scripts/cani.csv.
```

`lib/data/seed/seed_data.dart` line 53, from:

```dart
/// Anagrafe vera da `cani.csv` + 6 cani / 3 volontari / 5 richieste di prova.
```

to:

```dart
/// Anagrafe vera da `backend/scripts/cani.csv` + 6 cani / 3 volontari / 5 richieste di prova.
```

Do not change the raw string `caniCsvSource`. Do not change `settings_page.dart` (`anagrafe-cani.csv`) or `stats_page.dart` (`anagrafe_cani.csv`). Do not change `tool/import/anagrafe.mjs`.

- [ ] **Step 6: Re-run the path assertion**

Same `node --input-type=module -e "..."` command as Step 2.

Expected: exit 0, `OK` and a path ending in `backend/scripts/cani.csv`.

```powershell
Test-Path 'cani.csv'
Test-Path 'backend/scripts/cani.csv'
Test-Path 'import/anagrafe_src/cani.csv'
```

Expected: `False`, `True`, `True`.

- [ ] **Step 7: Commit**

```powershell
git add -- backend/scripts/cani.csv backend/scripts/replace_dogs_from_csv.mjs lib/data/seed/cani_csv.dart lib/data/seed/seed_data.dart
git commit -m @"
chore: keep anagrafe CSV next to the replace script.

"@
```

---

### Task 4: Cancellare scarto ovvio (non le cache)

**Files:**
- Delete: `New folder/`
- Delete: `Moduli/modulo-adozione.pdf`
- Delete: `Moduli/modulo-preaffido.pdf`
- Delete: `Moduli/`
- Delete: `tmp/step18-ter/` and `tmp/`

**Interfaces:**
- Consumes: duplicati e output di test in radice
- Produces: quelle path assenti; `assets/moduli/` intatto

- [ ] **Step 1: Prove assets are the real copies**

```powershell
Get-FileHash 'assets/moduli/modulo-adozione.pdf','Moduli/modulo-adozione.pdf' | Format-Table
Get-ChildItem 'assets/moduli' | Select-Object Name
Test-Path 'New folder'
Test-Path 'tmp'
```

Expected: two hashes (may match). `assets/moduli` lists `modulo-adozione.pdf`, `modulo-affido.pdf`, `modulo-preaffido.pdf`. `New folder` and `tmp` exist or `tmp` exists.

- [ ] **Step 2: Delete only the listed junk**

```powershell
Remove-Item -LiteralPath 'New folder' -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath 'Moduli' -Recurse -Force
Remove-Item -LiteralPath 'tmp' -Recurse -Force
```

Do not delete `assets/moduli`. Do not delete `build/`, `.dart_tool/`, `tool/import/node_modules/` in this task. Do not run `git clean`.

- [ ] **Step 3: Verify**

```powershell
$mustGo = @('New folder','Moduli','tmp')
$mustStay = @(
  'assets/moduli/modulo-adozione.pdf',
  'assets/moduli/modulo-affido.pdf',
  'assets/moduli/modulo-preaffido.pdf',
  'import/foto',
  'tool/import/import.mjs'
)
$mustGo | ForEach-Object { if (Test-Path $_) { throw "ancora presente $_" } }
$mustStay | ForEach-Object { if (-not (Test-Path $_)) { throw "manca $_" } }
```

Expected: no throw.

- [ ] **Step 4: Commit only if git sees a tracked delete**

```powershell
git status --short -- 'New folder' Moduli tmp
```

These paths are untracked. If git shows nothing tracked, **do not create an empty commit**. If a tracked file appeared under those folders, add the deletion and commit:

```powershell
git add -u -- 'New folder' Moduli tmp
git commit -m @"
chore: remove duplicate moduli, empty folder, and tmp output.

"@
```

---

### Task 5: Verifica analyze e test (prima delle cache)

**Files:**
- None, unless a live reference was missed (then fix only that reference, still inside the spec inventory)

**Interfaces:**
- Consumes: albero dopo i task 1–4
- Produces: `flutter analyze` 0 issue, `flutter test` verde

- [ ] **Step 1: Grep leftover live paths**

```powershell
rg -n "PROMPT-CURSOR\.md|PROMPT-icone-e-precisione\.md|PROMPT-import-anagrafe\.md" --glob '!docs/archive/**' --glob '!docs/superpowers/**'
rg -n "Moduli/" --glob '!docs/superpowers/**' --glob '!.gitignore'
rg -n "SPEC-integrazione-step\.md" --glob '!docs/archive/**'
rg -n "(^|[^\w./])cani\.csv" --glob '!docs/archive/**' --glob '!docs/superpowers/**'
```

Allowed leftover hits:

- `AMICI-PER-LA-CODA_SPEC.md` and `docs/SPEC-integrazione-step.md` with the `docs/` prefix
- `backend/scripts/replace_dogs_from_csv.mjs` → `cani.csv` next to the script
- `lib/data/seed/*` comments naming `backend/scripts/cani.csv`
- `lib/data/seed/cani_csv.dart` raw CSV content (header/data, not a path)
- `tool/import/anagrafe.mjs` → `import/anagrafe_src/cani.csv`
- `settings_page.dart` / `stats_page.dart` / their tests: `anagrafe-cani.csv` / `anagrafe_cani.csv`
- `.gitignore` rules for `/Moduli/`

If any other live hit appears, stop and fix only that citation. Do not “clean” comments inside `docs/archive/`.

- [ ] **Step 2: Confirm pubspec assets unchanged**

```powershell
rg -n "assets/" pubspec.yaml
```

Expected exactly:

```
    - assets/logo.png
    - assets/branding/logo_login.png
    - assets/branding/logo_header.png
    - assets/moduli/modulo-preaffido.pdf
    - assets/moduli/modulo-adozione.pdf
    - assets/moduli/modulo-affido.pdf
    - assets/fonts/Roboto-Regular.ttf
    - assets/fonts/Roboto-Italic.ttf
    - assets/fonts/Roboto-Bold.ttf
        - asset: assets/fonts/Roboto-Regular.ttf
        - asset: assets/fonts/Roboto-Italic.ttf
        - asset: assets/fonts/Roboto-Bold.ttf
```

- [ ] **Step 3: Analyze**

```powershell
flutter analyze
```

Expected: `No issues found!` (or 0 issues). If analyze fails because `.dart_tool` is stale, run `flutter pub get` once, then analyze again. Do not change app code to silence new lints unrelated to this cleanup.

- [ ] **Step 4: Test**

```powershell
flutter test
```

Expected: all tests pass. `test/features/dogs/step18_ter_test.dart` may recreate `tmp/step18-ter/` during the run. After the suite, delete that leftover again:

```powershell
if (Test-Path tmp) { Remove-Item -LiteralPath tmp -Recurse -Force }
```

- [ ] **Step 5: Commit only if Step 1 forced a reference fix**

If you changed a file in Step 1:

```powershell
git add -- <those-files>
git commit -m @"
chore: fix leftover path references after repo cleanup.

"@
```

If nothing changed, skip the commit.

---

### Task 6: Cancellare le cache locali

**Files:**
- Delete (local, already gitignored): `build/`
- Delete (local, already gitignored): `.dart_tool/`
- Delete (local, already gitignored): `tool/import/node_modules/`

**Interfaces:**
- Consumes: cache sul PC
- Produces: quelle cartelle assenti; `import/foto/` e `tool/import/backup-2026-09-11/` ancora presenti

- [ ] **Step 1: Measure before delete**

```powershell
@('build','.dart_tool','tool/import/node_modules','import/foto','tool/import/backup-2026-09-11') | ForEach-Object {
  if (Test-Path $_) {
    $sum = (Get-ChildItem $_ -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
    '{0,8:N1} MB  {1}' -f ($sum/1MB), $_
  } else { "MISSING  $_" }
}
```

Expected: `build` and `.dart_tool` large; `import/foto` present; backup folder present or `MISSING` if that machine never ran the import backup.

- [ ] **Step 2: Delete only the three cache trees**

```powershell
Remove-Item -LiteralPath 'build' -Recurse -Force
Remove-Item -LiteralPath '.dart_tool' -Recurse -Force
Remove-Item -LiteralPath 'tool/import/node_modules' -Recurse -Force
```

Do not delete `import/foto`. Do not delete `tool/import/backup-2026-09-11`. Do not delete `tool/import/serviceAccount.json`. Do not run `git clean`.

- [ ] **Step 3: Verify caches gone and keep-list intact**

```powershell
$mustGo = @('build','.dart_tool','tool/import/node_modules')
$mustStay = @(
  'lib/main.dart',
  'assets/moduli/modulo-adozione.pdf',
  'import/foto',
  'import/cani_rifugio.csv',
  'tool/import/import.mjs',
  'tool/import/package.json',
  'docs/documenti-cani.zip',
  'docs/SPEC-integrazione-step.md',
  'docs/archive/PROMPT-CURSOR.md',
  'backend/scripts/cani.csv',
  'AMICI-PER-LA-CODA_SPEC.md',
  'README.md',
  'design/reference.html'
)
$mustGo | ForEach-Object { if (Test-Path $_) { throw "ancora presente $_" } }
$mustStay | ForEach-Object { if (-not (Test-Path $_)) { throw "manca $_" } }
```

Expected: no throw.

- [ ] **Step 4: Root listing vs spec §1**

```powershell
Get-ChildItem -Force | Select-Object Name
```

Allowed in the root: `lib`, `android`, `assets`, `test`, `backend`, `tool`, `import`, `design`, `docs`, `.cursor`, `.github`, `.git`, `README.md`, `AMICI-PER-LA-CODA_SPEC.md`, `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `firebase.json`, `.cursorrules`, `.gitignore`, `.metadata`, plus harmless generated/IDE leftovers already ignored (`.flutter-plugins-dependencies`, `.idea`, `amici_per_la_coda.iml`).

Forbidden in the root: `PROMPT-*.md`, `RAPPORTO-STATO-APP.md`, `SPEC-integrazione-step.md`, `cani.csv`, `Moduli`, `New folder`, `tmp`, `Scheda-Pongo-AmiciPerLaCoda.pdf`, `csv-anagrafe.zip`, `Cani_Amici_per_la_Coda_IMPORT.xlsx`.

- [ ] **Step 5: No commit for ignored cache deletes**

```powershell
git status --short -- build .dart_tool tool/import/node_modules
```

Expected: empty (those paths are gitignored). Do not create a commit. Do not run `flutter pub get` unless the next person needs to work; the next `flutter analyze` / `flutter test` will recreate `.dart_tool`.

---

## Rollback

- Commit dei task 1–3 (e 4/5 se ci sono): `git revert` di quei commit, oppure `git checkout` dei file tracciati.
- File archiviati: restano in `docs/archive/` anche dopo un revert parziale; rispostarli in radice solo se si vuole lo stato precedente.
- Cache: `flutter pub get` e un build le ricreano. `npm install` in `tool/import/` ricrea `node_modules`.
