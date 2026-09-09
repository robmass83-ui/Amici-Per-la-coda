import 'dart:convert';
import 'dart:typed_data';

import 'package:amici_per_la_coda/data/documents/document_codec.dart';
import 'package:amici_per_la_coda/data/documents/document_file_picker.dart';
import 'package:amici_per_la_coda/data/documents/template_assets.dart';
import 'package:amici_per_la_coda/data/firestore/firestore_repositories.dart';
import 'package:amici_per_la_coda/data/models/app_document.dart';
import 'package:amici_per_la_coda/data/models/document_template.dart';
import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/data/photos/photo_codec.dart';
import 'package:amici_per_la_coda/features/adoptions/adoption_detail_page.dart';
import 'package:amici_per_la_coda/features/affido/affido_copy.dart';
import 'package:amici_per_la_coda/features/affido/affido_page.dart';
import 'package:amici_per_la_coda/features/dogs/dog_detail_page.dart';
import 'package:amici_per_la_coda/features/settings/settings_page.dart';
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
import '../../helpers/test_image.dart';

Uint8List _patternBytes(int length) {
  final bytes = Uint8List(length);
  for (var i = 0; i < length; i++) {
    bytes[i] = i % 256;
  }
  return bytes;
}

AppDocument _signedDoc({
  String id = 'doc-firmato',
  String dogId = 'fenice',
  String adoptionId = 'ad1',
  String adopterId = 'adp1',
  String nome = 'Preaffido firmato Marta',
}) {
  return AppDocument(
    id: id,
    dogId: dogId,
    adoptionId: adoptionId,
    adopterId: adopterId,
    tipo: DocumentTipo.preaffidoFirmato,
    nome: nome,
    mime: 'application/pdf',
    chunkCount: 0,
    contenutoB64: base64Encode(Uint8List.fromList([1, 2, 3])),
    caricatoIl: DateTime(2026, 9, 12),
    caricatoDa: 'uid-1',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 9, 12, 10);

  Future<void> pumpLogged(
    WidgetTester tester, {
    required String location,
    Size size = const Size(360, 1400),
    InMemoryTemplateRepository? templates,
    InMemoryDocumentRepository? documents,
    InMemoryAdoptionRepository? adoptions,
    InMemoryDogRepository? dogs,
    RecordingFileShare? share,
    FakeDocumentFilePicker? picker,
    AssetBytesLoader? assets,
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
      dogs: dogs ?? InMemoryDogRepository(testListDogs()),
      adoptions:
          adoptions ??
          InMemoryAdoptionRepository([
            testAdoption(
              id: 'ad1',
              dogId: 'fenice',
              adopterId: 'adp1',
              richiedente: testRichiedente(nome: 'Marta', cognome: 'Rossi'),
            ),
          ]),
      documents: documents ?? InMemoryDocumentRepository(),
      templates: templates ?? InMemoryTemplateRepository(),
      volunteers: InMemoryVolunteerRepository([testVolunteer()]),
      documentPicker: picker,
      fileShare: share ?? RecordingFileShare(),
      assets: assets,
      dogListNow: now,
    );
  }

  testWidgets(
    '1. al primo avvio i moduli nascono dagli asset con versione 1',
    (tester) async {
      final templates = InMemoryTemplateRepository();
      await pumpLogged(
        tester,
        location: AppRoutes.impostazioni,
        templates: templates,
        assets: const RootBundleAssetLoader(),
      );
      expect(templates.items, hasLength(2));
      expect(
        templates.items.map((item) => item.id).toSet(),
        {'preaffido', 'adozione'},
      );
      expect(templates.items.every((item) => item.versione == 1), isTrue);
      expect(templates.items.every((item) => item.pdfB64.isNotEmpty), isTrue);
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.text('Modulo di preaffido'), findsOneWidget);
      expect(find.text('Modulo di adozione'), findsOneWidget);
      expect(find.textContaining('Versione 1'), findsWidgets);

      final db = FakeFirebaseFirestore();
      final firestoreTemplates = FirestoreTemplateRepository(db);
      await firestoreTemplates.ensureDefaults(
        loader: const RootBundleAssetLoader(),
        uid: 'uid-1',
        now: now,
      );
      expect(await firestoreTemplates.getById('preaffido'), isNotNull);
      expect(await firestoreTemplates.getById('adozione'), isNotNull);
    },
  );

  testWidgets(
    '2. sostituendo un modulo la versione passa a 2 e si condivide il file nuovo',
    (tester) async {
      final nuovo = _patternBytes(128);
      final templates = InMemoryTemplateRepository([
        DocumentTemplate(
          id: templatePreaffidoId,
          nome: templatePreaffidoNome,
          descrizione: '',
          fileName: 'modulo-preaffido.pdf',
          mime: 'application/pdf',
          pdfB64: base64Encode(_patternBytes(32)),
          versione: 1,
          aggiornatoIl: now,
          aggiornatoDa: 'uid-1',
        ),
        DocumentTemplate(
          id: templateAdozioneId,
          nome: templateAdozioneNome,
          descrizione: '',
          fileName: 'modulo-adozione.pdf',
          mime: 'application/pdf',
          pdfB64: base64Encode(_patternBytes(16)),
          versione: 1,
          aggiornatoIl: now,
          aggiornatoDa: 'uid-1',
        ),
      ]);
      final share = RecordingFileShare();
      final picker = FakeDocumentFilePicker(
        pdf: PickedDocumentFile(
          bytes: nuovo,
          name: 'modulo-preaffido-v2.pdf',
          mime: 'application/pdf',
        ),
      );
      await pumpLogged(
        tester,
        location: AppRoutes.impostazioni,
        templates: templates,
        share: share,
        picker: picker,
      );
      final router = GoRouter.of(tester.element(find.byType(SettingsPage)));
      await tester.tap(find.byKey(SettingsPage.replacePreaffidoKey));
      await tester.pumpAndSettle();
      final updated = templates.items.firstWhere(
        (item) => item.id == templatePreaffidoId,
      );
      expect(updated.versione, 2);
      expect(updated.pdfB64, base64Encode(nuovo));

      router.go(AppRoutes.affidoPer(adoptionId: 'ad1', dogId: 'fenice'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AffidoPage.inviaPreaffidoKey));
      await tester.pumpAndSettle();
      expect(share.lastBytes, nuovo);
    },
  );

  testWidgets(
    '3. Invia modulo apre la condivisione con PDF e testo su adottante e cane',
    (tester) async {
      final pdf = _patternBytes(64);
      final templates = InMemoryTemplateRepository([
        DocumentTemplate(
          id: templatePreaffidoId,
          nome: templatePreaffidoNome,
          descrizione: '',
          fileName: 'modulo-preaffido.pdf',
          mime: 'application/pdf',
          pdfB64: base64Encode(pdf),
          versione: 1,
          aggiornatoIl: now,
          aggiornatoDa: 'uid-1',
        ),
      ]);
      final share = RecordingFileShare();
      await pumpLogged(
        tester,
        location: AppRoutes.affidoPer(
          adoptionId: 'ad1',
          dogId: 'fenice',
        ),
        templates: templates,
        share: share,
      );
      await tester.tap(find.byKey(AffidoPage.inviaPreaffidoKey));
      await tester.pumpAndSettle();
      expect(share.lastBytes, pdf);
      expect(share.lastFileName, 'modulo-preaffido.pdf');
      expect(share.lastText, contains('Marta Rossi'));
      expect(share.lastText, contains('Fenice'));
      expect(
        share.lastText,
        moduloShareText(
          templateId: templatePreaffidoId,
          adopterNome: 'Marta Rossi',
          dogNome: 'Fenice',
        ),
      );
    },
  );

  testWidgets(
    '4. dopo l\'invio la richiesta mostra la data, chi l\'ha mandato e lo storico',
    (tester) async {
      final templates = InMemoryTemplateRepository([
        DocumentTemplate(
          id: templatePreaffidoId,
          nome: templatePreaffidoNome,
          descrizione: '',
          fileName: 'modulo-preaffido.pdf',
          mime: 'application/pdf',
          pdfB64: base64Encode(_patternBytes(8)),
          versione: 1,
          aggiornatoIl: now,
          aggiornatoDa: 'uid-1',
        ),
      ]);
      final adoptions = InMemoryAdoptionRepository([
        testAdoption(
          id: 'ad1',
          dogId: 'fenice',
          adopterId: 'adp1',
          richiedente: testRichiedente(nome: 'Marta', cognome: 'Rossi'),
        ),
      ]);
      await pumpLogged(
        tester,
        location: AppRoutes.affidoPer(
          adoptionId: 'ad1',
          dogId: 'fenice',
        ),
        templates: templates,
        adoptions: adoptions,
        share: RecordingFileShare(),
      );
      await tester.tap(find.byKey(AffidoPage.inviaPreaffidoKey));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Modulo preaffido inviato il 12/09/2026 da Giovanna'),
        findsWidgets,
      );
      final adoption = adoptions.items.single;
      expect(adoption.storicoStati.last.isModuloInviato, isTrue);
      expect(adoption.storicoStati.last.moduloId, templatePreaffidoId);
      expect(adoption.storicoStati.last.autoreId, 'uid-1');
    },
  );

  test('5. un PDF da 4 MB si salva in 7 blocchi e torna identico', () async {
    final bytes = _patternBytes(4 * 1024 * 1024);
    expect(documentChunkCount(bytes.lengthInBytes), 7);
    final db = FakeFirebaseFirestore();
    final repo = FirestoreDocumentRepository(db);
    final saved = await repo.saveBytes(
      _signedDoc(id: 'big', nome: 'scan.pdf'),
      bytes,
    );
    expect(saved.chunkCount, 7);
    expect(saved.contenutoB64, isNull);
    final chunks = await db
        .collection('documents')
        .doc(saved.id)
        .collection('chunks')
        .get();
    expect(chunks.docs, hasLength(7));
    final loaded = await repo.loadBytes(saved.id);
    expect(loaded, bytes);
    expect(base64Encode(loaded), base64Encode(bytes));
  });

  test(
    '6. una foto da 6 MB viene compressa sotto i 300 KB in un documento solo',
    () async {
      final source = await noisyPng(width: 5000, height: 4000);
      expect(source.lengthInBytes, greaterThan(6 * 1024 * 1024));
      final compressed = await compressDocumentImage(source);
      expect(compressed.lengthInBytes, lessThan(300 * 1024));
      final db = FakeFirebaseFirestore();
      final repo = FirestoreDocumentRepository(db);
      final saved = await repo.saveBytes(
        _signedDoc(id: 'foto', nome: 'pagina.jpg', adopterId: 'adp1'),
        compressed,
      );
      expect(saved.chunkCount, 0);
      expect(saved.contenutoB64, isNotNull);
      final loaded = await repo.loadBytes(saved.id);
      expect(loaded, compressed);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    '7. un file da 12 MB viene rifiutato con un messaggio chiaro',
    (tester) async {
      final tooBig = _patternBytes(12 * 1024 * 1024);
      expect(
        () => ensureDocumentSizeAllowed(tooBig.lengthInBytes),
        throwsA(
          isA<DocumentTooLarge>().having(
            (error) => error.toString(),
            'message',
            DocumentTooLarge.message,
          ),
        ),
      );
      await pumpLogged(
        tester,
        location: AppRoutes.affidoPer(
          adoptionId: 'ad1',
          dogId: 'fenice',
        ),
        picker: FakeDocumentFilePicker(
          pdf: PickedDocumentFile(
            bytes: tooBig,
            name: 'scan-pesante.pdf',
            mime: 'application/pdf',
          ),
        ),
      );
      await tester.tap(find.byKey(AffidoPage.caricaKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(UploadSignedSheet.pdfKey));
      await tester.pumpAndSettle();
      expect(find.text(DocumentTooLarge.message), findsOneWidget);
    },
  );

  testWidgets(
    '8. lo stesso documento compare su cane e adottante, una sola copia',
    (tester) async {
      final documents = InMemoryDocumentRepository([
        _signedDoc(),
      ]);
      await pumpLogged(
        tester,
        location: AppRoutes.dog('fenice'),
        documents: documents,
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
      expect(find.text('Preaffido firmato Marta'), findsOneWidget);

      final context = tester.element(find.byType(DogDetailPage));
      GoRouter.of(context).go(AppRoutes.richiesta('ad1'));
      await tester.pumpAndSettle();
      expect(find.byType(AdoptionDetailPage), findsOneWidget);
      expect(find.text('Preaffido firmato Marta'), findsOneWidget);
      expect(documents.items, hasLength(1));
    },
  );

  test(
    '9. il caricamento si salva in locale e si rilegge senza rete',
    () async {
      final db = FakeFirebaseFirestore();
      final repo = FirestoreDocumentRepository(db);
      final bytes = _patternBytes(2048);
      final saved = await repo.saveBytes(_signedDoc(id: 'offline'), bytes);
      final loaded = await repo.loadBytes(saved.id);
      expect(loaded, bytes);
      final snap = await db.collection('documents').doc(saved.id).get();
      expect(snap.exists, isTrue);
    },
  );
}
