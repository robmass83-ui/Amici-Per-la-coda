import 'package:amici_per_la_coda/features/auth/login_page.dart';
import 'package:amici_per_la_coda/features/dashboard/home_page.dart';
import 'package:amici_per_la_coda/ui/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  const email = 'giovanna@amiciperlacoda.it';
  const password = 'corretta';

  testWidgets('mostra il logo ufficiale al posto della scritta', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.byType(AppLogo), findsOneWidget);
    expect(find.bySemanticsLabel('Amici per la Coda'), findsOneWidget);
    expect(find.byIcon(Icons.pets_rounded), findsNothing);
  });

  testWidgets('email e password hanno la stessa altezza', (tester) async {
    await pumpApp(tester);

    final email = tester.getSize(find.byType(TextField).at(0));
    final password = tester.getSize(find.byType(TextField).at(1));
    expect(password.height, email.height);
  });

  testWidgets('login con credenziali corrette entra', (tester) async {
    await pumpApp(tester);

    await tester.enterText(find.byType(TextField).at(0), email);
    await tester.enterText(find.byType(TextField).at(1), password);
    await tester.tap(find.text('Accedi'));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('Nessun cane ancora registrato'), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
  });

  testWidgets('credenziali sbagliate mostrano il messaggio in italiano', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.enterText(find.byType(TextField).at(0), email);
    await tester.enterText(find.byType(TextField).at(1), 'sbagliata');
    await tester.tap(find.text('Accedi'));
    await tester.pumpAndSettle();

    expect(find.text('Password non corretta.'), findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('logout riporta al login', (tester) async {
    final auth = FakeAuthRepository();
    await auth.signIn(email: email, password: password);
    await pumpApp(tester, auth: auth);

    expect(find.byType(HomePage), findsOneWidget);
    await tester.tap(find.text('Altro'));
    await tester.pumpAndSettle();
    expect(find.text('Esci'), findsOneWidget);
    await tester.tap(find.text('Esci'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Accedi'), findsOneWidget);
  });

  testWidgets('riaprendo l\'app con sessione persistente resta loggato', (
    tester,
  ) async {
    final session = InMemoryAuthSession();
    final first = FakeAuthRepository(session: session);
    await first.signIn(email: email, password: password);
    await pumpApp(tester, auth: first);
    expect(find.byType(HomePage), findsOneWidget);

    await pumpApp(tester, auth: FakeAuthRepository(session: session));
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
  });
}
