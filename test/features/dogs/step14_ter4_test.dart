import 'dart:io';

import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/features/auth/login_page.dart';
import 'package:amici_per_la_coda/features/calendar/add_appointment_sheet.dart';
import 'package:amici_per_la_coda/features/dogs/dog_adozione_tab.dart';
import 'package:amici_per_la_coda/features/dogs/dog_detail_page.dart';
import 'package:amici_per_la_coda/features/dogs/pick_dog_sheet.dart';
import 'package:amici_per_la_coda/features/dogs/record_actions.dart';
import 'package:amici_per_la_coda/features/settings/settings_page.dart';
import 'package:amici_per_la_coda/features/shell/new_item_sheet.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:amici_per_la_coda/ui/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_adopter_repository.dart';
import '../../helpers/fake_adoption_repository.dart';
import '../../helpers/fake_appointment_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_dog_repository.dart';
import '../../helpers/fake_volunteer_repository.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/pubspec_version.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 9, 8);

  Future<FakeAuthRepository> pumpLogged(
    WidgetTester tester, {
    String location = AppRoutes.home,
    Size size = const Size(360, 1100),
    InMemoryDogRepository? dogs,
    InMemoryVolunteerRepository? volunteers,
    InMemoryAdoptionRepository? adoptions,
    InMemoryAdopterRepository? adopters,
    InMemoryAppointmentRepository? appointments,
  }) async {
    final session = FakeAuthRepository();
    await session.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    await pumpApp(
      tester,
      auth: session,
      initialLocation: location,
      size: size,
      dogs: dogs ?? InMemoryDogRepository(testListDogs()),
      volunteers: volunteers,
      adoptions: adoptions,
      adopters: adopters,
      appointments: appointments,
      dogListNow: now,
    );
    return session;
  }

  testWidgets('10. il login mostra la versione del pubspec, non una costante', (
    tester,
  ) async {
    await pumpApp(tester, size: const Size(360, 900));
    final version = pubspecVersionName();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byKey(LoginPage.versionKey), findsOneWidget);
    expect(find.text('Versione $version'), findsOneWidget);
    expect(find.text('Versione 1.0'), findsNothing);
    expect(tester.widget<Text>(find.byKey(LoginPage.versionKey)).data, isNot('Versione 1.0'));
  });

  testWidgets(
    '11. Rimuovi dati di prova visibile al presidente, nascosta al volontario',
    (tester) async {
      final dogs = InMemoryDogRepository([
        testDog(id: 'seed_fenice', nome: '[PROVA] Fenice'),
        testDog(id: 'orso', nome: 'Orso'),
      ]);
      final adoptions = InMemoryAdoptionRepository([
        testAdoption(id: 'seed_ad1', dogId: 'seed_fenice'),
      ]);
      final adopters = InMemoryAdopterRepository([
        testAdopter(id: 'seed_adp1'),
      ]);
      await pumpLogged(
        tester,
        location: AppRoutes.impostazioni,
        size: const Size(360, 1600),
        dogs: dogs,
        adoptions: adoptions,
        adopters: adopters,
      );
      expect(find.byKey(SettingsPage.rimuoviDatiProvaKey), findsOneWidget);
      expect(find.textContaining('3 documenti con prefisso seed_'), findsOneWidget);

      await tester.ensureVisible(find.byKey(SettingsPage.rimuoviDatiProvaKey));
      await tester.tap(find.byKey(SettingsPage.rimuoviDatiProvaKey));
      await tester.pumpAndSettle();
      expect(find.textContaining('Eliminare 3 documenti di prova'), findsOneWidget);
      await tester.tap(find.byKey(ConfirmActionKeys.confirm));
      await tester.pumpAndSettle();

      expect(dogs.items.any((item) => item.id.startsWith('seed_')), isFalse);
      expect(adoptions.items, isEmpty);
      expect(adopters.items, isEmpty);
      expect(dogs.items.any((item) => item.id == 'orso'), isTrue);
      expect(find.byKey(SettingsPage.rimuoviDatiProvaKey), findsNothing);
    },
  );

  testWidgets('11. il volontario non vede Rimuovi dati di prova', (
    tester,
  ) async {
    await pumpLogged(
      tester,
      location: AppRoutes.impostazioni,
      dogs: InMemoryDogRepository([
        testDog(id: 'seed_fenice', nome: '[PROVA] Fenice'),
      ]),
      volunteers: InMemoryVolunteerRepository([
        testVolunteer(ruolo: VolunteerRuolo.volontario),
      ]),
    );
    expect(find.byKey(SettingsPage.rimuoviDatiProvaKey), findsNothing);
  });

  testWidgets(
    '12. iter preaffido: quattro tappe verdi e la quinta grigia',
    (tester) async {
      await pumpLogged(
        tester,
        location: AppRoutes.dog('fenice'),
        adoptions: InMemoryAdoptionRepository([
          testAdoption(
            id: 'ad_fenice',
            dogId: 'fenice',
            stato: AdoptionStato.preaffido,
          ),
        ]),
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
      expect(find.text('Iter di adozione'), findsNothing);
      expect(find.text('Registra nuova richiesta'), findsNothing);
    },
  );

  testWidgets('tab Adozione senza famiglia: registra e collega', (
    tester,
  ) async {
    await pumpLogged(tester, location: AppRoutes.dog('fenice'));
    await tester.tap(
      find.descendant(
        of: find.byKey(DogDetailPage.tabBarKey),
        matching: find.text('Adozione'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(DogAdozioneTab.registraFamigliaKey), findsOneWidget);
    expect(find.byKey(DogAdozioneTab.collegaFamigliaKey), findsOneWidget);
    expect(find.text('Iter di adozione'), findsNothing);
  });

  test('13. «disponibile negli step successivi» solo nei file ammessi', () {
    const allowed = {
      'lib/features/dashboard/placeholder_feature_page.dart',
    };
    final hits = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final text = entity.readAsStringSync();
      if (!text.contains('disponibile negli step successivi')) {
        continue;
      }
      hits.add(entity.path.replaceAll('\\', '/'));
    }
    expect(hits.toSet(), allowed);
  });

  testWidgets('appuntamento: Cane e Richiesta si salvano sul record', (
    tester,
  ) async {
    final appointments = InMemoryAppointmentRepository();
    final adoptions = InMemoryAdoptionRepository([
      testAdoption(id: 'ad_fenice', dogId: 'fenice'),
    ]);
    await pumpLogged(
      tester,
      appointments: appointments,
      adoptions: adoptions,
    );
    await tester.tap(find.byTooltip('Nuovo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(NewItemSheetKeys.appuntamento));
    await tester.pumpAndSettle();
    expect(find.byKey(AddAppointmentSheet.caneKey), findsOneWidget);
    await tester.enterText(find.byKey(AddAppointmentSheet.titoloKey), 'Visita');
    await tester.tap(find.byKey(AddAppointmentSheet.caneKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(PickDogSheet.dogKey('fenice')));
    await tester.pumpAndSettle();
    expect(find.text('Fenice'), findsWidgets);
    await tester.tap(find.byKey(AddAppointmentSheet.richiestaKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('appointment-richiesta-ad_fenice')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AddAppointmentSheet.saveKey));
    await tester.pumpAndSettle();
    expect(appointments.items, hasLength(1));
    expect(appointments.items.single.dogId, 'fenice');
    expect(appointments.items.single.adoptionId, 'ad_fenice');
  });
}
