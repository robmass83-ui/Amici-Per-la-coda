import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/features/dogs/dog_adozione_tab.dart';
import 'package:amici_per_la_coda/features/dogs/dog_detail_page.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_adopter_repository.dart';
import '../../helpers/fake_adoption_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_dog_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpDog(
    WidgetTester tester, {
    required InMemoryDogRepository dogs,
    InMemoryAdopterRepository? adopters,
    InMemoryAdoptionRepository? adoptions,
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
      adopters: adopters,
      adoptions: adoptions,
    );
    await tester.ensureVisible(
      find.descendant(
        of: find.byKey(DogDetailPage.tabBarKey),
        matching: find.text('Adozione'),
      ),
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(DogDetailPage.tabBarKey),
        matching: find.text('Adozione'),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tab Adozione senza iter mostra famiglia e nasconde richiesta', (
    tester,
  ) async {
    await pumpDog(
      tester,
      dogs: InMemoryDogRepository([
        testDog(id: 'fenice', nome: 'Fenice', adottabile: true),
      ]),
    );
    expect(find.text('Iter di adozione'), findsNothing);
    expect(find.text('Registra nuova richiesta'), findsNothing);
    expect(find.byKey(DogAdozioneTab.registraFamigliaKey), findsOneWidget);
    expect(find.byKey(DogAdozioneTab.collegaFamigliaKey), findsOneWidget);
  });

  testWidgets('Collega + Sì imposta adottato', (tester) async {
    final dogs = InMemoryDogRepository([
      testDog(
        id: 'fenice',
        nome: 'Fenice',
        stato: DogStato.inRifugio,
        adottabile: true,
      ),
    ]);
    final adopters = InMemoryAdopterRepository([
      testAdopter(id: 'adp1', nome: 'Roberto', cognome: 'Masala'),
    ]);
    await pumpDog(tester, dogs: dogs, adopters: adopters);
    await tester.tap(find.byKey(DogAdozioneTab.collegaFamigliaKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Roberto Masala'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DogAdozioneTab.confermaSiKey));
    await tester.pumpAndSettle();
    expect(dogs.items.single.stato, DogStato.adottato);
    expect(dogs.items.single.adottabile, isFalse);
    expect(find.byKey(DogAdozioneTab.famigliaCardKey), findsOneWidget);
  });

  testWidgets('Collega + No lascia lo stato', (tester) async {
    final dogs = InMemoryDogRepository([
      testDog(
        id: 'fenice',
        nome: 'Fenice',
        stato: DogStato.inRifugio,
        adottabile: true,
      ),
    ]);
    final adopters = InMemoryAdopterRepository([
      testAdopter(id: 'adp1', nome: 'Roberto', cognome: 'Masala'),
    ]);
    await pumpDog(tester, dogs: dogs, adopters: adopters);
    await tester.tap(find.byKey(DogAdozioneTab.collegaFamigliaKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Roberto Masala'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DogAdozioneTab.confermaNoKey));
    await tester.pumpAndSettle();
    expect(dogs.items.single.stato, DogStato.inRifugio);
    expect(dogs.items.single.adottabile, isTrue);
    expect(find.byKey(DogAdozioneTab.famigliaCardKey), findsOneWidget);
  });

  testWidgets('Scollega toglie il card e tiene l\'adottante', (tester) async {
    final adopters = InMemoryAdopterRepository([
      testAdopter(
        id: 'adp1',
        nome: 'Roberto',
        cognome: 'Masala',
        adozioniIds: const ['a1'],
      ),
    ]);
    final adoptions = InMemoryAdoptionRepository([
      testAdoption(id: 'a1', dogId: 'fenice', adopterId: 'adp1'),
    ]);
    await pumpDog(
      tester,
      dogs: InMemoryDogRepository([
        testDog(id: 'fenice', nome: 'Fenice', stato: DogStato.adottato),
      ]),
      adopters: adopters,
      adoptions: adoptions,
    );
    expect(find.byKey(DogAdozioneTab.famigliaCardKey), findsOneWidget);
    await tester.tap(find.byKey(DogAdozioneTab.scollegaKey));
    await tester.pumpAndSettle();
    expect(find.byKey(DogAdozioneTab.famigliaCardKey), findsNothing);
    expect(adopters.items, hasLength(1));
    expect(adopters.items.single.adozioniIds, isEmpty);
    expect(adoptions.items, isEmpty);
  });
}
