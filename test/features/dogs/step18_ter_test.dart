import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:amici_per_la_coda/data/models/dog.dart';
import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/data/models/health_record.dart';
import 'package:amici_per_la_coda/features/dogs/dog_adozione_tab.dart';
import 'package:amici_per_la_coda/features/dogs/dog_detail_page.dart';
import 'package:amici_per_la_coda/features/dogs/export/adoption_card_widget.dart';
import 'package:amici_per_la_coda/features/dogs/export/adoption_pdf.dart';
import 'package:amici_per_la_coda/features/dogs/export/adoption_post_text.dart';
import 'package:amici_per_la_coda/features/dogs/export/adoption_profile.dart';
import 'package:amici_per_la_coda/features/dogs/export/jpeg_encode.dart';
import 'package:amici_per_la_coda/features/dogs/export/photo_prepare.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:amici_per_la_coda/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_dog_repository.dart';
import '../../helpers/fake_photo_repository.dart';
import '../../helpers/fake_settings_repository.dart';
import '../../helpers/fake_volunteer_repository.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_image.dart';
import '../../golden/golden_support.dart';

const _chip = '999999999999999';
const _box = 'BOX-SENTINELLA';
const _settore = 'SETTORE-SENTINELLA';
const _id = 'ID-INTERNO-SENTINELLA';
const _ref = 'REF-SENTINELLA';
const _nota = 'SENTINELLA-NOTA';
const _adottante = 'SENTINELLA-ADOTTANTE';
const _euro = '€ 999,00';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 9, 10);

  late AdoptionAssociation association;
  late Uint8List logoBytes;

  setUpAll(() async {
    final data = await rootBundle.load(logoAssetPath);
    logoBytes = data.buffer.asUint8List();
    association = AdoptionAssociation.fromSettings(
      testAssociationSettings(),
      assetLogo: logoBytes,
    );
    final roboto = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Roboto-Bold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Roboto-Italic.ttf'));
    await roboto.load();
  });

  Dog completeDog() {
    return testDog(
      id: _id,
      nome: 'Fenice',
      sesso: DogSex.F,
      dataNascita: DateTime.utc(2025, 3, 10),
      microchip: _chip,
      settore: _settore,
      box: _box,
      provenienza: 'Corleto Perticara (PZ)',
      slogan: 'Dolce, forte, speciale.',
      descrizione:
          'Fenice è una cagnolina meravigliosa, dolce, socievole e piena di vita.',
      pesoKg: 22,
      sterilizzato: true,
      adottabile: true,
      carattere: const ['Dolce', 'Socievole', 'Equilibrata'],
      conPersone: ConPersone.moltoSocievole,
      conCani: ConCani.si,
      conGatti: ConGatti.si,
      conBambini: ConBambini.si,
      noteCarattere: 'Adatta a famiglia, ama le coccole.',
    ).copyWith(
      referenteId: _ref,
      dataSterilizzazione: DateTime.utc(2025, 3, 15),
      ultimaUbicazione: 'VIA-PRIVATA-SENTINELLA',
      veterinarioApplicatore: 'VET-PRIVATO-SENTINELLA',
    );
  }

  List<HealthRecord> vaccinesOk() {
    return [
      testHealth(
        id: 'v1',
        dogId: _id,
        tipo: HealthTipo.vaccino,
        data: DateTime.utc(2026, 2, 2),
        prossimaScadenza: DateTime.utc(2027, 2, 2),
        descrizione: 'Richiamo',
      ),
      testHealth(
        id: 'p1',
        dogId: _id,
        tipo: HealthTipo.antiparassitario,
        data: DateTime.utc(2026, 8, 20),
        descrizione: 'NexGard',
      ),
      testHealth(
        id: 'l1',
        dogId: _id,
        tipo: HealthTipo.esame,
        data: DateTime.utc(2026, 1, 10),
        descrizione: 'Leishmania negativo',
      ),
    ];
  }

  test(
    '1. fromDog non serializza microchip, box, settore, id, referente',
    () {
      final profile = AdoptionProfile.fromDog(
        completeDog(),
        vaccinesOk(),
        [testWeight(dogId: _id, kg: 22)],
        const [],
        association,
        now: now,
      );
      final json = jsonEncode(profile.toJson());
      for (final key in [
        '"microchip"',
        '"box"',
        '"settore"',
        '"id"',
        '"referente"',
        '"referenteId"',
        '"ultimaUbicazione"',
        '"veterinarioApplicatore"',
        '"tipoPelo"',
        '"dataApplicazioneChip"',
        '"intestatario"',
        '"codiceFiscale"',
        '"detentore"',
      ]) {
        expect(json.contains(key), isFalse, reason: key);
      }
      for (final value in [_chip, _box, _settore, _id, _ref, 'VIA-PRIVATA-SENTINELLA', 'VET-PRIVATO-SENTINELLA']) {
        expect(json.contains(value), isFalse, reason: value);
      }
      expect(profile.nome, 'Fenice');
      expect(profile.provenienza, 'Corleto Perticara');
    },
  );

  test('2. il PDF non contiene dati interni sentinella', () async {
    final photo = await solidPng(width: 80, height: 100);
    final profile = AdoptionProfile.fromDog(
      completeDog(),
      vaccinesOk(),
      const [],
      [photo, photo, photo],
      association,
      now: now,
    );
    final pdf = await buildAdoptionPdf(profile);
    final hay = pdfHaystack(pdf);
    expect(hay.contains(_chip), isFalse);
    expect(hay.contains(_box), isFalse);
    expect(hay.contains(_settore), isFalse);
    expect(hay.contains(_nota), isFalse);
    expect(hay.contains(_adottante), isFalse);
    expect(hay.contains(_euro), isFalse);
    expect(hay.contains('999,00'), isFalse);
    expect(latin1.decode(pdf.take(4).toList()), '%PDF');
  });

  test('3. 1 pagina con descrizione breve; la storia lunga resta in pagina 1', () async {
    final small = await solidPng(width: 40, height: 30);
    final fonts = await AdoptionPdfFonts.load();
    final brief = AdoptionProfile.fromDog(
      completeDog(),
      vaccinesOk(),
      const [],
      [small, small, small],
      association,
      now: now,
    );
    final one = await buildAdoptionPdf(brief, fonts: fonts);
    expect(pdfPageCount(one), 1);

    final longDog = completeDog().copyWith(
      descrizione: List.filled(40, 'Fenice corre in area sgambamento. ').join(),
    );
    final long = AdoptionProfile.fromDog(
      longDog,
      vaccinesOk(),
      const [],
      [small],
      association,
      now: now,
    );
    final longPdf = await buildAdoptionPdf(long, fonts: fonts);
    expect(pdfPageCount(longPdf), 1);
    expect(pdfContainsVisible(longPdf, 'Fenice corre in area sgambamento'), isTrue);

    final eight = AdoptionProfile.fromDog(
      completeDog(),
      vaccinesOk(),
      const [],
      List.filled(9, small),
      association,
      now: now,
    );
    final two = await buildAdoptionPdf(eight, fonts: fonts);
    expect(pdfPageCount(two), lessThanOrEqualTo(2));
    expect(pdfPageCount(two), isNot(3));
  });

  test('4. PDF sotto 2 MB con 8 foto da 4 MB', () async {
    final seed = encodeJpeg(
      Uint8List.fromList(List<int>.filled(64 * 64 * 4, 180)),
      width: 64,
      height: 64,
      quality: 80,
    );
    final fat = Uint8List(4 * 1024 * 1024);
    fat.setRange(0, seed.length, seed);
    final prepared = <Uint8List>[];
    for (var i = 0; i < 8; i++) {
      prepared.add(await preparePhotoForPdf(fat));
    }
    final profile = AdoptionProfile.fromDog(
      completeDog(),
      vaccinesOk(),
      const [],
      prepared,
      association,
      now: now,
    );
    final pdf = await buildAdoptionPdf(profile);
    expect(pdf.length, lessThan(2 * 1024 * 1024));
  });

  testWidgets('5. la card è 1080×1350 JPEG sotto 600 KB', (tester) async {
    final jpeg = await _renderCard(
      tester,
      AdoptionProfile.fromDog(
        completeDog(),
        vaccinesOk(),
        const [],
        const [],
        association,
        now: now,
      ),
    );
    expect(jpeg[0], 0xFF);
    expect(jpeg[1], 0xD8);
    expect(jpeg.length, lessThan(600 * 1024));
    final size = await tester.runAsync(
      () async {
        final codec = await ui.instantiateImageCodec(jpeg);
        final frame = await codec.getNextFrame();
        final w = frame.image.width;
        final h = frame.image.height;
        frame.image.dispose();
        return (w, h);
      },
    );
    expect(size!.$1, 1080);
    expect(size.$2, 1350);
  });

  testWidgets('6. Ok cani solo se conCani == si', (tester) async {
    tester.view.physicalSize = const Size(1080, 1350);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final si = AdoptionProfile.fromDog(
      completeDog(),
      const [],
      const [],
      const [],
      association,
      now: now,
    );
    await tester.pumpWidget(_cardApp(si));
    expect(find.byKey(AdoptionCardWidget.okCaniKey), findsOneWidget);

    final no = AdoptionProfile.fromDog(
      completeDog().copyWith(conCani: ConCani.no),
      const [],
      const [],
      const [],
      association,
      now: now,
    );
    await tester.pumpWidget(_cardApp(no));
    expect(find.byKey(AdoptionCardWidget.okCaniKey), findsNothing);
    expect(find.text('Ok cani'), findsNothing);
  });

  testWidgets('7. senza foto PDF e card usano il segnaposto', (tester) async {
    tester.view.physicalSize = const Size(1080, 1350);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final profile = AdoptionProfile.fromDog(
      completeDog(),
      vaccinesOk(),
      const [],
      const [],
      association,
      now: now,
    );
    expect(profile.fotoCopertina, isNull);
    final pdf = await buildAdoptionPdf(profile);
    expect(pdf.length, greaterThan(100));
    await tester.pumpWidget(_cardApp(profile));
    expect(find.text('F'), findsWidgets);
  });

  testWidgets('8. senza vaccini: non registrato nel PDF, — nella card', (
    tester,
  ) async {
    final profile = AdoptionProfile.fromDog(
      completeDog(),
      const [],
      const [],
      const [],
      association,
      now: now,
    );
    expect(profile.haVacciniRegistrati, isFalse);
    expect(profile.vaccinatoInRegola, isFalse);
    final pdf = await buildAdoptionPdf(profile);
    expect(pdfContainsVisible(pdf, 'non registrato'), isTrue);

    tester.view.physicalSize = const Size(1080, 1350);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_cardApp(profile));
    expect(find.text('—'), findsWidgets);
  });

  test('9. il testo del post ha nome, telefono e un hashtag', () {
    final profile = AdoptionProfile.fromDog(
      completeDog(),
      vaccinesOk(),
      const [],
      const [],
      association,
      now: now,
    );
    final text = testoPostAdozione(profile);
    expect(text.contains('Fenice'), isTrue);
    expect(text.contains(association.telefono), isTrue);
    expect(text.contains('#adozione'), isTrue);
  });

  testWidgets(
    '10. Condividi ha PDF e card per ogni ruolo; ⋮ senza export; elimina solo a chi scrive',
    (tester) async {
      Future<void> openShare({required VolunteerRuolo ruolo}) async {
        tester.view.reset();
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
          size: const Size(360, 1100),
          dogs: dogs,
          volunteers: InMemoryVolunteerRepository([
            testVolunteer(ruolo: ruolo),
          ]),
          photos: InMemoryPhotoRepository(dogs: dogs),
          dogListNow: now,
        );
        final ink = tester.widget<InkWell>(
          find.descendant(
            of: find.byTooltip('Condividi'),
            matching: find.byType(InkWell),
          ),
        );
        ink.onTap!.call();
        await tester.pumpAndSettle();
      }

      Future<void> openMore({required VolunteerRuolo ruolo}) async {
        tester.view.reset();
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
          size: const Size(360, 1100),
          dogs: dogs,
          volunteers: InMemoryVolunteerRepository([
            testVolunteer(ruolo: ruolo),
          ]),
          photos: InMemoryPhotoRepository(dogs: dogs),
          dogListNow: now,
        );
        final ink = tester.widget<InkWell>(
          find.descendant(
            of: find.byTooltip('Altre azioni'),
            matching: find.byType(InkWell),
          ),
        );
        ink.onTap!.call();
        await tester.pumpAndSettle();
      }

      for (final ruolo in VolunteerRuolo.values) {
        await openShare(ruolo: ruolo);
        expect(find.byKey(DogDetailPage.azioneEsportaPdfKey), findsOneWidget);
        expect(find.byKey(DogDetailPage.azioneCardSocialKey), findsOneWidget);
        expect(find.text('Copia link scheda pubblica'), findsNothing);
        expect(find.text('Esporta scheda PDF'), findsNothing);
        expect(find.byKey(DogDetailPage.azioneCondividiKey), findsNothing);
      }

      for (final ruolo in VolunteerRuolo.values) {
        await openMore(ruolo: ruolo);
        expect(find.byKey(DogDetailPage.azioneEsportaPdfKey), findsNothing);
        expect(find.byKey(DogDetailPage.azioneCardSocialKey), findsNothing);
        expect(find.text('Copia link scheda pubblica'), findsNothing);
        expect(find.text('Esporta scheda PDF'), findsNothing);
        if (ruolo == VolunteerRuolo.volontario) {
          expect(find.byKey(DogDetailPage.azioneEliminaKey), findsNothing);
          expect(find.text('Elimina definitivamente'), findsNothing);
        } else {
          expect(find.byKey(DogDetailPage.azioneEliminaKey), findsOneWidget);
        }
      }
    },
  );

  testWidgets('11. PDF ha il logo oltre alle foto; card ha il logo in alto a destra', (
    tester,
  ) async {
    final photo = (await tester.runAsync(
      () => solidPng(width: 60, height: 80),
    ))!;
    final profile = AdoptionProfile.fromDog(
      completeDog(),
      vaccinesOk(),
      const [],
      [photo],
      association,
      now: now,
    );
    final pdf = await buildAdoptionPdf(profile);
    final images = pdfImageCount(pdf);
    expect(images, greaterThan(1));

    tester.view.physicalSize = const Size(1080, 1350);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_cardApp(profile));
    final logo = tester.getRect(find.byKey(AdoptionCardWidget.logoKey));
    expect(logo.right, greaterThan(800));
    expect(logo.top, lessThan(80));
  });

  testWidgets('12. golden card 1080×1350', (tester) async {
    const fileName = 'adoption_card_1080.png';
    tester.view.physicalSize = const Size(1080, 1350);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final photo = await solidPng(width: 200, height: 260);
    await tester.pumpWidget(
      _cardApp(
        AdoptionProfile.fromDog(
          completeDog(),
          vaccinesOk(),
          const [],
          [photo],
          association,
          now: now,
        ),
      ),
    );
    await expectLater(
      find.byType(AdoptionCardWidget),
      matchesGoldenFile('../golden/goldens/$fileName'),
    );
  }, skip: skipUntilPng('adoption_card_1080.png'));

  testWidgets('tab Adozione ha le tre voci di export', (tester) async {
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
      dogListNow: now,
    );
    await tester.ensureVisible(find.text('Adozione'));
    await tester.tap(
      find.descendant(
        of: find.byKey(DogDetailPage.tabBarKey),
        matching: find.text('Adozione'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Condividi scheda'), findsNothing);
    expect(find.byKey(DogAdozioneTab.pdfKey), findsOneWidget);
    expect(find.byKey(DogAdozioneTab.cardKey), findsOneWidget);
    expect(find.byKey(DogAdozioneTab.copiaTestoKey), findsOneWidget);
  });

  testWidgets('scrive PDF e JPEG di prova (5 foto e senza foto)', (
    tester,
  ) async {
    final dir = Directory('tmp/step18-ter');
    dir.createSync(recursive: true);
    final photos = <Uint8List>[
      (await tester.runAsync(
        () => solidPng(width: 240, height: 320, color: const Color(0xFFC8AB7D)),
      ))!,
      (await tester.runAsync(
        () => solidPng(width: 240, height: 180, color: const Color(0xFF8FA07D)),
      ))!,
      (await tester.runAsync(
        () => solidPng(width: 240, height: 180, color: const Color(0xFFB9A68D)),
      ))!,
      (await tester.runAsync(
        () => solidPng(width: 240, height: 180, color: const Color(0xFF6E7A68)),
      ))!,
      (await tester.runAsync(
        () => solidPng(width: 240, height: 180, color: const Color(0xFF4E5A41)),
      ))!,
    ];
    final withPhotos = AdoptionProfile.fromDog(
      completeDog(),
      vaccinesOk(),
      [testWeight(dogId: _id, kg: 22)],
      photos,
      association,
      now: now,
    );
    final noPhotos = AdoptionProfile.fromDog(
      completeDog().copyWith(nome: 'Luna'),
      const [],
      const [],
      const [],
      association,
      now: now,
    );
    File('${dir.path}/Fenice-5foto.pdf').writeAsBytesSync(
      await buildAdoptionPdf(withPhotos),
    );
    File('${dir.path}/Luna-senza-foto.pdf').writeAsBytesSync(
      await buildAdoptionPdf(noPhotos),
    );
    File('${dir.path}/Fenice-5foto.jpg').writeAsBytesSync(
      await _renderCard(tester, withPhotos),
    );
    File('${dir.path}/Luna-senza-foto.jpg').writeAsBytesSync(
      await _renderCard(tester, noPhotos),
    );
    for (final name in [
      'Fenice-5foto.pdf',
      'Fenice-5foto.jpg',
      'Luna-senza-foto.pdf',
      'Luna-senza-foto.jpg',
    ]) {
      final file = File('${dir.path}/$name');
      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(500));
    }
  });

  test('12. 1 foto: 1 pagina, nessuna griglia', () async {
    final photo = await solidPng(width: 60, height: 80);
    final fonts = await AdoptionPdfFonts.load();
    final pdf = await buildAdoptionPdf(
      AdoptionProfile.fromDog(
        completeDog(),
        vaccinesOk(),
        const [],
        [photo],
        association,
        now: now,
      ),
      fonts: fonts,
    );
    expect(pdfPageCount(pdf), 1);
    expect(pdfContainsVisible(pdf, 'Le foto di'), isFalse);
    expect(pdfContainsVisible(pdf, 'pagina 1 di 1'), isTrue);
  });

  test('13. 5 foto e descrizione breve: 1 pagina, 4 foto sotto il testo', () async {
    final photo = await solidPng(width: 60, height: 80);
    final fonts = await AdoptionPdfFonts.load();
    final profile = AdoptionProfile.fromDog(
      completeDog(),
      vaccinesOk(),
      const [],
      List.filled(5, photo),
      association,
      now: now,
    );
    expect(profile.altreFoto, hasLength(4));
    final pdf = await buildAdoptionPdf(profile, fonts: fonts);
    expect(pdfPageCount(pdf), 1);
    expect(pdfContainsVisible(pdf, 'Le foto di Fenice'), isTrue);
    expect(pdfContainsVisible(pdf, 'pagina 1 di 1'), isTrue);
  });

  test('14. 20 foto: 3 pagine, 12 in pagina 2, storia solo in pagina 1', () async {
    final photo = await solidPng(width: 60, height: 80);
    final fonts = await AdoptionPdfFonts.load();
    final profile = AdoptionProfile.fromDog(
      completeDog(),
      vaccinesOk(),
      const [],
      List.filled(20, photo),
      association,
      now: now,
    );
    expect(profile.altreFoto, hasLength(19));
    final pdf = await buildAdoptionPdf(profile, fonts: fonts);
    expect(pdfPageCount(pdf), 3);
    expect(pdfContainsVisible(pdf, 'pagina 2 di 3'), isTrue);
    expect(pdfContainsVisible(pdf, 'pagina 3 di 3'), isTrue);
    expect(pdfContainsVisible(pdf, 'LE FOTO DI FENICE'), isTrue);
    final storiaHits = _visibleCount(pdf, 'LA SUA STORIA');
    expect(storiaHits, 1);
    final perPage = pdfPageImageCounts(pdf);
    expect(perPage, hasLength(3));
    expect(perPage[1], greaterThanOrEqualTo(12));
    expect(perPage[1], greaterThan(perPage[2]));
  });

  test('15. storia di 1500 caratteri e 20 foto: intera, max 3 pagine', () async {
    final photo = await solidPng(width: 60, height: 80);
    final fonts = await AdoptionPdfFonts.load();
    const chunk = 'Fenice corre libera nel bosco ogni mattina. ';
    final descrizione = (chunk * 40).substring(0, 1500);
    expect(descrizione.length, 1500);
    final profile = AdoptionProfile.fromDog(
      completeDog().copyWith(descrizione: descrizione),
      vaccinesOk(),
      const [],
      List.filled(20, photo),
      association,
      now: now,
    );
    final pdf = await buildAdoptionPdf(profile, fonts: fonts);
    expect(pdfPageCount(pdf), lessThanOrEqualTo(3));
    expect(pdfContainsVisible(pdf, chunk.trim()), isTrue);
    expect(pdfContainsVisible(pdf, descrizione.substring(descrizione.length - 40)), isTrue);
  });

  test('16. senza descrizione: testo generato, niente — né quattro non registrato', () async {
    final photo = await solidPng(width: 60, height: 80);
    final fonts = await AdoptionPdfFonts.load();
    final profile = AdoptionProfile.fromDog(
      completeDog().copyWith(
        descrizione: '',
        slogan: '',
        sterilizzato: false,
        dataSterilizzazione: null,
        razza: 'Meticcia',
      ),
      const [],
      const [],
      [photo],
      association,
      now: now,
    );
    expect(profile.descrizione, isEmpty);
    expect(profile.haDatoSanitario, isFalse);
    final generated = storiaGenerata(profile);
    expect(generated.contains('Fenice'), isTrue);
    expect(generated.contains('Meticcia'), isTrue);
    expect(generated.contains('Corleto Perticara'), isTrue);
    final pdf = await buildAdoptionPdf(profile, fonts: fonts);
    expect(pdfContainsVisible(pdf, 'Fenice'), isTrue);
    expect(pdfContainsVisible(pdf, 'Meticcia'), isTrue);
    expect(pdfContainsVisible(pdf, 'Corleto Perticara'), isTrue);
    expect(pdfContainsVisible(pdf, 'Dati sanitari non ancora registrati'), isTrue);
    expect(pdfContainsVisible(pdf, '—'), isFalse);
    expect(_visibleCount(pdf, 'non registrato'), 0);
  });

  test('17. il builder non usa Spacer né Expanded', () {
    final src = File('lib/features/dogs/export/adoption_pdf.dart').readAsStringSync();
    expect(src.contains('pw.Spacer'), isFalse);
    expect(src.contains('pw.Expanded'), isFalse);
  });

  test('18. 20 foto pesano meno di 2 MB', () async {
    final seed = encodeJpeg(
      Uint8List.fromList(List<int>.filled(64 * 64 * 4, 180)),
      width: 64,
      height: 64,
      quality: 80,
    );
    final fat = Uint8List(800 * 1024);
    fat.setRange(0, seed.length, seed);
    final prepared = await preparePhotosForPdf(List.filled(20, fat));
    final profile = AdoptionProfile.fromDog(
      completeDog(),
      vaccinesOk(),
      const [],
      prepared,
      association,
      now: now,
    );
    final pdf = await buildAdoptionPdf(profile);
    expect(pdf.length, lessThan(2 * 1024 * 1024));
  });

  test('scrive i quattro PDF di prova 18-ter.7', () async {
    final dir = Directory('tmp/step18-ter');
    dir.createSync(recursive: true);
    final fonts = await AdoptionPdfFonts.load();
    final p1 = await solidPng(
      width: 240,
      height: 320,
      color: const Color(0xFFC8AB7D),
    );
    final extras = <Uint8List>[
      await solidPng(width: 240, height: 180, color: const Color(0xFF8FA07D)),
      await solidPng(width: 240, height: 180, color: const Color(0xFFB9A68D)),
      await solidPng(width: 240, height: 180, color: const Color(0xFF6E7A68)),
      await solidPng(width: 240, height: 180, color: const Color(0xFF4E5A41)),
    ];
    Future<Uint8List> pdfOf({
      required int count,
      String descrizione = '',
      bool longStory = false,
    }) async {
      final photos = <Uint8List>[p1];
      for (var i = 1; i < count; i++) {
        photos.add(extras[(i - 1) % extras.length]);
      }
      var dog = completeDog();
      if (longStory) {
        dog = dog.copyWith(
          descrizione: ('Fenice aspetta una famiglia da tempo. ' * 50).substring(0, 1500),
        );
      } else {
        dog = dog.copyWith(
          descrizione: descrizione,
          sterilizzato: descrizione.isEmpty ? false : dog.sterilizzato,
          slogan: descrizione.isEmpty ? '' : dog.slogan,
        );
      }
      return buildAdoptionPdf(
        AdoptionProfile.fromDog(
          dog,
          descrizione.isEmpty && !longStory ? const [] : vaccinesOk(),
          const [],
          photos,
          association,
          now: now,
        ),
        fonts: fonts,
      );
    }

    File('${dir.path}/1foto-senza-descrizione.pdf').writeAsBytesSync(
      await pdfOf(count: 1, descrizione: ''),
    );
    File('${dir.path}/5foto.pdf').writeAsBytesSync(
      await pdfOf(
        count: 5,
        descrizione:
            'Fenice è una cagnolina meravigliosa, dolce, socievole e piena di vita.',
      ),
    );
    File('${dir.path}/12foto.pdf').writeAsBytesSync(
      await pdfOf(
        count: 12,
        descrizione: 'Fenice è una cagnolina meravigliosa.',
      ),
    );
    File('${dir.path}/20foto-storia-lunga.pdf').writeAsBytesSync(
      await pdfOf(count: 20, longStory: true),
    );
    for (final name in [
      '1foto-senza-descrizione.pdf',
      '5foto.pdf',
      '12foto.pdf',
      '20foto-storia-lunga.pdf',
    ]) {
      final file = File('${dir.path}/$name');
      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(500));
      expect(latin1.decode(file.readAsBytesSync().take(4).toList()), '%PDF');
    }
  });
}

Widget _cardApp(AdoptionProfile profile) {
  return MaterialApp(
    home: Material(
      child: Center(
        child: SizedBox(
          width: AppDim.exportCardW,
          height: AppDim.exportCardH,
          child: AdoptionCardWidget(profile: profile),
        ),
      ),
    ),
  );
}

Future<Uint8List> _renderCard(
  WidgetTester tester,
  AdoptionProfile profile,
) async {
  tester.view.physicalSize = const Size(1080, 1350);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_cardApp(profile));
  await tester.pump();
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 16)),
    );
    await tester.pump();
  }
  final captured = await captureImage(
    tester.element(find.byType(AdoptionCardWidget)),
  );
  final pngData = await tester.runAsync(
    () => captured.toByteData(format: ui.ImageByteFormat.png),
  );
  captured.dispose();
  final png = Uint8List.fromList(
    pngData!.buffer.asUint8List(
      pngData.offsetInBytes,
      pngData.lengthInBytes,
    ),
  );
  expect(png[0], 0x89);
  final decoded = await tester.runAsync(
    () async {
      final codec = await ui.instantiateImageCodec(png);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      try {
        return (
          image.width,
          image.height,
          await image.toByteData(format: ui.ImageByteFormat.rawRgba),
        );
      } finally {
        image.dispose();
      }
    },
  );
  final width = decoded!.$1;
  final height = decoded.$2;
  final data = decoded.$3;
  expect(width, 1080);
  expect(height, 1350);
  final pixels = data!.buffer.asUint8List(
    data.offsetInBytes,
    data.lengthInBytes,
  );
  return encodeJpeg(
    pixels,
    width: width,
    height: height,
    quality: 90,
  );
}

bool pdfContainsVisible(Uint8List pdf, String text) {
  final hay = pdfHaystack(pdf).toLowerCase();
  final needle = text.toLowerCase();
  if (hay.contains(needle)) {
    return true;
  }
  if (needle.length < 4) {
    return false;
  }
  final hex = needle.codeUnits
      .map((c) => c.toRadixString(16).padLeft(4, '0'))
      .join();
  return hay.contains(hex);
}

String pdfHaystack(Uint8List bytes) {
  final combined = BytesBuilder(copy: false);
  combined.add(bytes);
  final latin = latin1.decode(bytes, allowInvalid: true);
  var from = 0;
  while (true) {
    final filter = latin.indexOf('/FlateDecode', from);
    if (filter < 0) {
      break;
    }
    final start = latin.indexOf('stream', filter);
    if (start < 0) {
      break;
    }
    var dataStart = start + 6;
    if (dataStart < latin.length && latin.codeUnitAt(dataStart) == 13) {
      dataStart++;
    }
    if (dataStart < latin.length && latin.codeUnitAt(dataStart) == 10) {
      dataStart++;
    }
    final end = latin.indexOf('endstream', dataStart);
    if (end < 0) {
      break;
    }
    from = end + 9;
    final chunk = bytes.sublist(dataStart, end);
    try {
      combined.add(zlib.decode(chunk));
    } catch (_) {}
  }
  final all = combined.toBytes();
  final decoded = latin1.decode(all, allowInvalid: true);
  final hex = StringBuffer();
  for (var i = 0; i + 3 < all.length; i++) {
    if (all[i] == 0 && all[i + 2] == 0) {
      final c1 = all[i + 1];
      final c2 = all[i + 3];
      if (c1 >= 32 && c1 < 127) {
        hex.writeCharCode(c1);
      }
      if (c2 >= 32 && c2 < 127) {
        hex.writeCharCode(c2);
      }
    }
  }
  final shown = StringBuffer();
  for (final match in RegExp(r'\((?:\\.|[^\\)])*\)').allMatches(decoded)) {
    var token = match.group(0)!;
    token = token.substring(1, token.length - 1);
    token = token.replaceAll(r'\(', '(').replaceAll(r'\)', ')');
    shown.write(token);
    shown.write(' ');
  }
  return '$decoded\n$hex\n$shown';
}

int pdfPageCount(Uint8List bytes) {
  final raw = latin1.decode(bytes, allowInvalid: true);
  return RegExp(r'/Type\s*/Page(?![sA-Za-z])').allMatches(raw).length;
}

int pdfImageCount(Uint8List bytes) {
  final raw = latin1.decode(bytes, allowInvalid: true);
  return RegExp(r'/Subtype\s*/Image').allMatches(raw).length;
}

int _visibleCount(Uint8List pdf, String text) {
  final hay = pdfHaystack(pdf).toLowerCase();
  final needle = text.toLowerCase();
  var n = 0;
  var from = 0;
  while (true) {
    final at = hay.indexOf(needle, from);
    if (at < 0) {
      return n;
    }
    n++;
    from = at + needle.length;
  }
}

List<int> pdfPageImageCounts(Uint8List bytes) {
  final raw = latin1.decode(bytes, allowInvalid: true);
  final counts = <int>[];
  final pageStarts = RegExp(r'/Type\s*/Page(?![sA-Za-z])').allMatches(raw).toList();
  for (var i = 0; i < pageStarts.length; i++) {
    final start = pageStarts[i].start;
    final end = i + 1 < pageStarts.length ? pageStarts[i + 1].start : raw.length;
    final slice = raw.substring(start, end);
    final xobj = RegExp(r'/XObject\s*<<([^>]*)>>').firstMatch(slice);
    if (xobj == null) {
      counts.add(0);
      continue;
    }
    counts.add(RegExp(r'/\S+\s+\d+\s+0\s+R').allMatches(xobj.group(1)!).length);
  }
  return counts;
}
