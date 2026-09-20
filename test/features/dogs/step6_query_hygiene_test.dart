import 'dart:io';

import 'package:amici_per_la_coda/features/affido/affido_providers.dart';
import 'package:amici_per_la_coda/features/dashboard/home_providers.dart';
import 'package:amici_per_la_coda/features/dogs/dogs_providers.dart';
import 'package:amici_per_la_coda/features/search/search_providers.dart';
import 'package:amici_per_la_coda/features/stats/stats_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'i listener lunghi non sono autoDispose e il router usa indexedStack',
    () {
      expect(dogsStreamProvider.isAutoDispose, isFalse);
      expect(coverPhotosProvider.isAutoDispose, isFalse);
      expect(volunteersStreamProvider.isAutoDispose, isFalse);
      expect(adoptionsStreamProvider.isAutoDispose, isFalse);
      expect(healthAllProvider.isAutoDispose, isFalse);

      final router = File('lib/router.dart').readAsStringSync();
      expect(router.contains('indexedStack'), isTrue);
      expect(
        File('lib/features/dogs/dogs_providers.dart')
            .readAsStringSync()
            .contains('indexedStack'),
        isTrue,
      );
    },
  );

  test('i provider per-cane e di pagina sono autoDispose', () {
    expect(healthByDogProvider.isAutoDispose, isTrue);
    expect(weightsByDogProvider.isAutoDispose, isTrue);
    expect(sponsorshipsByDogProvider.isAutoDispose, isTrue);
    expect(expensesByDogProvider.isAutoDispose, isTrue);
    expect(notesByDogProvider.isAutoDispose, isTrue);
    expect(documentsByDogProvider.isAutoDispose, isTrue);
    expect(photosByDogProvider.isAutoDispose, isTrue);
    expect(coverPhotoProvider.isAutoDispose, isTrue);
    expect(documentsByAdopterProvider.isAutoDispose, isTrue);
    expect(documentsByAdoptionProvider.isAutoDispose, isTrue);
    expect(expensesAllProvider.isAutoDispose, isTrue);
    expect(sponsorshipsAllProvider.isAutoDispose, isTrue);
    expect(documentsAllProvider.isAutoDispose, isTrue);
    expect(adoptersStreamProvider.isAutoDispose, isTrue);
  });

  test(
    'la lista Animali ascolta healthAll solo se serve il filtro vaccini',
    () {
      final source = File('lib/features/dogs/dogs_page.dart')
          .readAsStringSync();
      expect(source.contains('needsHealthAll'), isTrue);
      expect(source.contains('healthAllProvider'), isTrue);
    },
  );
}
