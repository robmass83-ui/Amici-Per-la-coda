import 'package:amici_per_la_coda/core/firestore_codec.dart';
import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/data/models/note.dart';
import 'package:amici_per_la_coda/features/dogs/add_treatment_sheet.dart';
import 'package:amici_per_la_coda/features/dogs/concurrent_edit.dart';
import 'package:amici_per_la_coda/features/dogs/dog_detail_page.dart';
import 'package:amici_per_la_coda/features/dogs/dog_note_tab.dart';
import 'package:amici_per_la_coda/features/dogs/dog_spese_tab.dart';
import 'package:amici_per_la_coda/features/dogs/edit_dog_page.dart';
import 'package:amici_per_la_coda/features/dogs/new_dog/new_dog_draft.dart';
import 'package:amici_per_la_coda/features/dogs/record_actions.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:amici_per_la_coda/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_box_repository.dart';
import '../../helpers/fake_dog_repository.dart';
import '../../helpers/fake_expense_repository.dart';
import '../../helpers/fake_health_repository.dart';
import '../../helpers/fake_note_repository.dart';
import '../../helpers/fake_volunteer_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const widths = [320.0, 360.0, 411.0, 430.0];
  final now = DateTime.utc(2026, 9, 8);
  final openedAt = DateTime.utc(2024, 6, 25);

  Finder horizontalScrollables() {
    return find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable &&
          axisDirectionToAxis(widget.axisDirection) == Axis.horizontal &&
          widget.restorationId != 'editable',
    );
  }

  Finder tabLabel(String label) {
    return find.descendant(
      of: find.byKey(DogDetailPage.tabBarKey),
      matching: find.text(label),
    );
  }

  Future<void> openDogTab(WidgetTester tester, String tab) async {
    if (find.byType(DogDetailPage).evaluate().isEmpty) {
      await tester.tap(find.text('Fenice'));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(tabLabel(tab));
    await tester.tap(tabLabel(tab));
    await tester.pumpAndSettle();
  }

  Text saveLabel(WidgetTester tester) {
    return tester.widget<Text>(
      find.descendant(
        of: find.byKey(EditDogPage.saveKey),
        matching: find.text('Salva'),
      ),
    );
  }

  Future<void> pumpLogged(
    WidgetTester tester, {
    required String location,
    required InMemoryDogRepository dogs,
    Size size = const Size(360, 1100),
    InMemoryVolunteerRepository? volunteers,
    InMemoryHealthRepository? health,
    InMemoryExpenseRepository? expenses,
    InMemoryNoteRepository? notes,
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
      dogs: dogs,
      health: health,
      expenses: expenses,
      notes: notes,
      boxes: InMemoryBoxRepository([testBox()]),
      volunteers:
          volunteers ?? InMemoryVolunteerRepository([testVolunteer()]),
      dogListNow: now,
    );
  }

  test('guardia concorrente: updatedAt più recente blocca', () {
    expect(
      hasConcurrentDogEdit(
        openedUpdatedAt: openedAt,
        serverUpdatedAt: DateTime.utc(2026, 9, 9),
      ),
      isTrue,
    );
    expect(
      hasConcurrentDogEdit(
        openedUpdatedAt: openedAt,
        serverUpdatedAt: openedAt,
      ),
      isFalse,
    );
  });

  test('sterilizzazione: sì / no / programmata dal documento cane', () {
    expect(
      sterilizzazioneFromDog(sterilizzato: true, dataSterilizzazione: null),
      WizardSterilizzazione.si,
    );
    expect(
      sterilizzazioneFromDog(
        sterilizzato: true,
        dataSterilizzazione: DateTime.utc(2024, 8, 12),
      ),
      WizardSterilizzazione.si,
    );
    expect(
      sterilizzazioneFromDog(sterilizzato: false, dataSterilizzazione: null),
      WizardSterilizzazione.no,
    );
    expect(
      sterilizzazioneFromDog(
        sterilizzato: false,
        dataSterilizzazione: DateTime.utc(2026, 10, 1),
      ),
      WizardSterilizzazione.programmata,
    );
  });

  testWidgets(
    '1. Salva è disabilitato finché un campo non cambia',
    (tester) async {
      final dogs = InMemoryDogRepository(testListDogs());
      await pumpLogged(
        tester,
        location: AppRoutes.dogModifica('fenice'),
        dogs: dogs,
      );

      expect(find.byType(EditDogPage), findsOneWidget);
      expect(saveLabel(tester).style?.color, AppColor.faint);
      expect(
        tester.widget<GestureDetector>(find.byKey(EditDogPage.saveKey)).onTap,
        isNull,
      );

      await tester.enterText(
        find.byKey(EditDogPage.nomeKey),
        '[PROVA] Fenice X',
      );
      await tester.pump();

      expect(saveLabel(tester).style?.color, AppColor.card);
      expect(
        tester.widget<GestureDetector>(find.byKey(EditDogPage.saveKey)).onTap,
        isNotNull,
      );
    },
  );

  testWidgets('matita nella scheda apre la modifica', (tester) async {
    final dogs = InMemoryDogRepository(testListDogs());
    await pumpLogged(
      tester,
      location: AppRoutes.dog('fenice'),
      dogs: dogs,
    );

    expect(find.byTooltip('Modifica'), findsOneWidget);
    await tester.tap(find.byTooltip('Modifica'));
    await tester.pumpAndSettle();
    expect(find.byType(EditDogPage), findsOneWidget);
    expect(find.byKey(EditDogPage.nomeKey), findsOneWidget);
  });

  testWidgets(
    'volontario con id seed e stessa email può aprire la modifica',
    (tester) async {
      final dogs = InMemoryDogRepository(testListDogs());
      await pumpLogged(
        tester,
        location: AppRoutes.dog('fenice'),
        dogs: dogs,
        volunteers: InMemoryVolunteerRepository([
          testVolunteer(id: 'seed_giovanna'),
        ]),
      );

      expect(find.byTooltip('Modifica'), findsOneWidget);
      await tester.tap(find.byTooltip('Modifica'));
      await tester.pumpAndSettle();
      expect(find.byType(EditDogPage), findsOneWidget);
      expect(
        find.text('Non hai il permesso di modificare la scheda.'),
        findsNothing,
      );
      expect(find.byKey(EditDogPage.nomeKey), findsOneWidget);
    },
  );

  testWidgets(
    '2. cambiando la taglia, elenco e scheda mostrano il valore nuovo',
    (tester) async {
      final dogs = InMemoryDogRepository(testListDogs());
      await pumpLogged(
        tester,
        location: AppRoutes.dogModifica('fenice'),
        dogs: dogs,
      );

      await tester.ensureVisible(find.byKey(EditDogPage.tagliaKey));
      final tagliaBox = tester.getRect(find.byKey(EditDogPage.tagliaKey));
      await tester.tapAt(Offset(tagliaBox.right - 12, tagliaBox.center.dy));
      await tester.pumpAndSettle();
      expect(saveLabel(tester).style?.color, AppColor.card);
      await tester.tap(find.byKey(EditDogPage.saveKey));
      await tester.pumpAndSettle();

      expect((await dogs.getById('fenice'))?.taglia, Taglia.grande);
      expect(find.byType(DogDetailPage), findsOneWidget);
      await tester.ensureVisible(find.byKey(DogDetailPage.razzaTagliaKey));
      expect(
        tester.widget<Text>(find.byKey(DogDetailPage.razzaTagliaKey)).data,
        contains('Taglia grande'),
      );

      await tester.tap(find.byTooltip('Indietro'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Taglia grande'), findsWidgets);
    },
  );

  testWidgets(
    'sterilizzazione: Sì/No/Programmata è modificabile e si salva',
    (tester) async {
      final dogs = InMemoryDogRepository(testListDogs());
      await pumpLogged(
        tester,
        location: AppRoutes.dogModifica('fenice'),
        dogs: dogs,
      );

      await tester.fling(
        find.byKey(EditDogPage.formListKey),
        const Offset(0, -1200),
        2000,
      );
      await tester.pumpAndSettle();
      expect(find.text('Situazione sanitaria'), findsOneWidget);
      await tester.ensureVisible(find.byKey(EditDogPage.sterilizzazioneKey));
      expect(find.byKey(EditDogPage.sterilizzazioneKey), findsOneWidget);
      expect(find.text('Programmata'), findsOneWidget);
      expect((await dogs.getById('fenice'))?.sterilizzato, isTrue);

      final box = tester.getRect(find.byKey(EditDogPage.sterilizzazioneKey));
      await tester.tapAt(Offset(box.left + box.width / 2, box.center.dy));
      await tester.pump();
      expect(saveLabel(tester).style?.color, AppColor.card);
      await tester.tap(find.byKey(EditDogPage.saveKey));
      await tester.pumpAndSettle();

      final saved = await dogs.getById('fenice');
      expect(saved?.sterilizzato, isFalse);
      expect(saved?.dataSterilizzazione, isNull);
    },
  );

  testWidgets(
    '3. uscendo con modifiche non salvate, Annulla fa restare',
    (tester) async {
      final dogs = InMemoryDogRepository(testListDogs());
      await pumpLogged(
        tester,
        location: AppRoutes.dogModifica('fenice'),
        dogs: dogs,
      );

      await tester.enterText(
        find.byKey(EditDogPage.nomeKey),
        '[PROVA] Fenice X',
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Indietro'));
      await tester.pumpAndSettle();

      expect(find.text('Modifiche non salvate'), findsOneWidget);
      await tester.tap(find.byKey(ConfirmActionKeys.discardStay));
      await tester.pumpAndSettle();

      expect(find.byType(EditDogPage), findsOneWidget);
      expect(find.text('Modifica Fenice X'), findsOneWidget);
    },
  );

  testWidgets(
    '4. microchip di 14 cifre: errore e salvataggio bloccato',
    (tester) async {
      final dogs = InMemoryDogRepository(testListDogs());
      await pumpLogged(
        tester,
        location: AppRoutes.dogModifica('fenice'),
        dogs: dogs,
      );

      await tester.enterText(
        find.byKey(EditDogPage.microchipKey),
        '38026004321098',
      );
      await tester.pump();
      await tester.tap(find.byKey(EditDogPage.saveKey));
      await tester.pumpAndSettle();

      expect(find.text('Il microchip deve avere 15 cifre.'), findsOneWidget);
      expect(find.byType(EditDogPage), findsOneWidget);
      expect(
        (await dogs.getById('fenice'))?.microchip,
        '380260043210987',
      );
    },
  );

  testWidgets(
    '5. updatedAt più recente: non scrive e chiede Ricarica/Sovrascrivi',
    (tester) async {
      final dogs = InMemoryDogRepository(testListDogs());
      await pumpLogged(
        tester,
        location: AppRoutes.dogModifica('fenice'),
        dogs: dogs,
        volunteers: InMemoryVolunteerRepository([
          testVolunteer(),
          testVolunteer(id: 'marco', nome: 'Marco'),
        ]),
      );

      final current = await dogs.getById('fenice');
      await dogs.save(
        current!.copyWith(
          audit: current.audit.touched('marco', DateTime.utc(2026, 9, 9)),
        ),
      );

      await tester.enterText(
        find.byKey(EditDogPage.nomeKey),
        '[PROVA] Fenice nuova',
      );
      await tester.pump();
      await tester.tap(find.byKey(EditDogPage.saveKey));
      await tester.pumpAndSettle();

      expect(
        find.text('Marco ha modificato questa scheda mentre la stavi aprendo'),
        findsOneWidget,
      );
      expect(find.byKey(ConfirmActionKeys.ricarica), findsOneWidget);
      expect(find.byKey(ConfirmActionKeys.overwrite), findsOneWidget);
      expect(find.byType(EditDogPage), findsOneWidget);
      expect((await dogs.getById('fenice'))?.nome, '[PROVA] Fenice');
    },
  );

  testWidgets(
    '6. modificando la data di un trattamento, la timeline si riordina',
    (tester) async {
      final dogs = InMemoryDogRepository(testListDogs());
      final health = InMemoryHealthRepository([
        testHealth(
          id: 'h-old',
          dogId: 'fenice',
          tipo: HealthTipo.vaccino,
          data: DateTime.utc(2026, 1, 10),
          descrizione: 'Polivalente',
        ),
        testHealth(
          id: 'h-mid',
          dogId: 'fenice',
          tipo: HealthTipo.visita,
          data: DateTime.utc(2026, 6, 10),
          descrizione: 'Controllo',
        ),
      ]);
      await pumpLogged(
        tester,
        location: AppRoutes.dog('fenice'),
        dogs: dogs,
        health: health,
      );

      await tester.ensureVisible(tabLabel('Salute'));
      await tester.tap(tabLabel('Salute'));
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.textContaining('Controllo')).dy,
        lessThan(tester.getTopLeft(find.textContaining('Polivalente')).dy),
      );

      await tester.ensureVisible(find.byKey(recordMenuKey('h-old')));
      await tester.tap(find.byKey(recordMenuKey('h-old')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('record-action-edit')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(AddTreatmentSheet.dataKey),
        '10/09/2026',
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(AddTreatmentSheet.saveKey));
      await tester.tap(find.byKey(AddTreatmentSheet.saveKey));
      await tester.pumpAndSettle();

      expect(find.byKey(AddTreatmentSheet.saveKey), findsNothing);
      await openDogTab(tester, 'Salute');
      await tester.ensureVisible(find.textContaining('Polivalente'));
      expect(
        tester.getTopLeft(find.textContaining('Polivalente')).dy,
        lessThan(tester.getTopLeft(find.textContaining('Controllo')).dy),
      );
    },
  );

  testWidgets(
    '7. eliminando una spesa, il totale della tab Spese si ricalcola',
    (tester) async {
      final dogs = InMemoryDogRepository(testListDogs());
      await pumpLogged(
        tester,
        location: AppRoutes.dog('fenice'),
        dogs: dogs,
        expenses: InMemoryExpenseRepository([
          testExpense(
            id: 'e-grande',
            importo: 100,
            descrizione: 'Visita lunga',
          ),
          testExpense(
            id: 'e-piccola',
            importo: 50,
            descrizione: 'Farmaco',
          ),
        ]),
      );

      await tester.ensureVisible(tabLabel('Spese'));
      await tester.tap(tabLabel('Spese'));
      await tester.pumpAndSettle();
      expect(find.byKey(DogSpeseTab.totaleKey), findsOneWidget);
      expect(find.text('€ 150,00'), findsWidgets);

      await tester.ensureVisible(find.byKey(recordMenuKey('e-piccola')));
      await tester.tap(find.byKey(recordMenuKey('e-piccola')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('record-action-delete')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Farmaco'), findsWidgets);
      await tester.tap(find.byKey(ConfirmActionKeys.confirm));
      await tester.pumpAndSettle();

      await openDogTab(tester, 'Spese');
      expect(find.byKey(DogSpeseTab.totaleKey), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(DogSpeseTab.totaleKey)).data,
        '€ 100,00',
      );
      expect(find.text('Farmaco'), findsNothing);
    },
  );

  testWidgets(
    '8. un volontario non vede azioni sulle note altrui',
    (tester) async {
      final dogs = InMemoryDogRepository(testListDogs());
      await pumpLogged(
        tester,
        location: AppRoutes.dog('fenice'),
        dogs: dogs,
        volunteers: InMemoryVolunteerRepository([
          testVolunteer(ruolo: VolunteerRuolo.volontario),
        ]),
        notes: InMemoryNoteRepository([
          Note(
            id: 'n-mia',
            dogId: 'fenice',
            tipo: NoteTipo.generale,
            testo: 'La mia nota.',
            autoreId: 'uid-1',
            createdAt: DateTime.utc(2026, 9, 1),
          ),
          Note(
            id: 'n-altrui',
            dogId: 'fenice',
            tipo: NoteTipo.generale,
            testo: 'Nota di un altro.',
            autoreId: 'presidente',
            createdAt: DateTime.utc(2026, 8, 21),
          ),
        ]),
      );

      await tester.ensureVisible(tabLabel('Note'));
      await tester.tap(tabLabel('Note'));
      await tester.pumpAndSettle();

      expect(find.byType(DogNoteTab), findsOneWidget);
      expect(find.text('Nota di un altro.'), findsOneWidget);
      expect(find.byKey(recordMenuKey('n-altrui')), findsNothing);
      expect(find.byKey(recordMenuKey('n-mia')), findsOneWidget);
    },
  );

  for (final width in widths) {
    testWidgets(
      '9. modifica cane a ${width.toInt()} dp senza overflow',
      (tester) async {
        final dogs = InMemoryDogRepository(testListDogs());
        await pumpLogged(
          tester,
          location: AppRoutes.dogModifica('fenice'),
          dogs: dogs,
          size: Size(width, 1100),
        );

        expect(find.byType(EditDogPage), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(horizontalScrollables(), findsNothing);

        await tester.fling(find.byType(ListView).first, const Offset(0, -400), 2000);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byKey(EditDogPage.ultimaModificaKey), findsOneWidget);
      },
    );
  }

  testWidgets(
    '10. updatedBy e updatedAt sono scritti e mostrati in fondo',
    (tester) async {
      final dogs = InMemoryDogRepository([
        testDog(
          id: 'fenice',
          nome: '[PROVA] Fenice',
          sesso: DogSex.F,
          audit: Audit.seed(openedAt, by: 'test'),
        ),
      ]);
      await pumpLogged(
        tester,
        location: AppRoutes.dogModifica('fenice'),
        dogs: dogs,
      );

      expect(find.byType(EditDogPage), findsOneWidget);
      await tester.enterText(
        find.byKey(EditDogPage.nomeKey),
        '[PROVA] Fenice 2',
      );
      await tester.pump();
      await tester.tap(find.byKey(EditDogPage.saveKey));
      await tester.pumpAndSettle();

      final saved = await dogs.getById('fenice');
      expect(saved?.audit.updatedBy, 'uid-1');
      expect(saved?.audit.updatedAt.isAfter(openedAt), isTrue);

      await tester.tap(find.byTooltip('Modifica'));
      await tester.pumpAndSettle();
      expect(find.byType(EditDogPage), findsOneWidget);
      await tester.fling(
        find.byType(ListView).first,
        const Offset(0, -800),
        2000,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(EditDogPage.ultimaModificaKey), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(EditDogPage.ultimaModificaKey)).data,
        contains('Giovanna'),
      );
    },
  );
}
