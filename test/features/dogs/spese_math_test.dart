import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/features/dogs/health_labels.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';

void main() {
  final documenti = [
    testExpense(
      id: 'e-visite',
      categoria: ExpenseCategoria.visita,
      importo: 320,
    ),
    testExpense(
      id: 'e-ster',
      categoria: ExpenseCategoria.sterilizzazione,
      importo: 180,
    ),
    testExpense(
      id: 'e-esami',
      categoria: ExpenseCategoria.esami,
      importo: 120,
    ),
    testExpense(
      id: 'e-farmaci',
      categoria: ExpenseCategoria.farmaci,
      importo: 95,
    ),
  ];

  test('la somma delle spese coincide con la somma dei documenti', () {
    expect(totaleSpese(documenti), 715);
    expect(
      totaleSpese(documenti),
      documenti.fold<double>(0, (sum, item) => sum + item.importo),
    );
    expect(
      ripartizioneSpese(documenti).fold<double>(0, (sum, v) => sum + v.importo),
      totaleSpese(documenti),
    );
  });

  test('le percentuali della ripartizione sommano 100', () {
    final parts = ripartizioneSpese(documenti);
    expect(parts.map((v) => v.percentuale).fold<int>(0, (a, b) => a + b), 100);
    expect(
      parts.map((v) => v.percentuale).toList(),
      [45, 25, 17, 13],
    );
  });

  test('la copertura dell\'adozione a distanza non supera mai 100%', () {
    expect(
      coperturaAdozioneADistanza(
        contributoMensile: 200,
        speseTotali: 100,
        mesiPermanenza: 12,
      ),
      100,
    );
    final riepilogo = riepilogoAdozioneADistanza(
      sponsorships: [
        testSponsorship(id: 's1', importoMensile: 80),
        testSponsorship(id: 's2', nome: 'Luca', importoMensile: 50),
      ],
      expenses: [testExpense(importo: 20)],
      from: DateTime.utc(2024, 6, 25),
      now: DateTime.utc(2026, 9, 8),
    );
    expect(riepilogo, isNotNull);
    expect(riepilogo!.coperturaPercentuale, lessThanOrEqualTo(100));
    expect(riepilogo.contributoMensile, 130);
    expect(riepilogo.sostenitoriAttivi, 2);
  });

  test('copertura a zero spese non va in errore e resta 0', () {
    expect(
      coperturaAdozioneADistanza(
        contributoMensile: 30,
        speseTotali: 0,
        mesiPermanenza: 12,
      ),
      0,
    );
    final riepilogo = riepilogoAdozioneADistanza(
      sponsorships: [testSponsorship()],
      expenses: const [],
      from: DateTime.utc(2024, 6, 25),
      now: DateTime.utc(2026, 9, 8),
    );
    expect(riepilogo, isNotNull);
    expect(riepilogo!.coperturaPercentuale, 0);
    expect(riepilogo.contributoMensile, 15);
  });

  test('senza sostenitori attivi il riepilogo è vuoto', () {
    expect(
      riepilogoAdozioneADistanza(
        sponsorships: [testSponsorship(attiva: false)],
        expenses: [testExpense(importo: 100)],
        from: DateTime.utc(2024, 6, 25),
        now: DateTime.utc(2026, 9, 8),
      ),
      isNull,
    );
  });
}
