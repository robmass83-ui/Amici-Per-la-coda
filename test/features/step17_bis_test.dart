import 'dart:io';
import 'dart:ui' as ui;

import 'package:amici_per_la_coda/core/app_update/installed_apk_share.dart';
import 'package:amici_per_la_coda/data/models/dog.dart';
import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/data/search_recents_store.dart';
import 'package:amici_per_la_coda/features/adoptions/adopters_page.dart';
import 'package:amici_per_la_coda/features/adoptions/adoptions_page.dart';
import 'package:amici_per_la_coda/features/boxes/boxes_page.dart';
import 'package:amici_per_la_coda/features/calendar/calendar_page.dart';
import 'package:amici_per_la_coda/features/dogs/archived_dogs_page.dart';
import 'package:amici_per_la_coda/features/dogs/dog_detail_page.dart';
import 'package:amici_per_la_coda/features/dogs/dogs_page.dart';
import 'package:amici_per_la_coda/features/notifications/notifications_page.dart';
import 'package:amici_per_la_coda/features/search/search_page.dart';
import 'package:amici_per_la_coda/features/settings/altro_page.dart';
import 'package:amici_per_la_coda/features/settings/moduli_page.dart';
import 'package:amici_per_la_coda/features/settings/settings_page.dart';
import 'package:amici_per_la_coda/features/stats/stats_page.dart';
import 'package:amici_per_la_coda/features/vendors/vendors_page.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:amici_per_la_coda/ui/components.dart';
import 'package:amici_per_la_coda/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/dog_fixtures.dart';
import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_dog_repository.dart';
import '../helpers/fake_file_actions.dart';
import '../helpers/fake_health_repository.dart';
import '../helpers/fake_installed_apk_share.dart';
import '../helpers/fake_volunteer_repository.dart';
import '../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const widths = [320.0, 360.0, 411.0, 430.0];
  final now = DateTime.utc(2026, 9, 8);
  const chip = '380260043210987';

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

  Future<void> pumpLogged(
    WidgetTester tester, {
    required String location,
    Size size = const Size(360, 900),
    List<Dog>? dogs,
    InMemoryVolunteerRepository? volunteers,
    InMemoryHealthRepository? health,
    SearchRecentsStore? searchRecents,
    RecordingFileShare? fileShare,
    InstalledApkShare? installedApkShare,
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
      volunteers: volunteers,
      health: health,
      searchRecents: searchRecents,
      fileShare: fileShare,
      installedApkShare: installedApkShare,
      dogListNow: now,
    );
  }

  Future<void> enterSearch(WidgetTester tester, String value) async {
    await tester.enterText(
      find.descendant(
        of: find.byKey(SearchPage.fieldKey),
        matching: find.byType(TextField),
      ),
      value,
    );
    await tester.pump();
  }

  testWidgets('Altro: il profilo apre Impostazioni', (tester) async {
    await pumpLogged(tester, location: AppRoutes.altro);
    expect(find.text('GESTIONE'), findsOneWidget);
    expect(find.text('ARCHIVIO'), findsOneWidget);
    expect(find.text('APP'), findsOneWidget);
    expect(find.text('Volontari e turni'), findsNothing);
    expect(find.byKey(AltroPage.aggiornamentiKey), findsOneWidget);
    expect(find.byKey(AltroPage.condividiAppKey), findsOneWidget);
    await tester.tap(find.byKey(AltroPage.profiloKey));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.text('Moduli'), findsNothing);
  });

  testWidgets('Altro: il volontario non vede le voci riservate', (
    tester,
  ) async {
    await pumpLogged(
      tester,
      location: AppRoutes.altro,
      volunteers: InMemoryVolunteerRepository([
        testVolunteer(ruolo: VolunteerRuolo.volontario),
      ]),
    );
    expect(find.byKey(AltroPage.documentiKey), findsOneWidget);
    expect(find.byKey(AltroPage.catalogoKey), findsNothing);
    expect(find.byKey(AltroPage.aggiornamentiKey), findsOneWidget);
    expect(find.byKey(AltroPage.condividiAppKey), findsOneWidget);
    expect(find.byKey(AltroPage.condividiWebAppKey), findsNothing);
    expect(find.byKey(AltroPage.anagrafeKey), findsOneWidget);
    expect(find.byKey(AltroPage.famiglieKey), findsOneWidget);
    expect(find.byKey(AltroPage.impostazioniKey), findsOneWidget);
  });

  testWidgets('Altro: il responsabile non vede Condividi web app', (
    tester,
  ) async {
    await pumpLogged(
      tester,
      location: AppRoutes.altro,
      volunteers: InMemoryVolunteerRepository([
        testVolunteer(ruolo: VolunteerRuolo.referente),
      ]),
    );
    expect(find.byKey(AltroPage.condividiWebAppKey), findsNothing);
    expect(find.byKey(AltroPage.condividiAppKey), findsOneWidget);
  });

  testWidgets('Altro: ogni voce di menu apre la schermata giusta', (
    tester,
  ) async {
    Future<void> restartAltro() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await pumpLogged(tester, location: AppRoutes.altro);
      expect(find.byKey(AltroPage.listKey), findsOneWidget);
    }

    Future<void> expectOpens(Key key, Finder page) async {
      await restartAltro();
      tester.widget<OptionRow>(find.byKey(key)).onTap();
      await tester.pumpAndSettle();
      expect(page, findsWidgets);
    }

    await expectOpens(AltroPage.anagrafeKey, find.byType(DogsPage));
    await expectOpens(AltroPage.richiesteKey, find.byType(AdoptionsPage));
    await expectOpens(AltroPage.boxKey, find.byType(BoxesPage));
    await expectOpens(AltroPage.calendarioKey, find.byType(CalendarPage));
    await expectOpens(AltroPage.documentiKey, find.byType(ModuliPage));
    await expectOpens(AltroPage.famiglieKey, find.byType(AdoptersPage));
    await expectOpens(AltroPage.fornitoriKey, find.byType(VendorsPage));
    await expectOpens(AltroPage.archiviatiKey, find.byType(ArchivedDogsPage));
    await expectOpens(AltroPage.statsKey, find.byType(StatsPage));
    await expectOpens(AltroPage.notificheKey, find.byType(NotificationsPage));
    await expectOpens(AltroPage.impostazioniKey, find.byType(SettingsPage));

    await restartAltro();
    expect(find.text('Anagrafe cani'), findsOneWidget);
    expect(find.text('Richieste e adozioni'), findsOneWidget);
    expect(find.text('Box e settori'), findsOneWidget);
    expect(find.text('Calendario'), findsWidgets);
    expect(find.text('Documenti e modulistica'), findsOneWidget);
    expect(find.text('Famiglie adottanti'), findsOneWidget);
    expect(find.text('Veterinari e fornitori'), findsOneWidget);
    expect(find.text('Cani archiviati'), findsOneWidget);
    expect(find.text('Statistiche e report'), findsOneWidget);
    expect(find.text('Notifiche'), findsOneWidget);
    expect(find.text('Aggiornamenti'), findsOneWidget);
    expect(find.text('Condividi app'), findsOneWidget);
    expect(find.text('Condividi web app'), findsOneWidget);
    expect(find.text('Impostazioni'), findsWidgets);
    expect(find.text('Esci'), findsOneWidget);
    expect(find.text('Catalogo UI'), findsOneWidget);
    expect(find.byKey(AltroPage.aggiornamentiKey), findsOneWidget);
    expect(find.byKey(AltroPage.condividiAppKey), findsOneWidget);
    expect(find.byKey(AltroPage.condividiWebAppKey), findsOneWidget);
    expect(find.byKey(AltroPage.catalogoKey), findsOneWidget);
  });

  testWidgets('Altro: Documenti e modulistica apre la pagina unificata', (
    tester,
  ) async {
    await pumpLogged(tester, location: AppRoutes.altro);
    await tester.tap(find.byKey(AltroPage.documentiKey));
    await tester.pumpAndSettle();
    expect(find.byType(ModuliPage), findsOneWidget);
    expect(find.text('Documenti e modulistica'), findsWidgets);
    expect(find.text('Moduli'), findsOneWidget);
    expect(find.text('Documenti caricati'), findsOneWidget);
  });

  testWidgets('Altro: Condividi app invia l\'APK installato', (tester) async {
    final share = RecordingFileShare();
    const apk = SharedApk(
      path: '/tmp/Amici-per-la-Coda-1.0.0+12.apk',
      fileName: 'Amici-per-la-Coda-1.0.0+12.apk',
      versionName: '1.0.0',
      versionCode: 12,
    );
    await pumpLogged(
      tester,
      location: AppRoutes.altro,
      fileShare: share,
      installedApkShare: FakeInstalledApkShare(apk),
    );
    await tester.ensureVisible(find.byKey(AltroPage.condividiAppKey));
    await tester.tap(find.byKey(AltroPage.condividiAppKey));
    await tester.pumpAndSettle();
    expect(share.lastPath, apk.path);
    expect(share.lastFileName, apk.fileName);
    expect(share.lastMime, 'application/vnd.android.package-archive');
    expect(share.lastText, contains('1.0.0'));
    expect(share.lastText, contains('12'));
  });

  testWidgets('Altro: il proprietario condivide l\'indirizzo della web app', (
    tester,
  ) async {
    final share = RecordingFileShare();
    await pumpLogged(
      tester,
      location: AppRoutes.altro,
      fileShare: share,
    );
    await tester.ensureVisible(find.byKey(AltroPage.condividiWebAppKey));
    expect(find.text('https://amici-per-la-coda.web.app'), findsOneWidget);
    tester.widget<OptionRow>(find.byKey(AltroPage.condividiWebAppKey)).onTap();
    await tester.pumpAndSettle();
    expect(share.lastText, contains('https://amici-per-la-coda.web.app'));
    expect(share.lastText, contains('Amici per la Coda'));
    expect(share.lastPath, isNull);
    expect(share.lastBytes, isNull);
  });

  testWidgets('Altro: Aggiornamenti avvia il controllo versione', (
    tester,
  ) async {
    await pumpLogged(tester, location: AppRoutes.altro);
    await tester.ensureVisible(find.byKey(AltroPage.aggiornamentiKey));
    await tester.tap(find.byKey(AltroPage.aggiornamentiKey));
    await tester.pump();
    expect(
      find.text(
        'Questa è una versione di sviluppo: gli aggiornamenti GitHub sono disattivati.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Ricerca: una lettera non parte; il microchip trova Fenice', (
    tester,
  ) async {
    await pumpLogged(tester, location: AppRoutes.cerca);
    await enterSearch(tester, 'f');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(SearchPage.dogsKey), findsNothing);
    expect(find.text('Cerca anche per'), findsOneWidget);

    await enterSearch(tester, chip);
    expect(find.byKey(SearchPage.dogsKey), findsNothing);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(SearchPage.dogsKey), findsNothing);
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byKey(SearchPage.dogsKey), findsOneWidget);
    expect(find.byKey(SearchPage.dogHitKey('fenice')), findsOneWidget);
    expect(find.byKey(SearchPage.dogHitKey('brando')), findsNothing);
    expect(find.text('Cani (1)'), findsOneWidget);
  });

  testWidgets('Ricerca: i recenti sopravvivono alla chiusura, max 6', (
    tester,
  ) async {
    final store = MemorySearchRecentsStore([
      'q1',
      'q2',
      'q3',
      'q4',
      'q5',
      'q6',
    ]);
    await pumpLogged(tester, location: AppRoutes.cerca, searchRecents: store);
    await enterSearch(tester, chip);
    await tester.pump(const Duration(milliseconds: 400));
    expect(store.items.first, chip);
    expect(store.items, hasLength(6));
    expect(store.items, isNot(contains('q6')));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await pumpLogged(tester, location: AppRoutes.cerca, searchRecents: store);
    expect(find.text('Cerca anche per'), findsOneWidget);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byKey(SearchPage.recentChipKey(chip)), findsOneWidget);
    expect(find.byKey(SearchPage.recentsKey), findsOneWidget);
  });

  testWidgets(
    'Notifiche: scadenza scaduta con bordo rosso, tap apre la scheda',
    (tester) async {
      await pumpLogged(
        tester,
        location: AppRoutes.notifiche,
        health: InMemoryHealthRepository([
          testHealth(
            id: 'h-scad',
            dogId: 'fenice',
            prossimaScadenza: DateTime.utc(2026, 8, 1),
          ),
        ]),
      );
      final card = find.byKey(NotificationsPage.noticeKey('health-h-scad'));
      expect(card, findsOneWidget);
      expect(find.text('Vaccino scaduto'), findsOneWidget);
      final accents = tester.widgetList<ColoredBox>(
        find.descendant(of: card, matching: find.byType(ColoredBox)),
      );
      expect(
        accents.any(
          (box) =>
              box.color == AppColor.red &&
              box.child is SizedBox &&
              (box.child as SizedBox).width == AppDim.notifyAccentW,
        ),
        isTrue,
      );
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(find.byType(DogDetailPage), findsOneWidget);
      expect(find.textContaining('Fenice'), findsWidgets);
    },
  );

  testWidgets('Archiviati: filtri senza Ripristina', (tester) async {
    final dogs = [
      ...testListDogs(),
      testDog(
        id: 'old',
        nome: 'Old',
        stato: DogStato.adottato,
        archiviato: true,
        microchip: '380260099999999',
      ),
      testDog(
        id: 'gone',
        nome: 'Gone',
        stato: DogStato.deceduto,
        archiviato: true,
      ),
    ];
    await pumpLogged(tester, location: AppRoutes.archiviati, dogs: dogs);
    expect(find.textContaining('Old'), findsOneWidget);
    expect(find.textContaining('Gone'), findsOneWidget);
    expect(find.text('Ripristina'), findsNothing);
    await tester.tap(find.text('Adott.'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Old'), findsOneWidget);
    expect(find.textContaining('Gone'), findsNothing);
  });

  testWidgets(
    'Archiviati: un deceduto senza flag compare nel filtro Deced.',
    (tester) async {
      await pumpLogged(
        tester,
        location: AppRoutes.archiviati,
        dogs: [
          testDog(
            id: 'pongo',
            nome: 'Pongo',
            stato: DogStato.deceduto,
            archiviato: false,
          ),
        ],
      );
      expect(find.textContaining('Pongo'), findsOneWidget);
      await tester.tap(find.text('Deced.'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Pongo'), findsOneWidget);
      await tester.tap(find.text('Adott.'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Pongo'), findsNothing);
    },
  );

  testWidgets('Archiviati: tap sulla card apre la scheda', (tester) async {
    await pumpLogged(
      tester,
      location: AppRoutes.altro,
      dogs: [
        testDog(
          id: 'old',
          nome: 'Old',
          stato: DogStato.adottato,
          archiviato: true,
        ),
        testDog(
          id: 'gone',
          nome: 'Gone',
          stato: DogStato.deceduto,
          archiviato: true,
        ),
      ],
    );
    tester.widget<OptionRow>(find.byKey(AltroPage.archiviatiKey)).onTap();
    await tester.pumpAndSettle();
    expect(find.byType(ArchivedDogsPage), findsOneWidget);
    await tester.tap(find.textContaining('Gone'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(DogDetailPage), findsOneWidget);
    expect(find.textContaining('Gone'), findsWidgets);
    expect(find.byTooltip('Indietro'), findsOneWidget);
    await tester.tap(find.byTooltip('Indietro'));
    await tester.pumpAndSettle();
    expect(find.byType(ArchivedDogsPage), findsOneWidget);
  });

  for (final width in widths) {
    testWidgets(
      'Altro a ${width.toInt()} dp senza overflow né scroll orizzontale',
      (tester) async {
        await pumpLogged(
          tester,
          location: AppRoutes.altro,
          size: Size(width, 900),
        );
        expect(tester.takeException(), isNull);
        expect(horizontalScrollables(), findsNothing);
      },
    );
    testWidgets(
      'Cerca a ${width.toInt()} dp senza overflow né scroll orizzontale',
      (tester) async {
        await pumpLogged(
          tester,
          location: AppRoutes.cerca,
          size: Size(width, 900),
        );
        expect(tester.takeException(), isNull);
        expect(horizontalScrollables(), findsNothing);
      },
    );
    testWidgets(
      'Notifiche a ${width.toInt()} dp senza overflow né scroll orizzontale',
      (tester) async {
        await pumpLogged(
          tester,
          location: AppRoutes.notifiche,
          size: Size(width, 900),
          health: InMemoryHealthRepository([
            testHealth(
              id: 'h-scad',
              dogId: 'fenice',
              prossimaScadenza: DateTime.utc(2026, 8, 1),
            ),
          ]),
        );
        expect(tester.takeException(), isNull);
        expect(horizontalScrollables(), findsNothing);
      },
    );
    testWidgets(
      'sheet ⋮ a ${width.toInt()} dp senza overflow né scroll orizzontale',
      (tester) async {
        await pumpLogged(
          tester,
          location: AppRoutes.dog('fenice'),
          size: Size(width, 900),
        );
        await tester.tap(find.byTooltip('Altre azioni'));
        await tester.pumpAndSettle();
        expect(find.byKey(DogDetailPage.azioneArchiviaKey), findsOneWidget);
        expect(find.byKey(DogDetailPage.azioneEliminaKey), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(horizontalScrollables(), findsNothing);
      },
    );
  }

  testWidgets('screenshot Altro', (tester) async {
    await pumpLogged(
      tester,
      location: AppRoutes.altro,
      size: const Size(360, 900),
    );
    await _saveShot(tester, 'altro.png');
  });

  testWidgets('screenshot Notifiche', (tester) async {
    await pumpLogged(
      tester,
      location: AppRoutes.notifiche,
      size: const Size(360, 900),
      health: InMemoryHealthRepository([
        testHealth(
          id: 'h-scad',
          dogId: 'fenice',
          prossimaScadenza: DateTime.utc(2026, 8, 1),
        ),
      ]),
    );
    await _saveShot(tester, 'notifiche.png');
  });

  testWidgets('screenshot Cerca', (tester) async {
    await pumpLogged(
      tester,
      location: AppRoutes.cerca,
      size: const Size(360, 900),
    );
    await _saveShot(tester, 'cerca.png');
  });
}

Future<void> _saveShot(WidgetTester tester, String name) async {
  await tester.pump();
  final dir = Directory('${Directory.current.path}/test/screenshots');
  dir.createSync(recursive: true);
  final file = File('${dir.path}/$name');
  final image = await captureImage(tester.element(find.byType(MaterialApp)));
  final byteData = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.png),
  );
  if (byteData == null) {
    throw StateError(
      'screenshot $name: toByteData è null (cwd=${Directory.current.path})',
    );
  }
  file.writeAsBytesSync(byteData.buffer.asUint8List());
  if (!file.existsSync() || file.lengthSync() < 100) {
    throw StateError('screenshot $name non scritto in ${file.path}');
  }
}
