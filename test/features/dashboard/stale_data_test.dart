import 'package:amici_per_la_coda/data/models/photo.dart';
import 'package:amici_per_la_coda/features/dashboard/home_page.dart';
import 'package:amici_per_la_coda/features/dogs/dog_detail_page.dart';
import 'package:amici_per_la_coda/features/dogs/dog_gallery_page.dart';
import 'package:amici_per_la_coda/features/dogs/dogs_page.dart';
import 'package:amici_per_la_coda/features/shell/app_shell.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_dog_repository.dart';
import '../../helpers/fake_photo_repository.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'offline: lista, scheda e galleria restano consultabili con il banner',
    (tester) async {
      final dogs = InMemoryDogRepository([
        testDog(id: 'fenice', nome: 'Fenice', fotoCount: 1),
      ]);
      final photos = InMemoryPhotoRepository(
        dogs: dogs,
        photos: [
          Photo(
            id: 'c1',
            dogId: 'fenice',
            isCover: true,
            w: 32,
            h: 32,
            mime: 'image/png',
            thumb: tinyPngBytes(),
            bytesFull: tinyPngBytes().lengthInBytes,
            createdAt: DateTime.utc(2026, 9, 12),
            createdBy: 'test',
          ),
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
        dogs: dogs,
        photos: photos,
        offline: true,
        size: const Size(360, 1100),
      );

      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byKey(HomePage.offlineBannerKey), findsOneWidget);
      expect(find.text('Dati non aggiornati · sei offline'), findsOneWidget);

      await tester.tap(find.text('Animali'));
      await tester.pumpAndSettle();
      expect(find.byType(DogsPage), findsOneWidget);
      expect(find.text('Fenice'), findsWidgets);
      expect(find.byKey(HomePage.offlineBannerKey), findsOneWidget);

      await tester.tap(find.text('Fenice'));
      await tester.pumpAndSettle();
      expect(find.byType(DogDetailPage), findsOneWidget);
      expect(find.text('Fenice'), findsWidgets);
      expect(find.byKey(HomePage.offlineBannerKey), findsOneWidget);

      final context = tester.element(find.byType(AppShell));
      GoRouter.of(context).go(AppRoutes.dogFoto('fenice'));
      await tester.pumpAndSettle();
      expect(find.byType(DogGalleryPage), findsOneWidget);
      expect(find.byKey(HomePage.offlineBannerKey), findsOneWidget);
    },
  );

  testWidgets('dati dalla cache mostrano il banner anche in linea', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    await pumpApp(
      tester,
      auth: auth,
      dogs: InMemoryDogRepository([testDog()]),
      dataFromCache: true,
    );

    expect(find.byKey(HomePage.offlineBannerKey), findsOneWidget);
    expect(find.text('Dati non aggiornati'), findsOneWidget);
    expect(find.text('Dati non aggiornati · sei offline'), findsNothing);
  });
}
