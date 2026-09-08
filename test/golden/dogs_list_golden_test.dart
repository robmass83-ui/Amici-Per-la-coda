import 'package:amici_per_la_coda/features/dogs/dogs_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_support.dart';

void main() {
  const fileName = 'dogs_list_360.png';

  testWidgets('Elenco cani — aspetto bloccato a 360×640', (tester) async {
    await pumpGolden(tester, location: animalsLocation);
    expect(find.byType(DogsPage), findsOneWidget);
    await expectLater(
      find.byType(DogsPage),
      matchesGoldenFile('goldens/$fileName'),
    );
  }, skip: skipUntilPng(fileName));
}
