import 'package:amici_per_la_coda/app.dart';
import 'package:amici_per_la_coda/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('l\'app parte senza eccezioni e con lo sfondo corretto', (
    tester,
  ) async {
    await tester.pumpWidget(const AmiciPerLaCodaApp());

    expect(tester.takeException(), isNull);
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(EmptyHomePage), findsOneWidget);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppColor.bg);
  });
}
