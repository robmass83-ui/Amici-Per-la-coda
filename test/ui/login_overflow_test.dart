import 'package:amici_per_la_coda/features/auth/login_page.dart';
import 'package:amici_per_la_coda/ui/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  const widths = [320.0, 360.0, 411.0, 430.0];

  for (final width in widths) {
    testWidgets('login a ${width.toInt()} dp senza overflow', (tester) async {
      await pumpApp(tester, size: Size(width, 900));

      expect(tester.takeException(), isNull);
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(AppLogo), findsOneWidget);

      final scrollView = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(scrollView.scrollDirection, Axis.vertical);
    });
  }
}
