import 'dart:convert';
import 'dart:typed_data';

import 'package:amici_per_la_coda/data/models/app_document.dart';
import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/features/dogs/add_document_sheet.dart';
import 'package:amici_per_la_coda/features/dogs/dog_detail_page.dart';
import 'package:amici_per_la_coda/features/dogs/dog_documenti_tab.dart';
import 'package:amici_per_la_coda/features/dogs/record_actions.dart';
import 'package:amici_per_la_coda/features/documents/document_actions.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_document_repository.dart';
import '../../helpers/fake_dog_repository.dart';
import '../../helpers/fake_file_actions.dart';
import '../../helpers/fake_volunteer_repository.dart';
import '../../helpers/pump_app.dart';

Uint8List _pdfBytes() => Uint8List.fromList(utf8.encode('%PDF-1.4 test'));

AppDocument _doc({
  String id = 'doc-evelin',
  String nome = 'Attestato di passaggio di proprietà — EVELIN',
  String mime = 'application/pdf',
}) {
  return AppDocument(
    id: id,
    dogId: 'fenice',
    adoptionId: null,
    adopterId: '',
    tipo: DocumentTipo.altro,
    nome: nome,
    mime: mime,
    chunkCount: 0,
    contenutoB64: base64Encode(_pdfBytes()),
    caricatoIl: DateTime.utc(2024, 7, 15),
    caricatoDa: 'uid-1',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 9, 18);

  test('il nome file per aprire/condividere tiene l\'estensione del mime', () {
    expect(documentFileName(_doc()), endsWith('.pdf'));
    expect(
      documentFileName(_doc(nome: 'libretto.pdf')),
      'libretto.pdf',
    );
    expect(
      documentFileName(_doc(nome: 'Foto box', mime: 'image/jpeg')),
      'Foto box.jpg',
    );
  });

  Future<void> pumpDocumenti(
    WidgetTester tester, {
    required InMemoryDocumentRepository documents,
    required FakeFileOpener opener,
    required RecordingFileShare share,
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
      size: const Size(360, 1100),
      dogs: InMemoryDogRepository(testListDogs()),
      documents: documents,
      volunteers: InMemoryVolunteerRepository([testVolunteer()]),
      fileOpener: opener,
      fileShare: share,
      dogListNow: now,
    );
    await tester.ensureVisible(
      find.descendant(
        of: find.byKey(DogDetailPage.tabBarKey),
        matching: find.text('Documenti'),
      ),
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(DogDetailPage.tabBarKey),
        matching: find.text('Documenti'),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openMenu(WidgetTester tester, String id) async {
    await tester.ensureVisible(find.byKey(recordMenuKey(id)));
    await tester.tap(find.byKey(recordMenuKey(id)));
    await tester.pumpAndSettle();
  }

  testWidgets('Apri dal menu apre il file e resta sulla scheda cane', (
    tester,
  ) async {
    final documents = InMemoryDocumentRepository([_doc()]);
    final opener = FakeFileOpener();
    final share = RecordingFileShare();
    await pumpDocumenti(
      tester,
      documents: documents,
      opener: opener,
      share: share,
    );

    await openMenu(tester, 'doc-evelin');
    expect(find.byKey(DocumentActionKeys.open), findsOneWidget);
    await tester.tap(find.byKey(DocumentActionKeys.open));
    await tester.pumpAndSettle();

    expect(find.byType(DogDetailPage), findsOneWidget);
    expect(find.byType(DogDocumentiTab), findsOneWidget);
    expect(find.text('Documenti del cane'), findsOneWidget);
    expect(find.byKey(DocumentActionKeys.open), findsNothing);
    expect(opener.lastBytes, _pdfBytes());
    expect(opener.lastFileName, endsWith('.pdf'));
    expect(opener.lastMime, 'application/pdf');
    expect(share.lastBytes, isNull);
  });

  testWidgets('Condividi dal menu invia il file caricato', (tester) async {
    final documents = InMemoryDocumentRepository([_doc()]);
    final opener = FakeFileOpener();
    final share = RecordingFileShare();
    await pumpDocumenti(
      tester,
      documents: documents,
      opener: opener,
      share: share,
    );

    await openMenu(tester, 'doc-evelin');
    await tester.tap(find.byKey(DocumentActionKeys.share));
    await tester.pumpAndSettle();

    expect(find.byType(DogDetailPage), findsOneWidget);
    expect(share.lastBytes, _pdfBytes());
    expect(share.lastFileName, endsWith('.pdf'));
    expect(share.lastMime, 'application/pdf');
    expect(share.lastText, contains('EVELIN'));
    expect(opener.lastBytes, isNull);
  });

  testWidgets('Rinomina dal menu cambia il nome del documento', (tester) async {
    final documents = InMemoryDocumentRepository([_doc()]);
    final opener = FakeFileOpener();
    final share = RecordingFileShare();
    await pumpDocumenti(
      tester,
      documents: documents,
      opener: opener,
      share: share,
    );

    await openMenu(tester, 'doc-evelin');
    await tester.tap(find.byKey(DocumentActionKeys.rename));
    await tester.pumpAndSettle();

    expect(find.text('Modifica documento'), findsOneWidget);
    await tester.enterText(
      find.byKey(AddDocumentSheet.nomeKey),
      'Attestato Evelin aggiornato',
    );
    await tester.pump();
    await tester.tap(find.byKey(AddDocumentSheet.saveKey));
    await tester.pumpAndSettle();

    expect(find.byType(DogDetailPage), findsOneWidget);
    expect(find.text('Attestato Evelin aggiornato'), findsOneWidget);
    expect(documents.items.single.nome, 'Attestato Evelin aggiornato');
  });

  testWidgets('Elimina dal menu chiede conferma e toglie il file', (
    tester,
  ) async {
    final documents = InMemoryDocumentRepository([_doc()]);
    final opener = FakeFileOpener();
    final share = RecordingFileShare();
    await pumpDocumenti(
      tester,
      documents: documents,
      opener: opener,
      share: share,
    );

    await openMenu(tester, 'doc-evelin');
    await tester.tap(find.byKey(DocumentActionKeys.delete));
    await tester.pumpAndSettle();

    expect(find.text('Conferma eliminazione'), findsOneWidget);
    await tester.tap(find.byKey(ConfirmActionKeys.confirm));
    await tester.pumpAndSettle();

    expect(find.byType(DogDetailPage), findsOneWidget);
    expect(find.text('Nessun documento.'), findsOneWidget);
    expect(documents.items, isEmpty);
  });
}
