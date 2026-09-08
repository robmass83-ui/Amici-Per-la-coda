import 'package:amici_per_la_coda/features/auth/login_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

void main() {
  testWidgets('l\'app parte senza eccezioni e mostra il login', (tester) async {
    await pumpApp(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Accedi'), findsOneWidget);
  });
}
