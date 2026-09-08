import 'package:amici_per_la_coda/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/pump_app.dart';

void main() {
  const widths = [320.0, 360.0, 411.0, 430.0];

  for (final width in widths) {
    testWidgets(
      'catalogo /debug/ui a ${width.toInt()} dp senza overflow',
      (tester) async {
        final auth = FakeAuthRepository();
        await auth.signIn(
          email: 'giovanna@amiciperlacoda.it',
          password: 'corretta',
        );

        await pumpApp(
          tester,
          auth: auth,
          initialLocation: AppRoutes.debugUi,
          size: Size(width, 900),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Catalogo UI'), findsOneWidget);

        final scrollView = tester.widget<SingleChildScrollView>(
          find.byType(SingleChildScrollView),
        );
        expect(scrollView.scrollDirection, Axis.vertical);

        final tabBar = tester.widget<TabBar>(find.byType(TabBar));
        expect(tabBar.isScrollable, isFalse);
        expect(tabBar.tabs, hasLength(7));

        final position = tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position;
        position.jumpTo(position.maxScrollExtent);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  }
}
