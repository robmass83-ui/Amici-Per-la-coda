import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/features/dashboard/home_aggregators.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';

void main() {
  final now = DateTime(2026, 9, 8);

  test('42 su 54 dà 78% e stato sotto capienza', () {
    final view = occupazioneDi(42, 54);
    expect(view.kind, OccupancyKind.sottoCapienza);
    expect(view.percentuale, 78);
    expect(view.caption, '78% dei 54 posti');
    expect(view.showBar, isTrue);
    expect(view.barFill, closeTo(42 / 54, 0.0001));
    expect(view.barFill, lessThanOrEqualTo(1.0));

    final dogs = [
      for (var i = 0; i < 42; i++)
        testDog(id: 'd$i', stato: DogStato.inRifugio),
    ];
    final summary = buildHomeSummary(
      dogs: dogs,
      boxes: [testBox(id: 'cap', capienza: 54)],
      adoptions: const [],
      health: const [],
      appointments: const [],
      now: now,
    );
    expect(summary.caniInRifugio, 42);
    expect(summary.postiTotali, 54);
    expect(summary.occupancy.kind, OccupancyKind.sottoCapienza);
    expect(summary.occupancy.percentuale, 78);
    expect(summary.databaseVuoto, isFalse);
  });

  test('53 su 17 dà oltre capienza con riempimento barra 1.0', () {
    final view = occupazioneDi(53, 17);
    expect(view.kind, OccupancyKind.oltreCapienza);
    expect(view.barFill, 1.0);
    expect(view.percentuale, isNull);
    expect(view.caption, '53 su 17 posti · oltre capienza');
    expect(view.caption.contains('%'), isFalse);

    final dogs = [
      for (var i = 0; i < 53; i++)
        testDog(id: 'd$i', stato: DogStato.inRifugio),
    ];
    final summary = buildHomeSummary(
      dogs: dogs,
      boxes: [testBox(id: 'cap', capienza: 17)],
      adoptions: const [],
      health: const [],
      appointments: const [],
      now: now,
    );
    expect(summary.occupancy.kind, OccupancyKind.oltreCapienza);
    expect(summary.occupancy.barFill, 1.0);
  });

  test('53 su 0 dà non configurato senza divisione per zero', () {
    expect(() => occupazioneDi(53, 0), returnsNormally);
    final view = occupazioneDi(53, 0);
    expect(view.kind, OccupancyKind.nonConfigurato);
    expect(view.showBar, isFalse);
    expect(view.caption, 'posti non configurati');
    expect(view.percentuale, isNull);

    final dogs = [
      for (var i = 0; i < 53; i++)
        testDog(id: 'd$i', stato: DogStato.inRifugio),
    ];
    final summary = buildHomeSummary(
      dogs: dogs,
      boxes: const [],
      adoptions: const [],
      health: const [],
      appointments: const [],
      now: now,
    );
    expect(summary.postiTotali, 0);
    expect(summary.occupancy.kind, OccupancyKind.nonConfigurato);
  });

  test('daFareOggi: scadenza scaduta, poi appuntamento, poi preaffido, poi ferma', () {
    final dogs = [
      testDog(id: 'fido', nome: 'Fido'),
      testDog(id: 'luna', nome: 'Luna'),
    ];
    final items = daFareOggiDi(
      dogs: dogs,
      health: [
        testHealth(
          dogId: 'fido',
          tipo: HealthTipo.vaccino,
          prossimaScadenza: DateTime(2026, 9, 1),
        ),
      ],
      appointments: [
        testAppointment(
          dogId: 'luna',
          titolo: 'Visita odierna',
          inizio: DateTime(2026, 9, 8, 10, 30),
        ),
      ],
      adoptions: [
        testAdoption(
          id: 'ferma',
          dogId: 'fido',
          stato: AdoptionStato.ricevuta,
          dataRichiesta: DateTime(2026, 8, 20),
          richiedente: testRichiedente(nome: 'Marta', cognome: 'Neri'),
        ),
        testAdoption(
          id: 'pre',
          dogId: 'luna',
          stato: AdoptionStato.preaffido,
          dataRichiesta: DateTime(2026, 8, 1),
          preaffidoDal: DateTime(2026, 9, 1),
          preaffidoAl: DateTime(2026, 9, 12),
        ),
      ],
      now: now,
    );

    expect(items, hasLength(4));
    expect(items.map((item) => item.priority).toList(), [1, 2, 3, 4]);
    expect(items[0].nomeCane, 'Fido');
    expect(items[0].resto, contains('Vaccino scaduto da 7 gg'));
    expect(items[0].trailing, '⚠️');
    expect(items[1].resto, contains('Visita odierna'));
    expect(items[1].trailing, '10:30');
    expect(items[2].resto, contains('preaffido in scadenza'));
    expect(items[3].nomeCane, 'Marta Neri');
  });
}
