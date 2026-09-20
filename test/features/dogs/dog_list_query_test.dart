import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/features/dogs/dog_list_query.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';

void main() {
  final now = DateTime.utc(2026, 9, 8);
  final dogs = testListDogs();

  test('i segmenti rapidi sono cinque e nell\'ordine richiesto', () {
    expect(dogQuickFilterLabels, [
      'Rifugio',
      'Stallo',
      'Adottab.',
      'Cuccioli',
      'Adottati',
    ]);
    expect(dogQuickFilterLabels, hasLength(DogQuickFilter.values.length));
    expect(DogQuickFilter.values, [
      DogQuickFilter.inRifugio,
      DogQuickFilter.inStallo,
      DogQuickFilter.adottabili,
      DogQuickFilter.cuccioli,
      DogQuickFilter.adottati,
    ]);
  });

  test('cercando fen resta 1 risultato', () {
    final result = filterDogs(dogs, query: 'fen', now: now);
    expect(result, hasLength(1));
    expect(result.single.nome, contains('Fenice'));
  });

  test('cercando il microchip completo resta 1 risultato', () {
    final result = filterDogs(dogs, query: '380260043210987', now: now);
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

  test('un cane archiviato non compare in nessun segmento', () {
    final archived = testDog(
      id: 'archivio',
      nome: 'Archivione',
      archiviato: true,
      adottabile: true,
      dataNascita: DateTime.utc(2026, 3, 1),
    );
    final mixed = [...dogs, archived];
    for (final filter in DogQuickFilter.values) {
      final result = filterDogs(mixed, query: '', filter: filter, now: now);
      expect(
        result.any((dog) => dog.id == 'archivio'),
        isFalse,
        reason: filter.name,
      );
      expect(countForFilter(mixed, filter, now), result.length);
    }
    expect(filterDogs(mixed, query: 'archivio', now: now), isEmpty);
  });

  test('un cane deceduto non compare nei segmenti del rifugio', () {
    final dead = testDog(
      id: 'pongo',
      nome: 'Pongo',
      stato: DogStato.deceduto,
      archiviato: false,
      adottabile: true,
      dataNascita: DateTime.utc(2026, 3, 1),
    );
    final mixed = [...dogs, dead];
    for (final filter in [
      DogQuickFilter.inRifugio,
      DogQuickFilter.inStallo,
      DogQuickFilter.adottabili,
      DogQuickFilter.cuccioli,
    ]) {
      final result = filterDogs(mixed, query: '', filter: filter, now: now);
      expect(
        result.any((dog) => dog.id == 'pongo'),
        isFalse,
        reason: filter.name,
      );
    }
    expect(filterDogs(mixed, query: 'pongo', now: now), isEmpty);
  });

  test('il filtro Adottati mostra i cani adottati anche se archiviati', () {
    final adopted = testDog(
      id: 'luna',
      nome: 'Luna',
      stato: DogStato.adottato,
      archiviato: true,
    );
    final mixed = [...dogs, adopted];
    final result = filterDogs(
      mixed,
      query: '',
      filter: DogQuickFilter.adottati,
      now: now,
    );
    expect(result, hasLength(1));
    expect(result.single.id, 'luna');
    expect(countForFilter(mixed, DogQuickFilter.adottati, now), 1);
    expect(
      filterDogs(
        mixed,
        query: '',
        filter: DogQuickFilter.inRifugio,
        now: now,
      ).any((dog) => dog.id == 'luna'),
      isFalse,
    );
  });

  test('il filtro Taglia grande lascia solo i cani grandi', () async {
    final mixed = [
      testDog(id: 'media', nome: 'Media', taglia: Taglia.media),
      testDog(id: 'grosso', nome: 'Grosso', taglia: Taglia.grande),
    ];
    final result = filterDogs(
      mixed,
      query: '',
      now: now,
      extra: const DogListFilters(taglie: {Taglia.grande}),
    );
    expect(result, hasLength(1));
    expect(result.single.id, 'grosso');
  });

  test('la lista chiede healthAll solo col filtro vaccini scaduti', () {
    expect(const DogListFilters().needsHealthAll, isFalse);
    expect(
      const DogListFilters(sanitari: {DogSanitario.sterilizzati})
          .needsHealthAll,
      isFalse,
    );
    expect(
      const DogListFilters(sanitari: {DogSanitario.vacciniScaduti})
          .needsHealthAll,
      isTrue,
    );
  });
}
