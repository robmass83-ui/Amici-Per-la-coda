import 'package:amici_per_la_coda/data/models/dog.dart';
import 'package:amici_per_la_coda/features/dogs/add_treatment_sheet.dart';
import 'package:amici_per_la_coda/features/dogs/dog_detail_page.dart';
import 'package:amici_per_la_coda/features/dogs/dog_salute_tab.dart';
import 'package:amici_per_la_coda/features/dogs/dog_scheda_tab.dart';
import 'package:amici_per_la_coda/features/dogs/dog_tabs.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:amici_per_la_coda/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_dog_repository.dart';
import '../../helpers/fake_health_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  final now = DateTime.utc(2026, 9, 8);

  Finder tabLabel(String label) {
    return find.descendant(
      of: find.byKey(DogDetailPage.tabBarKey),
      matching: find.text(label),
    );
  }

  Future<void> pumpDetail(
    WidgetTester tester, {
    String dogId = 'fenice',
    List<Dog>? dogs,
    InMemoryHealthRepository? health,
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
      health: health ?? InMemoryHealthRepository(),
      dogListNow: now,
    );
  }

  testWidgets(
    'vaccino con scadenza fra 3 giorni compare in rosso fra le prossime scadenze',
    (tester) async {
      final health = InMemoryHealthRepository();
      await pumpDetail(tester, health: health);

      await tester.ensureVisible(tabLabel('Salute'));
      await tester.tap(tabLabel('Salute'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(DogSaluteTab.addTreatmentKey));
      await tester.tap(find.byKey(DogSaluteTab.addTreatmentKey));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(AddTreatmentSheet.descrizioneKey),
        'Richiamo vaccino polivalente',
      );
      await tester.enterText(
        find.byKey(AddTreatmentSheet.scadenzaKey),
        '11/09/2026',
      );
      await tester.tap(find.byKey(AddTreatmentSheet.saveKey));
      await tester.pumpAndSettle();

      expect(find.text('Richiamo vaccino polivalente'), findsOneWidget);
      expect(find.text('tra 3 gg'), findsOneWidget);
      final label = tester.widget<Text>(find.text('tra 3 gg'));
      expect(label.style?.color, AppColor.red);
    },
  );

  testWidgets('la griglia 2×2 non va in overflow con testi lunghi', (
    tester,
  ) async {
    const long =
        'Dolcissima socievole equilibrata giocosa affettuosa '
        'paziente curiosa e sempre pronta alle coccole in famiglia numerosa';
    await pumpDetail(
      tester,
      dogId: 'lungo',
      dogs: [
        testDog(
          id: 'lungo',
          nome: 'NomeVeramenteMoltoLungoDelCane',
          carattere: const [long],
          noteCarattere: '$long. $long',
          microchip: '3802601701234569999',
          provenienza: 'Un comune con un nome estremamente lungo in provincia',
        ),
      ],
      size: const Size(320, 1100),
    );

    expect(find.byKey(DogSchedaTab.gridKey), findsOneWidget);
    expect(find.text('Carattere e compatibilità'), findsOneWidget);
    expect(find.text('Stato adozione'), findsOneWidget);
    expect(find.text('Ultime attività sanitarie'), findsOneWidget);
    expect(find.text('Spese sostenute'), findsOneWidget);

    await tester.fling(
      find.byType(NestedScrollView),
      const Offset(0, -400),
      2000,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final scrollables = tester.widgetList<Scrollable>(find.byType(Scrollable));
    for (final scrollable in scrollables) {
      expect(scrollable.axis, isNot(Axis.horizontal));
    }
  });

  testWidgets('tab Salute visibile senza overflow a 320 dp', (tester) async {
    await pumpDetail(tester, size: const Size(320, 1100));
    await tester.tap(tabLabel('Salute'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(DogDetailPage.tabBodyKey(DogSheetTab.salute)),
      findsOneWidget,
    );
    expect(find.text('Aggiungi trattamento'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
