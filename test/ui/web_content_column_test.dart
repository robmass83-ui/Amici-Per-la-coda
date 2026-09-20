import 'package:amici_per_la_coda/ui/components/web_content_column.dart';
import 'package:amici_per_la_coda/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('token colonna', () {
    expect(AppDim.webMaxContentWidth, 430);
  });

  testWidgets('viewport larga: colonna 430 centrata', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      const MaterialApp(
        home: WebContentColumn(
          isWebOverride: true,
          child: ColoredBox(color: Colors.red, child: SizedBox.expand()),
        ),
      ),
    );
    final column = tester.getSize(find.byType(ColoredBox).last);
    expect(column.width, AppDim.webMaxContentWidth);
  });

  testWidgets('APK larga: nessuna colonna', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      const MaterialApp(
        home: WebContentColumn(
          isWebOverride: false,
          child: ColoredBox(color: Colors.red, child: SizedBox.expand()),
        ),
      ),
    );
    final box = tester.getSize(find.byType(ColoredBox).last);
    expect(box.width, 1280);
  });
}
