import 'package:amici_per_la_coda/features/adoptions/adopter_detail_page.dart';
import 'package:amici_per_la_coda/features/adoptions/adopter_form_page.dart';
import 'package:amici_per_la_coda/features/adoptions/adopters_page.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_adopter_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tap apre il profilo con telefono e città', (tester) async {
    final adopters = InMemoryAdopterRepository([
      testAdopter(
        nome: 'Roberto',
        cognome: 'Masala',
        telefono: '320',
        citta: 'Quartu',
      ),
    ]);
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    await pumpApp(
      tester,
      auth: auth,
      initialLocation: AppRoutes.adottanti,
      adopters: adopters,
    );
    await tester.tap(find.text('Roberto Masala'));
    await tester.pumpAndSettle();
    expect(find.byType(AdopterDetailPage), findsOneWidget);
    expect(find.text('320'), findsOneWidget);
    expect(find.text('Quartu'), findsOneWidget);
    expect(find.textContaining('richiesta'), findsNothing);
  });

  testWidgets('+ da Altro crea solo adopters', (tester) async {
    final adopters = InMemoryAdopterRepository();
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    await pumpApp(
      tester,
      auth: auth,
      initialLocation: AppRoutes.adottanti,
      adopters: adopters,
    );
    await tester.tap(find.byKey(AdoptersPage.addKey));
    await tester.pumpAndSettle();
    expect(find.text('Nuova famiglia'), findsOneWidget);
    await tester.enterText(find.byKey(AdopterFormPage.nomeKey), 'Anna');
    await tester.enterText(find.byKey(AdopterFormPage.cognomeKey), 'Bianchi');
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();
    expect(adopters.items, hasLength(1));
    expect(adopters.items.single.nome, 'Anna');
    expect(adopters.items.single.adozioniIds, isEmpty);
  });
}
