import 'package:amici_per_la_coda/features/dogs/edit_dog_page.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_support.dart';

void main() {
  const fileName = 'edit_dog_360.png';

  testWidgets('Modifica cane — aspetto bloccato a 360×640', (tester) async {
    await pumpGolden(tester, location: AppRoutes.dogModifica('fenice'));
    expect(find.byType(EditDogPage), findsOneWidget);
    await expectLater(
      find.byType(EditDogPage),
      matchesGoldenFile('goldens/$fileName'),
    );
  }, skip: skipUntilPng(fileName));
}
