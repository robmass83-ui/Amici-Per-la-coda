import 'dart:typed_data';

import 'package:amici_per_la_coda/core/firestore_codec.dart';
import 'package:amici_per_la_coda/data/models/documento_contabile.dart';
import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/features/contabilita/anno_page.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:amici_per_la_coda/ui/components/app_button.dart';
import 'package:amici_per_la_coda/ui/components/app_text_field.dart';
import 'package:amici_per_la_coda/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_contabilita_repository.dart';
import '../../helpers/fake_volunteer_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('ordina i documenti dal più recente', (tester) async {
    final repo = await _repoConDocumenti();

    await _pumpAnno(tester, contabilita: repo, size: const Size(360, 900));

    expect(
      tester.getTopLeft(find.text('Documento recente')).dy,
      lessThan(tester.getTopLeft(find.text('Documento vecchio')).dy),
    );
  });

  testWidgets('la ricerca filtra per nome e aggiorna il riepilogo', (
    tester,
  ) async {
    final repo = await _repoConDocumenti();

    await _pumpAnno(tester, contabilita: repo, size: const Size(360, 900));
    await tester.enterText(
      find.widgetWithText(TextField, 'Cerca per nome'),
      'recente',
    );
    await tester.pumpAndSettle();

    expect(find.text('Documento recente'), findsOneWidget);
    expect(find.text('Documento vecchio'), findsNothing);
    expect(find.textContaining('1 documento'), findsOneWidget);
  });

  testWidgets('export usa la lista non filtrata ed è disabilitato se vuota', (
    tester,
  ) async {
    final repo = await _repoConDocumenti();

    await _pumpAnno(tester, contabilita: repo, size: const Size(360, 900));
    var export = tester.widget<AppButton>(
      find.byKey(AnnoContabilePage.esportaKey),
    );
    expect(export.onPressed, isNotNull);

    await tester.enterText(
      find.widgetWithText(TextField, 'Cerca per nome'),
      'nessun risultato',
    );
    await tester.pumpAndSettle();
    export = tester.widget<AppButton>(find.byKey(AnnoContabilePage.esportaKey));
    expect(export.onPressed, isNotNull);

    await _pumpAnno(
      tester,
      contabilita: InMemoryContabilitaRepository(),
      size: const Size(360, 900),
    );
    export = tester.widget<AppButton>(find.byKey(AnnoContabilePage.esportaKey));
    expect(export.onPressed, isNull);
  });

  testWidgets('il volontario può aggiungere ma non esportare', (tester) async {
    final volunteers = InMemoryVolunteerRepository([
      testVolunteer(ruolo: VolunteerRuolo.volontario),
    ]);

    await _pumpAnno(
      tester,
      contabilita: InMemoryContabilitaRepository(),
      volunteers: volunteers,
      size: const Size(360, 900),
    );

    expect(find.byKey(AnnoContabilePage.esportaKey), findsNothing);
    expect(find.byKey(AnnoContabilePage.aggiungiKey), findsOneWidget);
  });

  testWidgets('a 320 dp non trabocca e la ricerca rispetta il contratto', (
    tester,
  ) async {
    final repo = await _repoConDocumenti();

    await _pumpAnno(tester, contabilita: repo, size: const Size(320, 900));

    expect(tester.takeException(), isNull);
    final search = tester.widget<AppTextField>(
      find.byKey(AnnoContabilePage.cercaKey),
    );
    expect(search.hint, 'Cerca per nome');
    expect(search.label, isNull);
    expect(search.fieldHeight, AppDim.searchH);
    expect(find.byKey(AnnoContabilePage.filtriKey), findsOneWidget);
  });
}

Future<void> _pumpAnno(
  WidgetTester tester, {
  required InMemoryContabilitaRepository contabilita,
  required Size size,
  InMemoryVolunteerRepository? volunteers,
}) async {
  final auth = FakeAuthRepository();
  await auth.signIn(email: 'giovanna@amiciperlacoda.it', password: 'corretta');
  await pumpApp(
    tester,
    auth: auth,
    contabilita: contabilita,
    volunteers: volunteers,
    initialLocation: AppRoutes.contabilitaAnno(2026),
    size: size,
  );
}

Future<InMemoryContabilitaRepository> _repoConDocumenti() async {
  final repo = InMemoryContabilitaRepository();
  await repo.createAnno(
    anno: 2026,
    uid: 'uid-1',
    now: DateTime.utc(2026, 1, 1),
  );
  await repo.saveNuovo(
    _documento(
      id: 'recente',
      nome: 'Documento recente',
      data: DateTime.utc(2026, 8, 20),
      importo: 20,
    ),
    Uint8List.fromList([1]),
  );
  await repo.saveNuovo(
    _documento(
      id: 'vecchio',
      nome: 'Documento vecchio',
      data: DateTime.utc(2026, 2, 10),
      importo: 10,
    ),
    Uint8List.fromList([2]),
  );
  return repo;
}

DocumentoContabile _documento({
  required String id,
  required String nome,
  required DateTime data,
  double? importo,
}) {
  return DocumentoContabile(
    id: id,
    anno: 2026,
    nome: nome,
    data: data,
    tipologia: TipologiaContabile.fattura,
    descrizione: 'Nota $nome',
    importo: importo,
    mime: 'application/pdf',
    nomeFile: '$id.pdf',
    dimensione: 1,
    chunkCount: 1,
    generation: 1,
    audit: Audit.seed(data, by: 'uid-1'),
  );
}
