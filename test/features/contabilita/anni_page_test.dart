import 'dart:typed_data';

import 'package:amici_per_la_coda/core/firestore_codec.dart';
import 'package:amici_per_la_coda/core/format_it.dart';
import 'package:amici_per_la_coda/data/models/documento_contabile.dart';
import 'package:amici_per_la_coda/features/contabilita/anni_page.dart';
import 'package:amici_per_la_coda/features/contabilita/contabilita_logic.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_contabilita_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  Future<void> pumpContabilita(
    WidgetTester tester,
    InMemoryContabilitaRepository repo,
  ) async {
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    await pumpApp(
      tester,
      auth: auth,
      contabilita: repo,
      initialLocation: AppRoutes.contabilita,
      size: const Size(360, 900),
    );
  }

  testWidgets('crea l anno in corso e mostra la riga', (tester) async {
    final repo = InMemoryContabilitaRepository();

    await pumpContabilita(tester, repo);

    expect(find.text('${DateTime.now().year}'), findsWidgets);
    expect(find.byKey(AnniContabiliPage.aggiungiKey), findsOneWidget);
    expect(find.byKey(AnniContabiliPage.archivioKey), findsOneWidget);
  });

  testWidgets('non genera overflow alle larghezze supportate', (tester) async {
    for (final width in [320.0, 360.0, 411.0, 430.0]) {
      final auth = FakeAuthRepository();
      await auth.signIn(
        email: 'giovanna@amiciperlacoda.it',
        password: 'corretta',
      );

      await pumpApp(
        tester,
        auth: auth,
        contabilita: InMemoryContabilitaRepository(),
        initialLocation: AppRoutes.contabilita,
        size: Size(width, 640),
      );

      expect(tester.takeException(), isNull, reason: 'larghezza $width');
    }
  });

  testWidgets('mostra importi e anni dal piu recente', (tester) async {
    final repo = InMemoryContabilitaRepository();
    await repo.createAnno(
      anno: 2020,
      uid: 'uid-1',
      now: DateTime.utc(2020, 1, 1),
    );
    await repo.createAnno(
      anno: 2024,
      uid: 'uid-1',
      now: DateTime.utc(2024, 1, 1),
    );
    await repo.saveNuovo(
      DocumentoContabile(
        id: 'documento-2024',
        anno: 2024,
        nome: 'Fattura',
        data: DateTime.utc(2024, 1, 2),
        tipologia: TipologiaContabile.fattura,
        descrizione: '',
        importo: 12.5,
        mime: 'application/pdf',
        nomeFile: 'fattura.pdf',
        dimensione: 1,
        chunkCount: 1,
        generation: 1,
        audit: Audit.seed(DateTime.utc(2024, 1, 2), by: 'uid-1'),
      ),
      Uint8List.fromList([1]),
    );

    await pumpContabilita(tester, repo);

    expect(find.text(formatEuro(12.5)), findsOneWidget);
    final riga2020 = find.ancestor(
      of: find.text('2020'),
      matching: find.byType(InkWell),
    );
    expect(
      find.descendant(of: riga2020, matching: find.text(formatEuro(0))),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.text('2024')).dy,
      lessThan(tester.getTopLeft(find.text('2020')).dy),
    );
  });

  testWidgets('aggiungere un anno doppio mostra il messaggio', (tester) async {
    final repo = InMemoryContabilitaRepository();
    await repo.createAnno(
      anno: 2024,
      uid: 'uid-1',
      now: DateTime.utc(2024, 1, 1),
    );
    await pumpContabilita(tester, repo);

    await tester.tap(find.byKey(AnniContabiliPage.aggiungiKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '2024');
    await tester.tap(find.text('Crea'));
    await tester.pumpAndSettle();

    expect(find.text('Il 2024 è già presente.'), findsOneWidget);
  });

  testWidgets('sopra 400 MB compare l avviso', (tester) async {
    final repo = InMemoryContabilitaRepository();
    await repo.createAnno(
      anno: 2026,
      uid: 'uid-1',
      now: DateTime.utc(2026, 1, 1),
    );
    await repo.saveNuovo(documentoGrande(), Uint8List.fromList([1]));

    await pumpContabilita(tester, repo);

    expect(find.byKey(AnniContabiliPage.avvisoKey), findsOneWidget);
    expect(find.text(contabilitaAvviso400), findsOneWidget);
    expect(find.byKey(AnniContabiliPage.archivioKey), findsOneWidget);
  });
}

DocumentoContabile documentoGrande() {
  return DocumentoContabile(
    id: 'grande',
    anno: 2026,
    nome: 'Archivio',
    data: DateTime.utc(2026, 1, 2),
    tipologia: TipologiaContabile.fattura,
    descrizione: '',
    importo: null,
    mime: 'application/pdf',
    nomeFile: 'a.pdf',
    dimensione: 400 * 1024 * 1024 + 1,
    chunkCount: 1,
    generation: 1,
    audit: Audit.seed(DateTime.utc(2026, 1, 2), by: 'uid-1'),
  );
}
