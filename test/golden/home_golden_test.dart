import 'package:amici_per_la_coda/features/dashboard/empty_home_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_support.dart';

void main() {
  const fileName = 'home_360.png';

  testWidgets('Home — aspetto bloccato a 360×640', (tester) async {
    await pumpGolden(tester, location: homeLocation);
    expect(find.byType(EmptyHomePage), findsOneWidget);
    await expectLater(
      find.byType(EmptyHomePage),
      matchesGoldenFile('goldens/$fileName'),
    );
  }, skip: skipUntilPng(fileName));
}
