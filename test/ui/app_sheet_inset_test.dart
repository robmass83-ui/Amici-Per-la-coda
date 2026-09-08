import 'package:amici_per_la_coda/ui/components.dart';
import 'package:amici_per_la_coda/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/system_nav.dart';

void main() {
  const galleryKey = Key('sheet-gallery');
  const saveKey = Key('sheet-save');

  Future<void> pumpAndOpen(
    WidgetTester tester, {
    required Future<void> Function(BuildContext context) open,
  }) async {
    simulateSystemNavBar(tester);
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              backgroundColor: AppColor.bg,
              body: TextButton(
                onPressed: () => open(context),
                child: const Text('Apri'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'il menu Aggiungi foto resta sopra la barra di sistema',
    (tester) async {
      await pumpAndOpen(
        tester,
        open: (context) => AppSheet.show<void>(
          context: context,
          title: 'Aggiungi foto',
          children: [
            OptionRow(
              icon: const IconBadge(AppIcons.fotocamera, size: IconBadge.inMenu),
              title: 'Fotocamera',
              subtitle: 'Scatta una foto',
              onTap: () {},
            ),
            OptionRow(
              key: galleryKey,
              icon: const IconBadge(AppIcons.galleria, size: IconBadge.inMenu),
              title: 'Scegli dalla galleria',
              subtitle: 'Selezione multipla',
              onTap: () {},
            ),
          ],
        ),
      );

      expect(find.text('Aggiungi foto'), findsOneWidget);
      expectAboveSystemNav(tester, find.byKey(galleryKey));
      await tester.tap(find.byKey(galleryKey));
    },
  );

  testWidgets(
    'il foglio di caricamento documenti resta sopra la barra di sistema',
    (tester) async {
      await pumpAndOpen(
        tester,
        open: (context) => AppSheet.present<void>(
          context: context,
          builder: (context) {
            return Padding(
              padding: AppDim.pagePad,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Carica documento'),
                  AppButton(key: saveKey, label: 'Salva', onPressed: () {}),
                ],
              ),
            );
          },
        ),
      );

      expect(find.text('Carica documento'), findsOneWidget);
      expectAboveSystemNav(tester, find.byKey(saveKey));
      await tester.tap(find.byKey(saveKey));
    },
  );
}
