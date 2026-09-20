import 'dart:convert';
import 'dart:typed_data';

import 'package:amici_per_la_coda/data/documents/document_file_picker.dart';
import 'package:amici_per_la_coda/data/documents/template_assets.dart';
import 'package:amici_per_la_coda/data/firestore/firestore_repositories.dart';
import 'package:amici_per_la_coda/data/models/app_document.dart';
import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/features/dashboard/home_page.dart';
import 'package:amici_per_la_coda/features/dogs/dog_detail_page.dart';
import 'package:amici_per_la_coda/features/documents/moduli_share_card.dart';
import 'package:amici_per_la_coda/features/dogs/record_actions.dart';
import 'package:amici_per_la_coda/features/settings/altro_page.dart';
import 'package:amici_per_la_coda/features/settings/add_modulo_sheet.dart';
import 'package:amici_per_la_coda/features/settings/modulo_detail_sheet.dart';
import 'package:amici_per_la_coda/features/settings/moduli_page.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_adoption_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_document_repository.dart';
import '../../helpers/fake_dog_repository.dart';
import '../../helpers/fake_file_actions.dart';
import '../../helpers/fake_template_repository.dart';
import '../../helpers/fake_volunteer_repository.dart';
import '../../helpers/pump_app.dart';

Uint8List _pdf([int length = 32]) {
  final bytes = Uint8List(length);
  for (var i = 0; i < length; i++) {
    bytes[i] = i % 256;
  }
  return bytes;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 9, 12, 10);

  Future<void> pumpLogged(
    WidgetTester tester, {
    required String location,
    InMemoryTemplateRepository? templates,
    InMemoryDocumentRepository? documents,
    RecordingFileShare? share,
    FakeDocumentFilePicker? picker,
    Size size = const Size(360, 1400),
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
      adoptions: InMemoryAdoptionRepository([
        testAdoption(
          id: 'ad1',
          dogId: 'fenice',
          adopterId: 'adp1',
          richiedente: testRichiedente(nome: 'Marta', cognome: 'Rossi'),
        ),
      ]),
      templates: templates ?? InMemoryTemplateRepository(),
      documents: documents,
      volunteers: InMemoryVolunteerRepository([testVolunteer()]),
      documentPicker: picker,
      fileShare: share ?? RecordingFileShare(),
      dogListNow: now,
    );
  }

  testWidgets('da Altro si entra in Documenti e modulistica', (
    tester,
  ) async {
    await pumpLogged(
      tester,
      location: AppRoutes.altro,
      templates: InMemoryTemplateRepository([
        testTemplate(
          id: templatePreaffidoId,
          nome: templatePreaffidoNome,
        ),
        testTemplate(
          id: templateAdozioneId,
          nome: templateAdozioneNome,
        ),
      ]),
    );
    expect(find.byKey(AltroPage.documentiKey), findsOneWidget);
    await tester.tap(find.byKey(AltroPage.documentiKey));
    await tester.pumpAndSettle();
    expect(find.byType(ModuliPage), findsOneWidget);
    expect(find.text('Documenti e modulistica'), findsWidgets);
    expect(find.text('Modulo di preaffido'), findsOneWidget);
    expect(find.text('Modulo di adozione'), findsOneWidget);
    expect(find.byKey(ModuliPage.addKey), findsOneWidget);
    expect(find.text('Documenti caricati'), findsOneWidget);
  });

  testWidgets('si può aggiungere un modulo con nome, PDF e visibilità', (
    tester,
  ) async {
    final templates = InMemoryTemplateRepository([
      testTemplate(),
    ]);
    final pdf = _pdf(64);
    await pumpLogged(
      tester,
      location: AppRoutes.moduli,
      templates: templates,
      picker: FakeDocumentFilePicker(
        pdf: PickedDocumentFile(
          bytes: pdf,
          name: 'liberatoria.pdf',
          mime: 'application/pdf',
        ),
      ),
    );
    await tester.tap(find.byKey(ModuliPage.addKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(AddModuloSheet.nomeKey), 'Liberatoria');
    await tester.tap(find.byKey(AddModuloSheet.fileKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AddModuloSheet.aggiungiKey));
    await tester.pumpAndSettle();
    expect(templates.items, hasLength(2));
    final added = templates.items.firstWhere(
      (item) => item.id != templatePreaffidoId,
    );
    expect(added.nome, 'Liberatoria');
    expect(added.fileName, 'liberatoria.pdf');
    expect(added.pdfB64, base64Encode(pdf));
    expect(added.visibilita, TemplateVisibilita.home);
    expect(find.text('Liberatoria'), findsOneWidget);
  });

  testWidgets('si può rimuovere un modulo dalla lista', (tester) async {
    final templates = InMemoryTemplateRepository([
      testTemplate(
        id: templatePreaffidoId,
        nome: templatePreaffidoNome,
      ),
      testTemplate(
        id: templateAdozioneId,
        nome: templateAdozioneNome,
      ),
    ]);
    await pumpLogged(
      tester,
      location: AppRoutes.moduli,
      templates: templates,
    );
    await tester.tap(find.byKey(ModuliPage.rowKey(templateAdozioneId)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ModuloDetailSheet.rimuoviKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ConfirmActionKeys.confirm));
    await tester.pumpAndSettle();
    expect(templates.items, hasLength(1));
    expect(templates.items.single.id, templatePreaffidoId);
    expect(find.text('Modulo di adozione'), findsNothing);
  });

  testWidgets('visibilità home: in home sì, in scheda cane no', (
    tester,
  ) async {
    final templates = InMemoryTemplateRepository([
      testTemplate(
        id: 'liberatoria',
        nome: 'Liberatoria',
        visibilita: TemplateVisibilita.home,
      ),
    ]);
    await pumpLogged(
      tester,
      location: AppRoutes.home,
      templates: templates,
    );
    expect(find.byKey(HomePage.moduliCardKey), findsOneWidget);
    expect(find.byKey(ModuliShareCard.rowKey('liberatoria')), findsOneWidget);

    final router = GoRouter.of(tester.element(find.byType(HomePage)));
    router.go(AppRoutes.dog('fenice'));
    await tester.pumpAndSettle();
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
    expect(find.byKey(ModuliShareCard.rowKey('liberatoria')), findsNothing);
  });

  testWidgets('visibilità scheda: in scheda cane sì, in home no', (
    tester,
  ) async {
    final templates = InMemoryTemplateRepository([
      testTemplate(
        id: 'liberatoria',
        nome: 'Liberatoria',
        visibilita: TemplateVisibilita.scheda,
      ),
    ]);
    await pumpLogged(
      tester,
      location: AppRoutes.home,
      templates: templates,
    );
    expect(find.byKey(HomePage.moduliCardKey), findsNothing);

    final router = GoRouter.of(tester.element(find.byType(HomePage)));
    router.go(AppRoutes.dog('fenice'));
    await tester.pumpAndSettle();
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
    expect(find.byKey(ModuliShareCard.rowKey('liberatoria')), findsOneWidget);
  });

  testWidgets('visibilità nessuna: non compare in home né in scheda', (
    tester,
  ) async {
    final templates = InMemoryTemplateRepository([
      testTemplate(
        id: 'liberatoria',
        nome: 'Liberatoria',
        visibilita: TemplateVisibilita.nessuna,
      ),
    ]);
    await pumpLogged(
      tester,
      location: AppRoutes.home,
      templates: templates,
    );
    expect(find.byKey(HomePage.moduliCardKey), findsNothing);
    final router = GoRouter.of(tester.element(find.byType(HomePage)));
    router.go(AppRoutes.dog('fenice'));
    await tester.pumpAndSettle();
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
    expect(find.byKey(ModuliShareCard.rowKey('liberatoria')), findsNothing);
  });

  testWidgets('dalla scheda cane si condivide il modulo con il nome del cane', (
    tester,
  ) async {
    final pdf = _pdf(48);
    final share = RecordingFileShare();
    final templates = InMemoryTemplateRepository([
      testTemplate(
        id: 'liberatoria',
        nome: 'Liberatoria',
        fileName: 'liberatoria.pdf',
        pdfB64: base64Encode(pdf),
        visibilita: TemplateVisibilita.scheda,
      ),
    ]);
    await pumpLogged(
      tester,
      location: AppRoutes.dog('fenice'),
      templates: templates,
      share: share,
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
    await tester.tap(find.byKey(ModuliShareCard.rowKey('liberatoria')));
    await tester.pumpAndSettle();
    expect(share.lastBytes, pdf);
    expect(share.lastFileName, 'liberatoria.pdf');
    expect(share.lastText, contains('Liberatoria'));
    expect(share.lastText, contains('Fenice'));
  });

  testWidgets('i documenti caricati sulle schede cane si vedono raggruppati', (
    tester,
  ) async {
    await pumpLogged(
      tester,
      location: AppRoutes.documenti,
      documents: InMemoryDocumentRepository([
        AppDocument(
          id: 'doc-fenice',
          dogId: 'fenice',
          adoptionId: 'ad1',
          adopterId: 'adp1',
          tipo: DocumentTipo.preaffidoFirmato,
          nome: 'Preaffido Fenice',
          mime: 'application/pdf',
          chunkCount: 0,
          contenutoB64: base64Encode(_pdf()),
          caricatoIl: DateTime(2026, 9, 9),
          caricatoDa: 'uid-1',
        ),
        AppDocument(
          id: 'doc-brando',
          dogId: 'brando',
          adoptionId: '',
          adopterId: '',
          tipo: DocumentTipo.altro,
          nome: 'Libretto Brando',
          mime: 'application/pdf',
          chunkCount: 0,
          contenutoB64: base64Encode(_pdf()),
          caricatoIl: DateTime(2026, 9, 8),
          caricatoDa: 'uid-1',
        ),
      ]),
    );
    expect(find.byKey(ModuliPage.dogGroupKey('fenice')), findsOneWidget);
    expect(find.byKey(ModuliPage.dogGroupKey('brando')), findsOneWidget);
    expect(find.textContaining('[PROVA] Fenice'), findsOneWidget);
    expect(find.textContaining('[PROVA] Brando'), findsOneWidget);
    expect(find.byKey(ModuliPage.documentRowKey('doc-fenice')), findsOneWidget);
    expect(find.byKey(ModuliPage.documentRowKey('doc-brando')), findsOneWidget);
  });

  test('ensureDefaults non ripristina un modulo cancellato se ne resta uno',
      () async {
    final db = FakeFirebaseFirestore();
    final repo = FirestoreTemplateRepository(db);
    await repo.save(
      testTemplate(
        id: templatePreaffidoId,
        nome: templatePreaffidoNome,
        aggiornatoIl: now,
      ),
    );
    await repo.delete(templateAdozioneId);
    await repo.ensureDefaults(
      loader: FakeAssetBytesLoader({
        templateAdozioneAsset: _pdf(),
        templatePreaffidoAsset: _pdf(),
      }),
      uid: 'uid-1',
      now: now,
    );
    expect(await repo.getById(templateAdozioneId), isNull);
    expect(await repo.getById(templatePreaffidoId), isNotNull);
  });
}
