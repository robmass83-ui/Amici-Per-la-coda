import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/features/dogs/change_status_page.dart';
import 'package:amici_per_la_coda/features/dogs/dog_detail_page.dart';
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

  Finder tile(String label) {
    return find.ancestor(
      of: find.text(label),
      matching: find.byType(StatTile),
    );
  }

  testWidgets('tessera Situazione mostra Intera su femmina non operata', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      dogs: InMemoryDogRepository([
        testDog(
          id: 'fenice',
          nome: 'Luna',
          sesso: DogSex.F,
          sterilizzato: false,
        ),
      ]),
    );
    expect(find.byType(DogDetailPage), findsOneWidget);
    expect(find.text('Situazione'), findsOneWidget);
    expect(find.text('Intera'), findsWidgets);
  });

  testWidgets('tap Stato attuale apre Cambia stato', (tester) async {
    await pumpDetail(tester, dogs: InMemoryDogRepository(testListDogs()));
    await tester.ensureVisible(tile('Stato attuale'));
    await tester.tap(tile('Stato attuale'));
    await tester.pumpAndSettle();
    expect(find.byType(ChangeStatusPage), findsOneWidget);
  });

  testWidgets('salvare Castrato su maschio aggiorna il cane', (tester) async {
    final dogs = InMemoryDogRepository([
      testDog(
        id: 'fenice',
        nome: 'Kratos',
        sesso: DogSex.M,
        sterilizzato: false,
      ),
    ]);
    await pumpDetail(tester, dogs: dogs);
    await tester.ensureVisible(tile('Situazione'));
    await tester.tap(tile('Situazione'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Castrato'));
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();
    expect(dogs.items.single.sterilizzato, isTrue);
    expect(find.text('Castrato'), findsWidgets);
  });

  testWidgets('volontario in sola lettura non apre i fogli', (tester) async {
    await pumpDetail(
      tester,
      dogs: InMemoryDogRepository(testListDogs()),
      volunteers: InMemoryVolunteerRepository([
        testVolunteer(ruolo: VolunteerRuolo.volontario),
      ]),
    );
    await tester.ensureVisible(tile('Situazione'));
    await tester.tap(tile('Situazione'));
    await tester.pumpAndSettle();
    expect(find.text('Salva'), findsNothing);
  });
}
