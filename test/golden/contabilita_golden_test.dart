import 'dart:typed_data';

import 'package:amici_per_la_coda/core/firestore_codec.dart';
import 'package:amici_per_la_coda/data/models/documento_contabile.dart';
import 'package:amici_per_la_coda/features/contabilita/anni_page.dart';
import 'package:amici_per_la_coda/features/contabilita/anno_page.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_contabilita_repository.dart';
import 'golden_support.dart';

Future<InMemoryContabilitaRepository> _repository() async {
  final repo = InMemoryContabilitaRepository();
  final timestamp = DateTime.utc(2026, 3, 12);
  await repo.createAnno(anno: 2026, uid: 'uid-1', now: timestamp);
  await repo.saveNuovo(
    DocumentoContabile(
      id: 'fattura-veterinario',
      anno: 2026,
      nome: 'Fattura veterinario',
      data: timestamp,
      tipologia: TipologiaContabile.fattura,
      descrizione: 'Visita',
      importo: 1240.50,
      mime: 'application/pdf',
      nomeFile: 'fattura.pdf',
      dimensione: 4,
      chunkCount: 1,
      generation: 1,
      audit: Audit.seed(timestamp, by: 'uid-1'),
    ),
    Uint8List.fromList([1, 2, 3, 4]),
  );
  return repo;
}

void main() {
  testWidgets('elenco anni 360', (tester) async {
    final repo = await _repository();
    await pumpGolden(
      tester,
      location: AppRoutes.contabilita,
      contabilita: repo,
    );
    expect(find.byType(AnniContabiliPage), findsOneWidget);
    await expectLater(
      find.byType(AnniContabiliPage),
      matchesGoldenFile('goldens/contabilita_anni_360.png'),
    );
  }, skip: skipUntilPng('contabilita_anni_360.png'));

  testWidgets('archivio anno 360', (tester) async {
    final repo = await _repository();
    await pumpGolden(
      tester,
      location: AppRoutes.contabilitaAnno(2026),
      contabilita: repo,
    );
    expect(find.byType(AnnoContabilePage), findsOneWidget);
    await expectLater(
      find.byType(AnnoContabilePage),
      matchesGoldenFile('goldens/contabilita_anno_360.png'),
    );
  }, skip: skipUntilPng('contabilita_anno_360.png'));
}
