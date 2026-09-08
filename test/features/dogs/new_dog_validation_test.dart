import 'package:amici_per_la_coda/features/dogs/new_dog/new_dog_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nome vuoto non è valido', () {
    expect(validateNomeCane(''), 'Inserisci il nome del cane.');
    expect(validateNomeCane('   '), 'Inserisci il nome del cane.');
    expect(validateNomeCane('Fenice'), isNull);
  });

  test('microchip accetta vuoto o esattamente 15 cifre', () {
    expect(validateMicrochip(''), isNull);
    expect(validateMicrochip('380260170123456'), isNull);
    expect(validateMicrochip('123'), 'Il microchip deve avere 15 cifre.');
    expect(
      validateMicrochip('3802601701234567'),
      'Il microchip deve avere 15 cifre.',
    );
    expect(
      validateMicrochip('38026017012345a'),
      'Il microchip deve avere 15 cifre.',
    );
  });

  test('estrae 15 cifre da un codice con caratteri extra', () {
    expect(extractMicrochipDigits('380260170123456'), '380260170123456');
    expect(extractMicrochipDigits('MC 380260170123456'), '380260170123456');
    expect(extractMicrochipDigits('123'), isNull);
  });

  test('data ingresso obbligatoria', () {
    expect(validateDataIngresso(null), 'Inserisci la data di ingresso.');
    expect(validateDataIngresso(DateTime(2026, 9, 8)), isNull);
  });
}
