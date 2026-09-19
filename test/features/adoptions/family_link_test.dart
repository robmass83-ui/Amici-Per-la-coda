import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/features/adoptions/family_link.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';

void main() {
  test('familyLinkOf prende l\'adozione più recente del cane', () {
    final older = testAdoption(
      id: 'a1',
      dogId: 'k',
      dataRichiesta: DateTime.utc(2026, 1, 1),
    );
    final newer = testAdoption(
      id: 'a2',
      dogId: 'k',
      dataRichiesta: DateTime.utc(2026, 9, 1),
    );
    expect(familyLinkOf([older, newer], 'k')?.id, 'a2');
    expect(familyLinkOf([older, newer], 'altro'), isNull);
  });

  test('markDogAdottatoIfNeeded non riscrive lo storico se già adottato', () {
    final dog = testDog(stato: DogStato.adottato, adottabile: true);
    final now = DateTime.utc(2026, 9, 19);
    final result = markDogAdottatoIfNeeded(
      dog: dog,
      now: now,
      autoreId: 'u1',
    );
    expect(result.wroteStorico, isFalse);
    expect(result.dog.adottabile, isFalse);
    expect(result.dog.storicoStati.length, dog.storicoStati.length);
  });

  test('markDogAdottatoIfNeeded da in_rifugio scrive adottato', () {
    final dog = testDog(stato: DogStato.inRifugio, adottabile: true);
    final now = DateTime.utc(2026, 9, 19);
    final result = markDogAdottatoIfNeeded(
      dog: dog,
      now: now,
      autoreId: 'u1',
    );
    expect(result.wroteStorico, isTrue);
    expect(result.dog.stato, DogStato.adottato);
    expect(result.dog.adottabile, isFalse);
  });
}
