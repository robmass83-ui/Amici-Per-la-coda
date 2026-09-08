import 'package:amici_per_la_coda/core/format_it.dart';
import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/features/dogs/dog_labels.dart';
import 'package:amici_per_la_coda/features/dogs/dog_share.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';

void main() {
  final now = DateTime.utc(2026, 9, 8);

  test('formatItalianDate usa dd/MM/yyyy', () {
    expect(formatItalianDate(DateTime.utc(2024, 6, 25)), '25/06/2024');
  });

  test('età presunta con mezzo anno', () {
    final dog = testDog(
      dataNascita: DateTime.utc(2023, 1, 10),
      nascitaPresunta: true,
    );
    expect(dogAgeDetailLabel(dog, now), contains('Circa 3 anni e mezzo'));
    expect(dogAgeDetailLabel(dog, now), contains('(10/01/2023 presunta)'));
  });

  test('peso con virgola', () {
    expect(dogPesoLabel(18.5), 'Circa 18,5 kg');
    expect(dogPesoLabel(22), 'Circa 22 kg');
    expect(dogPesoLabel(null), '—');
  });

  test('euro con virgola e due decimali', () {
    expect(formatEuro(715), '€ 715,00');
    expect(formatEuro(18.5), '€ 18,50');
  });

  test('sì / no', () {
    expect(yesNo(true), 'Sì');
    expect(yesNo(false), 'No');
    expect(tagliaLabel(Taglia.media), 'Media');
  });

  test('testo di condivisione: nome, età, carattere', () {
    final dog = testDog(
      nome: '[PROVA] Fenice',
      dataNascita: DateTime.utc(2023, 1, 10),
      nascitaPresunta: true,
      carattere: const ['Dolce', 'Socievole', 'Equilibrata'],
    );
    expect(
      testoCondivisioneScheda(dog, now),
      'Fenice\nCirca 3 anni e mezzo\nDolce, Socievole, Equilibrata',
    );
  });
}
