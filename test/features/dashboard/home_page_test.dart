import 'package:amici_per_la_coda/data/models/adoption.dart';
import 'package:amici_per_la_coda/data/models/appointment.dart';
import 'package:amici_per_la_coda/data/models/dog.dart';
import 'package:amici_per_la_coda/data/models/health_record.dart';
import 'package:amici_per_la_coda/data/models/shelter_box.dart';
import 'package:amici_per_la_coda/features/dashboard/home_page.dart';
import 'package:amici_per_la_coda/features/dashboard/placeholder_feature_page.dart';
import 'package:amici_per_la_coda/features/dogs/dogs_page.dart';
import 'package:amici_per_la_coda/features/dogs/new_dog/new_dog_wizard_page.dart';
import 'package:amici_per_la_coda/ui/components.dart';
import 'package:amici_per_la_coda/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_adoption_repository.dart';
import '../../helpers/fake_appointment_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_box_repository.dart';
import '../../helpers/fake_dog_repository.dart';
import '../../helpers/fake_health_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  const widths = [320.0, 360.0, 411.0, 430.0];
  final now = DateTime(2026, 9, 8);

  Finder horizontalScrollables() {
    return find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable &&
          axisDirectionToAxis(widget.axisDirection) == Axis.horizontal,
    );
  }

  Future<void> pumpHome(
    WidgetTester tester, {
    Size size = const Size(360, 900),
    List<Dog>? dogs,
    List<ShelterBox>? boxes,
    List<Adoption>? adoptions,
    List<HealthRecord>? health,
    List<Appointment>? appointments,
    bool offline = false,
  }) async {
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    await pumpApp(
      tester,
      auth: auth,
      size: size,
      dogs: InMemoryDogRepository(dogs ?? testListDogs()),
      boxes: InMemoryBoxRepository(boxes ?? [testBox(id: 'cap', capienza: 54)]),
      adoptions: InMemoryAdoptionRepository(adoptions ?? const []),
      health: InMemoryHealthRepository(health ?? const []),
      appointments: InMemoryAppointmentRepository(appointments ?? const []),
      dogListNow: now,
      offline: offline,
    );
  }

  Future<void> revealShortcuts(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.byKey(HomePage.shortcutStatsKey),
      120,
      scrollable: find.descendant(
        of: find.byKey(HomePage.listKey),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.physics is! NeverScrollableScrollPhysics,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final width in widths) {
    testWidgets(
      'home a ${width.toInt()} dp senza overflow né scroll orizzontale',
      (tester) async {
        await pumpHome(tester, size: Size(width, 900));
        expect(find.byType(HomePage), findsOneWidget);
        await revealShortcuts(tester);

        expect(tester.takeException(), isNull);
        expect(horizontalScrollables(), findsNothing);
      },
    );
  }

  testWidgets('nella home non esiste nessuno Scrollable orizzontale', (
    tester,
  ) async {
    await pumpHome(tester);
    await revealShortcuts(tester);

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable &&
            axisDirectionToAxis(widget.axisDirection) == Axis.horizontal,
      ),
      findsNothing,
    );
  });

  testWidgets('zero richieste aperte mostra EmptyState, non una card vuota', (
    tester,
  ) async {
    await pumpHome(tester, adoptions: const []);

    expect(find.text('Nessuna richiesta in sospeso'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(HomePage.richiesteCardKey),
        matching: find.byType(EmptyState),
      ),
      findsOneWidget,
    );
    expect(find.text('0 nuove ›'), findsOneWidget);
  });

  testWidgets('un solo cane in Ultimi arrivi non deforma la card', (
    tester,
  ) async {
    await pumpHome(tester, dogs: [testDog(id: 'solo', nome: 'Solo')]);

    final row = find.byKey(HomePage.ultimiArriviRowKey);
    final cards = find.descendant(of: row, matching: find.byType(AppCard));
    expect(cards, findsOneWidget);
    expect(find.text('Solo'), findsOneWidget);

    final rowWidth = tester.getSize(row).width;
    final cardWidth = tester.getSize(cards).width;
    final slot = (rowWidth - 2 * AppDim.gapM) / 3;
    expect(cardWidth, closeTo(slot, 1.5));
    expect(cardWidth, lessThan(rowWidth * 0.5));
  });

  testWidgets('Vedi tutti e le 4 scorciatoie portano alle rotte giuste', (
    tester,
  ) async {
    await pumpHome(tester);

    await tester.tap(find.text('Vedi tutti ›'));
    await tester.pumpAndSettle();
    expect(find.byType(DogsPage), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    Future<void> tapShortcut(Key key, String title) async {
      await revealShortcuts(tester);
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
      expect(find.byType(PlaceholderFeaturePage), findsOneWidget);
      expect(find.text(title), findsWidgets);
      await tester.tap(find.byTooltip('Indietro'));
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
    }

    await revealShortcuts(tester);
    await tester.tap(find.byKey(HomePage.shortcutNuovoKey));
    await tester.pumpAndSettle();
    expect(find.byType(NewDogWizardPage), findsOneWidget);
    expect(find.textContaining('Nuovo cane'), findsWidgets);
    await tester.tap(find.byTooltip('Indietro'));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);

    await tapShortcut(HomePage.shortcutAffidoKey, 'Modulo affido');
    await tapShortcut(HomePage.shortcutBoxKey, 'Box e settori');
    await tapShortcut(HomePage.shortcutStatsKey, 'Statistiche');
  });

  testWidgets('database vuoto mostra EmptyState e il pulsante del primo cane', (
    tester,
  ) async {
    await pumpHome(tester, dogs: const []);

    expect(find.text('Nessun cane ancora registrato'), findsOneWidget);
    expect(find.text('Aggiungi il primo cane'), findsOneWidget);
    expect(find.text('Cani in rifugio'), findsNothing);

    await tester.tap(find.text('Aggiungi il primo cane'));
    await tester.pumpAndSettle();
    expect(find.byType(NewDogWizardPage), findsOneWidget);
    expect(find.textContaining('Nuovo cane'), findsWidgets);
  });

  testWidgets('offline mostra la riga di avviso in cima', (tester) async {
    await pumpHome(tester, offline: true);

    expect(find.byKey(HomePage.offlineBannerKey), findsOneWidget);
    expect(find.text('Dati non aggiornati · sei offline'), findsOneWidget);
  });

  testWidgets('posti non configurati nasconde la barra di occupazione', (
    tester,
  ) async {
    await pumpHome(tester, boxes: const []);

    expect(find.text('posti non configurati'), findsOneWidget);
    expect(find.textContaining('% dei'), findsNothing);
  });
}
