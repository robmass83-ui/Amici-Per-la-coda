import 'package:amici_per_la_coda/features/dogs/dog_detail_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_support.dart';

void main() {
  const fileName = 'dog_detail_360.png';

  testWidgets('Scheda cane — aspetto bloccato a 360×640', (tester) async {
    await pumpGolden(tester, location: dogLocation('fenice'));
    expect(find.byType(DogDetailPage), findsOneWidget);
    await expectLater(
      find.byType(DogDetailPage),
      matchesGoldenFile('goldens/$fileName'),
    );
  }, skip: skipUntilPng(fileName));
}
