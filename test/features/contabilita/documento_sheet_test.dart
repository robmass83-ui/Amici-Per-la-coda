import 'dart:convert';
import 'dart:typed_data';

import 'package:amici_per_la_coda/core/firestore_codec.dart';
import 'package:amici_per_la_coda/data/documents/document_file_picker.dart';
import 'package:amici_per_la_coda/data/models/documento_contabile.dart';
import 'package:amici_per_la_coda/features/contabilita/anno_page.dart';
import 'package:amici_per_la_coda/features/contabilita/contabilita_logic.dart';
import 'package:amici_per_la_coda/features/contabilita/documento_page.dart';
import 'package:amici_per_la_coda/features/contabilita/documento_sheet.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_contabilita_repository.dart';
import '../../helpers/fake_file_actions.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('valida nome, file e importo prima del salvataggio', (
    tester,
  ) async {
    final repo = InMemoryContabilitaRepository();
    await _pumpAnno(tester, repo: repo);
    await tester.tap(find.byKey(AnnoContabilePage.aggiungiKey));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salva'));
    await tester.pump();
    expect(find.text(contabilitaNomeVuoto), findsOneWidget);

    await tester.enterText(
      _field(DocumentoContabileSheet.nomeKey),
      'Veterinario',
    );
    await tester.tap(find.text('Salva'));
    await tester.pump();
    expect(find.text(contabilitaFileMancante), findsOneWidget);

    await tester.enterText(_field(DocumentoContabileSheet.importoKey), '-1');
    await tester.tap(find.text('Salva'));
    await tester.pump();
    expect(find.text(contabilitaImportoNonValido), findsOneWidget);
  });

  testWidgets('crea un PDF con importo vuoto e tipologia Fattura', (
    tester,
  ) async {
    final repo = InMemoryContabilitaRepository();
    final picker = FakeDocumentFilePicker(
      pdf: PickedDocumentFile(
        bytes: Uint8List.fromList([1, 2]),
        name: 'a.pdf',
        mime: 'application/pdf',
      ),
    );
    await _pumpAnno(tester, repo: repo, picker: picker);
    await tester.tap(find.byKey(AnnoContabilePage.aggiungiKey));
    await tester.pumpAndSettle();

    expect(find.text('Nuovo documento'), findsOneWidget);
    expect(find.text('Fattura'), findsOneWidget);
    await tester.enterText(
      _field(DocumentoContabileSheet.nomeKey),
      '  Veterinario  ',
    );
    await tester.ensureVisible(find.text('File'));
    await tester.tap(find.text('File'));
    await tester.pump();
    await tester.ensureVisible(find.text('Salva'));
    await tester.tap(find.text('Salva'));
    await _pumpUntil(
      tester,
      () => find.text('Nuovo documento').evaluate().isEmpty,
    );
    final docs = repo.documents.where((doc) => doc.anno == 2026).toList();
    expect(docs, hasLength(1));
    expect(docs.single.nome, 'Veterinario');
    expect(docs.single.tipologia, TipologiaContabile.fattura);
    expect(docs.single.importo, isNull);
    expect(docs.single.dimensione, 2);
    expect(repo.bytesOf(docs.single.id), [1, 2]);
  });

  testWidgets('modifica i metadati senza cambiare generazione o file', (
    tester,
  ) async {
    final repo = InMemoryContabilitaRepository();
    final original = _doc(
      id: 'd1',
      nome: 'Prima',
      dimensione: _pixelPng.length,
    );
    await repo.saveNuovo(original, _pixelPng);
    await _pumpDocumento(tester, repo: repo, id: original.id);

    await tester.tap(find.byKey(DocumentoContabilePage.modificaKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(_field(DocumentoContabileSheet.nomeKey), 'Dopo');
    await tester.ensureVisible(find.text('Salva'));
    await tester.tap(find.text('Salva'));
    await _pumpUntil(
      tester,
      () => find.text('Modifica documento').evaluate().isEmpty,
    );

    final saved = repo.documents.single;
    expect(saved.nome, 'Dopo');
    expect(saved.generation, 1);
    expect(repo.bytesOf(saved.id), _pixelPng);
  });

  testWidgets('rifiuta una sostituzione che supera 700 MiB', (tester) async {
    final repo = InMemoryContabilitaRepository();
    final original = _doc(id: 'd1', nome: 'Prima', dimensione: 1);
    await repo.saveNuovo(original, _pixelPng);
    await repo.saveNuovo(
      _doc(id: 'grande', nome: 'Archivio', dimensione: 700 * 1024 * 1024),
      Uint8List.fromList([6]),
    );
    final picker = FakeDocumentFilePicker(
      pdf: PickedDocumentFile(
        bytes: Uint8List.fromList([1, 2]),
        name: 'nuovo.pdf',
        mime: 'application/pdf',
      ),
    );
    await _pumpDocumento(tester, repo: repo, id: original.id, picker: picker);

    await tester.tap(find.byKey(DocumentoContabilePage.modificaKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.text('File'));
    await tester.tap(find.text('File'));
    await tester.pump();
    await tester.ensureVisible(find.text('Salva'));
    await tester.tap(find.text('Salva'));
    await _pumpUntil(
      tester,
      () => find.text(contabilitaPieno).evaluate().isNotEmpty,
    );

    expect(find.text(contabilitaPieno), findsOneWidget);
    expect(repo.bytesOf(original.id), _pixelPng);
  });
}

Finder _field(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(TextField));

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 20 && !condition(); attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(condition(), isTrue);
}

Future<void> _pumpAnno(
  WidgetTester tester, {
  required InMemoryContabilitaRepository repo,
  FakeDocumentFilePicker? picker,
}) async {
  final auth = FakeAuthRepository();
  await auth.signIn(email: 'giovanna@amiciperlacoda.it', password: 'corretta');
  await pumpApp(
    tester,
    auth: auth,
    contabilita: repo,
    documentPicker: picker,
    initialLocation: AppRoutes.contabilitaAnno(2026),
    size: const Size(360, 900),
  );
}

Future<void> _pumpDocumento(
  WidgetTester tester, {
  required InMemoryContabilitaRepository repo,
  required String id,
  FakeDocumentFilePicker? picker,
}) async {
  final auth = FakeAuthRepository();
  await auth.signIn(email: 'giovanna@amiciperlacoda.it', password: 'corretta');
  await pumpApp(
    tester,
    auth: auth,
    contabilita: repo,
    documentPicker: picker,
    initialLocation: AppRoutes.contabilitaDocumento(2026, id),
    size: const Size(360, 900),
    settle: false,
  );
  await tester.pump();
  await tester.pump();
}

DocumentoContabile _doc({
  required String id,
  required String nome,
  required int dimensione,
}) {
  final at = DateTime.utc(2026, 3, 12);
  return DocumentoContabile(
    id: id,
    anno: 2026,
    nome: nome,
    data: at,
    tipologia: TipologiaContabile.fattura,
    descrizione: '',
    importo: null,
    mime: 'image/jpeg',
    nomeFile: '$id.jpg',
    dimensione: dimensione,
    chunkCount: 1,
    generation: 1,
    audit: Audit.seed(at, by: 'uid-1'),
  );
}

final _pixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
  '+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);
