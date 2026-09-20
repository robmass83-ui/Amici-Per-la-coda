import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:amici_per_la_coda/data/models/dog.dart';
import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/features/dogs/dog_altro_tab.dart';
import 'package:amici_per_la_coda/features/dogs/dog_detail_page.dart';
import 'package:amici_per_la_coda/features/dogs/export/adoption_pdf_preview_page.dart';
import 'package:amici_per_la_coda/features/stats/stats_aggregators.dart';
import 'package:amici_per_la_coda/features/stats/stats_csv.dart';
import 'package:amici_per_la_coda/features/stats/stats_page.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_adoption_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_dog_repository.dart';
import '../../helpers/fake_expense_repository.dart';
import '../../helpers/fake_file_actions.dart';
import '../../helpers/fake_photo_repository.dart';
import '../../helpers/fake_sponsorship_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const widths = [320.0, 360.0, 411.0, 430.0];
  final now = DateTime.utc(2026, 9, 8);

  final dogs = [
    testDog(
      id: 'a',
      nome: 'Ada',
      taglia: Taglia.media,
      dataIngresso: DateTime.utc(2026, 2, 1),
      dataNascita: DateTime.utc(2023, 1, 1),
    ),
    testDog(
      id: 'b',
      nome: 'Brio',
      taglia: Taglia.grande,
      dataIngresso: DateTime.utc(2025, 1, 1),
      dataNascita: DateTime.utc(2022, 1, 1),
    ),
    testDog(
      id: 'c',
      nome: 'Cucciolo',
      taglia: Taglia.piccola,
      dataIngresso: DateTime.utc(2026, 6, 1),
      dataNascita: DateTime.utc(2026, 3, 1),
    ),
    testDog(
      id: 'd',
      nome: 'Dino',
      stato: DogStato.adottato,
      dataIngresso: DateTime.utc(2024, 1, 1),
      storicoStati: [
        StatoVoce(
          stato: DogStato.restituito,
          dal: DateTime.utc(2026, 4, 10),
          note: '',
          autoreId: 'test',
        ),
      ],
    ),
  ];
  final adoptions = [
    testAdoption(
      id: 'ad-mar',
      dogId: 'x',
      stato: AdoptionStato.adottato,
      dataRichiesta: DateTime.utc(2026, 3, 12),
    ),
    testAdoption(
      id: 'ad-lug',
      dogId: 'y',
      stato: AdoptionStato.adottato,
      dataRichiesta: DateTime.utc(2026, 7, 2),
    ),
    testAdoption(
      id: 'ad-old',
      dogId: 'z',
      stato: AdoptionStato.adottato,
      dataRichiesta: DateTime.utc(2025, 7, 2),
    ),
  ];
  final expenses = [
    testExpense(id: 'e1', importo: 100, data: DateTime.utc(2026, 4, 1)),
    testExpense(id: 'e2', importo: 50, data: DateTime.utc(2025, 4, 1)),
  ];
  final sponsorships = [
    testSponsorship(importoMensile: 15, dal: DateTime.utc(2026, 1, 1)),
  ];

  Finder horizontalScrollables() {
    return find.byWidgetPredicate((widget) {
      if (widget is! Scrollable) {
        return false;
      }
      if (axisDirectionToAxis(widget.axisDirection) != Axis.horizontal) {
        return false;
      }
      return widget.restorationId != 'editable';
    });
  }

  Future<void> pumpStats(
    WidgetTester tester, {
    Size size = const Size(360, 900),
    RecordingFileShare? share,
    String location = AppRoutes.statistiche,
    List<Dog>? dogList,
  }) async {
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    final dogRepo = InMemoryDogRepository(dogList ?? dogs);
    await pumpApp(
      tester,
      auth: auth,
      size: size,
      initialLocation: location,
      dogs: dogRepo,
      adoptions: InMemoryAdoptionRepository(adoptions),
      expenses: InMemoryExpenseRepository(expenses),
      sponsorships: InMemorySponsorshipRepository(sponsorships),
      photos: InMemoryPhotoRepository(dogs: dogRepo),
      fileShare: share,
      dogListNow: now,
    );
  }

  testWidgets('i quattro contatori coincidono con gli aggregatori', (
    tester,
  ) async {
    await pumpStats(tester);
    final stats = buildYearStats(
      dogs: dogs,
      adoptions: adoptions,
      expenses: expenses,
      sponsorships: sponsorships,
      year: 2026,
      now: now,
    );
    expect(
      find.descendant(
        of: find.byKey(StatsPage.adozioniKey),
        matching: find.text('${stats.adozioniConcluse}'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(StatsPage.ingressiKey),
        matching: find.text('${stats.nuoviIngressi}'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(StatsPage.giorniKey),
        matching: find.text('${stats.giorniMediInRifugio}'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(StatsPage.rientriKey),
        matching: find.text('${stats.rientriDopoAffido}'),
      ),
      findsOneWidget,
    );
    expect(find.text('Adozioni per mese'), findsOneWidget);
    expect(find.text('Composizione del rifugio'), findsOneWidget);
    expect(find.text('Bilancio spese sanitarie'), findsOneWidget);
    await tester.ensureVisible(find.byKey(StatsPage.saldoKey));
    expect(find.text(formatSaldo(stats.saldo)), findsOneWidget);
  });

  testWidgets('CSV e PDF si aprono con le intestazioni e il mime corretti', (
    tester,
  ) async {
    final share = RecordingFileShare();
    await pumpStats(tester, share: share);

    await tester.ensureVisible(find.byKey(StatsPage.csvKey));
    await tester.tap(find.byKey(StatsPage.csvKey));
    await tester.pumpAndSettle();
    expect(share.lastFileName, 'anagrafe_cani.csv');
    expect(share.lastMime, 'text/csv');
    final csv = utf8.decode(share.lastBytes!);
    final lines = csv.trimRight().split('\n');
    expect(lines.first.split(','), anagrafeCsvHeaders);
    expect(lines.length, dogs.length + 1);
    expect(csv, contains('Ada'));
    expect(csv, contains('Dino'));

    await tester.ensureVisible(find.byKey(StatsPage.pdfKey));
    await tester.tap(find.byKey(StatsPage.pdfKey));
    await tester.pumpAndSettle();
    expect(share.lastFileName, 'report_2026.pdf');
    expect(share.lastMime, 'application/pdf');
    expect(
      String.fromCharCodes(share.lastBytes!.sublist(0, 4)),
      '%PDF',
    );
  });

  testWidgets('Esporta scheda in PDF dalla tab Altro apre l\'anteprima', (
    tester,
  ) async {
    await pumpStats(
      tester,
      size: const Size(360, 1200),
      location: AppRoutes.dog('a'),
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(DogDetailPage.tabBarKey),
        matching: find.text('Altro'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(DogAltroTab.esportaPdfKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DogAltroTab.esportaPdfKey));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(AdoptionPdfPreviewPage.pageKey), findsOneWidget);
    expect(find.text('Scheda di adozione'), findsWidgets);
  });

  testWidgets('il selettore anno aggiorna i contatori', (tester) async {
    await pumpStats(tester);
    expect(
      find.descendant(
        of: find.byKey(StatsPage.adozioniKey),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(StatsPage.yearKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('stats-year-2025')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(StatsPage.adozioniKey),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(StatsPage.ingressiKey),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('320–430 dp senza overflow né scroll orizzontale', (
    tester,
  ) async {
    for (final width in widths) {
      await pumpStats(tester, size: Size(width, 640));
      expect(tester.takeException(), isNull, reason: '${width.toInt()} dp');
      expect(horizontalScrollables(), findsNothing, reason: '${width.toInt()} dp');
    }
  });

  testWidgets('screenshot Statistiche', (tester) async {
    await pumpStats(tester, size: const Size(360, 800));
    await _saveShot(tester, 'statistiche.png');
  });
}

Future<void> _saveShot(WidgetTester tester, String name) async {
  await tester.pump();
  final dir = Directory('${Directory.current.path}/test/screenshots');
  dir.createSync(recursive: true);
  final file = File('${dir.path}/$name');
  final image = await captureImage(tester.element(find.byType(MaterialApp)));
  final byteData = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.png),
  );
  if (byteData == null) {
    throw StateError(
      'screenshot $name: toByteData è null (cwd=${Directory.current.path})',
    );
  }
  file.writeAsBytesSync(byteData.buffer.asUint8List());
  if (!file.existsSync() || file.lengthSync() < 100) {
    throw StateError('screenshot $name non scritto in ${file.path}');
  }
}
