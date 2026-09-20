import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/features/dogs/dog_detail_page.dart';
import 'package:amici_per_la_coda/features/dogs/dog_labels.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_dog_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  test('dogIngressoLabel aggiunge (stimata) solo se il flag è true', () {
    final certa = testDog(nome: 'Orso');
    final stimata = certa.copyWith(dataIngressoStimata: true);
    expect(dogIngressoLabel(certa), isNot(contains('stimata')));
    expect(dogIngressoLabel(stimata), contains('(stimata)'));
  });

  test('etichette anagrafe extra restano trattino se il documento non parla', () {
    expect(tipoPeloLabel(null), '—');
    expect(purezzaLabel(null), '—');
    expect(tipoPeloLabel(TipoPelo.corto), 'Corto');
    expect(purezzaLabel(Purezza.inPurezza), 'In purezza');
    expect(yesNo(null), '—');
    expect(yesNo(false), 'No');
  });

  testWidgets('la scheda mostra la data di ingresso stimata', (tester) async {
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    final dog = testDog(id: 'orso', nome: 'Orso').copyWith(
      dataIngressoStimata: true,
      veterinarioApplicatore: 'Tisci Tommaso',
      ultimaUbicazione: 'C/DA PANTALOIANO',
      tipoPelo: TipoPelo.medio,
      purezza: Purezza.meticcio,
    );
    await pumpApp(
      tester,
      auth: auth,
      initialLocation: AppRoutes.dog('orso'),
      size: const Size(360, 1100),
      dogs: InMemoryDogRepository([dog]),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DogDetailPage), findsOneWidget);
    expect(find.textContaining('(stimata)'), findsWidgets);
  });
}
