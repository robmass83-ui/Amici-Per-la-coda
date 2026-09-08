import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const systemNavBarH = 48.0;

void simulateSystemNavBar(
  WidgetTester tester, {
  double bottom = systemNavBarH,
}) {
  final physical = bottom * tester.view.devicePixelRatio;
  tester.view.padding = FakeViewPadding(bottom: physical);
  tester.view.viewPadding = FakeViewPadding(bottom: physical);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);
}

void expectAboveSystemNav(WidgetTester tester, Finder finder) {
  expect(finder, findsOneWidget);
  final rect = tester.getRect(finder);
  final screen = tester.getRect(find.byType(Navigator).first);
  expect(
    rect.bottom,
    lessThanOrEqualTo(screen.bottom - systemNavBarH),
    reason:
        '$finder finisce a ${rect.bottom}, sotto o dentro la barra di sistema',
  );
}
