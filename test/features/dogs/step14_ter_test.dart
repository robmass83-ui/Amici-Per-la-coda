import 'dart:convert';
import 'dart:typed_data';

import 'package:amici_per_la_coda/data/documents/document_file_picker.dart';
import 'package:amici_per_la_coda/data/documents/document_upload.dart';
import 'package:amici_per_la_coda/data/models/app_document.dart';
import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/data/models/note.dart';
import 'package:amici_per_la_coda/data/models/photo.dart';
import 'package:amici_per_la_coda/features/dashboard/home_page.dart';
import 'package:amici_per_la_coda/features/dogs/change_status_page.dart';
import 'package:amici_per_la_coda/features/dogs/dog_altro_tab.dart';
import 'package:amici_per_la_coda/features/dogs/dog_detail_page.dart';
import 'package:amici_per_la_coda/features/dogs/dog_documenti_tab.dart';
import 'package:amici_per_la_coda/features/dogs/dog_gallery_page.dart';
import 'package:amici_per_la_coda/features/dogs/dog_note_tab.dart';
import 'package:amici_per_la_coda/features/dogs/dog_salute_tab.dart';
import 'package:amici_per_la_coda/features/dogs/dog_spese_tab.dart';
import 'package:amici_per_la_coda/features/dogs/dogs_page.dart';
import 'package:amici_per_la_coda/features/dogs/edit_permissions.dart';
import 'package:amici_per_la_coda/features/dogs/record_actions.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_document_repository.dart';
import '../../helpers/fake_dog_repository.dart';
import '../../helpers/fake_expense_repository.dart';
import '../../helpers/fake_health_repository.dart';
import '../../helpers/fake_note_repository.dart';
import '../../helpers/fake_photo_repository.dart';
import '../../helpers/fake_volunteer_repository.dart';
import '../../helpers/fake_weight_repository.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 9, 8);

  Finder tabLabel(String label) {
    return find.descendant(
      of: find.byKey(DogDetailPage.tabBarKey),
      matching: find.text(label),
    );
  }

  Future<void> openTab(WidgetTester tester, String tab) async {
    await tester.ensureVisible(tabLabel(tab));
    await tester.tap(tabLabel(tab));
    await tester.pumpAndSettle();
  }

  Future<void> pumpWithoutVolunteer(
    WidgetTester tester, {
    required String location,
    Size size = const Size(360, 1100),
  }) async {
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    final dogs = InMemoryDogRepository(testListDogs());
    final photos = InMemoryPhotoRepository(
      photos: [
        Photo(
          id: 'p-write',
          dogId: 'fenice',
          isCover: true,
          w: 1,
          h: 1,
          mime: 'image/png',
          thumb: tinyPngBytes(),
          bytesFull: 20,
          createdAt: now,
          createdBy: 'uid-1',
        ),
      ],
      dogs: dogs,
    );
    await pumpApp(
      tester,
      auth: auth,
      initialLocation: location,
      size: size,
      dogs: dogs,
      photos: photos,
      health: InMemoryHealthRepository([
        testHealth(id: 'h-write', dogId: 'fenice'),
      ]),
      weights: InMemoryWeightRepository([testWeight(id: 'w-write')]),
      expenses: InMemoryExpenseRepository([testExpense(id: 'e-write')]),
      notes: InMemoryNoteRepository([
        Note(
          id: 'n-write',
          dogId: 'fenice',
          tipo: NoteTipo.generale,
          testo: 'Nota esistente.',
          autoreId: 'uid-1',
          createdAt: now,
        ),
      ]),
      documents: InMemoryDocumentRepository([
        AppDocument(
          id: 'd-write',
          dogId: 'fenice',
          adoptionId: null,
          adopterId: '',
          tipo: DocumentTipo.altro,
          nome: 'Libretto',
          mime: 'application/pdf',
          chunkCount: 1,
          contenutoB64: 'YQ==',
          caricatoIl: now,
          caricatoDa: 'uid-1',
        ),
      ]),
      volunteers: InMemoryVolunteerRepository([]),
      dogListNow: now,
    );
  }

  test('1. canWriteRecords(null) è false', () {
    expect(canWriteRecords(null), isFalse);
    expect(canCreateNotes(null), isFalse);
    expect(canWriteRecords(testVolunteer()), isTrue);
    expect(
      canWriteRecords(testVolunteer(ruolo: VolunteerRuolo.volontario)),
      isFalse,
    );
  });

  test('volunteerForAuth collega per UID oppure per email', () {
    final byUid = testVolunteer();
    final byEmail = testVolunteer(id: 'seed_giovanna');
    expect(
      volunteerForAuth(
        [byEmail],
        uid: 'uid-1',
        email: 'giovanna@amiciperlacoda.it',
      )?.id,
      'seed_giovanna',
    );
    expect(
      volunteerForAuth(
        [byUid, byEmail],
        uid: 'uid-1',
        email: 'giovanna@amiciperlacoda.it',
      )?.id,
      'uid-1',
    );
    expect(volunteerForAuth([byEmail], uid: 'altro', email: 'no@x.it'), isNull);
    expect(
      volunteerForAuth(
        [byEmail],
        uid: 'altro',
        email: 'ROBERTO.MASALA@gmail.com',
      )?.id,
      isNull,
    );
  });

  test('volunteerForAuth: email locale su altro dominio', () {
    final roberto = testVolunteer(
      id: 'seed_roberto',
      nome: 'Roberto',
      email: 'roberto@amiciperlacoda.it',
    );
    final giovanna = testVolunteer(id: 'seed_giovanna');
    final all = [giovanna, roberto];
    expect(
      volunteerForAuth(
        all,
        uid: 'firebase-roberto',
        email: 'roberto@gmail.com',
      )?.nome,
      'Roberto',
    );
    expect(
      volunteerForAuth(
        all,
        uid: 'firebase-roberto',
        email: 'roberto.masala@gmail.com',
      ),
      isNull,
    );
    expect(
      volunteerForAuth(
        all,
        uid: 'firebase-giovanna',
        email: 'giovanna@amiciperlacoda.it',
      )?.nome,
      'Giovanna',
    );
    expect(greetingNameFromEmail('roberto.masala@gmail.com'), 'Roberto Masala');
    expect(greetingName(volunteer: roberto, email: 'altro@x.it'), 'Roberto');
  });

  test('volunteerForAuth: email vince su UID incrociati', () {
    final sulUidDiRoberto = testVolunteer(
      id: 'uid-roberto',
      nome: 'Giovanna',
      email: 'giovannacacciuto@hotmail.it',
    );
    final sulUidDiGiovanna = testVolunteer(
      id: 'uid-giovanna',
      nome: 'Roberto',
      email: 'robmass83@gmail.com',
    );
    final all = [sulUidDiRoberto, sulUidDiGiovanna];
    expect(
      volunteerForAuth(
        all,
        uid: 'uid-roberto',
        email: 'robmass83@gmail.com',
      )?.nome,
      'Roberto',
    );
    expect(
      volunteerForAuth(
        all,
        uid: 'uid-giovanna',
        email: 'giovannacacciuto@hotmail.it',
      )?.nome,
      'Giovanna',
    );
  });

  testWidgets(
    '1. con volontario nullo nessun pulsante di scrittura in sette schermate',
    (tester) async {
      await pumpWithoutVolunteer(tester, location: AppRoutes.dog('fenice'));

      expect(find.byType(DogDetailPage), findsOneWidget);
      expect(find.byTooltip('Modifica'), findsNothing);
      expect(find.byTooltip('Altre azioni'), findsOneWidget);
      await tester.tap(find.byTooltip('Altre azioni'));
      await tester.pumpAndSettle();
      expect(find.byKey(DogDetailPage.azioneModificaKey), findsNothing);
      expect(find.byKey(DogDetailPage.azioneStatoKey), findsNothing);
      expect(find.byKey(DogDetailPage.azioneArchiviaKey), findsNothing);
      expect(find.byKey(DogDetailPage.azioneEliminaKey), findsNothing);
      Navigator.of(
        tester.element(find.byType(DogDetailPage)),
        rootNavigator: true,
      ).pop();
      await tester.pumpAndSettle();

      await openTab(tester, 'Salute');
      expect(find.byType(DogSaluteTab), findsOneWidget);
      expect(find.byKey(DogSaluteTab.addTreatmentKey), findsNothing);
      expect(find.byKey(DogSaluteTab.addWeightKey), findsNothing);
      expect(find.byKey(DogSaluteTab.editPatologieKey), findsNothing);
      expect(find.text('Aggiungi trattamento'), findsNothing);
      expect(find.text('Registra peso'), findsNothing);
      expect(find.text('Aggiungi patologia'), findsNothing);
      expect(find.byKey(recordMenuKey('h-write')), findsNothing);
      expect(find.byKey(recordMenuKey('w-write')), findsNothing);

      await openTab(tester, 'Spese');
      expect(find.byType(DogSpeseTab), findsOneWidget);
      expect(find.byKey(DogSpeseTab.addKey), findsNothing);
      expect(find.byKey(DogSpeseTab.addSponsorshipKey), findsNothing);
      expect(find.text('Registra spesa'), findsNothing);
      expect(find.byKey(recordMenuKey('e-write')), findsNothing);

      await openTab(tester, 'Documenti');
      expect(find.byType(DogDocumentiTab), findsOneWidget);
      expect(find.byKey(DogDocumentiTab.addKey), findsNothing);
      expect(find.text('Carica documento'), findsNothing);
      expect(find.byKey(recordMenuKey('d-write')), findsNothing);

      await openTab(tester, 'Note');
      expect(find.byType(DogNoteTab), findsOneWidget);
      expect(find.byKey(DogNoteTab.addKey), findsNothing);
      expect(find.text('Aggiungi nota'), findsNothing);
      expect(find.byKey(recordMenuKey('n-write')), findsNothing);
    },
  );

  testWidgets(
    '1. galleria: senza volontario upload, elimina e copertina non si disegnano',
    (tester) async {
      await pumpWithoutVolunteer(tester, location: AppRoutes.dogFoto('fenice'));

      expect(find.byType(DogGalleryPage), findsOneWidget);
      expect(find.byKey(DogGalleryPage.addKey), findsNothing);
      expect(find.byKey(DogGalleryPage.uploadKey), findsNothing);
      expect(find.byKey(DogGalleryPage.setCoverKey), findsNothing);
      expect(find.byKey(DogGalleryPage.useForAdKey), findsNothing);
      expect(find.byKey(DogGalleryPage.deleteKey('p-write')), findsNothing);
      expect(find.text('Imposta copertina'), findsNothing);
      expect(find.text('Usa per annuncio'), findsNothing);
      expect(find.text('Carica nuove foto'), findsNothing);
    },
  );

  testWidgets('1. cambio stato: senza volontario Salva non si disegna', (
    tester,
  ) async {
    await pumpWithoutVolunteer(tester, location: AppRoutes.dogStato('fenice'));

    expect(find.byType(ChangeStatusPage), findsOneWidget);
    expect(find.byKey(ChangeStatusPage.saveKey), findsNothing);
    expect(find.text('Salva nuovo stato'), findsNothing);
    expect(find.text('Cambia stato'), findsNothing);
  });

  testWidgets(
    '1. home: account senza riga in volunteers mostra l\'avviso, non la dashboard',
    (tester) async {
      await pumpWithoutVolunteer(tester, location: AppRoutes.home);

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byKey(HomePage.accountDisabledKey), findsOneWidget);
      expect(
        find.text(
          'Il tuo account non è ancora abilitato: chiedi al presidente',
        ),
        findsOneWidget,
      );
      expect(find.text('Cani in rifugio'), findsNothing);
      expect(find.textContaining('Ciao'), findsNothing);
    },
  );

  testWidgets(
    '2. un cane archiviato non compare in nessun segmento dell\'elenco',
    (tester) async {
      final auth = FakeAuthRepository();
      await auth.signIn(
        email: 'giovanna@amiciperlacoda.it',
        password: 'corretta',
      );
      await pumpApp(
        tester,
        auth: auth,
        initialLocation: AppRoutes.animali,
        size: const Size(360, 900),
        dogs: InMemoryDogRepository([
          ...testListDogs(),
          testDog(
            id: 'archivio',
            nome: 'Archivione',
            archiviato: true,
            adottabile: true,
            dataNascita: DateTime.utc(2026, 3, 1),
          ),
        ]),
        dogListNow: now,
      );

      expect(find.byType(DogsPage), findsOneWidget);
      expect(find.text('Archivione'), findsNothing);
      for (final label in [
        'Rifugio',
        'Stallo',
        'Adottab.',
        'Cuccioli',
        'Adottati',
      ]) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(find.text('Archivione'), findsNothing, reason: label);
      }
    },
  );

  testWidgets(
    '3. Archivia chiede conferma con il nome; poi il cane sparisce e resta nello storico',
    (tester) async {
      final auth = FakeAuthRepository();
      await auth.signIn(
        email: 'giovanna@amiciperlacoda.it',
        password: 'corretta',
      );
      final dogs = InMemoryDogRepository(testListDogs());
      await pumpApp(
        tester,
        auth: auth,
        initialLocation: AppRoutes.dog('fenice'),
        size: const Size(360, 1400),
        dogs: dogs,
        dogListNow: now,
      );

      await openTab(tester, 'Altro');
      await tester.ensureVisible(find.byKey(DogAltroTab.archiviaKey));
      await tester.tap(find.byKey(DogAltroTab.archiviaKey));
      await tester.pumpAndSettle();

      expect(find.text('Archiviare la scheda di Fenice?'), findsOneWidget);
      expect(find.text('Archivia scheda'), findsWidgets);
      await tester.tap(find.byKey(ConfirmActionKeys.confirm));
      await tester.pumpAndSettle();

      expect(find.byType(DogsPage), findsOneWidget);
      expect(find.text('[PROVA] Fenice'), findsNothing);
      final archived = await dogs.getById('fenice');
      expect(archived?.archiviato, isTrue);
      expect(
        archived?.storicoStati.any((voce) => voce.note == 'Scheda archiviata'),
        isTrue,
      );
    },
  );

  testWidgets(
    '3b. Elimina definitivamente dalla tab Altro cancella la scheda',
    (tester) async {
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    final dogs = InMemoryDogRepository(testListDogs());
    await pumpApp(
      tester,
      auth: auth,
      initialLocation: AppRoutes.dog('fenice'),
      size: const Size(360, 1400),
      dogs: dogs,
      dogListNow: now,
    );

    await openTab(tester, 'Altro');
    await tester.ensureVisible(find.byKey(DogAltroTab.eliminaKey));
    await tester.tap(find.byKey(DogAltroTab.eliminaKey));
    await tester.pumpAndSettle();
    expect(find.textContaining('Eliminare per sempre la scheda di Fenice'), findsOneWidget);
    await tester.tap(find.byKey(ConfirmActionKeys.confirm));
    await tester.pumpAndSettle();

    expect(find.byType(DogsPage), findsOneWidget);
    expect(await dogs.getById('fenice'), isNull);
  });

  testWidgets('4. cambio stato a trasferito senza struttura è bloccato', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    final dogs = InMemoryDogRepository(testListDogs());
    await pumpApp(
      tester,
      auth: auth,
      initialLocation: AppRoutes.dogStato(
        'fenice',
        stato: DogStato.trasferito.wire,
      ),
      size: const Size(360, 1400),
      dogs: dogs,
      dogListNow: now,
    );

    expect(find.byType(ChangeStatusPage), findsOneWidget);
    expect(find.byKey(ChangeStatusPage.strutturaKey), findsOneWidget);
    await tester.ensureVisible(find.byKey(ChangeStatusPage.saveKey));
    await tester.tap(find.byKey(ChangeStatusPage.saveKey));
    await tester.pumpAndSettle();

    expect(find.byType(ChangeStatusPage), findsOneWidget);
    expect(find.text('Indica la struttura di destinazione.'), findsOneWidget);
    expect((await dogs.getById('fenice'))?.stato, DogStato.inRifugio);
  });

  test(
    '5. lo stesso PDF da 3 MB produce gli stessi blocchi da scheda e da Affido',
    () async {
      final bytes = Uint8List(3 * 1024 * 1024);
      for (var i = 0; i < bytes.length; i++) {
        bytes[i] = i % 256;
      }
      final file = PickedDocumentFile(
        bytes: bytes,
        name: 'libretto.pdf',
        mime: 'application/pdf',
      );
      final fromDog = InMemoryDocumentRepository();
      final fromAffido = InMemoryDocumentRepository();
      final now = DateTime.utc(2026, 9, 8);
      final meta = AppDocument(
        id: 'doc_shared',
        dogId: 'fenice',
        adoptionId: null,
        adopterId: '',
        tipo: DocumentTipo.libretto,
        nome: '',
        mime: '',
        chunkCount: 0,
        contenutoB64: null,
        caricatoIl: now,
        caricatoDa: 'uid-1',
      );

      final dogSaved = await savePickedDocument(
        repository: fromDog,
        files: [file],
        meta: meta,
      );
      final affidoSaved = await savePickedDocument(
        repository: fromAffido,
        files: [file],
        meta: meta.copyWith(adoptionId: 'ad1', adopterId: 'adp1'),
      );

      expect(dogSaved.chunkCount, greaterThan(0));
      expect(dogSaved.chunkCount, affidoSaved.chunkCount);
      expect(dogSaved.contenutoB64, isNull);
      expect(affidoSaved.contenutoB64, isNull);
      final dogBytes = await fromDog.loadBytes(dogSaved.id);
      final affidoBytes = await fromAffido.loadBytes(affidoSaved.id);
      expect(dogBytes, affidoBytes);
      expect(base64Encode(dogBytes), base64Encode(affidoBytes));
    },
  );

  test('6. non si può salvare un documento senza contenuto', () {
    final repo = InMemoryDocumentRepository();
    final empty = AppDocument(
      id: 'doc_empty',
      dogId: 'fenice',
      adoptionId: null,
      adopterId: '',
      tipo: DocumentTipo.altro,
      nome: 'Vuoto',
      mime: 'application/pdf',
      chunkCount: 0,
      contenutoB64: null,
      caricatoIl: now,
      caricatoDa: 'uid-1',
    );
    expect(() => repo.save(empty), throwsA(isA<ArgumentError>()));
    expect(
      () => repo.save(empty.copyWith(contenutoB64: '')),
      throwsA(isA<ArgumentError>()),
    );
  });
}
