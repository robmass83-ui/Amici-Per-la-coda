import 'dart:io';
import 'dart:ui' as ui;

import 'package:amici_per_la_coda/data/models/dog.dart';
import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/data/models/photo.dart';
import 'package:amici_per_la_coda/features/adoptions/adoption_detail_page.dart';
import 'package:amici_per_la_coda/features/adoptions/adoptions_page.dart';
import 'package:amici_per_la_coda/features/adoptions/new_adoption_page.dart';
import 'package:amici_per_la_coda/features/affido/affido_page.dart';
import 'package:amici_per_la_coda/features/auth/login_page.dart';
import 'package:amici_per_la_coda/features/calendar/add_appointment_sheet.dart';
import 'package:amici_per_la_coda/features/dashboard/home_page.dart';
import 'package:amici_per_la_coda/features/dogs/add_expense_sheet.dart';
import 'package:amici_per_la_coda/features/dogs/add_treatment_sheet.dart';
import 'package:amici_per_la_coda/features/dogs/change_status_page.dart';
import 'package:amici_per_la_coda/features/dogs/dog_altro_tab.dart';
import 'package:amici_per_la_coda/features/dogs/dog_detail_page.dart';
import 'package:amici_per_la_coda/features/dogs/dog_filters_sheet.dart';
import 'package:amici_per_la_coda/features/dogs/dog_gallery_page.dart';
import 'package:amici_per_la_coda/features/dogs/dogs_page.dart';
import 'package:amici_per_la_coda/features/boxes/boxes_page.dart';
import 'package:amici_per_la_coda/features/dogs/edit_dog_page.dart';
import 'package:amici_per_la_coda/features/dogs/export/adoption_pdf_preview_page.dart';
import 'package:amici_per_la_coda/features/dogs/pick_dog_sheet.dart';
import 'package:amici_per_la_coda/features/dogs/record_actions.dart';
import 'package:amici_per_la_coda/features/shell/new_item_sheet.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_adoption_repository.dart';
import '../../helpers/fake_app_link_opener.dart';
import '../../helpers/fake_appointment_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_dog_repository.dart';
import '../../helpers/fake_file_actions.dart';
import '../../helpers/fake_health_repository.dart';
import '../../helpers/fake_photo_repository.dart';
import '../../helpers/fake_volunteer_repository.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 9, 8);

  Future<FakeAuthRepository> pumpLogged(
    WidgetTester tester, {
    String location = AppRoutes.home,
    Size size = const Size(360, 1100),
    List<Dog>? dogs,
    FakeAuthRepository? auth,
    InMemoryVolunteerRepository? volunteers,
    InMemoryHealthRepository? health,
    InMemoryAdoptionRepository? adoptions,
    InMemoryAppointmentRepository? appointments,
    InMemoryPhotoRepository? photos,
    FakeAppLinkOpener? links,
    RecordingFileShare? fileShare,
  }) async {
    final session = auth ?? FakeAuthRepository();
    if (session.currentUser == null) {
      await session.signIn(
        email: 'giovanna@amiciperlacoda.it',
        password: 'corretta',
      );
    }
    final dogList = dogs ?? testListDogs();
    final dogRepo = InMemoryDogRepository(dogList);
    await pumpApp(
      tester,
      auth: session,
      initialLocation: location,
      size: size,
      dogs: dogRepo,
      volunteers: volunteers,
      health: health,
      adoptions: adoptions,
      appointments: appointments,
      photos: photos ?? InMemoryPhotoRepository(dogs: dogRepo),
      links: links,
      fileShare: fileShare,
      dogListNow: now,
    );
    return session;
  }

  Future<void> openFab(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Nuovo'));
    await tester.pumpAndSettle();
  }

  testWidgets('7. FAB Nuovo cane apre il wizard, non un toast', (tester) async {
    await pumpLogged(tester);
    await openFab(tester);
    await tester.tap(find.byKey(NewItemSheetKeys.nuovoCane));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nuovo cane'), findsWidgets);
    expect(
      find.textContaining('disponibile negli step successivi'),
      findsNothing,
    );
  });

  testWidgets('7. FAB Richiesta apre /richieste/nuova', (tester) async {
    await pumpLogged(tester);
    await openFab(tester);
    await tester.tap(find.byKey(NewItemSheetKeys.richiesta));
    await tester.pumpAndSettle();
    expect(find.byType(NewAdoptionPage), findsOneWidget);
    expect(find.text('Nuova richiesta'), findsOneWidget);
    expect(
      find.textContaining('disponibile negli step successivi'),
      findsNothing,
    );
  });

  testWidgets('7. FAB Trattamento apre selettore e poi il foglio', (
    tester,
  ) async {
    await pumpLogged(tester);
    await openFab(tester);
    await tester.tap(find.byKey(NewItemSheetKeys.trattamento));
    await tester.pumpAndSettle();
    expect(find.text('Scegli un cane'), findsOneWidget);
    await tester.tap(find.byKey(PickDogSheet.dogKey('fenice')));
    await tester.pumpAndSettle();
    expect(find.byType(AddTreatmentSheet), findsOneWidget);
    expect(find.text('Aggiungi trattamento'), findsOneWidget);
    expect(
      find.textContaining('disponibile negli step successivi'),
      findsNothing,
    );
  });

  testWidgets('7. FAB Spesa apre selettore con spesa generale e il foglio', (
    tester,
  ) async {
    await pumpLogged(tester);
    await openFab(tester);
    await tester.tap(find.byKey(NewItemSheetKeys.spesa));
    await tester.pumpAndSettle();
    expect(find.text('Spesa generale del rifugio'), findsOneWidget);
    await tester.tap(find.byKey(PickDogSheet.generalExpenseKey));
    await tester.pumpAndSettle();
    expect(find.byType(AddExpenseSheet), findsOneWidget);
    expect(find.text('Registra spesa'), findsOneWidget);
    expect(
      find.textContaining('disponibile negli step successivi'),
      findsNothing,
    );
  });

  testWidgets('7. FAB Appuntamento apre AddAppointmentSheet', (tester) async {
    await pumpLogged(tester);
    await openFab(tester);
    await tester.tap(find.byKey(NewItemSheetKeys.appuntamento));
    await tester.pumpAndSettle();
    expect(find.byType(AddAppointmentSheet), findsOneWidget);
    expect(find.text('Nuovo appuntamento'), findsOneWidget);
    expect(
      find.textContaining('disponibile negli step successivi'),
      findsNothing,
    );
  });

  testWidgets('7. FAB Foto rapida apre selettore e foglio galleria', (
    tester,
  ) async {
    await pumpLogged(tester);
    await openFab(tester);
    await tester.tap(find.byKey(NewItemSheetKeys.foto));
    await tester.pumpAndSettle();
    expect(find.text('Scegli un cane'), findsOneWidget);
    await tester.tap(find.byKey(PickDogSheet.dogKey('fenice')));
    await tester.pumpAndSettle();
    expect(find.byType(DogGalleryPage), findsOneWidget);
    expect(find.text('Aggiungi foto'), findsOneWidget);
    expect(
      find.textContaining('disponibile negli step successivi'),
      findsNothing,
    );
  });

  testWidgets('8. il ⋮ della scheda non mostra più PDF e card social', (
    tester,
  ) async {
    await pumpLogged(tester, location: AppRoutes.dog('fenice'));
    await tester.tap(find.byTooltip('Altre azioni'));
    await tester.pumpAndSettle();
    expect(find.byKey(DogDetailPage.azioneModificaKey), findsOneWidget);
    expect(find.byKey(DogDetailPage.azioneFotoKey), findsOneWidget);
    expect(find.byKey(DogDetailPage.azioneStatoKey), findsOneWidget);
    expect(find.byKey(DogDetailPage.azioneModuloKey), findsOneWidget);
    expect(find.byKey(DogDetailPage.azioneEsportaPdfKey), findsNothing);
    expect(find.byKey(DogDetailPage.azioneCardSocialKey), findsNothing);
    expect(find.byKey(DogDetailPage.azioneDuplicaKey), findsOneWidget);
    expect(find.byKey(DogDetailPage.azioneArchiviaKey), findsOneWidget);
    expect(find.byKey(DogDetailPage.azioneEliminaKey), findsOneWidget);
    expect(find.byKey(DogDetailPage.azioneCondividiKey), findsNothing);
  });

  testWidgets('8. ⋮ Modifica apre la pagina di modifica', (tester) async {
    await pumpLogged(tester, location: AppRoutes.dog('fenice'));
    await tester.tap(find.byTooltip('Altre azioni'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DogDetailPage.azioneModificaKey));
    await tester.pumpAndSettle();
    expect(find.byType(EditDogPage), findsOneWidget);
  });

  testWidgets('8. ⋮ Gestisci foto apre la galleria', (tester) async {
    await pumpLogged(tester, location: AppRoutes.dog('fenice'));
    await tester.tap(find.byTooltip('Altre azioni'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DogDetailPage.azioneFotoKey));
    await tester.pumpAndSettle();
    expect(find.byType(DogGalleryPage), findsOneWidget);
  });

  testWidgets('8. ⋮ Cambia stato apre la pagina stato', (tester) async {
    await pumpLogged(tester, location: AppRoutes.dog('fenice'));
    await tester.tap(find.byTooltip('Altre azioni'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DogDetailPage.azioneStatoKey));
    await tester.pumpAndSettle();
    expect(find.byType(ChangeStatusPage), findsOneWidget);
  });

  testWidgets('8. ⋮ Invia modulo apre Affido', (tester) async {
    await pumpLogged(tester, location: AppRoutes.dog('fenice'));
    await tester.tap(find.byTooltip('Altre azioni'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DogDetailPage.azioneModuloKey));
    await tester.pumpAndSettle();
    expect(find.byType(AffidoPage), findsOneWidget);
  });

  testWidgets('8. Condividi → Scheda di adozione (PDF) apre l\'anteprima', (
    tester,
  ) async {
    await pumpLogged(tester, location: AppRoutes.dog('fenice'));
    await tester.tap(find.byTooltip('Condividi'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(DogDetailPage.azioneEsportaPdfKey));
    await tester.tap(find.byKey(DogDetailPage.azioneEsportaPdfKey));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(AdoptionPdfPreviewPage.pageKey), findsOneWidget);
    expect(find.text('Scheda di adozione'), findsWidgets);
    expect(find.text('Copia link scheda pubblica'), findsNothing);
  });

  testWidgets('8. ⋮ Duplica scheda apre la copia', (tester) async {
    await pumpLogged(tester, location: AppRoutes.dog('fenice'));
    await tester.tap(find.byTooltip('Altre azioni'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(DogDetailPage.azioneDuplicaKey));
    await tester.tap(find.byKey(DogDetailPage.azioneDuplicaKey));
    await tester.pumpAndSettle();
    expect(find.byType(DogDetailPage), findsOneWidget);
    expect(find.textContaining('Copia di Fenice'), findsWidgets);
  });

  testWidgets('8. ⋮ Archivia chiede conferma', (tester) async {
    await pumpLogged(tester, location: AppRoutes.dog('fenice'));
    await tester.tap(find.byTooltip('Altre azioni'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DogDetailPage.azioneArchiviaKey));
    await tester.pumpAndSettle();
    expect(find.textContaining('Archiviare la scheda'), findsOneWidget);
  });

  testWidgets('8. ⋮ Elimina definitivamente chiede conferma e cancella', (
    tester,
  ) async {
    await pumpLogged(tester, location: AppRoutes.dog('fenice'));
    await tester.tap(find.byTooltip('Altre azioni'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(DogDetailPage.azioneEliminaKey));
    expect(find.text('Elimina definitivamente'), findsOneWidget);
    await tester.tap(find.byKey(DogDetailPage.azioneEliminaKey));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Eliminare per sempre la scheda di Fenice'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(ConfirmActionKeys.confirm));
    await tester.pumpAndSettle();
    expect(find.byType(DogsPage), findsOneWidget);
    expect(find.text('[PROVA] Fenice'), findsNothing);
  });

  testWidgets('8. il ⋮ nasconde le voci di scrittura al volontario', (
    tester,
  ) async {
    await pumpLogged(
      tester,
      location: AppRoutes.dog('fenice'),
      volunteers: InMemoryVolunteerRepository([
        testVolunteer(ruolo: VolunteerRuolo.volontario),
      ]),
    );
    await tester.tap(find.byTooltip('Altre azioni'));
    await tester.pumpAndSettle();
    expect(find.byKey(DogDetailPage.azioneModificaKey), findsNothing);
    expect(find.byKey(DogDetailPage.azioneStatoKey), findsNothing);
    expect(find.byKey(DogDetailPage.azioneArchiviaKey), findsNothing);
    expect(find.byKey(DogDetailPage.azioneEliminaKey), findsNothing);
    expect(find.byKey(DogDetailPage.azioneFotoKey), findsOneWidget);
    expect(find.byKey(DogDetailPage.azioneModuloKey), findsOneWidget);
    expect(find.byKey(DogDetailPage.azioneEsportaPdfKey), findsNothing);
    expect(find.byKey(DogDetailPage.azioneCardSocialKey), findsNothing);
    expect(find.byKey(DogDetailPage.azioneCondividiKey), findsNothing);
    expect(find.byKey(DogDetailPage.azioneDuplicaKey), findsNothing);
  });

  testWidgets('9. Filtri e ordina: Taglia grande cambia la lista', (
    tester,
  ) async {
    final dogs = [
      for (final dog in testListDogs())
        dog.id == 'zeus' ? dog.copyWith(taglia: Taglia.grande) : dog,
    ];
    await pumpLogged(tester, location: AppRoutes.animali, dogs: dogs);
    expect(find.textContaining('Fenice'), findsWidgets);
    expect(find.textContaining('Zeus'), findsOneWidget);

    await tester.tap(find.byKey(DogsPage.filtriOrdinaKey));
    await tester.pumpAndSettle();
    expect(find.text('Filtri e ordinamento'), findsOneWidget);
    await tester.tap(find.byKey(DogFiltersSheet.tagliaGrandeKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DogFiltersSheet.applyKey));
    await tester.pumpAndSettle();

    expect(find.textContaining('Fenice'), findsNothing);
    expect(find.textContaining('Zeus'), findsOneWidget);
    expect(
      find.textContaining('disponibile negli step successivi'),
      findsNothing,
    );
  });

  testWidgets('Header Condividi apre PDF e card social', (tester) async {
    await pumpLogged(tester, location: AppRoutes.dog('fenice'));
    await tester.tap(find.byTooltip('Condividi'));
    await tester.pumpAndSettle();
    expect(find.text('Condividi'), findsWidgets);
    expect(find.byKey(DogDetailPage.azioneEsportaPdfKey), findsOneWidget);
    expect(find.byKey(DogDetailPage.azioneCardSocialKey), findsOneWidget);
    expect(
      find.textContaining('disponibile negli step successivi'),
      findsNothing,
    );
  });

  testWidgets('Altro Box apre la schermata Box e settori', (tester) async {
    await pumpLogged(tester, location: AppRoutes.dog('fenice'));
    await tester.tap(
      find.descendant(
        of: find.byKey(DogDetailPage.tabBarKey),
        matching: find.text('Altro'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(DogAltroTab.boxKey));
    await tester.tap(find.byKey(DogAltroTab.boxKey));
    await tester.pumpAndSettle();
    expect(find.byType(BoxesPage), findsOneWidget);
    expect(find.text('Box e settori'), findsWidgets);
    expect(find.byType(EditDogPage), findsNothing);
  });

  testWidgets('Altro referente apre il foglio dei volontari attivi', (
    tester,
  ) async {
    await pumpLogged(tester, location: AppRoutes.dog('fenice'));
    await tester.tap(
      find.descendant(
        of: find.byKey(DogDetailPage.tabBarKey),
        matching: find.text('Altro'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(DogAltroTab.referenteKey));
    await tester.tap(find.byKey(DogAltroTab.referenteKey));
    await tester.pumpAndSettle();
    expect(find.text('Volontario referente'), findsWidgets);
    expect(find.text('Giovanna'), findsWidgets);
  });

  testWidgets('Altro disegna Esporta scheda in PDF', (tester) async {
    await pumpLogged(tester, location: AppRoutes.dog('fenice'));
    await tester.tap(
      find.descendant(
        of: find.byKey(DogDetailPage.tabBarKey),
        matching: find.text('Altro'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(DogAltroTab.esportaPdfKey));
    expect(find.text('Scheda di adozione (PDF)'), findsOneWidget);
  });

  testWidgets('Home Cani in rifugio apre l\'elenco filtrato', (tester) async {
    await pumpLogged(tester);
    await tester.tap(find.byKey(HomePage.caniInRifugioKey));
    await tester.pumpAndSettle();
    expect(find.byType(DogsPage), findsOneWidget);
    final uri = GoRouterState.of(tester.element(find.byType(DogsPage))).uri;
    expect(uri.queryParameters['filtro'], 'in_rifugio');
  });

  testWidgets('Home Adozioni apre le richieste Chiuse', (tester) async {
    await pumpLogged(tester);
    await tester.tap(find.byKey(HomePage.adozioniKey));
    await tester.pumpAndSettle();
    expect(find.byType(AdoptionsPage), findsOneWidget);
    final uri = GoRouterState.of(tester.element(find.byType(AdoptionsPage)))
        .uri;
    expect(uri.queryParameters['filtro'], 'concluse');
  });

  testWidgets('Home da fare oggi: tap cane apre la scheda', (tester) async {
    await pumpLogged(
      tester,
      health: InMemoryHealthRepository([
        testHealth(
          id: 'h-scad',
          dogId: 'fenice',
          prossimaScadenza: DateTime.utc(2026, 8, 1),
        ),
      ]),
    );
    await tester.tap(find.byKey(HomePage.todoCardKey));
    await tester.pumpAndSettle();
    expect(find.byType(DogDetailPage), findsOneWidget);
  });

  testWidgets('Home da fare oggi: tap appuntamento apre il foglio', (
    tester,
  ) async {
    await pumpLogged(
      tester,
      appointments: InMemoryAppointmentRepository([
        testAppointment(
          id: 'ap-oggi',
          dogId: 'fenice',
          inizio: DateTime(2026, 9, 8, 10, 30),
        ),
      ]),
    );
    await tester.tap(find.byKey(HomePage.todoCardKey));
    await tester.pumpAndSettle();
    expect(find.byType(AddAppointmentSheet), findsOneWidget);
    expect(find.text('Modifica appuntamento'), findsOneWidget);
  });

  testWidgets('Home da fare oggi: tap richiesta apre il dettaglio', (
    tester,
  ) async {
    await pumpLogged(
      tester,
      adoptions: InMemoryAdoptionRepository([
        testAdoption(
          id: 'ad-ferma',
          dogId: 'fenice',
          dataRichiesta: DateTime.utc(2026, 8, 1),
        ),
      ]),
    );
    await tester.tap(find.byKey(HomePage.todoCardKey));
    await tester.pumpAndSettle();
    expect(find.byType(AdoptionDetailPage), findsOneWidget);
  });

  testWidgets('Tab Salute: tap scadenza apre il trattamento in modifica', (
    tester,
  ) async {
    await pumpLogged(
      tester,
      location: AppRoutes.dog('fenice'),
      health: InMemoryHealthRepository([
        testHealth(
          id: 'h-scad',
          dogId: 'fenice',
          descrizione: 'Richiamo test',
          prossimaScadenza: DateTime.utc(2026, 10, 1),
        ),
      ]),
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(DogDetailPage.tabBarKey),
        matching: find.text('Salute'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Richiamo test'));
    await tester.pumpAndSettle();
    expect(find.byType(AddTreatmentSheet), findsOneWidget);
    expect(find.text('Modifica trattamento'), findsOneWidget);
  });

  testWidgets('Chiama apre tel: e Email apre mailto:', (tester) async {
    final links = FakeAppLinkOpener();
    await pumpLogged(
      tester,
      location: AppRoutes.richiesta('ad1'),
      links: links,
      adoptions: InMemoryAdoptionRepository([
        testAdoption(id: 'ad1', dogId: 'fenice'),
      ]),
    );
    await tester.tap(find.byKey(AdoptionDetailPage.chiamaKey));
    await tester.pumpAndSettle();
    expect(links.opened, isNotEmpty);
    expect(links.opened.last.scheme, 'tel');
    expect(links.opened.last.path, '3331234567');

    await tester.tap(find.byKey(AdoptionDetailPage.emailKey));
    await tester.pumpAndSettle();
    expect(links.opened.last.scheme, 'mailto');
    expect(links.opened.last.path, 'luca@example.it');
    expect(
      links.opened.last.queryParameters['subject'],
      contains('Adozione di'),
    );
  });

  testWidgets('Galleria Usa per annuncio imposta copertina e condivide', (
    tester,
  ) async {
    final dogs = InMemoryDogRepository(testListDogs());
    final photos = InMemoryPhotoRepository(
      photos: [
        Photo(
          id: 'p-cover',
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
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    await pumpApp(
      tester,
      auth: auth,
      initialLocation: AppRoutes.dogFoto('fenice'),
      size: const Size(360, 1100),
      dogs: dogs,
      photos: photos,
      dogListNow: now,
    );
    await tester.tap(find.byKey(DogGalleryPage.useForAdKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      find.textContaining('disponibile negli step successivi'),
      findsNothing,
    );
  });

  testWidgets('Login Password dimenticata invia il reset con conferma', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await pumpApp(tester, auth: auth, size: const Size(360, 900));
    await tester.enterText(
      find.byType(TextField).first,
      'giovanna@amiciperlacoda.it',
    );
    await tester.tap(find.byKey(LoginPage.forgotPasswordKey));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Inviare l\'email di reimpostazione'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(ConfirmActionKeys.confirm));
    await tester.pumpAndSettle();
    expect(auth.lastPasswordResetEmail, 'giovanna@amiciperlacoda.it');
    expect(find.text('Email di reimpostazione inviata.'), findsOneWidget);
  });

  testWidgets('Login non mostra Resta collegato', (tester) async {
    await pumpApp(tester, size: const Size(360, 900));
    expect(find.text('Resta collegato'), findsNothing);
    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('screenshot FAB, ⋮, filtri e tab Altro', (tester) async {
    await pumpLogged(tester, size: const Size(360, 800));
    await openFab(tester);
    await _saveShot(tester, 'fab_aperto.png');

    await tester.tap(find.byKey(NewItemSheetKeys.nuovoCane));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Indietro'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Animali'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Fenice').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Altre azioni'));
    await tester.pumpAndSettle();
    await _saveShot(tester, 'scheda_menu.png');

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(DogDetailPage.tabBarKey),
        matching: find.text('Altro'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(DogAltroTab.boxKey));
    await tester.pumpAndSettle();
    await _saveShot(tester, 'tab_altro.png');

    await tester.tap(find.byTooltip('Indietro'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DogsPage.filtriOrdinaKey));
    await tester.pumpAndSettle();
    await _saveShot(tester, 'filtri_foglio.png');
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
