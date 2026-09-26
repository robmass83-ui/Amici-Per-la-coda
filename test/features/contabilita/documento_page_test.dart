import 'dart:convert';
import 'dart:typed_data';

import 'package:amici_per_la_coda/core/firestore_codec.dart';
import 'package:amici_per_la_coda/data/models/documento_contabile.dart';
import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/features/contabilita/anno_page.dart';
import 'package:amici_per_la_coda/features/contabilita/contabilita_logic.dart';
import 'package:amici_per_la_coda/features/contabilita/contabilita_zip.dart';
import 'package:amici_per_la_coda/features/contabilita/documento_page.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/printing.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_contabilita_repository.dart';
import '../../helpers/fake_file_actions.dart';
import '../../helpers/fake_volunteer_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('mostra JPEG in memoria e PDF con PdfPreview', (tester) async {
    final jpegRepo = InMemoryContabilitaRepository();
    await jpegRepo.saveNuovo(
      _doc(id: 'foto', mime: 'image/jpeg', nomeFile: 'foto.jpg'),
      _pixelPng,
    );
    await _pumpDocumento(tester, repo: jpegRepo, id: 'foto');
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Image && widget.image is MemoryImage,
      ),
      findsOneWidget,
    );

    final pdfRepo = InMemoryContabilitaRepository();
    await pdfRepo.saveNuovo(
      _doc(id: 'pdf', mime: 'application/pdf', nomeFile: 'a.pdf'),
      Uint8List.fromList(utf8.encode('%PDF-1.4\n%%EOF')),
    );
    await _pumpDocumento(tester, repo: pdfRepo, id: 'pdf');
    await tester.pump();
    await tester.pump();
    expect(find.byType(PdfPreview), findsOneWidget);
  });

  testWidgets('mostra il messaggio per un documento assente', (tester) async {
    await _pumpDocumento(
      tester,
      repo: InMemoryContabilitaRepository(),
      id: 'assente',
    );

    expect(find.text('Documento non trovato.'), findsOneWidget);
  });

  testWidgets('il volontario condivide ma non modifica o elimina', (
    tester,
  ) async {
    final repo = InMemoryContabilitaRepository();
    await repo.saveNuovo(_doc(id: 'd1'), Uint8List.fromList([1]));
    final share = RecordingFileShare();
    await _pumpDocumento(
      tester,
      repo: repo,
      id: 'd1',
      share: share,
      ruolo: VolunteerRuolo.volontario,
    );

    expect(find.byKey(DocumentoContabilePage.modificaKey), findsNothing);
    expect(find.byKey(DocumentoContabilePage.eliminaKey), findsNothing);
    expect(find.byKey(DocumentoContabilePage.condividiKey), findsOneWidget);
    await tester.tap(find.byKey(DocumentoContabilePage.condividiKey));
    await tester.pump();
    expect(share.lastFileName, 'd1.pdf');
  });

  testWidgets('il presidente scarica ed elimina dopo la conferma', (
    tester,
  ) async {
    final repo = InMemoryContabilitaRepository();
    await repo.saveNuovo(_doc(id: 'd1'), Uint8List.fromList([4, 5]));
    final opener = FakeFileOpener();
    await _pumpDocumento(tester, repo: repo, id: 'd1', opener: opener);

    expect(find.byKey(DocumentoContabilePage.modificaKey), findsOneWidget);
    expect(find.byKey(DocumentoContabilePage.eliminaKey), findsOneWidget);
    await tester.tap(find.byKey(DocumentoContabilePage.scaricaKey));
    await tester.pump();
    expect(opener.lastBytes, [4, 5]);

    await tester.tap(find.byKey(DocumentoContabilePage.eliminaKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text(contabilitaElimina), findsOneWidget);
    await tester.tap(find.text('Elimina').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(repo.documents, isEmpty);
  });

  testWidgets('export annuale ignora la ricerca e include tutti i file', (
    tester,
  ) async {
    final repo = InMemoryContabilitaRepository();
    await repo.saveNuovo(
      _doc(id: 'uno', nome: 'Visibile'),
      Uint8List.fromList([1]),
    );
    await repo.saveNuovo(
      _doc(id: 'due', nome: 'Nascosto'),
      Uint8List.fromList([2]),
    );
    final share = RecordingFileShare();
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    await pumpApp(
      tester,
      auth: auth,
      contabilita: repo,
      fileShare: share,
      initialLocation: AppRoutes.contabilitaAnno(2026),
      size: const Size(360, 900),
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Cerca per nome'),
      'Visibile',
    );
    await tester.pumpAndSettle();
    expect(find.text('Nascosto'), findsNothing);

    await tester.tap(find.byKey(AnnoContabilePage.esportaKey));
    await tester.pumpAndSettle();

    expect(share.lastFileName, nomeZipAnno(2026));
    expect(share.lastMime, 'application/zip');
    final archive = ZipDecoder().decodeBytes(share.lastBytes!);
    expect(archive.files.map((file) => file.name), contains('riepilogo.csv'));
    expect(archive.files, hasLength(3));
  });
}

Future<void> _pumpDocumento(
  WidgetTester tester, {
  required InMemoryContabilitaRepository repo,
  required String id,
  RecordingFileShare? share,
  FakeFileOpener? opener,
  VolunteerRuolo ruolo = VolunteerRuolo.presidente,
}) async {
  final auth = FakeAuthRepository();
  await auth.signIn(email: 'giovanna@amiciperlacoda.it', password: 'corretta');
  await pumpApp(
    tester,
    auth: auth,
    contabilita: repo,
    fileShare: share,
    fileOpener: opener,
    volunteers: InMemoryVolunteerRepository([testVolunteer(ruolo: ruolo)]),
    initialLocation: AppRoutes.contabilitaDocumento(2026, id),
    size: const Size(360, 900),
    settle: false,
  );
  await tester.pump();
  await tester.pump();
}

DocumentoContabile _doc({
  required String id,
  String nome = 'Documento',
  String mime = 'application/pdf',
  String? nomeFile,
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
    mime: mime,
    nomeFile: nomeFile ?? '$id.pdf',
    dimensione: 1,
    chunkCount: 1,
    generation: 1,
    audit: Audit.seed(at, by: 'uid-1'),
  );
}

final _pixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
  '+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);
