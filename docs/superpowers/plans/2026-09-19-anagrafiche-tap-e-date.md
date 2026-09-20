# Anagrafiche, tessere e date — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (recommended for this plan: the seven tasks are sequential) or superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Far funzionare le date del profilo cane, le tessere cliccabili (Stato / Situazione / Adottabile), la rubrica veterinari e la rubrica famiglie senza iter di adozione.

**Architecture:** Quattro fette in un piano solo, in ordine. Le date sistemano `AppFormField`. Le tessere usano `dogSituazioneValue` e fogli rapidi. I vendor sono una collezione Firestore nuova, unita in elenco ai nomi orfani di visite/spese. Le famiglie riusano `adopters` + un documento `adoptions` come solo legame cane↔persona.

**Tech Stack:** Flutter, Riverpod, go_router, Firestore, `flutter_test`. Nessuna libreria nuova.

**Spec:** `docs/superpowers/specs/2026-09-19-anagrafiche-tap-e-date-design.md`

## Global Constraints

- Testi in italiano, date `dd/MM/yyyy`.
- Padding, raggi, font e icone solo da `lib/ui/tokens.dart` e `AppIcons`.
- Nessuno scroll orizzontale; testi in `Row` con `Expanded`, `maxLines`, ellipsis.
- Aree toccabili minime 40×40 dp (`AppDim.minTouch`).
- Contratto di layout in cima a ogni schermata/componente nuovo o modificato in modo visibile.
- Niente librerie extra.
- `flutter analyze` pulito e test della fettina verdi prima del task successivo.
- Golden: si rigenerano solo se la modifica visiva era voluta (`test/golden/dog_detail_golden_test.dart`, elenco vendor, tab Adozione).
- Permessi: `canWriteRecords` — chi non può scrivere vede, non + / matita / tap di modifica.
- Non toccare: tendina vendor in Salute/Spese, pagina `/richieste`, Avanza/Respingi, questionario casa, `dogs.famigliaId`.

## File map

| File | Ruolo |
|---|---|
| `lib/ui/components/app_form_field.dart` | Tap InkWell solo se non c’è controller |
| `lib/ui/form_pickers.dart` | `dateFieldSuffix` 40×40 + `pickDogFormDate(allowFuture:)` |
| `lib/features/dogs/dog_profile_fields.dart` | Campi data digitabili + suffix |
| `lib/features/dogs/new_dog/new_dog_validation.dart` | `validateOptionalItalianDate` |
| `lib/features/dogs/new_dog/new_dog_wizard_page.dart` | Valida date opzionali sporche |
| `lib/features/dogs/edit_dog_page.dart` | Valida date opzionali sporche |
| `lib/features/dogs/dog_labels.dart` | `dogSituazioneValue` |
| `lib/ui/components/stat_tile.dart` | `onTap` opzionale |
| `lib/features/dogs/dog_quick_edit_sheets.dart` | Fogli Situazione e Adottabile |
| `lib/features/dogs/dog_detail_page.dart` | Tessere cliccabili |
| `lib/data/models/enums.dart` | `VendorTipo` |
| `lib/data/models/vendor.dart` | Documento `vendors/{id}` |
| `lib/features/vendors/vendor_logic.dart` | Merge elenco + etichette tipo |
| `lib/data/repositories/data_repositories.dart` | `VendorRepository` |
| `lib/data/firestore/firestore_repositories.dart` | `FirestoreVendorRepository` |
| `lib/data/data_providers.dart` | `vendorRepositoryProvider` |
| `lib/features/vendors/vendors_page.dart` | Elenco + + |
| `lib/features/vendors/vendor_detail_page.dart` | Scheda |
| `lib/features/vendors/vendor_form_page.dart` | Nuovo/modifica/orfano |
| `lib/features/adoptions/adopter_detail_page.dart` | Profilo famiglia |
| `lib/features/adoptions/adopter_form_page.dart` | Nuova/modifica famiglia |
| `lib/features/adoptions/adopters_page.dart` | Tap e + |
| `lib/features/adoptions/family_link.dart` | Un legame per cane, scollega, conferma stato |
| `lib/features/dogs/dog_adozione_tab.dart` | Senza iter; card famiglia |
| `lib/router.dart` | Rotte vendor e adottante |
| `test/helpers/fake_vendor_repository.dart` | Fake |
| `test/helpers/pump_app.dart` | Override vendor |

---

### Task 1: Date digitabili e calendario

**Files:**
- Modify: `lib/ui/components/app_form_field.dart` (`_input` InkWell)
- Modify: `lib/ui/form_pickers.dart` (`dateFieldSuffix`, aggiungi `pickDogFormDate`)
- Modify: `lib/features/dogs/dog_profile_fields.dart` (tutti i campi data)
- Modify: `lib/features/dogs/new_dog/new_dog_validation.dart`
- Modify: `lib/features/dogs/new_dog/new_dog_wizard_page.dart` (`_validateStep1`)
- Modify: `lib/features/dogs/edit_dog_page.dart` (`_validate`)
- Test: `test/features/dogs/new_dog_validation_test.dart`
- Test: `test/ui/app_form_field_date_test.dart` (create)

**Interfaces:**
- Consumes: `parseItalianDate`, `formatItalianDate` in `lib/core/format_it.dart`
- Produces:
  - `String? validateOptionalItalianDate(String raw)`
  - `Widget dateFieldSuffix({Key? key, VoidCallback? onTap})` — box 40×40, key default `Key('form-date-suffix')`
  - `Future<void> pickDogFormDate(BuildContext context, TextEditingController controller, VoidCallback? onChanged, {bool allowFuture = false})`

- [ ] **Step 1: Write the failing tests**

Append to `test/features/dogs/new_dog_validation_test.dart`:

```dart
  test('data opzionale: vuota ok, valida ok, invalida errore', () {
    expect(validateOptionalItalianDate(''), isNull);
    expect(validateOptionalItalianDate('  '), isNull);
    expect(validateOptionalItalianDate('19/09/2026'), isNull);
    expect(
      validateOptionalItalianDate('32/13/2026'),
      'Data non valida (gg/mm/aaaa).',
    );
  });
```

Create `test/ui/app_form_field_date_test.dart`:

```dart
import 'package:amici_per_la_coda/core/format_it.dart';
import 'package:amici_per_la_coda/features/dogs/dog_profile_fields.dart';
import 'package:amici_per_la_coda/ui/components.dart';
import 'package:amici_per_la_coda/ui/form_pickers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('si digita gg/mm/aaaa nel campo data', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppFormField(
            label: 'Data di nascita',
            hint: 'gg/mm/aaaa',
            controller: controller,
            keyboardType: TextInputType.datetime,
            suffix: dateFieldSuffix(),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '19/09/2026');
    expect(controller.text, '19/09/2026');
    expect(parseItalianDate(controller.text), DateTime(2026, 9, 19));
  });

  testWidgets('icona calendario apre il date picker', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: AppFormField(
                label: 'Data di nascita',
                hint: 'gg/mm/aaaa',
                controller: controller,
                suffix: dateFieldSuffix(
                  onTap: () => pickDogFormDate(context, controller, null),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('form-date-suffix')));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```
flutter test test/features/dogs/new_dog_validation_test.dart test/ui/app_form_field_date_test.dart
```

Expected: FAIL — `validateOptionalItalianDate` non definito; il tap sull’icona non apre `DatePickerDialog` (o l’icona non esiste).

- [ ] **Step 3: Write minimal implementation**

Add at the end of `lib/features/dogs/new_dog/new_dog_validation.dart`:

```dart
String? validateOptionalItalianDate(String raw) {
  if (raw.trim().isEmpty) {
    return null;
  }
  if (parseItalianDate(raw) == null) {
    return 'Data non valida (gg/mm/aaaa).';
  }
  return null;
}
```

Add `import '../../../core/format_it.dart';` in that file.

In `lib/ui/form_pickers.dart` replace `dateFieldSuffix` and add `pickDogFormDate` (spostandolo da `dog_profile_fields.dart`):

```dart
const formDateSuffixKey = Key('form-date-suffix');

Widget dateFieldSuffix({Key? key, VoidCallback? onTap}) {
  final boxed = SizedBox(
    key: key ?? formDateSuffixKey,
    width: AppDim.minTouch,
    height: AppDim.minTouch,
    child: const Center(child: IconBadge(AppIcons.data, size: IconBadge.inNotice)),
  );
  if (onTap == null) {
    return boxed;
  }
  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: boxed,
  );
}

Future<void> pickDogFormDate(
  BuildContext context,
  TextEditingController controller,
  VoidCallback? onChanged, {
  bool allowFuture = false,
}) async {
  final parsed = parseItalianDate(controller.text);
  final now = DateTime.now();
  final first = DateTime(now.year - 25);
  final last = allowFuture ? DateTime(now.year + 10, 12, 31) : now;
  var initial = parsed ?? DateTime(now.year - 2, now.month, now.day);
  if (initial.isBefore(first)) {
    initial = first;
  }
  if (initial.isAfter(last)) {
    initial = last;
  }
  final picked = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: first,
    lastDate: last,
  );
  if (picked == null) {
    return;
  }
  controller.text = formatItalianDate(picked);
  onChanged?.call();
}
```

`form_pickers.dart` already imports `components.dart` (tokens + `IconBadge`). Add `import 'tokens.dart';` only if `AppDim` is not exported from `components.dart` — it is, via `lib/ui/components.dart`. Use `AppDim.minTouch` without a new import if analyze is clean.

In `lib/ui/components/app_form_field.dart`, inside `_input()`, the InkWell must not steal taps when a controller exists:

```dart
onTap: widget.enabled && widget.controller == null ? widget.onTap : null,
```

Do **not** pass `widget.onTap` to `TextField`. The calendar is only the suffix.

Delete `pickDogFormDate` from `lib/features/dogs/dog_profile_fields.dart` and import `../../ui/form_pickers.dart`.

On every date `AppFormField` in `dog_profile_fields.dart` (nascita, ingresso, chip, anagrafe, sterilizzazione):

```dart
readOnly: false,
keyboardType: TextInputType.datetime,
suffix: dateFieldSuffix(
  onTap: () => pickDogFormDate(
    context,
    dataNascita, // or the matching controller
    onChanged,
    allowFuture: false, // true only on data sterilizzazione programmata
  ),
),
```

For sterilizzazione date field only: `allowFuture: true`.

In `new_dog_wizard_page.dart` `_validateStep1`, after ingresso:

```dart
    final nascitaErr = validateOptionalItalianDate(_dataNascita.text);
```

If `nascitaErr != null`, block continue (reuse `_ingressoError` or add `_nascitaError` and pass it to `DogAnagraficaFields` — if that widget has no error slot, show nascita error in `_ingressoError` only for ingresso; add optional `nascitaError` to `DogAnagraficaFields` and `errorText: nascitaError` on the nascita field).

Add to `DogAnagraficaFields`: `this.nascitaError` and `errorText: nascitaError` on the nascita field.

In `edit_dog_page.dart` `_validate`:

```dart
    final nascitaErr = validateOptionalItalianDate(_dataNascita.text);
    final chipDateErr = validateOptionalItalianDate(_dataApplicazioneChip.text);
    final anagrafeErr = validateOptionalItalianDate(_dataIscrizioneAnagrafe.text);
    final sterErr = validateOptionalItalianDate(_dataSterilizzazione.text);
```

Block save if any is non-null. Show `nascitaError` / `ingressoError` on the matching fields. For chip/anagrafe/ster, if no error slot exists, reuse `ingressoError` only for ingresso; add `errorText` on those three fields.

- [ ] **Step 4: Run tests to verify they pass**

```
flutter test test/features/dogs/new_dog_validation_test.dart test/ui/app_form_field_date_test.dart
flutter analyze lib/ui/components/app_form_field.dart lib/ui/form_pickers.dart lib/features/dogs/dog_profile_fields.dart lib/features/dogs/new_dog lib/features/dogs/edit_dog_page.dart
```

Expected: PASS, analyze clean.

- [ ] **Step 5: Commit**

```
git add lib/ui/components/app_form_field.dart lib/ui/form_pickers.dart lib/features/dogs/dog_profile_fields.dart lib/features/dogs/new_dog/new_dog_validation.dart lib/features/dogs/new_dog/new_dog_wizard_page.dart lib/features/dogs/edit_dog_page.dart test/features/dogs/new_dog_validation_test.dart test/ui/app_form_field_date_test.dart
git commit -m "fix: allow typing and picking dates on the dog profile"
```

---

### Task 2: Etichette Intero / Castrato / Intera / Sterilizzata

**Files:**
- Modify: `lib/features/dogs/dog_labels.dart`
- Modify: `lib/features/dogs/dog_list_tile.dart` (badge)
- Modify: `lib/features/dogs/export/adoption_post_text.dart`
- Modify: `lib/features/dogs/export/adoption_profile.dart`
- Modify: `lib/features/dogs/export/adoption_card_widget.dart`
- Modify: `lib/features/dogs/export/adoption_pdf.dart`
- Test: `test/features/dogs/dog_labels_test.dart`

**Interfaces:**
- Consumes: `Dog.sesso`, `Dog.sterilizzato`
- Produces: `String dogSituazioneValue(Dog dog)` — Intero, Castrato, Intera, Sterilizzata, or `—`

- [ ] **Step 1: Write the failing test**

Append to `test/features/dogs/dog_labels_test.dart`:

```dart
  test('situazione: Intero/Castrato e Intera/Sterilizzata', () {
    expect(
      dogSituazioneValue(testDog(sesso: DogSex.M, sterilizzato: false)),
      'Intero',
    );
    expect(
      dogSituazioneValue(testDog(sesso: DogSex.M, sterilizzato: true)),
      'Castrato',
    );
    expect(
      dogSituazioneValue(testDog(sesso: DogSex.F, sterilizzato: false)),
      'Intera',
    );
    expect(
      dogSituazioneValue(testDog(sesso: DogSex.F, sterilizzato: true)),
      'Sterilizzata',
    );
    expect(
      dogSituazioneValue(testDog(sesso: null, sterilizzato: false)),
      'Intero',
    );
    expect(
      dogSituazioneValue(testDog().copyWith(clearSterilizzato: true)),
      '—',
    );
  });
```

`testDog` already has `sesso` and `sterilizzato`. Null situazione uses `copyWith(clearSterilizzato: true)`.

- [ ] **Step 2: Run test to verify it fails**

```
flutter test test/features/dogs/dog_labels_test.dart
```

Expected: FAIL — `dogSituazioneValue` non definito.

- [ ] **Step 3: Write minimal implementation**

In `lib/features/dogs/dog_labels.dart`:

```dart
String dogSituazioneValue(Dog dog) {
  if (dog.sterilizzato == null) {
    return '—';
  }
  final female = dog.sesso == DogSex.F;
  if (dog.sterilizzato == true) {
    return female ? 'Sterilizzata' : 'Castrato';
  }
  return female ? 'Intera' : 'Intero';
}
```

Replace display uses:

- `dog_list_tile.dart`: `MiniBadge(label: dogSituazioneValue(dog))` only if `dog.sterilizzato != null` (keep hiding badge if null).
- `adoption_post_text.dart`: `final sterile = profile.isFemmina ? 'Sterilizzata' : 'Castrato';`
- `adoption_profile.dart` bits: `femmina ? 'Sterilizzata' : 'Castrato'`
- `adoption_card_widget.dart`: same pair
- `adoption_pdf.dart`: `final sterileTitle = femmina ? 'Sterilizzata' : 'Castrato';`

Leave `dogSterilizedLabel` unused or unused-delete if analyzer complains. Do not keep «Sterilizzato» on males.

- [ ] **Step 4: Run tests**

```
flutter test test/features/dogs/dog_labels_test.dart
flutter analyze lib/features/dogs/dog_labels.dart lib/features/dogs/dog_list_tile.dart lib/features/dogs/export
```

Expected: PASS, analyze clean.

- [ ] **Step 5: Commit**

```
git add lib/features/dogs/dog_labels.dart lib/features/dogs/dog_list_tile.dart lib/features/dogs/export test/features/dogs/dog_labels_test.dart test/helpers/dog_fixtures.dart
git commit -m "fix: use Intero/Castrato and Intera/Sterilizzata on dog copy"
```

---

### Task 3: Tessere cliccabili Stato / Situazione / Adottabile

**Files:**
- Modify: `lib/ui/components/stat_tile.dart`
- Create: `lib/features/dogs/dog_quick_edit_sheets.dart`
- Modify: `lib/features/dogs/dog_detail_page.dart` (`_StatGrid`)
- Test: `test/features/dogs/dog_quick_edit_test.dart` (create)
- Golden (after visual ok): `test/golden/dog_detail_golden_test.dart` / `test/golden/goldens/dog_detail_360.png`

**Interfaces:**
- Consumes: `dogSituazioneValue`, `yesNo`, `canWriteRecords`, `AppRoutes.dogStato`, `DogRepository.save`, `pickDogFormDate` (`allowFuture: false`)
- Produces:
  - `StatTile({..., VoidCallback? onTap})`
  - `Future<void> showSituazioneSheet({required BuildContext context, required Dog dog, required void Function(bool sterilizzato, DateTime? data) onSave})`
  - `Future<void> showAdottabileSheet({required BuildContext context, required Dog dog, required void Function(bool adottabile) onSave})`

- [ ] **Step 1: Write the failing tests**

Create `test/features/dogs/dog_quick_edit_test.dart`:

```dart
import 'package:amici_per_la_coda/features/dogs/dog_detail_page.dart';
import 'package:amici_per_la_coda/features/dogs/change_status_page.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:amici_per_la_coda/ui/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_dog_repository.dart';
import '../../helpers/fake_volunteer_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 9, 8);

  Future<void> pumpDetail(
    WidgetTester tester, {
    required InMemoryDogRepository dogs,
    InMemoryVolunteerRepository? volunteers,
  }) async {
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    await pumpApp(
      tester,
      auth: auth,
      initialLocation: AppRoutes.dog('fenice'),
      size: const Size(360, 900),
      dogs: dogs,
      volunteers: volunteers,
      dogListNow: now,
    );
  }

  testWidgets('tessera Situazione mostra Intera su femmina non operata', (
    tester,
  ) async {
    await pumpDetail(tester, dogs: InMemoryDogRepository(testListDogs()));
    expect(find.text('Situazione'), findsOneWidget);
    expect(find.text('Intera'), findsWidgets);
  });

  testWidgets('tap Stato attuale apre Cambia stato', (tester) async {
    await pumpDetail(tester, dogs: InMemoryDogRepository(testListDogs()));
    await tester.tap(find.widgetWithText(StatTile, 'Stato attuale'));
    await tester.pumpAndSettle();
    expect(find.byType(ChangeStatusPage), findsOneWidget);
  });

  testWidgets('salvare Castrato su maschio aggiorna il cane', (tester) async {
    final dogs = InMemoryDogRepository([
      testDog(id: 'fenice', nome: 'Kratos', sesso: DogSex.M, sterilizzato: false),
    ]);
    await pumpDetail(tester, dogs: dogs);
    await tester.tap(find.widgetWithText(StatTile, 'Situazione'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Castrato'));
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();
    expect(dogs.items.single.sterilizzato, isTrue);
    expect(find.text('Castrato'), findsWidgets);
  });

  testWidgets('volontario in sola lettura non apre i fogli', (tester) async {
    final volunteers = InMemoryVolunteerRepository([
      testVolunteer(ruolo: VolunteerRuolo.volontario),
    ]);
    await pumpDetail(
      tester,
      dogs: InMemoryDogRepository(testListDogs()),
      volunteers: volunteers,
    );
    await tester.tap(find.widgetWithText(StatTile, 'Situazione'));
    await tester.pumpAndSettle();
    expect(find.text('Salva'), findsNothing);
  });
}
```

`testVolunteer` already has `ruolo`. Tap the tile with:

```dart
await tester.tap(
  find.ancestor(
    of: find.text('Stato attuale'),
    matching: find.byType(StatTile),
  ),
);
```

Import `DogSex` and `VolunteerRuolo` from `package:amici_per_la_coda/data/models/enums.dart`.

- [ ] **Step 2: Run tests to verify they fail**

```
flutter test test/features/dogs/dog_quick_edit_test.dart
```

Expected: FAIL — tessera still says «Sterilizzata» / not tappable / no sheet.

- [ ] **Step 3: Write minimal implementation**

`lib/ui/components/stat_tile.dart` — add `final VoidCallback? onTap;` wrap the `DecoratedBox` in:

```dart
    return Material(
      color: AppColor.card,
      borderRadius: BorderRadius.circular(AppDim.radCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDim.radCard),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppDim.minTouch),
          child: /* existing Padding+Row */,
        ),
      ),
    );
```

Create `lib/features/dogs/dog_quick_edit_sheets.dart` with layout contract comment:

```
// AppSheet titolo
// ├ AppSegmented 2 valori h=40 larghezza piena
// ├ se operato: SizedBox 9 + AppFormField data (digitabile + suffix, allowFuture:false)
// └ SizedBox 9 + AppButton Salva
```

```dart
Future<void> showSituazioneSheet({
  required BuildContext context,
  required Dog dog,
  required void Function(bool sterilizzato, DateTime? data) onSave,
}) {
  return AppSheet.present<void>(
    context: context,
    builder: (context) => _SituazioneSheet(dog: dog, onSave: onSave),
  );
}

Future<void> showAdottabileSheet({
  required BuildContext context,
  required Dog dog,
  required void Function(bool adottabile) onSave,
}) {
  return AppSheet.present<void>(
    context: context,
    builder: (context) => _AdottabileSheet(dog: dog, onSave: onSave),
  );
}
```

`_SituazioneSheet` is StatefulWidget: index 0 = intero/intera (`sterilizzato: false`, clear date), index 1 = castrato/sterilizzata. Labels: `dog.sesso == DogSex.F ? ['Intera', 'Sterilizzata'] : ['Intero', 'Castrato']`. Salva pops then calls `onSave`.

`_AdottabileSheet`: `['Sì', 'No']`, Salva `onSave(index == 0)`.

In `_StatGrid` (must become ConsumerWidget or take `canWrite`, `onStato`, `onSituazione`, `onAdottabile`):

```dart
            StatTile(
              label: 'Stato attuale',
              value: dogStatoLabel(dog.stato),
              onTap: canWrite
                  ? () => context.push(AppRoutes.dogStato(dog.id))
                  : null,
            ),
            StatTile(
              label: 'Situazione',
              value: dogSituazioneValue(dog),
              onTap: canWrite ? onSituazione : null,
            ),
            StatTile(
              label: 'Adottabile',
              value: yesNo(dog.adottabile),
              onTap: canWrite ? onAdottabile : null,
            ),
```

On save situazione: `dogRepository.save(dog.copyWith(sterilizzato: ..., dataSterilizzazione: ..., clearDataSterilizzazione: !operated, audit: Audit(..., updatedAt: now, updatedBy: uid)))`. Do **not** create a HealthRecord.

On save adottabile: `copyWith(adottabile: value)`.

- [ ] **Step 4: Run tests**

```
flutter test test/features/dogs/dog_quick_edit_test.dart test/features/dogs/dog_labels_test.dart
flutter analyze lib/ui/components/stat_tile.dart lib/features/dogs/dog_quick_edit_sheets.dart lib/features/dogs/dog_detail_page.dart
```

Expected: PASS. Then, only because the tessera text changed:

```
flutter test --update-goldens test/golden/dog_detail_golden_test.dart
```

- [ ] **Step 5: Commit**

```
git add lib/ui/components/stat_tile.dart lib/features/dogs/dog_quick_edit_sheets.dart lib/features/dogs/dog_detail_page.dart test/features/dogs/dog_quick_edit_test.dart test/golden/goldens/dog_detail_360.png
git commit -m "feat: tap dog status tiles to edit stato, situazione, adottabile"
```

---

### Task 4: Modello e repository vendor

**Files:**
- Modify: `lib/data/models/enums.dart` (add `VendorTipo` after `Affidabilita`)
- Create: `lib/data/models/vendor.dart`
- Modify: `lib/features/vendors/vendor_logic.dart`
- Modify: `lib/data/repositories/data_repositories.dart`
- Modify: `lib/data/firestore/firestore_repositories.dart`
- Modify: `lib/data/data_providers.dart`
- Create: `test/helpers/fake_vendor_repository.dart`
- Modify: `test/helpers/pump_app.dart`
- Modify: `test/data/models_roundtrip_test.dart`
- Test: `test/features/vendors/vendor_logic_test.dart` (create)

**Interfaces:**
- Consumes: `Audit`, `dateTimeFrom`/`dateTimeTo`, `HealthRecord.veterinario`, `Expense.fornitore`
- Produces:
  - `enum VendorTipo { veterinario, clinica, farmacia, negozio, toelettatura, altro }` with `wire` / `parse`
  - `class Vendor` fields: `id, nome, tipo, telefono, email, indirizzo, convenzionato, note, audit`
  - `Vendor.fromMap` / `toMap`
  - `abstract interface class VendorRepository { Stream<List<Vendor>> watchAll(); Future<Vendor?> getById(String id); Future<void> save(Vendor vendor); }`
  - `class VendorListItem { required String nome; required VendorTipo tipo; Vendor? saved; }` — `saved == null` means orphan
  - `List<VendorListItem> mergeVendorList({required List<Vendor> vendors, required List<HealthRecord> health, required List<Expense> expenses})`
  - `String vendorTipoLabel(VendorTipo tipo)`
  - `final vendorRepositoryProvider`

- [ ] **Step 1: Write the failing tests**

Append a Vendor round-trip in `test/data/models_roundtrip_test.dart` next to Adopter:

```dart
  test('Vendor round-trip', () {
    final item = Vendor(
      id: 'v1',
      nome: 'Datena Anna Maria',
      tipo: VendorTipo.veterinario,
      telefono: '333',
      email: 'a@b.it',
      indirizzo: 'Via 1',
      convenzionato: true,
      note: 'note',
      audit: audit,
    );
    final again = Vendor.fromMap(item.id, item.toMap());
    expect(again.nome, 'Datena Anna Maria');
    expect(again.tipo, VendorTipo.veterinario);
    expect(again.convenzionato, isTrue);
  });
```

Create `test/features/vendors/vendor_logic_test.dart`:

```dart
import 'package:amici_per_la_coda/core/firestore_codec.dart';
import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/data/models/vendor.dart';
import 'package:amici_per_la_coda/features/vendors/vendor_logic.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';

void main() {
  final audit = Audit.seed(DateTime.utc(2026, 1, 1));

  test('orfano da visita è Veterinario, da spesa è Altro', () {
    final list = mergeVendorList(
      vendors: const [],
      health: [testHealth(veterinario: 'Datena')],
      expenses: [testExpense(fornitore: 'Agraria')],
    );
    expect(list.map((e) => e.nome).toList()..sort(), ['Agraria', 'Datena']);
    expect(
      list.firstWhere((e) => e.nome == 'Datena').tipo,
      VendorTipo.veterinario,
    );
    expect(list.firstWhere((e) => e.nome == 'Datena').saved, isNull);
    expect(
      list.firstWhere((e) => e.nome == 'Agraria').tipo,
      VendorTipo.altro,
    );
  });

  test('nome già in vendors non è orfano', () {
    final saved = Vendor(
      id: 'v1',
      nome: 'Datena Anna Maria',
      tipo: VendorTipo.clinica,
      telefono: '1',
      email: '',
      indirizzo: '',
      convenzionato: false,
      note: '',
      audit: audit,
    );
    final list = mergeVendorList(
      vendors: [saved],
      health: [testHealth(veterinario: 'datena anna maria')],
      expenses: const [],
    );
    expect(list, hasLength(1));
    expect(list.single.saved?.id, 'v1');
    expect(list.single.tipo, VendorTipo.clinica);
  });
}
```

`testExpense` already has `fornitore`. Change `testHealth` in `test/helpers/dog_fixtures.dart` from hardcoded `'Dr. Test'` to `String veterinario = 'Dr. Test'` and pass `veterinario: veterinario` into `HealthRecord`.

- [ ] **Step 2: Run tests to verify they fail**

```
flutter test test/data/models_roundtrip_test.dart test/features/vendors/vendor_logic_test.dart
```

Expected: FAIL — `Vendor` / `VendorTipo` / `mergeVendorList` assenti.

- [ ] **Step 3: Write minimal implementation**

`VendorTipo` in `enums.dart`:

```dart
enum VendorTipo {
  veterinario,
  clinica,
  farmacia,
  negozio,
  toelettatura,
  altro;

  String get wire => name;
  static VendorTipo parse(String? raw) =>
      enumByWire(values, (v) => v.wire, raw, VendorTipo.altro);
}
```

`lib/data/models/vendor.dart` — mirror `Adopter` (`fromMap`/`toMap`, `convenzionato: map['convenzionato'] as bool? ?? false`).

`vendorTipoLabel`:

```dart
String vendorTipoLabel(VendorTipo tipo) => switch (tipo) {
  VendorTipo.veterinario => 'Veterinario',
  VendorTipo.clinica => 'Clinica',
  VendorTipo.farmacia => 'Farmacia',
  VendorTipo.negozio => 'Negozio',
  VendorTipo.toelettatura => 'Toelettatura',
  VendorTipo.altro => 'Altro',
};
```

`mergeVendorList`: insert saved vendors first (map key = `nome.trim().toLowerCase()`). Then for each non-empty `health.veterinario` / `expense.fornitore`, `putIfAbsent` with `saved: null` and tipo veterinario / altro. Sort by `nome.toLowerCase()`.

`FirestoreVendorRepository` copy `FirestoreAdopterRepository` with collection `'vendors'`.

```dart
final vendorRepositoryProvider = Provider<VendorRepository?>((ref) {
  final db = ref.watch(firestoreProvider);
  return db == null ? null : FirestoreVendorRepository(db);
});
```

`InMemoryVendorRepository` copy `InMemoryAdopterRepository`.

`pump_app.dart`: add `VendorRepository? vendors` and

```dart
        vendorRepositoryProvider.overrideWith(
          (ref) => vendors ?? InMemoryVendorRepository(),
        ),
```

Firestore rules: no change (`vendors` is under `/{col}/{id}`).

Keep `VendorEntry` / `vendorsFrom` used by Salute/Spese pickers. Do not break `pickVendorName`.

- [ ] **Step 4: Run tests**

```
flutter test test/data/models_roundtrip_test.dart test/features/vendors/vendor_logic_test.dart
flutter analyze lib/data/models/vendor.dart lib/features/vendors/vendor_logic.dart lib/data/firestore/firestore_repositories.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```
git add lib/data/models/enums.dart lib/data/models/vendor.dart lib/features/vendors/vendor_logic.dart lib/data/repositories/data_repositories.dart lib/data/firestore/firestore_repositories.dart lib/data/data_providers.dart test/helpers/fake_vendor_repository.dart test/helpers/pump_app.dart test/helpers/dog_fixtures.dart test/data/models_roundtrip_test.dart test/features/vendors/vendor_logic_test.dart
git commit -m "feat: add vendors collection and merge orphan visit names"
```

---

### Task 5: UI veterinari (elenco, scheda, form)

**Files:**
- Modify: `lib/features/vendors/vendors_page.dart`
- Create: `lib/features/vendors/vendor_detail_page.dart`
- Create: `lib/features/vendors/vendor_form_page.dart`
- Modify: `lib/router.dart`
- Modify: `lib/features/dogs/dogs_providers.dart` (optional `vendorsStreamProvider`)
- Test: `test/features/vendors/vendors_page_test.dart` (create)

**Interfaces:**
- Consumes: `VendorRepository`, `mergeVendorList`, `canWriteRecords`
- Produces:
  - `AppRoutes.fornitoreNuovo`, `AppRoutes.fornitore(String id)`, `AppRoutes.fornitoreModifica(String id)`
  - `AppRoutes.fornitoreOrfano({required String nome, required String tipo})` query `nome` + `tipo` wire
  - `VendorsPage.addKey = Key('fornitori-add')`

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/data/models/vendor.dart';
import 'package:amici_per_la_coda/features/vendors/vendor_detail_page.dart';
import 'package:amici_per_la_coda/features/vendors/vendor_form_page.dart';
import 'package:amici_per_la_coda/features/vendors/vendors_page.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:amici_per_la_coda/core/firestore_codec.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_vendor_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tap su vendor salvato apre la scheda con telefono', (tester) async {
    final vendors = InMemoryVendorRepository([
      Vendor(
        id: 'v1',
        nome: 'Datena Anna Maria',
        tipo: VendorTipo.veterinario,
        telefono: '333111',
        email: '',
        indirizzo: 'Via Roma',
        convenzionato: false,
        note: '',
        audit: Audit.seed(DateTime.utc(2026, 1, 1)),
      ),
    ]);
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    await pumpApp(
      tester,
      auth: auth,
      initialLocation: AppRoutes.fornitori,
      vendors: vendors,
    );
    await tester.tap(find.text('Datena Anna Maria'));
    await tester.pumpAndSettle();
    expect(find.byType(VendorDetailPage), findsOneWidget);
    expect(find.text('333111'), findsOneWidget);
    expect(find.text('Via Roma'), findsOneWidget);
  });

  testWidgets('+ crea un veterinario e torna in elenco', (tester) async {
    final vendors = InMemoryVendorRepository();
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    await pumpApp(
      tester,
      auth: auth,
      initialLocation: AppRoutes.fornitori,
      vendors: vendors,
    );
    await tester.tap(find.byKey(VendorsPage.addKey));
    await tester.pumpAndSettle();
    expect(find.byType(VendorFormPage), findsOneWidget);
    await tester.enterText(find.byKey(VendorFormPage.nomeKey), 'Nuova Clinica');
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();
    expect(find.byType(VendorsPage), findsOneWidget);
    expect(find.text('Nuova Clinica'), findsOneWidget);
    expect(vendors.items, hasLength(1));
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```
flutter test test/features/vendors/vendors_page_test.dart
```

Expected: FAIL — tap still no-op / no `addKey`.

- [ ] **Step 3: Write minimal implementation**

Routes in `AppRoutes`:

```dart
  static const fornitoreNuovo = '/fornitori/nuovo';
  static String fornitore(String id) => '/fornitori/$id';
  static String fornitoreModifica(String id) => '/fornitori/$id/modifica';
  static String fornitoreOrfano({required String nome, required String tipo}) =>
      Uri(
        path: fornitoreNuovo,
        queryParameters: {'nome': nome, 'tipo': tipo},
      ).toString();
```

Nest under `AppRoutes.fornitori`: `nuovo`, `:vendorId`, `:vendorId/modifica`.

`vendorsStreamProvider` in `dogs_providers.dart` or `lib/features/vendors/vendor_providers.dart` (prefer new small file):

```dart
final vendorsStreamProvider = StreamProvider<List<Vendor>>((ref) {
  final repo = ref.watch(vendorRepositoryProvider);
  if (repo == null) return Stream.value(const <Vendor>[]);
  return repo.watchAll();
});
```

`VendorsPage`: watch vendors + `healthAllProvider` + `expensesAllProvider` (already used). `mergeVendorList`. Header `headerActions` if `canWriteRecords`: 40×40 `+` with `VendorsPage.addKey` → `context.push(AppRoutes.fornitoreNuovo)`.

`onTap`: if `item.saved != null` → `AppRoutes.fornitore(id)` else `AppRoutes.fornitoreOrfano(nome: item.nome, tipo: item.tipo.wire)`.

Subtitle: `vendorTipoLabel(item.tipo)`.

`VendorDetailPage`: `AppScaffold` title = nome, `onEdit` if canWrite → modifica. `KeyValueRow` for tipo, telefono, email, indirizzo, convenzionato (`yesNo`), note; empty → `—`.

`VendorFormPage`: compact header + Salva pill (copy `NewAdoptionPage` header Salva). Fields: nome*, tipo via `AppSheet` of 6 `OptionRow` (not 6 full-width buttons; not a 6-segment bar). Convenzionato `AppSegmented` Sì/No default No. Query `nome`/`tipo` prefill. Empty nome → error, no save. `newEntityId('ven', now)`.

Keys: `VendorFormPage.nomeKey = Key('vendor-nome')`.

- [ ] **Step 4: Run tests**

```
flutter test test/features/vendors/vendors_page_test.dart test/features/step17_bis_test.dart
flutter analyze lib/features/vendors lib/router.dart
```

Expected: PASS. No golden unless the + changes a locked PNG (Altro menu is unchanged).

- [ ] **Step 5: Commit**

```
git add lib/features/vendors lib/router.dart lib/features/dogs/dogs_providers.dart test/features/vendors/vendors_page_test.dart
git commit -m "feat: vendor directory with detail and manual add"
```

---

### Task 6: Profilo e form famiglie (senza cane)

**Files:**
- Create: `lib/features/adoptions/adopter_detail_page.dart`
- Create: `lib/features/adoptions/adopter_form_page.dart`
- Modify: `lib/features/adoptions/adopters_page.dart`
- Modify: `lib/data/models/adopter.dart` (`withoutAdozioneId`, optional `copyWith` not required if you construct)
- Modify: `lib/router.dart`
- Test: `test/features/adoptions/adopters_page_test.dart` (create)

**Interfaces:**
- Consumes: `AdopterRepository`, `findMatchingAdopter`, `canWriteRecords`, `adoptersStreamProvider` (already in `dogs_providers.dart`)
- Produces:
  - `AppRoutes.adottanteNuovo = '/adottanti/nuovo'`
  - `AppRoutes.adottante(String id) => '/adottanti/$id'`
  - `AppRoutes.adottanteModifica(String id) => '/adottanti/$id/modifica'`
  - `AdoptersPage.addKey = Key('adottanti-add')`
  - `AdopterFormPage.nomeKey`, `cognomeKey`
  - `Adopter withoutAdozioneId(String adoptionId, {Audit? audit})`

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:amici_per_la_coda/features/adoptions/adopter_detail_page.dart';
import 'package:amici_per_la_coda/features/adoptions/adopter_form_page.dart';
import 'package:amici_per_la_coda/features/adoptions/adopters_page.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_adopter_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tap apre il profilo con telefono e città', (tester) async {
    final adopters = InMemoryAdopterRepository([
      testAdopter(
        nome: 'Roberto',
        cognome: 'Masala',
        telefono: '320',
        citta: 'Quartu',
      ),
    ]);
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    await pumpApp(
      tester,
      auth: auth,
      initialLocation: AppRoutes.adottanti,
      adopters: adopters,
    );
    await tester.tap(find.text('Roberto Masala'));
    await tester.pumpAndSettle();
    expect(find.byType(AdopterDetailPage), findsOneWidget);
    expect(find.text('320'), findsOneWidget);
    expect(find.text('Quartu'), findsOneWidget);
    expect(find.textContaining('richiesta'), findsNothing);
  });

  testWidgets('+ da Altro crea solo adopters', (tester) async {
    final adopters = InMemoryAdopterRepository();
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    await pumpApp(
      tester,
      auth: auth,
      initialLocation: AppRoutes.adottanti,
      adopters: adopters,
    );
    await tester.tap(find.byKey(AdoptersPage.addKey));
    await tester.pumpAndSettle();
    expect(find.text('Nuova famiglia'), findsOneWidget);
    await tester.enterText(find.byKey(AdopterFormPage.nomeKey), 'Anna');
    await tester.enterText(find.byKey(AdopterFormPage.cognomeKey), 'Bianchi');
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();
    expect(adopters.items, hasLength(1));
    expect(adopters.items.single.nome, 'Anna');
    expect(adopters.items.single.adozioniIds, isEmpty);
  });
}
```

In `test/helpers/dog_fixtures.dart` add `String citta = 'Potenza'` to `testAdopter` and pass `citta: citta`.

- [ ] **Step 2: Run tests to verify they fail**

```
flutter test test/features/adoptions/adopters_page_test.dart
```

Expected: FAIL — `onTap: () {}`.

- [ ] **Step 3: Write minimal implementation**

`Adopter.withoutAdozioneId`:

```dart
  Adopter withoutAdozioneId(String adoptionId, {Audit? audit}) {
    return Adopter(
      id: id,
      nome: nome,
      cognome: cognome,
      telefono: telefono,
      email: email,
      citta: citta,
      indirizzo: indirizzo,
      docTipo: docTipo,
      docNumero: docNumero,
      dataNascita: dataNascita,
      note: note,
      adozioniIds: [for (final item in adozioniIds) if (item != adoptionId) item],
      affidabilita: affidabilita,
      audit: audit ?? this.audit,
    );
  }
```

Routes nested under `/adottanti`.

`AdoptersPage`: `onTap: () => context.push(AppRoutes.adottante(item.id))`. `+` if canWrite → `adottanteNuovo`.

`AdopterDetailPage`: KeyValueRow nome, cognome, telefono, email, città, indirizzo, documento (`docTipo docNumero`), data nascita, note. No `affidabilita`. List of dogs from `adozioniIds` → look up `adoptionsStreamProvider` then `dogById`. Tap dog → `AppRoutes.openDog`. `onEdit` if canWrite.

`AdopterFormPage`: fields per spec. Titles `Nuova famiglia` / `Modifica famiglia`. No questionario, no cane. Nome e cognome obbligatori. On save, if creating: `findMatchingAdopter` — if match, `AppToast` «Esiste già: {nome}. Apro quella scheda.» and go to that id (do not insert duplicate). `newEntityId('adp', now)`. Date nascita uses Task 1 date field. `affidabilita: Affidabilita.daVerificare` on create, unchanged on edit.

- [ ] **Step 4: Run tests**

```
flutter test test/features/adoptions/adopters_page_test.dart test/features/step17_bis_test.dart
flutter analyze lib/features/adoptions lib/data/models/adopter.dart lib/router.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```
git add lib/features/adoptions/adopter_detail_page.dart lib/features/adoptions/adopter_form_page.dart lib/features/adoptions/adopters_page.dart lib/data/models/adopter.dart lib/router.dart test/features/adoptions/adopters_page_test.dart test/helpers/dog_fixtures.dart
git commit -m "feat: adopter profile and manual family form"
```

---

### Task 7: Legame famiglia sulla tab Adozione

**Files:**
- Create: `lib/features/adoptions/family_link.dart`
- Modify: `lib/features/dogs/dog_adozione_tab.dart`
- Modify: `lib/features/dogs/dogs_providers.dart` (`dogAdoptionCountProvider` → 0/1 sul legame)
- Modify: `lib/features/adoptions/adopter_form_page.dart` (optional `dogId` query)
- Modify: `lib/router.dart` (`adottanteNuovo` may take `?dogId=`)
- Test: `test/features/adoptions/family_link_test.dart` (create)
- Test: `test/features/dogs/dog_adozione_tab_test.dart` (create or extend existing)
- Golden: tab Adozione is on dog detail — update `dog_detail_360.png` only if the default tab shows Adozione; Fenice golden is Scheda. If a test paints the Adozione tab, add/update that golden only when the visual change is intended.

**Interfaces:**
- Consumes: `applyDogStato` from `dog_stato.dart`, `Adopter.withAdozioneId` / `withoutAdozioneId`, `AdoptionRepository.delete` / `save`, `findMatchingAdopter`
- Produces:
  - `Adoption? familyLinkOf(List<Adoption> items, String dogId)` — most recent by `dataRichiesta`
  - `Adoption familyLinkAdoption({required String id, required String dogId, required Adopter adopter, required Audit audit, required DateTime now})`
  - `Questionario emptyQuestionario` constant
  - `({Dog dog, bool wroteStorico}) markDogAdottatoIfNeeded({required Dog dog, required DateTime now, required String autoreId})` — if `dog.stato == DogStato.adottato` then only `adottabile: false` and `wroteStorico: false`; else `applyDogStato(..., stato: DogStato.adottato)` + `adottabile: false`
  - `DogAdozioneTab.registraFamigliaKey`, `collegaFamigliaKey`, `famigliaCardKey`, `scollegaKey`

- [ ] **Step 1: Write the failing tests**

`test/features/adoptions/family_link_test.dart`:

```dart
import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/features/adoptions/family_link.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';

void main() {
  test('familyLinkOf prende l\'adozione più recente del cane', () {
    final older = testAdoption(id: 'a1', dogId: 'k', dataRichiesta: DateTime.utc(2026, 1, 1));
    final newer = testAdoption(id: 'a2', dogId: 'k', dataRichiesta: DateTime.utc(2026, 9, 1));
    expect(familyLinkOf([older, newer], 'k')?.id, 'a2');
    expect(familyLinkOf([older, newer], 'altro'), isNull);
  });

  test('markDogAdottatoIfNeeded non riscrive lo storico se già adottato', () {
    final dog = testDog(stato: DogStato.adottato, adottabile: true);
    final now = DateTime.utc(2026, 9, 19);
    final result = markDogAdottatoIfNeeded(
      dog: dog,
      now: now,
      autoreId: 'u1',
    );
    expect(result.wroteStorico, isFalse);
    expect(result.dog.adottabile, isFalse);
    expect(result.dog.storicoStati.length, dog.storicoStati.length);
  });

  test('markDogAdottatoIfNeeded da in_rifugio scrive adottato', () {
    final dog = testDog(stato: DogStato.inRifugio, adottabile: true);
    final now = DateTime.utc(2026, 9, 19);
    final result = markDogAdottatoIfNeeded(
      dog: dog,
      now: now,
      autoreId: 'u1',
    );
    expect(result.wroteStorico, isTrue);
    expect(result.dog.stato, DogStato.adottato);
    expect(result.dog.adottabile, isFalse);
  });
}
```

If `testAdoption` / `testDog` lack those params, add them.

Widget test `test/features/dogs/dog_adozione_tab_test.dart`:

```dart
  testWidgets('tab Adozione senza iter mostra famiglia e nasconde richiesta', ...);
  testWidgets('Collega + Sì imposta adottato', ...);
  testWidgets('Collega + No lascia lo stato', ...);
  testWidgets('Scollega toglie il card e tiene l\'adottante', ...);
```

Pump `AppRoutes.dog('fenice')`, tap tab `Adozione` (`find.text('Adozione')`).

Existing fixtures: create `testAdoption` with `adopterId: 'adp1'` and `InMemoryAdopterRepository([testAdopter(id: 'adp1')])`.

Collega: tap `DogAdozioneTab.collegaFamigliaKey`, tap adopter name, then tap `Sì` or `No` on «Segnare … come adottato?».

Scollega: tap `DogAdozioneTab.scollegaKey`.

Expect `find.text('Iter di adozione')` findsNothing.
Expect `find.text('Registra nuova richiesta')` findsNothing.

- [ ] **Step 2: Run tests to verify they fail**

```
flutter test test/features/adoptions/family_link_test.dart test/features/dogs/dog_adozione_tab_test.dart
```

Expected: FAIL — `family_link.dart` assente; iter ancora visibile.

- [ ] **Step 3: Write minimal implementation**

`family_link.dart`:

```dart
const emptyQuestionario = Questionario(
  abitazione: '',
  giardinoRecintato: false,
  altezzaRecinzione: '',
  altriAnimali: '',
  bambini: '',
  oreDaSolo: '',
  esperienzaCani: '',
  doveDormira: '',
  note: '',
);

Adoption? familyLinkOf(List<Adoption> items, String dogId) {
  final matches = [for (final item in items) if (item.dogId == dogId) item];
  if (matches.isEmpty) {
    return null;
  }
  matches.sort((a, b) => b.dataRichiesta.compareTo(a.dataRichiesta));
  return matches.first;
}

Adoption familyLinkAdoption({
  required String id,
  required String dogId,
  required Adopter adopter,
  required Audit audit,
  required DateTime now,
}) {
  return Adoption(
    id: id,
    dogId: dogId,
    adopterId: adopter.id,
    richiedente: Richiedente(
      nome: adopter.nome,
      cognome: adopter.cognome,
      telefono: adopter.telefono,
      email: adopter.email,
      citta: adopter.citta,
      indirizzo: adopter.indirizzo,
      docTipo: adopter.docTipo,
      docNumero: adopter.docNumero,
      eta: 0,
    ),
    questionario: emptyQuestionario,
    stato: AdoptionStato.adottato,
    storicoStati: const [],
    preaffidoDal: null,
    preaffidoAl: null,
    referenteId: '',
    dataRichiesta: now,
    audit: audit,
  );
}

({Dog dog, bool wroteStorico}) markDogAdottatoIfNeeded({
  required Dog dog,
  required DateTime now,
  required String autoreId,
}) {
  if (dog.stato == DogStato.adottato) {
    return (
      dog: dog.copyWith(adottabile: false),
      wroteStorico: false,
    );
  }
  final updated = applyDogStato(
    dog: dog,
    stato: DogStato.adottato,
    dal: now,
    note: '',
    autoreId: autoreId,
    now: now,
  ).copyWith(adottabile: false);
  return (dog: updated, wroteStorico: true);
}
```

Replace-link helper used by the tab (same file):

```dart
Future<void> replaceDogFamily({
  required AdoptionRepository adoptions,
  required AdopterRepository adopters,
  required List<Adoption> existing,
  required Adopter adopter,
  required String dogId,
  required String uid,
  required DateTime now,
}) async {
  for (final old in existing.where((item) => item.dogId == dogId)) {
    await adoptions.delete(old.id);
    final previous = await adopters.getById(old.adopterId);
    if (previous != null) {
      await adopters.save(previous.withoutAdozioneId(old.id));
    }
  }
  final link = familyLinkAdoption(
    id: newEntityId('ado', now),
    dogId: dogId,
    adopter: adopter,
    audit: Audit(createdAt: now, createdBy: uid, updatedAt: now, updatedBy: uid),
    now: now,
  );
  await adoptions.save(link);
  await adopters.save(adopter.withAdozioneId(link.id, audit: link.audit));
}
```

`dog_adozione_tab.dart` rebuild:

Keep banner + PDF/card/copia.
Remove iter card, richieste list, «Registra nuova richiesta».

If `familyLinkOf(requests, dog.id)` is null and canWrite:

- `AppButton` «Registra famiglia» → `AppRoutes.adottanteNuovo` + `?dogId=`
- `AppButton` grey «Collega famiglia» → `AppSheet` of adopters; on pick run `replaceDogFamily` then confirm sheet.

If link exists: card (`famigliaCardKey`) name, città, telefono; tap → `AppRoutes.adottante(id)`. If canWrite: «Sostituisci» (same as collega) and «Scollega» (`adoptions.delete` + `withoutAdozioneId`; do not change dog stato).

After successful registra/collega/sostituisci:

```dart
await AppSheet.present<void>(
  context: context,
  builder: (context) => AppSheet(
    title: 'Segnare ${dogDisplayName(dog.nome)} come adottato?',
    children: [
      AppButton(
        label: 'Sì',
        onPressed: () async {
          Navigator.pop(context);
          final result = markDogAdottatoIfNeeded(...);
          await dogRepo.save(result.dog);
        },
      ),
      AppButton(
        label: 'No',
        variant: AppButtonVariant.grey,
        onPressed: () => Navigator.pop(context),
      ),
    ],
  ),
);
```

`AdopterFormPage`: if `dogId` query is set, after save call `replaceDogFamily` then push confirmation (or pop to dog and let the tab show the sheet). Simplest: pop to dog with extra; tab detects new link and… do **not** auto-prompt on rebuild. Prompt from the form/sheet that created the link, then `context.go(AppRoutes.dog(dogId))`.

`dogAdoptionCountProvider`: `familyLinkOf(...) == null ? 0 : 1`.

Do not change `AdoptionsPage` or `AdoptionDetailPage`.

- [ ] **Step 4: Run tests**

```
flutter test test/features/adoptions/family_link_test.dart test/features/dogs/dog_adozione_tab_test.dart test/features/adoptions/adopters_page_test.dart
flutter analyze lib/features/adoptions lib/features/dogs/dog_adozione_tab.dart lib/features/dogs/dogs_providers.dart
flutter test test/features/dogs/dog_rest_tabs_test.dart test/features/adoptions/adoptions_page_test.dart
```

Expected: PASS.

Update `test/features/dogs/step14_ter4_test.dart`: it taps `DogAdozioneTab.iterKey` and `nessunaRichiestaKey`. Replace those expects with `find.byKey(DogAdozioneTab.registraFamigliaKey)` / assenza di `Iter di adozione`. Leave `test/features/adoptions/adoptions_page_test.dart` («Registra nuova richiesta» sulla pagina `/richieste`) invariato.

```
flutter analyze
```

Expected: No issues.

- [ ] **Step 5: Commit**

```
git add lib/features/adoptions/family_link.dart lib/features/dogs/dog_adozione_tab.dart lib/features/dogs/dogs_providers.dart lib/features/adoptions/adopter_form_page.dart lib/router.dart test/features/adoptions/family_link_test.dart test/features/dogs/dog_adozione_tab_test.dart
git commit -m "feat: link one family on the dog without the adoption pipeline"
```

---

## Self-review vs spec

| Spec | Task |
|---|---|
| Date digitabili + icona calendario; tap testo ≠ picker | 1 |
| `32/13/2026` blocca il salvataggio | 1 `validateOptionalItalianDate` |
| lastDate futura solo sterilizzazione programmata | 1 `allowFuture: true` on that field |
| lastDate oggi sul foglio Situazione operato | 3 `allowFuture: false` |
| Tessera Situazione Intero/Castrato/Intera/Sterilizzata | 2 + 3 |
| Tap Stato → ChangeStatusPage | 3 |
| Tap Adottabile Sì/No | 3 |
| Sola lettura senza tap | 3 |
| PDF/card/testo maschio = Castrato | 2 |
| vendors/{id} + merge orfani | 4 |
| Elenco + scheda + form + + | 5 |
| Tipo sheet 6 voci, convenzionato default No | 5 |
| Orfano prefill tipo visita/spesa | 4 + 5 |
| Tendina Salute/Spese intatta | 4 keeps `vendorsFrom` |
| Profilo famiglia, + da Altro, no iter/affidabilità | 6 |
| Tab Adozione senza iter/richieste; registra/collega; conferma stato | 7 |
| Scollega non cambia stato cane | 7 |
| Già adottato + Sì non riscrive storico | 7 `markDogAdottatoIfNeeded` |
| Dati Roberto/Kratos = card famiglia | 7 `familyLinkOf` |
| `/richieste` invariata | 7 does not touch it |

No TBD. Names are consistent: `dogSituazioneValue`, `mergeVendorList`, `familyLinkOf`, `markDogAdottatoIfNeeded`, `replaceDogFamily`.
