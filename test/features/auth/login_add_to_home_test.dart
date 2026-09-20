import 'package:amici_per_la_coda/features/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpLogin(
  WidgetTester tester, {
  required bool isWeb,
  required bool standalone,
}) {
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: LoginPage(
          isWebOverride: isWeb,
          standaloneOverride: standalone,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('hint Home visibile solo web non standalone', (tester) async {
    await _pumpLogin(tester, isWeb: true, standalone: false);
    expect(find.byKey(LoginPage.addToHomeHintKey), findsOneWidget);
    expect(find.textContaining('Aggiungi a Home'), findsOneWidget);
  });

  testWidgets('hint assente se già sulla Home', (tester) async {
    await _pumpLogin(tester, isWeb: true, standalone: true);
    expect(find.byKey(LoginPage.addToHomeHintKey), findsNothing);
  });

  testWidgets('hint assente sull\'APK', (tester) async {
    await _pumpLogin(tester, isWeb: false, standalone: false);
    expect(find.byKey(LoginPage.addToHomeHintKey), findsNothing);
  });
}
