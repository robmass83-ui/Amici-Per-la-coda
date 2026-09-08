import 'package:amici_per_la_coda/data/models/dog.dart';
import 'package:amici_per_la_coda/features/dogs/dogs_page.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:amici_per_la_coda/ui/components.dart';
import 'package:amici_per_la_coda/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_dog_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  const widths = [320.0, 360.0, 411.0, 430.0];
  final now = DateTime.utc(2026, 9, 8);

  Future<void> pumpDogs(
    WidgetTester tester, {
    List<Dog>? dogs,
    Size size = const Size(360, 900),
  }) async {
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    await pumpApp(
      tester,
      auth: auth,
      initialLocation: AppRoutes.animali,
      size: size,
      dogs: InMemoryDogRepository(dogs ?? testListDogs()),
      dogListNow: now,
    );
  }

  testWidgets('cercando fen resta 1 risultato', (tester) async {
    await pumpDogs(tester);

    await tester.enterText(find.byType(TextField), 'fen');
    await tester.pumpAndSettle();

    expect(find.text('1 risultato'), findsOneWidget);
    expect(find.text('[PROVA] Fenice'), findsOneWidget);
    expect(find.text('[PROVA] Brando'), findsNothing);
    expect(find.text('[PROVA] Nina'), findsNothing);
  });

  testWidgets('cercando il microchip completo resta 1 risultato', (
    tester,
  ) async {
    await pumpDogs(tester);

    await tester.enterText(find.byType(TextField), '380260043210987');
    await tester.pumpAndSettle();

    expect(find.text('1 risultato'), findsOneWidget);
    expect(find.text('[PROVA] Fenice'), findsOneWidget);
    expect(find.text('[PROVA] Zeus'), findsNothing);
  });

  testWidgets('il filtro In stallo mostra solo Nina', (tester) async {
    await pumpDogs(tester);

    await tester.tap(find.text('Stallo'));
    await tester.pumpAndSettle();

    expect(find.text('1 risultato'), findsOneWidget);
    expect(find.text('[PROVA] Nina'), findsOneWidget);
    expect(find.text('[PROVA] Fenice'), findsNothing);
    expect(find.text('[PROVA] Brando'), findsNothing);
  });

  testWidgets('lista vuota mostra EmptyState', (tester) async {
    await pumpDogs(tester, dogs: const []);

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Nessun cane in elenco.'), findsOneWidget);
    expect(find.text('0 risultati'), findsOneWidget);
  });

  testWidgets('i filtri rapidi stanno su una sola riga orizzontale', (
    tester,
  ) async {
    await pumpDogs(tester, size: const Size(320, 640));

    expect(find.byKey(DogsPage.filtersKey), findsOneWidget);
    expect(find.byType(AppSegmented), findsOneWidget);
    expect(find.text('Tutti'), findsOneWidget);
    expect(find.text('Rifugio'), findsOneWidget);
    expect(find.text('Stallo'), findsOneWidget);
    expect(find.text('Adottab.'), findsOneWidget);
    expect(find.text('Cuccioli'), findsOneWidget);

    final bar = tester.getRect(find.byKey(DogsPage.filtersKey));
    final tutti = tester.getRect(find.text('Tutti'));
    final cuccioli = tester.getRect(find.text('Cuccioli'));
    expect(bar.height, AppDim.minTouch);
    expect(tutti.center.dy, closeTo(cuccioli.center.dy, 1));
    expect(cuccioli.left, greaterThan(tutti.right));
    expect(tester.takeException(), isNull);
  });

  for (final width in widths) {
    testWidgets(
      'nome di 40 caratteri a ${width.toInt()} dp senza overflow',
      (tester) async {
        const longName =
            'AbcdefghijAbcdefghijAbcdefghijAbcdefghij'; // 40
        await pumpDogs(
          tester,
          dogs: [testDog(id: 'lungo', nome: longName)],
          size: Size(width, 900),
        );

        expect(find.byType(DogsPage), findsOneWidget);
        expect(find.text(longName), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
