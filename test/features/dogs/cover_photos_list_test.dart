import 'dart:io';

import 'package:amici_per_la_coda/data/models/dog.dart';
import 'package:amici_per_la_coda/data/models/photo.dart';
import 'package:amici_per_la_coda/features/dogs/dog_gallery_page.dart';
import 'package:amici_per_la_coda/features/dogs/dogs_page.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_dog_repository.dart';
import '../../helpers/fake_photo_repository.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_image.dart';

Photo _photo({
  required String id,
  required String dogId,
  required bool isCover,
}) {
  return Photo(
    id: id,
    dogId: dogId,
    isCover: isCover,
    w: 32,
    h: 32,
    mime: 'image/png',
    thumb: tinyPngBytes(),
    bytesFull: tinyPngBytes().lengthInBytes,
    createdAt: DateTime.utc(2026, 9, 12),
    createdBy: 'test',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 9, 12);

  test('la lista e la home non importano photosByDogProvider', () {
    const files = [
      'lib/features/dogs/dog_list_tile.dart',
      'lib/features/dashboard/home_page.dart',
      'lib/features/dogs/dog_detail_page.dart',
      'lib/features/adoptions/new_adoption_page.dart',
      'lib/features/dogs/dog_altro_tab.dart',
    ];
    for (final path in files) {
      final source = File(path).readAsStringSync();
      expect(
        source.contains('photosByDogProvider'),
        isFalse,
        reason: path,
      );
    }
    final gallery = File(
      'lib/features/dogs/dog_gallery_page.dart',
    ).readAsStringSync();
    expect(gallery.contains('photosByDogProvider'), isTrue);
  });

  test('upload e delete aggiornano fotoCount sul cane', () async {
    final dogs = InMemoryDogRepository([testDog(id: 'fenice')]);
    final photos = InMemoryPhotoRepository(dogs: dogs);
    await photos.upload('fenice', tinyPngBytes(), createdBy: 'test');
    expect((await dogs.getById('fenice'))!.fotoCount, 1);
    final list = await photos.watchByDog('fenice').first;
    expect(list, hasLength(1));
    await photos.delete(list.single.id);
    expect((await dogs.getById('fenice'))!.fotoCount, 0);
    expect((await dogs.getById('fenice'))!.fotoCopertinaId, isNull);
  });

  testWidgets(
    'lista cani: 1 listener copertine, 0 listener foto-per-cane',
    (tester) async {
      final dogsList = <Dog>[
        for (var i = 0; i < 30; i++)
          testDog(id: 'd$i', nome: 'Cane$i', fotoCount: 2),
      ];
      final dogs = InMemoryDogRepository(dogsList);
      final photos = InMemoryPhotoRepository(
        dogs: dogs,
        photos: [
          for (var i = 0; i < 30; i++) ...[
            _photo(id: 'c$i', dogId: 'd$i', isCover: true),
            _photo(id: 'e$i', dogId: 'd$i', isCover: false),
          ],
        ],
      );
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
        dogs: dogs,
        photos: photos,
        dogListNow: now,
      );

      expect(find.byType(DogsPage), findsOneWidget);
      expect(photos.watchCoversCalls, 1);
      expect(photos.watchByDogCalls, 0);

      final list = find.byKey(DogsPage.listKey);
      await tester.drag(list, const Offset(0, -2400));
      await tester.pumpAndSettle();
      expect(photos.watchCoversCalls, 1);
      expect(photos.watchByDogCalls, 0);
    },
  );

  testWidgets('la galleria ascolta tutte le foto del cane', (tester) async {
    final dogs = InMemoryDogRepository([
      testDog(id: 'fenice', nome: 'Fenice', fotoCount: 2),
    ]);
    final photos = InMemoryPhotoRepository(
      dogs: dogs,
      photos: [
        _photo(id: 'c1', dogId: 'fenice', isCover: true),
        _photo(id: 'e1', dogId: 'fenice', isCover: false),
      ],
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

    expect(find.byType(DogGalleryPage), findsOneWidget);
    expect(photos.watchByDogCalls, 1);
    expect(find.byKey(DogGalleryPage.heroKey), findsOneWidget);
    expect(find.byKey(DogGalleryPage.deleteKey('c1')), findsOneWidget);
    expect(find.byKey(DogGalleryPage.deleteKey('e1')), findsOneWidget);
  });
}
