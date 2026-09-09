import 'package:amici_per_la_coda/data/repositories/data_repositories.dart';
import 'package:amici_per_la_coda/features/calendar/calendar_placeholder_page.dart';
import 'package:amici_per_la_coda/features/dashboard/home_page.dart';
import 'package:amici_per_la_coda/features/dashboard/placeholder_feature_page.dart';
import 'package:amici_per_la_coda/features/dogs/dog_detail_page.dart';
import 'package:amici_per_la_coda/features/dogs/dogs_page.dart';
import 'package:amici_per_la_coda/features/settings/altro_page.dart';
import 'package:amici_per_la_coda/ui/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_dog_repository.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/system_nav.dart';

void main() {
  const widths = [320.0, 360.0, 411.0, 430.0];

  Future<void> pumpLoggedIn(
    WidgetTester tester, {
    Size size = const Size(360, 900),
    DogRepository? dogs,
  }) async {
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    await pumpApp(tester, auth: auth, size: size, dogs: dogs);
  }

  testWidgets('naviga fra le 5 destinazioni della shell', (tester) async {
    await pumpLoggedIn(tester);

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(find.byType(AppLogo), findsOneWidget);
    expect(find.text('Nessun cane ancora registrato'), findsOneWidget);

    await tester.tap(find.text('Animali'));
    await tester.pumpAndSettle();
    expect(find.byType(DogsPage), findsOneWidget);
    expect(find.text('Nome, microchip, box…'), findsOneWidget);

    await tester.tap(find.text('Calendario'));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarPlaceholderPage), findsOneWidget);
    expect(
      find.text('Il calendario arriva negli step successivi.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Altro'));
    await tester.pumpAndSettle();
    expect(find.byType(AltroPage), findsOneWidget);
    expect(find.text('Catalogo UI'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);

    await tester.tap(find.byTooltip('Nuovo'));
    await tester.pumpAndSettle();
    expect(find.text('Cosa vuoi creare?'), findsOneWidget);
    expect(find.text('Nuovo cane'), findsOneWidget);
    expect(find.text('Richiesta di adozione'), findsOneWidget);
    expect(find.text('Trattamento sanitario'), findsOneWidget);
    expect(find.text('Spesa'), findsOneWidget);
    expect(find.text('Appuntamento'), findsOneWidget);
    expect(find.text('Foto rapida'), findsOneWidget);
  });

  testWidgets('lo scroll di Animali si conserva tornando sulla voce', (
    tester,
  ) async {
    await pumpLoggedIn(
      tester,
      dogs: InMemoryDogRepository([
        for (var i = 0; i < 25; i++)
          testDog(id: 'd$i', nome: 'Cane elenco ${i + 1}'),
      ]),
    );

    await tester.tap(find.text('Animali'));
    await tester.pumpAndSettle();

    final list = find.byKey(DogsPage.listKey);
    expect(list, findsOneWidget);

    await tester.fling(list, const Offset(0, -400), 2000);
    await tester.pumpAndSettle();

    final offsetAfterScroll = tester
        .state<ScrollableState>(
          find.descendant(of: list, matching: find.byType(Scrollable)),
        )
        .position
        .pixels;
    expect(offsetAfterScroll, greaterThan(0));

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);

    await tester.tap(find.text('Animali'));
    await tester.pumpAndSettle();

    final offsetAfterReturn = tester
        .state<ScrollableState>(
          find.descendant(of: list, matching: find.byType(Scrollable)),
        )
        .position
        .pixels;
    expect(offsetAfterReturn, offsetAfterScroll);
  });

  testWidgets('il FAB apre il bottom sheet', (tester) async {
    await pumpLoggedIn(tester);

    expect(find.text('Cosa vuoi creare?'), findsNothing);
    await tester.tap(find.byTooltip('Nuovo'));
    await tester.pumpAndSettle();
    expect(find.text('Cosa vuoi creare?'), findsOneWidget);
  });

  testWidgets(
    'il menu Nuovo resta sopra la barra di sistema e si può toccare',
    (tester) async {
      simulateSystemNavBar(tester);
      await pumpLoggedIn(tester, size: const Size(360, 640));
      await tester.tap(find.byTooltip('Nuovo'));
      await tester.pumpAndSettle();
      expect(find.text('Cosa vuoi creare?'), findsOneWidget);
      expectAboveSystemNav(tester, find.text('Foto rapida'));
      await tester.tap(find.text('Foto rapida'));
      await tester.pumpAndSettle();
    },
  );

  for (final width in widths) {
    testWidgets('bottom nav a ${width.toInt()} dp senza overflow', (
      tester,
    ) async {
      await pumpLoggedIn(tester, size: Size(width, 900));

      expect(tester.takeException(), isNull);
      expect(find.byType(AppBottomNav), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Animali'), findsOneWidget);
      expect(find.text('Calendario'), findsOneWidget);
      expect(find.text('Altro'), findsOneWidget);

      for (final label in ['Animali', 'Calendario', 'Altro', 'Home']) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      await tester.tap(find.byTooltip('Nuovo'));
      await tester.pumpAndSettle();
      expect(find.text('Cosa vuoi creare?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  Future<bool> tapSystemBack(WidgetTester tester) async {
    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    return handled;
  }

  testWidgets('il tasto indietro di sistema torna alla tab precedente', (
    tester,
  ) async {
    await pumpLoggedIn(tester);

    await tester.tap(find.text('Animali'));
    await tester.pumpAndSettle();
    expect(find.byType(DogsPage), findsOneWidget);

    await tester.tap(find.text('Calendario'));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarPlaceholderPage), findsOneWidget);

    expect(await tapSystemBack(tester), isTrue);
    expect(find.byType(DogsPage), findsOneWidget);

    expect(await tapSystemBack(tester), isTrue);
    expect(find.byType(HomePage), findsOneWidget);

    expect(await tapSystemBack(tester), isFalse);
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('il tasto indietro di sistema chiude la scheda cane', (
    tester,
  ) async {
    await pumpLoggedIn(
      tester,
      dogs: InMemoryDogRepository(testListDogs()),
    );

    await tester.tap(find.text('Animali'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('[PROVA] Fenice'));
    await tester.pumpAndSettle();
    expect(find.byType(DogDetailPage), findsOneWidget);

    expect(await tapSystemBack(tester), isTrue);
    expect(find.byType(DogsPage), findsOneWidget);
    expect(find.byType(DogDetailPage), findsNothing);
  });

  testWidgets('il tasto indietro di sistema chiude una scorciatoia', (
    tester,
  ) async {
    await pumpLoggedIn(
      tester,
      dogs: InMemoryDogRepository(testListDogs()),
    );

    await tester.tap(find.byTooltip('Nuovo'));
    await tester.pumpAndSettle();
    expect(find.text('Cosa vuoi creare?'), findsOneWidget);

    expect(await tapSystemBack(tester), isTrue);
    expect(find.text('Cosa vuoi creare?'), findsNothing);
    expect(find.byType(HomePage), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(HomePage.shortcutAffidoKey),
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
    await tester.tap(find.byKey(HomePage.shortcutAffidoKey));
    await tester.pumpAndSettle();
    expect(find.byType(PlaceholderFeaturePage), findsOneWidget);

    expect(await tapSystemBack(tester), isTrue);
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(PlaceholderFeaturePage), findsNothing);
  });
}
