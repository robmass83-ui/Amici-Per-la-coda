import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:amici_per_la_coda/data/documents/document_file_picker.dart';
import 'package:amici_per_la_coda/features/adoptions/new_adoption_page.dart';
import 'package:amici_per_la_coda/features/calendar/add_appointment_sheet.dart';
import 'package:amici_per_la_coda/features/dogs/add_document_sheet.dart';
import 'package:amici_per_la_coda/features/dogs/add_expense_sheet.dart';
import 'package:amici_per_la_coda/features/dogs/add_note_sheet.dart';
import 'package:amici_per_la_coda/features/dogs/add_sponsorship_sheet.dart';
import 'package:amici_per_la_coda/features/dogs/add_treatment_sheet.dart';
import 'package:amici_per_la_coda/features/dogs/add_weight_sheet.dart';
import 'package:amici_per_la_coda/features/settings/new_volunteer_sheet.dart';
import 'package:amici_per_la_coda/features/settings/volunteer_detail_page.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:amici_per_la_coda/ui/components.dart';
import 'package:amici_per_la_coda/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_dog_repository.dart';
import '../../helpers/fake_file_actions.dart';
import '../../helpers/fake_health_repository.dart';
import '../../helpers/fake_volunteer_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  const widths = [320.0, 360.0, 411.0, 430.0];
  final now = DateTime.utc(2026, 9, 8);

  const formSources = [
    'lib/features/dogs/add_treatment_sheet.dart',
    'lib/features/dogs/add_weight_sheet.dart',
    'lib/features/dogs/add_expense_sheet.dart',
    'lib/features/dogs/add_sponsorship_sheet.dart',
    'lib/features/dogs/add_document_sheet.dart',
    'lib/features/dogs/add_note_sheet.dart',
    'lib/features/calendar/add_appointment_sheet.dart',
    'lib/features/settings/new_volunteer_sheet.dart',
    'lib/features/settings/volunteer_detail_page.dart',
    'lib/features/adoptions/new_adoption_page.dart',
  ];

  Future<void> pumpLogged(
    WidgetTester tester, {
    String location = '/animali/fenice',
    Size size = const Size(360, 800),
    DocumentFilePicker? documentPicker,
    InMemoryHealthRepository? health,
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
      dogs: InMemoryDogRepository(testListDogs()),
      health: health ?? InMemoryHealthRepository(),
      volunteers: InMemoryVolunteerRepository([testVolunteer()]),
      documentPicker: documentPicker,
      dogListNow: now,
    );
  }

  Future<void> openForm(
    WidgetTester tester,
    Future<void> Function(BuildContext) open,
  ) async {
    final ctx = tester.element(find.byType(Scaffold).first);
    unawaited(open(ctx));
    await tester.pumpAndSettle();
  }

  void expectDialogCentered(WidgetTester tester) {
    expect(find.byKey(AppDialog.cardKey), findsOneWidget);
    final card = tester.getRect(find.byKey(AppDialog.cardKey));
    expect(card.top, greaterThan(0));
    final screen = tester.getSize(find.byType(MaterialApp));
    expect(card.bottom, lessThan(screen.height));
  }

  Color saveColor(WidgetTester tester, Key saveKey) {
    return tester
        .widget<Material>(
          find.descendant(
            of: find.byKey(saveKey),
            matching: find.byType(Material),
          ),
        )
        .color!;
  }

  testWidgets(
    '1. ogni form breve apre un AppDialog centrato',
    (tester) async {
      await pumpLogged(tester);

      final openers = <Future<void> Function(BuildContext)>[
        (ctx) => AddTreatmentSheet.open(ctx, dogId: 'fenice'),
        (ctx) => AddWeightSheet.open(ctx, dogId: 'fenice'),
        (ctx) => AddExpenseSheet.open(ctx, dogId: 'fenice'),
        (ctx) => AddSponsorshipSheet.open(ctx, dogId: 'fenice'),
        (ctx) => AddDocumentSheet.open(ctx, dogId: 'fenice'),
        (ctx) => AddNoteSheet.open(ctx, dogId: 'fenice'),
        (ctx) => AddAppointmentSheet.open(ctx),
        NewVolunteerSheet.show,
        (ctx) => VolunteerDetailPage.show(ctx, 'uid-1'),
      ];

      for (final open in openers) {
        await openForm(tester, open);
        expectDialogCentered(tester);
        await tester.tap(find.byKey(AppDialog.defaultCloseKey));
        await tester.pumpAndSettle();
        expect(find.byKey(AppDialog.cardKey), findsNothing);
      }
    },
  );

  testWidgets(
    '2. con viewInsets.bottom = 300 il footer Salva resta visibile',
    (tester) async {
      await pumpLogged(tester, size: const Size(360, 800));
      await openForm(
        tester,
        (ctx) => AddTreatmentSheet.open(ctx, dogId: 'fenice'),
      );

      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.reset);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(AppDialog.footerKey), findsOneWidget);
      expect(find.byKey(AddTreatmentSheet.saveKey), findsOneWidget);
      final footer = tester.getRect(find.byKey(AppDialog.footerKey));
      final screen = tester.getSize(find.byType(MaterialApp));
      expect(footer.bottom, lessThanOrEqualTo(screen.height - 300 + 1));
      expect(footer.bottom, greaterThan(0));
    },
  );

  testWidgets(
    '3. Salva è disabilitato a form vuoto e si attiva quando valido',
    (tester) async {
      await pumpLogged(tester);
      await openForm(
        tester,
        (ctx) => AddTreatmentSheet.open(ctx, dogId: 'fenice'),
      );

      expect(
        saveColor(tester, AddTreatmentSheet.saveKey),
        AppColor.greenDisabled,
      );

      await tester.enterText(
        find.byKey(AddTreatmentSheet.descrizioneKey),
        'Vaccino polivalente',
      );
      await tester.pump();

      expect(saveColor(tester, AddTreatmentSheet.saveKey), AppColor.green);
    },
  );

  testWidgets(
    '4. chiudere con modifiche chiede conferma; senza modifiche chiude subito',
    (tester) async {
      await pumpLogged(tester);
      await openForm(
        tester,
        (ctx) => AddTreatmentSheet.open(ctx, dogId: 'fenice'),
      );

      await tester.tap(find.byKey(AppDialog.defaultCloseKey));
      await tester.pumpAndSettle();
      expect(find.text('Scartare le modifiche?'), findsNothing);
      expect(find.byKey(AppDialog.cardKey), findsNothing);

      await openForm(
        tester,
        (ctx) => AddTreatmentSheet.open(ctx, dogId: 'fenice'),
      );
      await tester.enterText(
        find.byKey(AddTreatmentSheet.descrizioneKey),
        'Richiamo',
      );
      await tester.pump();
      await tester.tap(find.byKey(AppDialog.defaultCloseKey));
      await tester.pumpAndSettle();
      expect(find.text('Scartare le modifiche?'), findsOneWidget);
      expect(find.byKey(AppDialog.cardKey), findsOneWidget);
    },
  );

  testWidgets(
    '5. existing mostra Modifica, valori precompilati e cestino',
    (tester) async {
      final existing = testHealth(
        id: 'h-edit',
        dogId: 'fenice',
        descrizione: 'Richiamo annuale',
      );
      await pumpLogged(
        tester,
        health: InMemoryHealthRepository([existing]),
      );

      await openForm(
        tester,
        (ctx) => AddTreatmentSheet.open(ctx, dogId: 'fenice'),
      );
      expect(find.text('Aggiungi trattamento'), findsOneWidget);
      expect(find.byKey(AppDialog.defaultTrashKey), findsNothing);
      await tester.tap(find.byKey(AppDialog.defaultCloseKey));
      await tester.pumpAndSettle();

      await openForm(
        tester,
        (ctx) => AddTreatmentSheet.open(
          ctx,
          dogId: 'fenice',
          existing: existing,
        ),
      );
      expect(find.text('Modifica trattamento'), findsOneWidget);
      expect(find.text('Richiamo annuale'), findsOneWidget);
      expect(find.byKey(AppDialog.defaultTrashKey), findsOneWidget);
    },
  );

  testWidgets(
    '6. documento: Salva off senza file; dopo pick compare nome e dimensione',
    (tester) async {
      final picker = FakeDocumentFilePicker(
        pdf: PickedDocumentFile(
          bytes: Uint8List.fromList(List<int>.filled(4, 1)),
          name: 'libretto.pdf',
          mime: 'application/pdf',
        ),
      );
      await pumpLogged(tester, documentPicker: picker);
      await openForm(
        tester,
        (ctx) => AddDocumentSheet.open(ctx, dogId: 'fenice'),
      );

      expect(
        saveColor(tester, AddDocumentSheet.saveKey),
        AppColor.greenDisabled,
      );
      expect(find.byKey(AddDocumentSheet.fileRowKey), findsNothing);

      await tester.ensureVisible(find.byKey(AddDocumentSheet.pdfKey));
      await tester.tap(find.byKey(AddDocumentSheet.pdfKey));
      await tester.pumpAndSettle();

      expect(find.byKey(AddDocumentSheet.fileRowKey), findsOneWidget);
      expect(find.text('libretto.pdf'), findsOneWidget);
      expect(find.text('4 B'), findsOneWidget);
      expect(saveColor(tester, AddDocumentSheet.saveKey), AppColor.green);
    },
  );

  testWidgets(
    '7. nota: quattro etichette su una riga a 320 dp senza overflow',
    (tester) async {
      await pumpLogged(tester, size: const Size(320, 800));
      await openForm(
        tester,
        (ctx) => AddNoteSheet.open(ctx, dogId: 'fenice'),
      );

      expect(find.text('Generale'), findsOneWidget);
      expect(find.text('Comportam.'), findsOneWidget);
      expect(find.text('Aliment.'), findsOneWidget);
      expect(find.text('Attenzione'), findsOneWidget);

      final ys = [
        tester.getTopLeft(find.text('Generale')).dy,
        tester.getTopLeft(find.text('Comportam.')).dy,
        tester.getTopLeft(find.text('Aliment.')).dy,
        tester.getTopLeft(find.text('Attenzione')).dy,
      ];
      expect(ys[1], closeTo(ys[0], 2));
      expect(ys[2], closeTo(ys[0], 2));
      expect(ys[3], closeTo(ys[0], 2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '8. Nuova richiesta: contenuto sotto 950 dp a 360, niente nav né FAB',
    (tester) async {
      await pumpLogged(
        tester,
        location: AppRoutes.nuovaRichiestaPer('fenice'),
        size: const Size(360, 640),
      );

      expect(find.byType(NewAdoptionPage), findsOneWidget);
      expect(find.byType(AppBottomNav), findsNothing);

      final scrollable = find.descendant(
        of: find.byKey(NewAdoptionPage.formListKey),
        matching: find.byWidgetPredicate((widget) {
          return widget is Scrollable &&
              widget.axisDirection == AxisDirection.down &&
              widget.restorationId != 'editable';
        }),
      );
      final pos = tester.state<ScrollableState>(scrollable.first).position;
      expect(
        pos.maxScrollExtent + pos.viewportDimension,
        lessThan(950),
      );
    },
  );

  test('9. nessun showModalBottomSheet resta nel codice dei form', () {
    for (final path in formSources) {
      final content = File(path).readAsStringSync();
      expect(
        content.contains('showModalBottomSheet'),
        isFalse,
        reason: path,
      );
    }
  });

  testWidgets(
    '10. i dialog a 320/360/411/430 dp non vanno in overflow',
    (tester) async {
      for (final width in widths) {
        await pumpLogged(tester, size: Size(width, 800));
        await openForm(
          tester,
          (ctx) => AddTreatmentSheet.open(ctx, dogId: 'fenice'),
        );
        expect(tester.takeException(), isNull, reason: 'trattamento $width');
        await tester.tap(find.byKey(AppDialog.defaultCloseKey));
        await tester.pumpAndSettle();

        await openForm(
          tester,
          (ctx) => AddNoteSheet.open(ctx, dogId: 'fenice'),
        );
        expect(tester.takeException(), isNull, reason: 'nota $width');
        await tester.tap(find.byKey(AppDialog.defaultCloseKey));
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets('screenshot trattamento, nota con tastiera, nuova richiesta', (
    tester,
  ) async {
    final existing = testHealth(
      id: 'h-edit',
      dogId: 'fenice',
      descrizione: 'Richiamo annuale',
    );
    await pumpLogged(
      tester,
      size: const Size(360, 800),
      health: InMemoryHealthRepository([existing]),
    );

    await openForm(
      tester,
      (ctx) => AddTreatmentSheet.open(ctx, dogId: 'fenice'),
    );
    await _saveShot(tester, '18bis_trattamento_vuoto.png');
    await tester.tap(find.byKey(AppDialog.defaultCloseKey));
    await tester.pumpAndSettle();

    await openForm(
      tester,
      (ctx) => AddTreatmentSheet.open(
        ctx,
        dogId: 'fenice',
        existing: existing,
      ),
    );
    await _saveShot(tester, '18bis_trattamento_modifica.png');
    await tester.tap(find.byKey(AppDialog.defaultCloseKey));
    await tester.pumpAndSettle();

    await openForm(
      tester,
      (ctx) => AddNoteSheet.open(ctx, dogId: 'fenice'),
    );
    await tester.tap(find.byKey(AddNoteSheet.testoKey));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.reset);
    await tester.pumpAndSettle();
    await _saveShot(tester, '18bis_nota_tastiera.png');
  });

  testWidgets('screenshot Nuova richiesta a 360 dp', (tester) async {
    await pumpLogged(
      tester,
      location: AppRoutes.nuovaRichiestaPer('fenice'),
      size: const Size(360, 640),
    );
    expect(find.byType(NewAdoptionPage), findsOneWidget);
    await _saveShot(tester, '18bis_nuova_richiesta_360.png');
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
    throw StateError('screenshot $name: toByteData è null');
  }
  file.writeAsBytesSync(byteData.buffer.asUint8List());
  expect(file.existsSync(), isTrue);
}
