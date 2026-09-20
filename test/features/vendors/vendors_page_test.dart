import 'package:amici_per_la_coda/core/firestore_codec.dart';
import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/data/models/vendor.dart';
import 'package:amici_per_la_coda/features/vendors/vendor_detail_page.dart';
import 'package:amici_per_la_coda/features/vendors/vendor_form_page.dart';
import 'package:amici_per_la_coda/features/vendors/vendors_page.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_vendor_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tap su vendor salvato apre la scheda con telefono', (tester) async {
    final vendors = InMemoryVendorRepository([
      Vendor(
        id: 'v1',
        nome: 'Datena Anna Maria',
        tipo: VendorTipo.veterinario,
        telefono: '333111',
        email: '',
        indirizzo: 'Via Roma',
        convenzionato: false,
        note: '',
        audit: Audit.seed(DateTime.utc(2026, 1, 1)),
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
      initialLocation: AppRoutes.fornitori,
      vendors: vendors,
    );
    await tester.tap(find.text('Datena Anna Maria'));
    await tester.pumpAndSettle();
    expect(find.byType(VendorDetailPage), findsOneWidget);
    expect(find.text('333111'), findsOneWidget);
    expect(find.text('Via Roma'), findsOneWidget);
  });

  testWidgets('+ crea un veterinario e torna in elenco', (tester) async {
    final vendors = InMemoryVendorRepository();
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    await pumpApp(
      tester,
      auth: auth,
      initialLocation: AppRoutes.fornitori,
      vendors: vendors,
    );
    await tester.tap(find.byKey(VendorsPage.addKey));
    await tester.pumpAndSettle();
    expect(find.byType(VendorFormPage), findsOneWidget);
    await tester.enterText(find.byKey(VendorFormPage.nomeKey), 'Nuova Clinica');
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();
    expect(find.byType(VendorsPage), findsOneWidget);
    expect(find.text('Nuova Clinica'), findsOneWidget);
    expect(vendors.items, hasLength(1));
  });
}
