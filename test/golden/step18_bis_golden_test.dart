import 'dart:async';

import 'package:amici_per_la_coda/features/dogs/add_note_sheet.dart';
import 'package:amici_per_la_coda/features/dogs/add_treatment_sheet.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:amici_per_la_coda/ui/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/dog_fixtures.dart';
import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_dog_repository.dart';
import '../helpers/pump_app.dart';
import 'golden_support.dart';

void main() {
  Future<void> pumpDialog(
    WidgetTester tester,
    Future<void> Function(BuildContext) open,
  ) async {
    tester.view.physicalSize = goldenSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    await pumpApp(
      tester,
      auth: auth,
      initialLocation: AppRoutes.dog('fenice'),
      size: goldenSize,
      dogs: InMemoryDogRepository(testListDogs()),
      dogListNow: now,
    );
    final ctx = tester.element(find.byType(Scaffold).first);
    unawaited(open(ctx));
    await tester.pumpAndSettle();
  }

  testWidgets('Trattamento — aspetto bloccato a 360×640', (tester) async {
    const fileName = 'treatment_dialog_360.png';
    await pumpDialog(
      tester,
      (ctx) => AddTreatmentSheet.open(ctx, dogId: 'fenice'),
    );
    expect(find.byKey(AppDialog.cardKey), findsOneWidget);
    await expectLater(
      find.byKey(AppDialog.cardKey),
      matchesGoldenFile('goldens/$fileName'),
    );
  }, skip: skipUntilPng('treatment_dialog_360.png'));

  testWidgets('Nota — aspetto bloccato a 360×640', (tester) async {
    const fileName = 'nota_dialog_360.png';
    await pumpDialog(
      tester,
      (ctx) => AddNoteSheet.open(ctx, dogId: 'fenice'),
    );
    expect(find.byKey(AppDialog.cardKey), findsOneWidget);
    await expectLater(
      find.byKey(AppDialog.cardKey),
      matchesGoldenFile('goldens/$fileName'),
    );
  }, skip: skipUntilPng('nota_dialog_360.png'));
}
