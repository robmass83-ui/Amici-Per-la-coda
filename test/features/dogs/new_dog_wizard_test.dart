import 'package:amici_per_la_coda/features/dogs/dog_detail_page.dart';
import 'package:amici_per_la_coda/features/dogs/dogs_page.dart';
import 'package:amici_per_la_coda/features/dogs/new_dog/new_dog_draft_store.dart';
import 'package:amici_per_la_coda/features/dogs/new_dog/new_dog_wizard_page.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_box_repository.dart';
import '../../helpers/fake_dog_repository.dart';
import '../../helpers/fake_health_repository.dart';
import '../../helpers/fake_microchip_scanner.dart';
import '../../helpers/fake_photo_repository.dart';
import '../../helpers/fake_volunteer_repository.dart';
import '../../helpers/fake_weight_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const widths = [320.0, 360.0, 411.0, 430.0];
  final now = DateTime(2026, 9, 8);

  Finder horizontalScrollables() {
    return find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable &&
          axisDirectionToAxis(widget.axisDirection) == Axis.horizontal &&
          widget.restorationId != 'editable',
    );
  }

  Future<void> pumpWizard(
    WidgetTester tester, {
    Size size = const Size(360, 1100),
    InMemoryDogRepository? dogs,
    InMemoryDogDraftStore? drafts,
    FakeMicrochipScanner? scanner,
  }) async {
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    final dogRepo = dogs ?? InMemoryDogRepository();
    await pumpApp(
      tester,
      auth: auth,
      initialLocation: AppRoutes.nuovo,
      size: size,
      dogs: dogRepo,
      health: InMemoryHealthRepository(),
      weights: InMemoryWeightRepository(const [], dogRepo),
      photos: InMemoryPhotoRepository(dogs: dogRepo),
      boxes: InMemoryBoxRepository([testBox()]),
      volunteers: InMemoryVolunteerRepository([testVolunteer()]),
      drafts: drafts,
      scanner: scanner ?? FakeMicrochipScanner(),
      dogListNow: now,
    );
  }

  testWidgets('nome vuoto blocca l\'avanzamento', (tester) async {
    await pumpWizard(tester);

    expect(find.text('Nuovo cane · 1 di 3'), findsOneWidget);
    await tester.tap(find.byKey(NewDogWizardPage.continuaKey));
    await tester.pumpAndSettle();

    expect(find.text('Inserisci il nome del cane.'), findsOneWidget);
    expect(find.text('Nuovo cane · 1 di 3'), findsOneWidget);
    expect(find.text('Nuovo cane · 2 di 3'), findsNothing);
  });

  testWidgets('microchip non di 15 cifre mostra errore sotto il campo', (
    tester,
  ) async {
    await pumpWizard(tester);

    await tester.enterText(find.byKey(NewDogWizardPage.nomeKey), 'Nerone');
    await tester.enterText(find.byKey(NewDogWizardPage.microchipKey), '12345');
    await tester.tap(find.byKey(NewDogWizardPage.continuaKey));
    await tester.pumpAndSettle();

    expect(find.text('Il microchip deve avere 15 cifre.'), findsOneWidget);
    expect(find.text('Nuovo cane · 1 di 3'), findsOneWidget);
  });

  testWidgets('completando i 3 passaggi il cane compare in elenco', (
    tester,
  ) async {
    final dogs = InMemoryDogRepository();
    await pumpWizard(tester, dogs: dogs);

    await tester.enterText(find.byKey(NewDogWizardPage.nomeKey), 'Nerone');
    await tester.enterText(
      find.byKey(NewDogWizardPage.microchipKey),
      '380260170123456',
    );
    await tester.tap(find.byKey(NewDogWizardPage.continuaKey));
    await tester.pumpAndSettle();
    expect(find.text('Nuovo cane · 2 di 3'), findsOneWidget);

    await tester.tap(find.byKey(NewDogWizardPage.continuaKey));
    await tester.pumpAndSettle();
    expect(find.text('Nuovo cane · 3 di 3'), findsOneWidget);

    await tester.tap(find.byKey(NewDogWizardPage.creaKey));
    await tester.pumpAndSettle();

    expect(find.byType(DogDetailPage), findsOneWidget);
    expect(find.text('Nerone'), findsWidgets);
    expect(dogs.watchAll(), isNotNull);
    final saved = await dogs.getById(
      (await dogs.watchAll().first).single.id,
    );
    expect(saved?.nome, 'Nerone');
    expect(saved?.microchip, '380260170123456');

    await tester.tap(find.byTooltip('Indietro'));
    await tester.pumpAndSettle();
    expect(find.byType(DogsPage), findsOneWidget);
    expect(find.text('Nerone'), findsOneWidget);
  });

  testWidgets('la bozza sopravvive alla chiusura dell\'app', (tester) async {
    final drafts = InMemoryDogDraftStore();
    await pumpWizard(tester, drafts: drafts);

    await tester.enterText(find.byKey(NewDogWizardPage.nomeKey), 'Bozza Luna');
    await tester.tap(find.byKey(NewDogWizardPage.salvaBozzaKey));
    await tester.pumpAndSettle();
    expect(find.text('Bozza salvata.'), findsOneWidget);

    await pumpWizard(tester, drafts: drafts);
    expect(find.text('Bozza Luna'), findsOneWidget);
    expect(find.text('Nuovo cane · 1 di 3'), findsOneWidget);
  });

  testWidgets('lo scanner compila il microchip a 15 cifre', (tester) async {
    await pumpWizard(
      tester,
      scanner: FakeMicrochipScanner(code: '380260170123456'),
    );

    await tester.tap(find.byKey(NewDogWizardPage.scanKey));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(NewDogWizardPage.microchipKey),
        matching: find.byType(TextField),
      ),
    );
    expect(field.controller?.text, '380260170123456');
  });

  for (final width in widths) {
    testWidgets('wizard senza overflow a ${width.toInt()} dp', (tester) async {
      await pumpWizard(tester, size: Size(width, 1100));

      expect(tester.takeException(), isNull);
      expect(horizontalScrollables(), findsNothing);
      expect(find.text('Nome del cane *'), findsOneWidget);

      await tester.enterText(find.byKey(NewDogWizardPage.nomeKey), 'Nerone');
      await tester.tap(find.byKey(NewDogWizardPage.continuaKey));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(horizontalScrollables(), findsNothing);
      expect(find.text('Foto del profilo'), findsOneWidget);

      await tester.tap(find.byKey(NewDogWizardPage.continuaKey));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(horizontalScrollables(), findsNothing);
      expect(find.text('Riepilogo'), findsOneWidget);
    });
  }

  testWidgets('nessun campo tagliato a 320 dp', (tester) async {
    await pumpWizard(tester, size: const Size(320, 1100));

    expect(tester.takeException(), isNull);
    expect(find.text('Nome del cane *'), findsOneWidget);
    expect(find.text('Microchip'), findsOneWidget);
    expect(find.text('Iscritto in anagrafe canina'), findsOneWidget);
    expect(find.text('Continua →'), findsOneWidget);
  });
}
