import 'package:amici_per_la_coda/core/web_surface.dart';
import 'package:amici_per_la_coda/features/settings/altro_page.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  test('showAndroidOnlyTools nasconde le voci APK sul web', () {
    expect(showAndroidOnlyTools(isWeb: true), isFalse);
  });

  testWidgets(
    'Altro in modalità web non mostra Condividi app né Aggiornamenti',
    (tester) async {
      final auth = FakeAuthRepository();
      await auth.signIn(
        email: 'giovanna@amiciperlacoda.it',
        password: 'corretta',
      );
      await pumpApp(
        tester,
        auth: auth,
        initialLocation: AppRoutes.altro,
        size: const Size(360, 900),
        webSurfaceIsWeb: true,
      );
      expect(find.byKey(AltroPage.condividiAppKey), findsNothing);
      expect(find.byKey(AltroPage.aggiornamentiKey), findsNothing);
      expect(find.byKey(AltroPage.esciKey), findsOneWidget);
    },
  );
}
