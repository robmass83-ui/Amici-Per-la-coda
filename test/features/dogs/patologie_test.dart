import 'package:amici_per_la_coda/data/models/dog.dart';
import 'package:amici_per_la_coda/features/dogs/dog_detail_page.dart';
import 'package:amici_per_la_coda/features/dogs/dog_salute_tab.dart';
import 'package:amici_per_la_coda/features/dogs/dog_scheda_tab.dart';
import 'package:amici_per_la_coda/features/dogs/patologie.dart';
import 'package:amici_per_la_coda/features/dogs/patologie_sheet.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_dog_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  final now = DateTime.utc(2026, 9, 8);

  Finder tabLabel(String label) {
    return find.descendant(
      of: find.byKey(DogDetailPage.tabBarKey),
      matching: find.text(label),
    );
  }

  test('toggle aggiunge e toglie più patologie dal testo libero', () {
    var testo = 'Sospetta infezione';
    testo = togglePatologiaNelTesto(testo, 'Leishmania');
    testo = togglePatologiaNelTesto(testo, 'Filaria');
    expect(testo, 'Sospetta infezione, Leishmania, Filaria');
    expect(patologiaSelezionata(testo, 'Leishmania'), isTrue);
    expect(patologiaSelezionata(testo, 'Giardia'), isFalse);
    testo = togglePatologiaNelTesto(testo, 'Leishmania');
    expect(testo, 'Sospetta infezione, Filaria');
    expect(patologieRiepilogo(''), 'Nessuna');
    expect(patologieRiepilogo('  '), 'Nessuna');
    expect(haPatologie(''), isFalse);
  });

  test('fromMap senza campo patologie resta vuoto', () {
    final withValue = testDog().copyWith(patologie: 'Giardia');
    expect(withValue.toMap()['patologie'], 'Giardia');
    expect(Dog.fromMap(withValue.id, withValue.toMap()).patologie, 'Giardia');
    final map = testDog().toMap()..remove('patologie');
    expect(Dog.fromMap('fido', map).patologie, '');
  });

  testWidgets(
    'tab Salute: chip rapide si sommano al testo e si salvano sulla scheda',
    (tester) async {
      final auth = FakeAuthRepository();
      await auth.signIn(
        email: 'giovanna@amiciperlacoda.it',
        password: 'corretta',
      );
      final dogs = InMemoryDogRepository(testListDogs());
      await pumpApp(
        tester,
        auth: auth,
        initialLocation: AppRoutes.dog('fenice'),
        size: const Size(360, 1100),
        dogs: dogs,
        dogListNow: now,
      );

      expect(find.byKey(DogSchedaTab.patologieKey), findsOneWidget);
      expect(find.text('Nessuna'), findsOneWidget);

      await tester.tap(tabLabel('Salute'));
      await tester.pumpAndSettle();
      expect(find.text('Nessuna patologia.'), findsOneWidget);

      await tester.ensureVisible(find.byKey(DogSaluteTab.editPatologieKey));
      await tester.tap(find.byKey(DogSaluteTab.editPatologieKey));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(PatologieSheet.testoKey),
        'Sospetta infezione',
      );
      await tester.pump();
      await tester.tap(find.byKey(PatologieSheet.chipKey('Leishmania')));
      await tester.pump();
      await tester.tap(find.byKey(PatologieSheet.chipKey('Giardia')));
      await tester.pump();
      expect(find.text('Sospetta infezione, Leishmania, Giardia'), findsOneWidget);

      await tester.tap(find.byKey(PatologieSheet.saveKey));
      await tester.pumpAndSettle();

      expect(find.text('Leishmania'), findsWidgets);
      expect(find.text('Giardia'), findsWidgets);
      expect(find.text('Sospetta infezione'), findsOneWidget);
      expect(find.text('Modifica patologie'), findsOneWidget);

      await tester.tap(tabLabel('Scheda'));
      await tester.pumpAndSettle();
      expect(
        find.text('Sospetta infezione, Leishmania, Giardia'),
        findsOneWidget,
      );
      expect(find.text('Nessuna'), findsNothing);
    },
  );
}
