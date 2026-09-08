import 'package:amici_per_la_coda/data/models/dog.dart';
import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/data/models/note.dart';
import 'package:amici_per_la_coda/features/dogs/add_document_sheet.dart';
import 'package:amici_per_la_coda/features/dogs/add_note_sheet.dart';
import 'package:amici_per_la_coda/features/dogs/dog_detail_page.dart';
import 'package:amici_per_la_coda/features/dogs/dog_documenti_tab.dart';
import 'package:amici_per_la_coda/features/dogs/dog_note_tab.dart';
import 'package:amici_per_la_coda/features/dogs/dog_spese_tab.dart';
import 'package:amici_per_la_coda/features/dogs/dog_tabs.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_dog_repository.dart';
import '../../helpers/fake_expense_repository.dart';
import '../../helpers/fake_note_repository.dart';
import '../../helpers/fake_volunteer_repository.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/system_nav.dart';

void main() {
  const widths = [320.0, 360.0, 411.0, 430.0];
  final now = DateTime.utc(2026, 9, 8);
  const restTabs = [
    DogSheetTab.adozione,
    DogSheetTab.spese,
    DogSheetTab.documenti,
    DogSheetTab.note,
    DogSheetTab.altro,
  ];

  Finder tabLabel(String label) {
    return find.descendant(
      of: find.byKey(DogDetailPage.tabBarKey),
      matching: find.text(label),
    );
  }

  Future<void> pumpDetail(
    WidgetTester tester, {
    String dogId = 'fenice',
    List<Dog>? dogs,
    InMemoryNoteRepository? notes,
    Size size = const Size(360, 1100),
  }) async {
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    await pumpApp(
      tester,
      auth: auth,
      initialLocation: AppRoutes.dog(dogId),
      size: size,
      dogs: InMemoryDogRepository(dogs ?? testListDogs()),
      notes: notes ?? InMemoryNoteRepository(),
      expenses: InMemoryExpenseRepository([
        testExpense(id: 'e-visite', importo: 320),
        testExpense(
          id: 'e-ster',
          categoria: ExpenseCategoria.sterilizzazione,
          importo: 180,
        ),
        testExpense(
          id: 'e-esami',
          categoria: ExpenseCategoria.esami,
          importo: 120,
        ),
        testExpense(
          id: 'e-farmaci',
          categoria: ExpenseCategoria.farmaci,
          importo: 95,
        ),
      ]),
      volunteers: InMemoryVolunteerRepository([testVolunteer()]),
      dogListNow: now,
    );
  }

  testWidgets(
    'tab Adozione: Pubblicato con data, senza sito social né visualizzazioni',
    (tester) async {
      await pumpDetail(
        tester,
        dogs: [
          testDog(
            id: 'fenice',
            nome: '[PROVA] Fenice',
            adottabile: true,
            pubblicato: true,
            dataPubblicazione: DateTime.utc(2024, 7, 1),
            carattere: const ['Dolce'],
          ),
        ],
      );

      await tester.ensureVisible(tabLabel('Adozione'));
      await tester.tap(tabLabel('Adozione'));
      await tester.pumpAndSettle();

      expect(find.text('Sito associazione'), findsNothing);
      expect(find.text('Facebook / Instagram'), findsNothing);
      expect(find.textContaining('Visualizzazioni'), findsNothing);
      expect(find.text('Pubblicato'), findsOneWidget);
      expect(find.text('01/07/2024'), findsOneWidget);
      expect(find.text('Condividi scheda'), findsOneWidget);
    },
  );

  testWidgets(
    'creando una nota compare in cima con autore e data corretti',
    (tester) async {
      final notes = InMemoryNoteRepository([
        Note(
          id: 'n-old',
          dogId: 'fenice',
          tipo: NoteTipo.generale,
          testo: 'Vecchia nota.',
          autoreId: 'uid-1',
          createdAt: DateTime.utc(2026, 8, 21),
        ),
      ]);
      await pumpDetail(tester, notes: notes);

      await tester.ensureVisible(tabLabel('Note'));
      await tester.tap(tabLabel('Note'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(DogNoteTab.addKey));
      await tester.tap(find.byKey(DogNoteTab.addKey));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(AddNoteSheet.testoKey),
        'Oggi ha giocato con Luna.',
      );
      await tester.tap(find.byKey(AddNoteSheet.saveKey));
      await tester.pumpAndSettle();

      expect(find.text('Oggi ha giocato con Luna.'), findsOneWidget);
      expect(find.textContaining('Giovanna'), findsWidgets);
      expect(find.textContaining('08/09/2026'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Oggi ha giocato con Luna.')).dy,
        lessThan(tester.getTopLeft(find.text('Vecchia nota.')).dy),
      );
    },
  );

  testWidgets('il totale spese in scheda coincide con la somma dei movimenti', (
    tester,
  ) async {
    await pumpDetail(tester);
    await tester.tap(tabLabel('Spese'));
    await tester.pumpAndSettle();
    expect(find.byKey(DogSpeseTab.totaleKey), findsOneWidget);
    expect(find.text('€ 715,00'), findsWidgets);
    expect(find.text('Attiva un\'adozione a distanza'), findsOneWidget);
  });

  testWidgets(
    'Carica documento resta sopra la barra di sistema e si può toccare',
    (tester) async {
      simulateSystemNavBar(tester);
      await pumpDetail(tester, size: const Size(360, 1100));

      await tester.ensureVisible(tabLabel('Documenti'));
      await tester.tap(tabLabel('Documenti'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(DogDocumentiTab.addKey));
      await tester.tap(find.byKey(DogDocumentiTab.addKey));
      await tester.pumpAndSettle();

      expect(find.byKey(AddDocumentSheet.saveKey), findsOneWidget);
      expectAboveSystemNav(tester, find.byKey(AddDocumentSheet.saveKey));
      await tester.tap(find.byKey(AddDocumentSheet.saveKey));
      await tester.pump();
    },
  );

  for (final width in widths) {
    testWidgets(
      'tab Adozione Spese Documenti Note Altro a ${width.toInt()} dp senza overflow',
      (tester) async {
        await pumpDetail(tester, size: Size(width, 1100));

        for (final tab in restTabs) {
          await tester.ensureVisible(tabLabel(tab.label));
          await tester.tap(tabLabel(tab.label));
          await tester.pumpAndSettle();
          expect(find.byKey(DogDetailPage.tabBodyKey(tab)), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.fling(
            find.byType(NestedScrollView),
            const Offset(0, -300),
            2000,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
}
