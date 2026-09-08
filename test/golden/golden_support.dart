import 'dart:io';

import 'package:amici_per_la_coda/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/dog_fixtures.dart';
import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_dog_repository.dart';
import '../helpers/pump_app.dart';

const goldenSize = Size(360, 640);

final now = DateTime.utc(2026, 9, 8);

/// I PNG si creano solo con `flutter test --update-goldens` dopo l'ok visivo.
bool goldenPngReady(String fileName) {
  return File('test/golden/goldens/$fileName').existsSync();
}

/// `true` se il confronto PNG va saltato (file non ancora bloccato).
bool skipUntilPng(String fileName) {
  return !autoUpdateGoldenFiles && !goldenPngReady(fileName);
}

Future<void> pumpGolden(
  WidgetTester tester, {
  required String location,
}) async {
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
    initialLocation: location,
    size: goldenSize,
    dogs: InMemoryDogRepository(testListDogs()),
    dogListNow: now,
  );
}

const homeLocation = AppRoutes.home;
const animalsLocation = AppRoutes.animali;
String dogLocation(String id) => AppRoutes.dog(id);
