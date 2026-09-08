import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/features/dogs/dog_list_query.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';

void main() {
  final now = DateTime.utc(2026, 9, 8);
  final dogs = testListDogs();

  test('cercando fen resta 1 risultato', () {
    final result = filterDogs(
      dogs,
      query: 'fen',
      filter: DogQuickFilter.tutti,
      now: now,
    );
    expect(result, hasLength(1));
    expect(result.single.nome, contains('Fenice'));
  });

  test('cercando il microchip completo resta 1 risultato', () {
    final result = filterDogs(
      dogs,
      query: '380260043210987',
      filter: DogQuickFilter.tutti,
      now: now,
    );
    expect(result, hasLength(1));
    expect(result.single.id, 'fenice');
  });

  test('il filtro In stallo mostra solo Nina', () {
    final result = filterDogs(
      dogs,
      query: '',
      filter: DogQuickFilter.inStallo,
      now: now,
    );
    expect(result, hasLength(1));
    expect(result.single.nome, contains('Nina'));
    expect(result.single.stato, DogStato.inStallo);
  });

  test('la paginazione mostra 20 elementi per volta', () {
    final many = [
      for (var i = 0; i < 25; i++) testDog(id: 'd$i', nome: 'Cane $i'),
    ];
    expect(pageDogs(many, dogListPageSize), hasLength(20));
    expect(pageDogs(many, dogListPageSize * 2), hasLength(25));
  });
}
