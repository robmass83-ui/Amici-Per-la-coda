import 'package:amici_per_la_coda/data/search_recents_store.dart';
import 'package:amici_per_la_coda/features/search/global_search.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';

void main() {
  final dogs = testListDogs();

  test('la query parte da 2 caratteri', () {
    expect(searchQueryReady(''), isFalse);
    expect(searchQueryReady('f'), isFalse);
    expect(searchQueryReady(' f '), isFalse);
    expect(searchQueryReady('fe'), isTrue);
  });

  test('il microchip completo trova un solo cane', () {
    final result = searchGlobal(
      query: '380260043210987',
      scope: SearchScope.tutto,
      dogs: dogs,
      documents: const [],
      adopters: const [],
      volunteers: const [],
    );
    expect(result.dogs.map((dog) => dog.id), ['fenice']);
  });

  test('una lettera non produce risultati', () {
    final result = searchGlobal(
      query: 'f',
      scope: SearchScope.tutto,
      dogs: dogs,
      documents: const [],
      adopters: const [],
      volunteers: const [],
    );
    expect(result.isEmpty, isTrue);
  });

  test('pushSearchRecent tiene al massimo 6 e mette in cima', () {
    var items = <String>[];
    for (var i = 1; i <= 7; i++) {
      items = pushSearchRecent(items, 'q$i');
    }
    expect(items, ['q7', 'q6', 'q5', 'q4', 'q3', 'q2']);
    items = pushSearchRecent(items, 'Q7');
    expect(items.first, 'Q7');
    expect(items.where((item) => item.toLowerCase() == 'q7'), hasLength(1));
  });
}
