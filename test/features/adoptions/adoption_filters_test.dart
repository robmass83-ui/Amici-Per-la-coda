import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/features/adoptions/adoption_filters.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';

void main() {
  test('filtri per stato raggruppano da valutare, in corso, preaffido e chiuse', () {
    final items = [
      testAdoption(id: 'a1', stato: AdoptionStato.ricevuta),
      testAdoption(id: 'a2', stato: AdoptionStato.colloquio),
      testAdoption(id: 'a3', stato: AdoptionStato.visita),
      testAdoption(id: 'a4', stato: AdoptionStato.preaffido),
      testAdoption(id: 'a5', stato: AdoptionStato.respinta),
    ];

    expect(countAdoptionsForFilter(items, AdoptionQuickFilter.tutte), 5);
    expect(countAdoptionsForFilter(items, AdoptionQuickFilter.daValutare), 1);
    expect(countAdoptionsForFilter(items, AdoptionQuickFilter.colloquio), 2);
    expect(countAdoptionsForFilter(items, AdoptionQuickFilter.preaffido), 1);
    expect(countAdoptionsForFilter(items, AdoptionQuickFilter.concluse), 1);

    final concluse = filterAdoptions(items, AdoptionQuickFilter.concluse);
    expect(concluse.single.id, 'a5');
  });
}
