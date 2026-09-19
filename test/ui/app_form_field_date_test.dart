import 'package:amici_per_la_coda/core/format_it.dart';
import 'package:amici_per_la_coda/ui/components.dart';
import 'package:amici_per_la_coda/ui/form_pickers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('si digita gg/mm/aaaa nel campo data', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppFormField(
            label: 'Data di nascita',
            hint: 'gg/mm/aaaa',
            controller: controller,
            keyboardType: TextInputType.datetime,
            suffix: dateFieldSuffix(),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '19/09/2026');
    expect(controller.text, '19/09/2026');
    expect(parseItalianDate(controller.text), DateTime(2026, 9, 19));
  });

  testWidgets('icona calendario apre il date picker', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: AppFormField(
                label: 'Data di nascita',
                hint: 'gg/mm/aaaa',
                controller: controller,
                suffix: dateFieldSuffix(
                  onTap: () => pickDogFormDate(context, controller, null),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('form-date-suffix')));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
  });
}
