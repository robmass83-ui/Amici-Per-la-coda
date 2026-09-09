import 'package:amici_per_la_coda/data/models/dog.dart';
import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/features/adoptions/adoption_detail_page.dart';
import 'package:amici_per_la_coda/features/adoptions/adoptions_page.dart';
import 'package:amici_per_la_coda/features/adoptions/new_adoption_page.dart';
import 'package:amici_per_la_coda/features/dogs/dog_detail_page.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_adopter_repository.dart';
import '../../helpers/fake_adoption_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_dog_repository.dart';
import '../../helpers/fake_volunteer_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
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

  Future<void> pumpLogged(
    WidgetTester tester, {
    String location = AppRoutes.richieste,
    Size size = const Size(360, 1400),
    List<Dog>? dogs,
    InMemoryAdoptionRepository? adoptions,
    InMemoryAdopterRepository? adopters,
  }) async {
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    await pumpApp(
      tester,
      auth: auth,
      initialLocation: location,
      size: size,
      dogs: InMemoryDogRepository(dogs ?? testListDogs()),
      adoptions: adoptions ?? InMemoryAdoptionRepository(),
      adopters: adopters ?? InMemoryAdopterRepository(),
      volunteers: InMemoryVolunteerRepository([testVolunteer()]),
      dogListNow: now,
    );
  }

  testWidgets('elenco e dettaglio senza overflow né scroll orizzontale', (
    tester,
  ) async {
    final adoptions = InMemoryAdoptionRepository([
      testAdoption(
        id: 'ad1',
        dogId: 'fenice',
        richiedente: testRichiedente(
          nome: 'MartaRossiNomeMoltoLungoPerVerificareEllipsis',
          cognome: 'CognomeEstesoOltreLaRiga',
        ),
      ),
    ]);
    for (final width in widths) {
      await pumpLogged(
        tester,
        size: Size(width, 1400),
        adoptions: adoptions,
      );
      expect(tester.takeException(), isNull);
      expect(horizontalScrollables(), findsNothing);
      expect(find.byType(AdoptionsPage), findsOneWidget);

      await tester.tap(find.byKey(AdoptionsPage.cardKey('ad1')));
      await tester.pumpAndSettle();
      expect(find.byType(AdoptionDetailPage), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(horizontalScrollables(), findsNothing);

      await tester.tap(find.byTooltip('Indietro'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('avanzando a preaffido il cane passa in stato preaffido', (
    tester,
  ) async {
    final dogs = InMemoryDogRepository([
      testDog(id: 'luna', nome: 'Luna', adottabile: true),
    ]);
    final adoptions = InMemoryAdoptionRepository([
      testAdoption(
        id: 'ad1',
        dogId: 'luna',
        stato: AdoptionStato.visita,
        richiedente: testRichiedente(nome: 'Marta', cognome: 'Rossi'),
      ),
    ]);
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    await pumpApp(
      tester,
      auth: auth,
      initialLocation: AppRoutes.richiesta('ad1'),
      size: const Size(360, 1400),
      dogs: dogs,
      adoptions: adoptions,
      volunteers: InMemoryVolunteerRepository([testVolunteer()]),
      dogListNow: now,
    );

    await tester.ensureVisible(find.byKey(AdoptionDetailPage.avanzaKey));
    await tester.tap(find.byKey(AdoptionDetailPage.avanzaKey));
    await tester.pumpAndSettle();

    final dog = await dogs.getById('luna');
    expect(dog?.stato, DogStato.preaffido);
    expect(dog?.adottabile, isFalse);
    final adoption = await adoptions.getById('ad1');
    expect(adoption?.stato, AdoptionStato.preaffido);
  });

  testWidgets('respingendo la richiesta il cane torna adottabile', (
    tester,
  ) async {
    final dogs = InMemoryDogRepository([
      testDog(
        id: 'otto',
        nome: 'Otto',
        stato: DogStato.preaffido,
        adottabile: false,
      ),
    ]);
    final adoptions = InMemoryAdoptionRepository([
      testAdoption(
        id: 'ad1',
        dogId: 'otto',
        stato: AdoptionStato.preaffido,
      ),
    ]);
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    await pumpApp(
      tester,
      auth: auth,
      initialLocation: AppRoutes.richiesta('ad1'),
      size: const Size(360, 1400),
      dogs: dogs,
      adoptions: adoptions,
      volunteers: InMemoryVolunteerRepository([testVolunteer()]),
      dogListNow: now,
    );

    await tester.ensureVisible(find.byKey(AdoptionDetailPage.respingiKey));
    await tester.tap(find.byKey(AdoptionDetailPage.respingiKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AdoptionDetailPage.confirmKey));
    await tester.pumpAndSettle();

    final dog = await dogs.getById('otto');
    expect(dog?.adottabile, isTrue);
    expect(dog?.stato, DogStato.inRifugio);
  });

  testWidgets('il contatore Richieste nella scheda cane è corretto', (
    tester,
  ) async {
    final dogs = InMemoryDogRepository(testListDogs());
    final adoptions = InMemoryAdoptionRepository();
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    await pumpApp(
      tester,
      auth: auth,
      initialLocation: AppRoutes.dog('fenice'),
      size: const Size(360, 2400),
      dogs: dogs,
      adoptions: adoptions,
      adopters: InMemoryAdopterRepository(),
      volunteers: InMemoryVolunteerRepository([testVolunteer()]),
      dogListNow: now,
    );

    expect(find.text('0'), findsWidgets);

    await tester.ensureVisible(find.text('Adozione'));
    await tester.tap(
      find.descendant(
        of: find.byKey(DogDetailPage.tabBarKey),
        matching: find.text('Adozione'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Registra nuova richiesta'));
    await tester.tap(find.text('Registra nuova richiesta'));
    await tester.pumpAndSettle();
    expect(find.byType(NewAdoptionPage), findsOneWidget);

    await tester.enterText(find.byKey(NewAdoptionPage.nomeKey), 'Marta');
    await tester.enterText(find.byKey(NewAdoptionPage.cognomeKey), 'Rossi');
    await tester.enterText(
      find.byKey(NewAdoptionPage.abitazioneKey),
      'Villetta con giardino',
    );
    await tester.ensureVisible(find.byKey(NewAdoptionPage.saveKey));
    await tester.tap(find.byKey(NewAdoptionPage.saveKey));
    await tester.pumpAndSettle();

    expect((await adoptions.watchAll().first).length, 1);
    expect(find.byType(DogDetailPage), findsOneWidget);
    expect(find.text('Marta Rossi'), findsOneWidget);
    expect(find.text('Richieste ricevute'), findsOneWidget);
  });

  testWidgets('il questionario si salva integralmente', (tester) async {
    final adoptions = InMemoryAdoptionRepository([
      testAdoption(
        id: 'ad1',
        dogId: 'fenice',
        questionario: testQuestionario(),
      ),
    ]);
    await pumpLogged(
      tester,
      location: AppRoutes.richiesta('ad1'),
      size: const Size(360, 2400),
      adoptions: adoptions,
    );

    await tester.ensureVisible(find.text('Modifica ›'));
    await tester.tap(find.text('Modifica ›'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(AdoptionDetailPage.abitazioneKey),
      'Villetta 300 m²',
    );
    await tester.enterText(find.byKey(AdoptionDetailPage.recinzioneKey), '1,8 m');
    await tester.enterText(find.byKey(AdoptionDetailPage.animaliKey), '1 gatto');
    await tester.enterText(find.byKey(AdoptionDetailPage.bambiniKey), '8 e 11');
    await tester.enterText(find.byKey(AdoptionDetailPage.oreKey), 'Max 4 ore');
    await tester.enterText(
      find.byKey(AdoptionDetailPage.esperienzaKey),
      'Sì, precedente meticcio',
    );
    await tester.enterText(find.byKey(AdoptionDetailPage.dormeKey), 'In casa');
    await tester.enterText(
      find.byKey(AdoptionDetailPage.noteKey),
      'Note complete',
    );
    await tester.ensureVisible(find.byKey(AdoptionDetailPage.saveQuestionarioKey));
    await tester.tap(find.byKey(AdoptionDetailPage.saveQuestionarioKey));
    await tester.pumpAndSettle();

    final saved = await adoptions.getById('ad1');
    expect(saved?.questionario.abitazione, 'Villetta 300 m²');
    expect(saved?.questionario.altezzaRecinzione, '1,8 m');
    expect(saved?.questionario.altriAnimali, '1 gatto');
    expect(saved?.questionario.bambini, '8 e 11');
    expect(saved?.questionario.oreDaSolo, 'Max 4 ore');
    expect(saved?.questionario.esperienzaCani, 'Sì, precedente meticcio');
    expect(saved?.questionario.doveDormira, 'In casa');
    expect(saved?.questionario.note, 'Note complete');
    expect(saved?.questionario.giardinoRecintato, isTrue);
  });

  testWidgets('filtro Chiuse mostra lo stato vuoto se non ci sono concluse', (
    tester,
  ) async {
    await pumpLogged(
      tester,
      adoptions: InMemoryAdoptionRepository([
        testAdoption(id: 'ad1', dogId: 'fenice'),
      ]),
    );
    await tester.tap(find.text('Chiuse'));
    await tester.pumpAndSettle();
    expect(find.text('Nessuna richiesta in questo filtro.'), findsOneWidget);
  });
}
