import 'package:amici_per_la_coda/features/dogs/dog_detail_page.dart';
import 'package:amici_per_la_coda/features/dogs/peso_chart.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_dog_repository.dart';
import '../../helpers/fake_weight_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  final now = DateTime.utc(2026, 9, 8);

  testWidgets('il grafico peso con tre pesate mostra tre punti', (tester) async {
    final dogs = InMemoryDogRepository(testListDogs());
    final weights = InMemoryWeightRepository([
      testWeight(id: 'w1', data: DateTime.utc(2026, 1, 12), kg: 17),
      testWeight(id: 'w2', data: DateTime.utc(2026, 2, 12), kg: 19.5),
      testWeight(id: 'w3', data: DateTime.utc(2026, 3, 12), kg: 22),
    ], dogs);
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    await pumpApp(
      tester,
      auth: auth,
      initialLocation: AppRoutes.dog('fenice'),
      size: const Size(360, 1100),
      dogs: dogs,
      weights: weights,
      dogListNow: now,
    );

    await tester.tap(
      find.descendant(
        of: find.byKey(DogDetailPage.tabBarKey),
        matching: find.text('Salute'),
      ),
    );
    await tester.pumpAndSettle();

    final chart = tester.widget<PesoChart>(find.byType(PesoChart));
    expect(chart.punti, hasLength(3));
    expect(chart.punti.map((p) => p.kg).toList(), [17, 19.5, 22]);
  });

  test('registrare un peso aggiorna dogs.pesoKg all\'ultimo valore', () async {
    final dogs = InMemoryDogRepository([testDog(id: 'fenice', pesoKg: 12)]);
    final weights = InMemoryWeightRepository(const [], dogs);
    await weights.save(testWeight(dogId: 'fenice', kg: 18.5));
    expect((await dogs.getById('fenice'))!.pesoKg, 18.5);
  });
}
