import 'package:amici_per_la_coda/core/local_notifications.dart';
import 'package:amici_per_la_coda/core/write_queue.dart';
import 'package:amici_per_la_coda/data/firestore/firestore_repositories.dart';
import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/data/models/note.dart';
import 'package:amici_per_la_coda/features/adoptions/adopters_page.dart';
import 'package:amici_per_la_coda/features/adoptions/adoption_detail_page.dart';
import 'package:amici_per_la_coda/features/adoptions/adoptions_page.dart';
import 'package:amici_per_la_coda/features/adoptions/new_adoption_page.dart';
import 'package:amici_per_la_coda/features/affido/affido_page.dart';
import 'package:amici_per_la_coda/features/auth/login_page.dart';
import 'package:amici_per_la_coda/features/boxes/boxes_page.dart';
import 'package:amici_per_la_coda/features/calendar/calendar_page.dart';
import 'package:amici_per_la_coda/features/dashboard/home_page.dart';
import 'package:amici_per_la_coda/features/dogs/archived_dogs_page.dart';
import 'package:amici_per_la_coda/features/dogs/change_status_page.dart';
import 'package:amici_per_la_coda/features/dogs/dog_detail_page.dart';
import 'package:amici_per_la_coda/features/dogs/dog_filters_sheet.dart';
import 'package:amici_per_la_coda/features/dogs/dog_gallery_page.dart';
import 'package:amici_per_la_coda/features/dogs/dog_tabs.dart';
import 'package:amici_per_la_coda/features/dogs/dogs_page.dart';
import 'package:amici_per_la_coda/features/dogs/new_dog/new_dog_wizard_page.dart';
import 'package:amici_per_la_coda/features/notifications/local_notification_plan.dart';
import 'package:amici_per_la_coda/features/notifications/notifications_page.dart';
import 'package:amici_per_la_coda/features/search/search_page.dart';
import 'package:amici_per_la_coda/features/settings/altro_page.dart';
import 'package:amici_per_la_coda/features/settings/moduli_page.dart';
import 'package:amici_per_la_coda/features/settings/settings_page.dart';
import 'package:amici_per_la_coda/features/stats/stats_page.dart';
import 'package:amici_per_la_coda/features/vendors/vendors_page.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/dog_fixtures.dart';
import '../helpers/fake_adoption_repository.dart';
import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_dog_repository.dart';
import '../helpers/fake_health_repository.dart';
import '../helpers/pump_app.dart';

void main() {
  const widths = [320.0, 360.0, 411.0, 430.0];
  final nowMorning = DateTime(2026, 9, 10, 7);
  final nowAfternoon = DateTime(2026, 9, 10, 9);

  Finder horizontalScrollables() {
    return find.byWidgetPredicate((widget) {
      if (widget is! Scrollable) {
        return false;
      }
      if (axisDirectionToAxis(widget.axisDirection) != Axis.horizontal) {
        return false;
      }
      return widget.restorationId != 'editable';
    });
  }

  test('nextEightAm prima delle 8 resta oggi, dopo passa a domani', () {
    expect(nextEightAm(nowMorning), DateTime(2026, 9, 10, 8));
    expect(nextEightAm(nowAfternoon), DateTime(2026, 9, 11, 8));
    expect(nextEightAm(DateTime(2026, 9, 10, 8)), DateTime(2026, 9, 10, 8));
  });

  test('nextMondayEight cade sul lunedì alle 8:00', () {
    expect(
      nextMondayEight(DateTime(2026, 9, 7, 7)),
      DateTime(2026, 9, 7, 8),
    );
    expect(
      nextMondayEight(DateTime(2026, 9, 7, 9)),
      DateTime(2026, 9, 14, 8),
    );
    expect(
      nextMondayEight(DateTime(2026, 9, 13, 10)),
      DateTime(2026, 9, 14, 8),
    );
  });

  test('un vaccino scaduto produce la notifica alle 8:00', () {
    final plan = buildLocalNotificationPlan(
      dogs: [testDog(id: 'fenice', nome: 'Fenice')],
      health: [
        testHealth(
          id: 'v1',
          dogId: 'fenice',
          tipo: HealthTipo.vaccino,
          prossimaScadenza: DateTime(2026, 9, 8),
        ),
      ],
      adoptions: const [],
      switches: const NotificationSwitches(),
      now: nowMorning,
    );
    expect(plan, isNotEmpty);
    final vaccine = plan.firstWhere((item) => item.title == 'Scadenza vaccino');
    expect(vaccine.at, DateTime(2026, 9, 10, 8));
    expect(vaccine.body, 'Fenice · vaccino scaduto da 2 gg');
    expect(vaccine.repeat, LocalNoticeRepeat.daily);
  });

  test('dopo le 8:00 la scadenza vaccino slitta a domani alle 8:00', () {
    final plan = buildLocalNotificationPlan(
      dogs: [testDog(id: 'fenice', nome: 'Fenice')],
      health: [
        testHealth(
          dogId: 'fenice',
          tipo: HealthTipo.vaccino,
          prossimaScadenza: DateTime(2026, 9, 8),
        ),
      ],
      adoptions: const [],
      switches: const NotificationSwitches(),
      now: nowAfternoon,
    );
    final vaccine = plan.firstWhere((item) => item.title == 'Scadenza vaccino');
    expect(vaccine.at, DateTime(2026, 9, 11, 8));
  });

  test('switch scadenze sanitarie spento non programma il vaccino', () {
    final plan = buildLocalNotificationPlan(
      dogs: [testDog(id: 'fenice', nome: 'Fenice')],
      health: [
        testHealth(
          dogId: 'fenice',
          tipo: HealthTipo.vaccino,
          prossimaScadenza: DateTime(2026, 9, 8),
        ),
      ],
      adoptions: const [],
      switches: const NotificationSwitches(scadenzeSanitarie: false),
      now: nowMorning,
    );
    expect(plan.where((item) => item.title.contains('vaccino')), isEmpty);
  });

  test('preaffido entro 7 giorni è alle 8:00 se lo switch è acceso', () {
    final plan = buildLocalNotificationPlan(
      dogs: [testDog(id: 'otto', nome: 'Otto')],
      health: const [],
      adoptions: [
        testAdoption(
          id: 'pre1',
          dogId: 'otto',
          stato: AdoptionStato.preaffido,
          preaffidoAl: DateTime(2026, 9, 16),
        ),
      ],
      switches: const NotificationSwitches(),
      now: nowMorning,
    );
    final item = plan.firstWhere((n) => n.title == 'Preaffido in scadenza');
    expect(item.at.hour, localNoticeHour);
    expect(item.body, contains('Otto'));
  });

  test('la coda ritenta le scritture fallite al flush', () async {
    final queue = WriteQueue();
    var attempts = 0;
    await queue.enqueue(() async {
      attempts++;
      if (attempts == 1) {
        throw StateError('offline');
      }
    });
    expect(queue.pendingCount, 1);
    await queue.flush();
    expect(queue.pendingCount, 0);
    expect(attempts, 2);
  });

  test('senza rete si crea un cane e una nota nel database locale', () async {
    final db = FakeFirebaseFirestore();
    final dogs = FirestoreDogRepository(db);
    final notes = FirestoreNoteRepository(db);
    await dogs.save(testDog(id: 'aria', nome: 'Aria'));
    await notes.save(
      Note(
        id: 'n-offline',
        dogId: 'aria',
        tipo: NoteTipo.generale,
        testo: 'nota in modalità aereo',
        autoreId: 'uid-1',
        createdAt: DateTime.utc(2026, 9, 10),
      ),
    );
    expect((await dogs.getById('aria'))?.nome, 'Aria');
    final saved = await notes.watchByDog('aria').first;
    expect(saved, hasLength(1));
    expect(saved.first.testo, 'nota in modalità aereo');
  });

  testWidgets('la home in offline mostra il banner', (tester) async {
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    await pumpApp(
      tester,
      auth: auth,
      dogs: InMemoryDogRepository(testListDogs()),
      offline: true,
    );
    expect(find.byKey(HomePage.offlineBannerKey), findsOneWidget);
    expect(find.text('Dati non aggiornati · sei offline'), findsOneWidget);
  });

  testWidgets('all\'avvio si programma la notifica vaccino alle 8:00', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    final notifications = RecordingLocalNotifications();
    await pumpApp(
      tester,
      auth: auth,
      dogs: InMemoryDogRepository([testDog(id: 'fenice', nome: 'Fenice')]),
      health: InMemoryHealthRepository([
        testHealth(
          dogId: 'fenice',
          tipo: HealthTipo.vaccino,
          prossimaScadenza: DateTime(2026, 9, 8),
        ),
      ]),
      dogListNow: nowMorning,
      notifications: notifications,
    );
    expect(notifications.initialized, isTrue);
    expect(notifications.permissionRequested, isTrue);
    expect(
      notifications.scheduled.any(
        (item) =>
            item.title == 'Scadenza vaccino' &&
            item.at.hour == localNoticeHour,
      ),
      isTrue,
    );
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    required String location,
    required Size size,
    bool signedIn = true,
  }) async {
    final auth = FakeAuthRepository();
    if (signedIn) {
      await auth.signIn(
        email: 'giovanna@amiciperlacoda.it',
        password: 'corretta',
      );
    }
    await pumpApp(
      tester,
      auth: auth,
      initialLocation: location,
      size: size,
      dogs: InMemoryDogRepository(testListDogs()),
      adoptions: InMemoryAdoptionRepository([
        testAdoption(id: 'ad1', dogId: 'fenice'),
      ]),
      health: InMemoryHealthRepository([
        testHealth(
          id: 'h-scad',
          dogId: 'fenice',
          tipo: HealthTipo.vaccino,
          prossimaScadenza: DateTime(2026, 9, 1),
        ),
      ]),
      dogListNow: DateTime(2026, 9, 10, 10),
    );
  }

  Future<void> expectClean(WidgetTester tester, [String? where]) async {
    expect(tester.takeException(), isNull, reason: where);
    expect(horizontalScrollables(), findsNothing, reason: where);
  }

  testWidgets('scheda Fenice con scadenza e richiesta a 320 dp', (tester) async {
    await pumpScreen(
      tester,
      location: '${AppRoutes.animali}/fenice',
      size: const Size(320, 1100),
    );
    expect(find.byType(DogDetailPage), findsOneWidget);
    await tester.pump();
    await expectClean(tester, 'fenice isolata');
  });

  for (final width in widths) {
    testWidgets(
      'le 29 schermate a ${width.toInt()} dp senza overflow',
      (tester) async {
        final size = Size(width, 1100);

        await pumpScreen(
          tester,
          location: AppRoutes.login,
          size: size,
          signedIn: false,
        );
        expect(find.byType(LoginPage), findsOneWidget);
        await expectClean(tester, 'login');

        const pages = <(String, Type)>[
          (AppRoutes.home, HomePage),
          (AppRoutes.animali, DogsPage),
          ('${AppRoutes.animali}/fenice', DogDetailPage),
          ('${AppRoutes.animali}/fenice/foto', DogGalleryPage),
          ('${AppRoutes.animali}/fenice/stato', ChangeStatusPage),
          (AppRoutes.nuovo, NewDogWizardPage),
          (AppRoutes.richieste, AdoptionsPage),
          ('${AppRoutes.richieste}/ad1', AdoptionDetailPage),
          (AppRoutes.nuovaRichiesta, NewAdoptionPage),
          (AppRoutes.affido, AffidoPage),
          (AppRoutes.calendario, CalendarPage),
          (AppRoutes.box, BoxesPage),
          (AppRoutes.statistiche, StatsPage),
          (AppRoutes.cerca, SearchPage),
          (AppRoutes.notifiche, NotificationsPage),
          (AppRoutes.altro, AltroPage),
          (AppRoutes.impostazioni, SettingsPage),
          (AppRoutes.documenti, ModuliPage),
          (AppRoutes.archiviati, ArchivedDogsPage),
          (AppRoutes.adottanti, AdoptersPage),
          (AppRoutes.fornitori, VendorsPage),
        ];
        for (final page in pages) {
          await pumpScreen(tester, location: page.$1, size: size);
          expect(find.byType(page.$2), findsOneWidget, reason: page.$1);
          await tester.pump();
          await expectClean(tester, page.$1);
        }

        await pumpScreen(
          tester,
          location: '${AppRoutes.animali}/fenice',
          size: size,
        );
        for (final label in DogSheetTab.labels) {
          await tester.tap(find.text(label).first);
          await tester.pumpAndSettle();
          await expectClean(tester);
        }

        await tester.tap(find.byTooltip('Altre azioni'));
        await tester.pumpAndSettle();
        expect(find.byKey(DogDetailPage.azioneFotoKey), findsOneWidget);
        await expectClean(tester);

        await pumpScreen(tester, location: AppRoutes.animali, size: size);
        await tester.tap(find.byKey(DogsPage.filtriOrdinaKey));
        await tester.pumpAndSettle();
        expect(find.byType(DogFiltersSheet), findsOneWidget);
        await expectClean(tester);

        await pumpScreen(tester, location: AppRoutes.home, size: size);
        await tester.tap(find.byTooltip('Nuovo'));
        await tester.pumpAndSettle();
        expect(find.text('Cosa vuoi creare?'), findsOneWidget);
        await expectClean(tester);
      },
    );
  }
}
