import 'dart:io';
import 'dart:ui' as ui;

import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/features/boxes/boxes_page.dart';
import 'package:amici_per_la_coda/features/boxes/edit_box_sheet.dart';
import 'package:amici_per_la_coda/features/boxes/move_dog_sheet.dart';
import 'package:amici_per_la_coda/features/dashboard/home_aggregators.dart';
import 'package:amici_per_la_coda/features/dashboard/home_page.dart';
import 'package:amici_per_la_coda/features/dogs/dog_profile_fields.dart';
import 'package:amici_per_la_coda/features/dogs/edit_dog_page.dart';
import 'package:amici_per_la_coda/features/dogs/new_dog/new_dog_wizard_page.dart';
import 'package:amici_per_la_coda/features/shell/new_item_sheet.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_box_repository.dart';
import '../../helpers/fake_dog_repository.dart';
import '../../helpers/fake_settings_repository.dart';
import '../../helpers/fake_volunteer_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const widths = [320.0, 360.0, 411.0, 430.0];
  final now = DateTime(2026, 9, 8);

  final boxes = [
    testBox(id: 'b7', settore: 'B', numero: '7', capienza: 2),
    testBox(id: 'b8', settore: 'B', numero: '8', capienza: 2),
    testBox(
      id: 'd1',
      settore: 'Inf',
      numero: '1',
      capienza: 1,
      tipo: BoxTipo.degenza,
    ),
  ];
  final dogs = [
    testDog(id: 'fenice', nome: 'Fenice', settore: 'B', box: '7'),
    testDog(id: 'nina', nome: 'Nina', settore: 'B', box: '7'),
  ];

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

  Future<void> pumpBoxes(
    WidgetTester tester, {
    Size size = const Size(360, 900),
    InMemoryBoxRepository? boxRepo,
    InMemoryDogRepository? dogRepo,
    InMemoryVolunteerRepository? volunteers,
    InMemorySettingsRepository? settings,
    String location = AppRoutes.box,
  }) async {
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    await pumpApp(
      tester,
      auth: auth,
      size: size,
      initialLocation: location,
      dogs: dogRepo ?? InMemoryDogRepository(dogs),
      boxes: boxRepo ?? InMemoryBoxRepository(boxes),
      volunteers: volunteers,
      settings: settings,
      dogListNow: now,
    );
  }

  testWidgets('spostando Fenice dal box B7 al B8 entrambi i box si aggiornano', (
    tester,
  ) async {
    final boxRepo = InMemoryBoxRepository(boxes);
    final dogRepo = InMemoryDogRepository(dogs);
    await pumpBoxes(tester, boxRepo: boxRepo, dogRepo: dogRepo);

    expect(find.text('Fenice, Nina'), findsOneWidget);
    expect(find.text('Libero'), findsWidgets);

    await tester.tap(find.byKey(BoxesPage.moveKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(MoveDogSheet.caneKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('move-pick-dog-fenice')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(MoveDogSheet.boxKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(MoveDogSheet.destBoxKey('b8')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(MoveDogSheet.saveKey));
    await tester.pumpAndSettle();

    expect(occupantiDelBox(boxes[0], dogRepo.items), 1);
    expect(occupantiDelBox(boxes[1], dogRepo.items), 1);
    expect(find.text('Nina'), findsOneWidget);
    expect(find.text('Fenice'), findsOneWidget);
  });

  testWidgets('spostando un cane oltre capienza il salvataggio è rifiutato', (
    tester,
  ) async {
    final full = [
      testBox(id: 'b7', settore: 'B', numero: '7', capienza: 2),
      testBox(id: 'b8', settore: 'B', numero: '8', capienza: 1),
    ];
    final packed = [
      testDog(id: 'fenice', nome: 'Fenice', settore: 'B', box: '7'),
      testDog(id: 'nina', nome: 'Nina', settore: 'B', box: '7'),
      testDog(id: 'zeus', nome: 'Zeus', settore: 'B', box: '8'),
    ];
    await pumpBoxes(
      tester,
      boxRepo: InMemoryBoxRepository(full),
      dogRepo: InMemoryDogRepository(packed),
    );

    await tester.tap(find.byKey(BoxesPage.moveKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(MoveDogSheet.caneKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('move-pick-dog-fenice')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(MoveDogSheet.boxKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(MoveDogSheet.destBoxKey('b8')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(MoveDogSheet.saveKey));
    await tester.pumpAndSettle();

    expect(find.byKey(MoveDogSheet.errorKey), findsOneWidget);
    expect(find.textContaining('è pieno (1/1)'), findsOneWidget);
    expect(find.textContaining('posto libero'), findsOneWidget);
  });

  testWidgets('il contatore posti liberi è coerente', (tester) async {
    await pumpBoxes(tester);
    expect(find.byKey(BoxesPage.postiKey), findsOneWidget);
    expect(find.text('4'), findsWidgets);
    expect(find.text('2'), findsWidgets);
    expect(find.text('Posti'), findsOneWidget);
    expect(find.text('Occupati'), findsOneWidget);
    expect(find.text('Liberi'), findsOneWidget);
  });

  testWidgets('creando un box compare nel selettore del wizard', (
    tester,
  ) async {
    final boxRepo = InMemoryBoxRepository(boxes);
    await pumpBoxes(tester, boxRepo: boxRepo);

    await tester.tap(find.byKey(BoxesPage.addKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(EditBoxSheet.settoreKey), 'C');
    await tester.enterText(find.byKey(EditBoxSheet.numeroKey), '1');
    await tester.enterText(find.byKey(EditBoxSheet.capienzaKey), '3');
    await tester.tap(find.byKey(EditBoxSheet.saveKey));
    await tester.pumpAndSettle();

    expect(find.byKey(BoxesPage.cardKey('c_1')), findsOneWidget);

    await tester.tap(find.byTooltip('Indietro'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Nuovo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(NewItemSheetKeys.nuovoCane));
    await tester.pumpAndSettle();
    expect(find.byType(NewDogWizardPage), findsOneWidget);
    await tester.ensureVisible(find.byKey(DogProvenienzaFields.boxFieldKey));
    await tester.tap(find.byKey(DogProvenienzaFields.boxFieldKey));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pick-box-c_1')), findsOneWidget);
    expect(find.text('C · 1'), findsOneWidget);

    GoRouter.of(tester.element(find.byType(NewDogWizardPage))).go(
      AppRoutes.dogModifica('fenice', sezione: 'provenienza'),
    );
    await tester.pumpAndSettle();
    expect(find.byType(EditDogPage), findsOneWidget);
    await tester.ensureVisible(find.byKey(DogProvenienzaFields.boxFieldKey));
    await tester.tap(find.byKey(DogProvenienzaFields.boxFieldKey));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pick-box-c_1')), findsOneWidget);
    expect(find.text('C · 1'), findsOneWidget);
  });

  testWidgets('il volontario non vede crea né sposta', (tester) async {
    await pumpBoxes(
      tester,
      volunteers: InMemoryVolunteerRepository([
        testVolunteer(ruolo: VolunteerRuolo.volontario),
      ]),
    );
    expect(find.byKey(BoxesPage.addKey), findsNothing);
    expect(find.byKey(BoxesPage.moveKey), findsNothing);
  });

  for (final width in widths) {
    testWidgets(
      'griglia box a ${width.toInt()} dp senza overflow né scroll orizzontale',
      (tester) async {
        await pumpBoxes(tester, size: Size(width, 900));
        expect(find.byType(BoxesPage), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(horizontalScrollables(), findsNothing);
      },
    );
  }

  testWidgets('screenshot Box e Home', (tester) async {
    final boxRepo = InMemoryBoxRepository([
      testBox(id: 'a1', settore: 'A', numero: '1', capienza: 3),
      testBox(id: 'a2', settore: 'A', numero: '2', capienza: 3),
      testBox(id: 'b7', settore: 'B', numero: '7', capienza: 2),
      testBox(id: 'b8', settore: 'B', numero: '8', capienza: 2),
      testBox(
        id: 'd1',
        settore: 'Inf',
        numero: '1',
        capienza: 1,
        tipo: BoxTipo.degenza,
      ),
    ]);
    final dogRepo = InMemoryDogRepository([
      testDog(id: 'fenice', nome: 'Fenice', settore: 'B', box: '7'),
      testDog(id: 'nina', nome: 'Nina', settore: 'B', box: '7'),
      testDog(id: 'luna', nome: 'Luna', settore: 'A', box: '1'),
    ]);
    await pumpBoxes(
      tester,
      size: const Size(360, 800),
      boxRepo: boxRepo,
      dogRepo: dogRepo,
    );
    await _saveShot(tester, 'box_settori.png');

    await tester.tap(find.byTooltip('Indietro'));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    await _saveShot(tester, 'home_box.png');
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
