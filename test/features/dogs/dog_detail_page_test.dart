import 'package:amici_per_la_coda/data/models/dog.dart';
import 'package:amici_per_la_coda/features/dogs/dog_detail_page.dart';
import 'package:amici_per_la_coda/features/dogs/dog_tabs.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_dog_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  const widths = [320.0, 360.0, 411.0, 430.0];
  final now = DateTime.utc(2026, 9, 8);

  Future<void> pumpDetail(
    WidgetTester tester, {
    String dogId = 'fenice',
    List<Dog>? dogs,
    Size size = const Size(360, 1100),
  }) async {
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    await pumpApp(
      tester,
      auth: auth,
      initialLocation: AppRoutes.dog(dogId),
      size: size,
      dogs: InMemoryDogRepository(dogs ?? testListDogs()),
      dogListNow: now,
    );
  }

  Finder tabLabel(String label) {
    return find.descendant(
      of: find.byKey(DogDetailPage.tabBarKey),
      matching: find.text(label),
    );
  }

  testWidgets('tap su un cane apre la scheda', (tester) async {
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    await pumpApp(
      tester,
      auth: auth,
      initialLocation: AppRoutes.animali,
      size: const Size(360, 1100),
      dogs: InMemoryDogRepository(testListDogs()),
      dogListNow: now,
    );

    await tester.tap(find.text('[PROVA] Fenice'));
    await tester.pumpAndSettle();

    expect(find.byType(DogDetailPage), findsOneWidget);
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.text('Dolce, forte, speciale.'), findsOneWidget);
  });

  testWidgets('a 320 dp tutte e 7 le tab sono visibili senza overflow', (
    tester,
  ) async {
    await pumpDetail(tester, size: const Size(320, 1100));

    expect(tester.takeException(), isNull);
    expect(find.byType(DogDetailPage), findsOneWidget);

    final tabBar = tester.widget<TabBar>(find.byKey(DogDetailPage.tabBarKey));
    expect(tabBar.isScrollable, isFalse);
    expect(tabBar.tabs, hasLength(7));

    for (final label in DogSheetTab.labels) {
      final finder = tabLabel(label);
      expect(finder, findsOneWidget);
      final rect = tester.getRect(finder);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(320.5));
    }

    final scrollables = tester.widgetList<Scrollable>(find.byType(Scrollable));
    for (final scrollable in scrollables) {
      expect(scrollable.axis, isNot(Axis.horizontal));
    }
  });

  testWidgets('il microchip lungo non manda in overflow la riga', (
    tester,
  ) async {
    const longChip = '3802601701234569999';
    await pumpDetail(
      tester,
      dogId: 'chip',
      dogs: [testDog(id: 'chip', nome: 'ChipLungo', microchip: longChip)],
      size: const Size(320, 1100),
    );

    expect(find.byKey(DogDetailPage.microchipKey), findsOneWidget);
    expect(find.text(longChip), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tap su ogni tab cambia contenuto', (tester) async {
    await pumpDetail(tester);

    expect(
      find.byKey(DogDetailPage.tabBodyKey(DogSheetTab.scheda)),
      findsOneWidget,
    );
    expect(find.text('Carattere e compatibilità'), findsOneWidget);

    await tester.ensureVisible(tabLabel('Salute'));
    await tester.tap(tabLabel('Salute'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(DogDetailPage.tabBodyKey(DogSheetTab.salute)),
      findsOneWidget,
    );
    expect(find.text('Prossime scadenze'), findsOneWidget);

    Future<void> expectTab(String label, String content) async {
      await tester.ensureVisible(tabLabel(label));
      await tester.tap(tabLabel(label));
      await tester.pumpAndSettle();
      expect(find.text(content), findsWidgets);
    }

    await expectTab('Adozione', 'Iter di adozione');
    await expectTab('Spese', 'Ripartizione');
    await expectTab('Documenti', 'Documenti del cane');
    await expectTab('Note', 'Aggiungi nota');
    await expectTab('Altro', 'Storico completo');
  });

  for (final width in widths) {
    testWidgets('scheda cane a ${width.toInt()} dp senza overflow', (
      tester,
    ) async {
      await pumpDetail(tester, size: Size(width, 1100));

      expect(find.byType(DogDetailPage), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.fling(
        find.byType(NestedScrollView),
        const Offset(0, -300),
        2000,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
