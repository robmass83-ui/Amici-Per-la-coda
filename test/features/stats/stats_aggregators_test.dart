import 'dart:convert';

import 'package:amici_per_la_coda/data/models/dog.dart';
import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/features/stats/stats_aggregators.dart';
import 'package:amici_per_la_coda/features/stats/stats_csv.dart';
import 'package:amici_per_la_coda/features/stats/stats_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';

void main() {
  final now = DateTime.utc(2026, 9, 8);

  test('i totali coincidono con i dati di anagrafe, adozioni e spese', () {
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
      testSponsorship(
        importoMensile: 15,
        dal: DateTime.utc(2026, 1, 1),
      ),
    ];
    final stats = buildYearStats(
      dogs: dogs,
      adoptions: adoptions,
      expenses: expenses,
      sponsorships: sponsorships,
      year: 2026,
      now: now,
    );
    expect(stats.adozioniConcluse, 2);
    expect(stats.nuoviIngressi, 2);
    expect(stats.rientriDopoAffido, 1);
    expect(stats.adozioniPerMese[2], 1);
    expect(stats.adozioniPerMese[6], 1);
    expect(stats.speseTotali, 100);
    expect(stats.donazioniRicevute, 0);
    expect(stats.adozioniADistanza, 15 * 9);
    expect(stats.saldo, 15 * 9 - 100);
    expect(stats.composizione.map((s) => s.count).toList(), [1, 1, 0, 1]);
    expect(
      stats.composizione.fold<int>(0, (sum, s) => sum + s.percentuale),
      100,
    );
    final inRifugio = [dogs[0], dogs[1], dogs[2]];
    var days = 0;
    for (final dog in inRifugio) {
      days += now.difference(dog.dataIngresso).inDays;
    }
    expect(stats.giorniMediInRifugio, (days / 3).round());
  });

  test('il CSV ha una riga per cane e le intestazioni corrette', () {
    final dogs = [
      testDog(id: 'b', nome: 'Brio', microchip: '111'),
      testDog(id: 'a', nome: 'Ada, la seconda', microchip: '222'),
      testDog(id: 'c', nome: 'Ciro', archiviato: true),
    ];
    final csv = anagrafeCsvDi(dogs);
    final lines = csv.trimRight().split('\n');
    expect(lines.first.split(','), anagrafeCsvHeaders);
    expect(lines.length, 4);
    expect(lines[1], contains('Ada, la seconda'));
    expect(lines[1].startsWith('"Ada, la seconda"'), isTrue);
    expect(csv, contains('Brio'));
    expect(csv, contains('Ciro'));
    expect(csv, contains('Microchip'));
    expect(csv, contains('Data ingresso'));
  });

  test('il report PDF è un file PDF valido', () async {
    final stats = buildYearStats(
      dogs: [testDog()],
      adoptions: const [],
      expenses: const [],
      sponsorships: const [],
      year: 2026,
      now: now,
    );
    final bytes = await reportAnnualePdf(stats);
    expect(bytes.length, greaterThan(100));
    expect(ascii.decode(bytes.take(4).toList()), '%PDF');
  });
}
