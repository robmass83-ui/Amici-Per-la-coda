import 'dart:io';

import 'package:amici_per_la_coda/data/photos/photo_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dog_list_tile non importa photosByDogProvider', () {
    final source = File('lib/features/dogs/dog_list_tile.dart')
        .readAsStringSync();
    expect(source.contains('photosByDogProvider'), isFalse);
    expect(source.contains('photosByDog'), isFalse);
  });

  test('i tetti delle regole restano sopra il codec e sotto 1 MiB', () {
    expect(photoThumbMaxBytes, lessThan(photoThumbRulesMaxBytes));
    expect(photoFullMaxBytes, lessThan(photoFullRulesMaxBytes));
    expect(photoThumbRulesMaxBytes, 25000);
    expect(photoFullRulesMaxBytes, 600000);
    expect(photoFullRulesMaxBytes, lessThan(1024 * 1024));
  });

  test('photo_codec e Photo spiegano i limiti', () {
    final codec = File('lib/data/photos/photo_codec.dart').readAsStringSync();
    expect(codec.contains('firestore.rules'), isTrue);
    expect(codec.contains('1 MiB'), isTrue);
    final photo = File('lib/data/models/photo.dart').readAsStringSync();
    expect(photo.contains('25 KB'), isTrue);
    expect(photo.contains('600 KB'), isTrue);
  });

  test('le regole Firestore tagliano thumb e dati', () {
    final rules = File('backend/firestore.rules').readAsStringSync();
    expect(rules.contains('thumb.size() < 25000'), isTrue);
    expect(rules.contains('dati.size() < 600000'), isTrue);
    expect(rules.contains("'photos'"), isTrue);
  });
}
