import 'package:amici_per_la_coda/data/models/photo.dart';
import 'package:amici_per_la_coda/data/photos/photo_codec.dart';
import 'package:amici_per_la_coda/data/photos/photo_limit.dart';
import 'package:amici_per_la_coda/features/dogs/dog_detail_page.dart';
import 'package:amici_per_la_coda/features/dogs/dog_gallery_page.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:amici_per_la_coda/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_dog_repository.dart';
import '../../helpers/fake_photo_picker.dart';
import '../../helpers/fake_photo_repository.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/system_nav.dart';
import '../../helpers/test_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const widths = [320.0, 360.0, 411.0, 430.0];
  final now = DateTime.utc(2026, 9, 8);

  Future<void> signInAndPump(
    WidgetTester tester, {
    required String location,
    required InMemoryDogRepository dogs,
    required InMemoryPhotoRepository photos,
    FakePhotoPicker? picker,
    Size size = const Size(360, 1100),
    bool settle = true,
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
      photos: photos,
      picker: picker,
      dogListNow: now,
      settle: settle,
    );
    if (!settle) {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pickAPhoto(WidgetTester tester) async {
    final open = find.byKey(DogGalleryPage.addKey);
    if (open.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        find.byKey(DogGalleryPage.uploadKey),
        AppDim.galleryHeroH,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.tap(find.byKey(DogGalleryPage.uploadKey));
    } else {
      await tester.tap(open);
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Fotocamera'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets(
    'caricando una foto e riaprendo la scheda la copertina è quella nuova',
    (tester) async {
      final dogs = InMemoryDogRepository(testListDogs());
      final photos = InMemoryPhotoRepository(dogs: dogs);
      await signInAndPump(
        tester,
        location: AppRoutes.dog('fenice'),
        dogs: dogs,
        photos: photos,
        picker: FakePhotoPicker(camera: tinyPngBytes()),
      );

      await tester.tap(find.byKey(DogDetailPage.coverKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(DogGalleryPage.heroKey), findsNothing);
      expect(find.byKey(DogGalleryPage.addKey), findsNothing);
      expect(find.text('Carica nuove foto'), findsOneWidget);
      expect(find.byKey(DogGalleryPage.uploadKey), findsOneWidget);
      expect(find.text('Imposta copertina'), findsNothing);

      await pickAPhoto(tester);

      expect(find.byKey(DogGalleryPage.limitKey), findsNothing);
      expect(find.byKey(DogGalleryPage.heroKey), findsOneWidget);
      expect(find.byKey(DogGalleryPage.addKey), findsOneWidget);
      expect(find.text('Imposta copertina'), findsOneWidget);
      expect((await dogs.getById('fenice'))?.fotoCopertinaId, isNotNull);
      expect((await dogs.getById('fenice'))?.fotoCount, 1);

      await tester.tap(find.byTooltip('Indietro'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(DogDetailPage), findsOneWidget);
      expect(find.byKey(DogDetailPage.coverImageKey), findsOneWidget);
    },
  );

  testWidgets(
    'galleria vuota: niente hero con iniziale, solo Carica nuove foto',
    (tester) async {
      final dogs = InMemoryDogRepository(testListDogs());
      final photos = InMemoryPhotoRepository(dogs: dogs);
      await signInAndPump(
        tester,
        location: AppRoutes.dogFoto('fenice'),
        dogs: dogs,
        photos: photos,
        settle: false,
      );

      expect(find.byType(DogGalleryPage), findsOneWidget);
      expect(find.byKey(DogGalleryPage.heroKey), findsNothing);
      expect(find.byKey(DogGalleryPage.addKey), findsNothing);
      expect(find.text('Carica nuove foto'), findsOneWidget);
      expect(find.byKey(DogGalleryPage.uploadKey), findsOneWidget);
      expect(
        find.text('Tocca per scattare o scegliere dalla galleria'),
        findsOneWidget,
      );
      expect(find.text('Imposta copertina'), findsNothing);
      expect(find.text('Usa per annuncio'), findsNothing);
      expect(find.text('F'), findsNothing);
    },
  );

  testWidgets('alla 21ª foto compare il messaggio di limite', (tester) async {
    final dogs = InMemoryDogRepository(testListDogs());
    final photos = InMemoryPhotoRepository(dogs: dogs);
    final full = tinyPngBytes();
    for (var i = 0; i < photoMaxPerDog; i++) {
      photos.seed(
        Photo(
          id: 'seed-p$i',
          dogId: 'fenice',
          isCover: i == 0,
          w: 1,
          h: 1,
          mime: 'image/png',
          thumb: tinyPngBytes(),
          bytesFull: full.lengthInBytes,
          createdAt: DateTime.utc(2026, 9, 8).subtract(Duration(minutes: i)),
          createdBy: 'uid-1',
        ),
        full,
      );
    }
    await signInAndPump(
      tester,
      location: AppRoutes.dogFoto('fenice'),
      dogs: dogs,
      photos: photos,
      picker: FakePhotoPicker(camera: tinyPngBytes()),
      settle: false,
    );

    await pickAPhoto(tester);

    expect(find.text(PhotoLimitReached.message), findsWidgets);
    expect(find.byKey(DogGalleryPage.limitKey), findsOneWidget);
  });

  testWidgets('la lista cani carica solo le thumb', (tester) async {
    final dogs = InMemoryDogRepository(testListDogs());
    final photos = InMemoryPhotoRepository(dogs: dogs);
    photos.seed(
      Photo(
        id: 'cover-fenice',
        dogId: 'fenice',
        isCover: true,
        w: 1,
        h: 1,
        mime: 'image/png',
        thumb: tinyPngBytes(),
        bytesFull: tinyPngBytes().lengthInBytes,
        createdAt: now,
        createdBy: 'uid-1',
      ),
      tinyPngBytes(),
    );

    await signInAndPump(
      tester,
      location: AppRoutes.animali,
      dogs: dogs,
      photos: photos,
    );

    expect(find.text('Fenice'), findsOneWidget);
    expect(photos.fullLoadCount, 0);
    expect(photos.watchByDogCalls, 0);
    expect(photos.watchCoversCalls, 1);
  });

  test('upload oltre 20 foto sul repository solleva PhotoLimitReached', () async {
    final dogs = InMemoryDogRepository(testListDogs());
    final photos = InMemoryPhotoRepository(dogs: dogs);
    final full = tinyPngBytes();
    for (var i = 0; i < photoMaxPerDog; i++) {
      photos.seed(
        Photo(
          id: 'p$i',
          dogId: 'fenice',
          isCover: i == 0,
          w: 1,
          h: 1,
          mime: 'image/png',
          thumb: tinyPngBytes(),
          bytesFull: full.lengthInBytes,
          createdAt: now.subtract(Duration(minutes: i)),
          createdBy: 'uid-1',
        ),
        full,
      );
    }
    await expectLater(
      photos.upload('fenice', tinyPngBytes(), createdBy: 'uid-1'),
      throwsA(isA<PhotoLimitReached>()),
    );
  });

  testWidgets(
    'il menu Aggiungi foto resta sopra la barra di sistema e si può toccare',
    (tester) async {
      simulateSystemNavBar(tester);
      final dogs = InMemoryDogRepository(testListDogs());
      final photos = InMemoryPhotoRepository(dogs: dogs);
      await signInAndPump(
        tester,
        location: AppRoutes.dogFoto('fenice'),
        dogs: dogs,
        photos: photos,
        picker: FakePhotoPicker(gallery: [tinyPngBytes()]),
        size: const Size(360, 640),
        settle: false,
      );

      await tester.scrollUntilVisible(
        find.byKey(DogGalleryPage.uploadKey),
        AppDim.galleryHeroH,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.tap(find.byKey(DogGalleryPage.uploadKey));
      await tester.pumpAndSettle();

      expect(find.text('Aggiungi foto'), findsOneWidget);
      expectAboveSystemNav(tester, find.byKey(DogGalleryPage.galleryPickKey));
      await tester.tap(find.byKey(DogGalleryPage.galleryPickKey));
      await tester.pumpAndSettle();
      expect(find.byKey(DogGalleryPage.galleryPickKey), findsNothing);
    },
  );

  for (final width in widths) {
    testWidgets('galleria senza overflow a ${width.toInt()} dp', (tester) async {
      final dogs = InMemoryDogRepository(testListDogs());
      final photos = InMemoryPhotoRepository(dogs: dogs);
      photos.seed(
        Photo(
          id: 'cover-fenice',
          dogId: 'fenice',
          isCover: true,
          w: 1,
          h: 1,
          mime: 'image/png',
          thumb: tinyPngBytes(),
          bytesFull: tinyPngBytes().lengthInBytes,
          createdAt: now,
          createdBy: 'uid-1',
        ),
        tinyPngBytes(),
      );
      await signInAndPump(
        tester,
        location: AppRoutes.dogFoto('fenice'),
        dogs: dogs,
        photos: photos,
        size: Size(width, 1100),
        settle: false,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(DogGalleryPage), findsOneWidget);
    });
  }
}
