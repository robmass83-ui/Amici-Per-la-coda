import 'package:amici_per_la_coda/features/dogs/scadenze.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 8);

  test('scaduto / entro 7 gg / entro 30 gg / lontano', () {
    expect(fasciaScadenza(DateTime(2026, 9, 7), now), ScadenzaFascia.scaduto);
    expect(fasciaScadenza(DateTime(2026, 9, 8), now), ScadenzaFascia.entro7);
    expect(fasciaScadenza(DateTime(2026, 9, 11), now), ScadenzaFascia.entro7);
    expect(fasciaScadenza(DateTime(2026, 9, 15), now), ScadenzaFascia.entro7);
    expect(fasciaScadenza(DateTime(2026, 9, 16), now), ScadenzaFascia.entro30);
    expect(fasciaScadenza(DateTime(2026, 10, 8), now), ScadenzaFascia.entro30);
    expect(fasciaScadenza(DateTime(2026, 10, 9), now), ScadenzaFascia.lontano);
  });

  test('etichette relative', () {
    expect(etichettaScadenza(DateTime(2026, 9, 7), now), 'scaduto da 1 g');
    expect(etichettaScadenza(DateTime(2026, 9, 8), now), 'oggi');
    expect(etichettaScadenza(DateTime(2026, 9, 11), now), 'tra 3 gg');
    expect(etichettaScadenza(DateTime(2026, 10, 9), now), '09/10/2026');
  });
}
