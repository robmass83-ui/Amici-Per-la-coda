import 'package:amici_per_la_coda/features/dogs/edit_dog_page.dart';
import 'package:amici_per_la_coda/features/dogs/new_dog/new_dog_draft_store.dart';
import 'package:amici_per_la_coda/features/dogs/new_dog/new_dog_wizard_page.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:amici_per_la_coda/ui/components.dart';
import 'package:amici_per_la_coda/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_box_repository.dart';
import '../../helpers/fake_dog_repository.dart';
import '../../helpers/fake_microchip_scanner.dart';
import '../../helpers/fake_volunteer_repository.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/system_nav.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const widths = [320.0, 360.0, 411.0, 430.0];
  final now = DateTime.utc(2026, 9, 8);

  Future<void> pumpEdit(
    WidgetTester tester, {
    Size size = const Size(360, 640),
  }) async {
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    await pumpApp(
      tester,
      auth: auth,
      initialLocation: AppRoutes.dogModifica('fenice'),
      size: size,
      dogs: InMemoryDogRepository(testListDogs()),
      boxes: InMemoryBoxRepository([testBox()]),
      volunteers: InMemoryVolunteerRepository([testVolunteer()]),
      dogListNow: now,
    );
  }

  Future<void> pumpWizard(
    WidgetTester tester, {
    Size size = const Size(360, 1100),
  }) async {
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    await pumpApp(
      tester,
      auth: auth,
      initialLocation: AppRoutes.nuovo,
      size: size,
      dogs: InMemoryDogRepository(),
      boxes: InMemoryBoxRepository([testBox()]),
      volunteers: InMemoryVolunteerRepository([testVolunteer()]),
      drafts: InMemoryDogDraftStore(),
      scanner: FakeMicrochipScanner(),
      dogListNow: now,
    );
  }

  Finder horizontalScrollables() {
    return find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable &&
          axisDirectionToAxis(widget.axisDirection) == Axis.horizontal &&
          widget.restorationId != 'editable',
    );
  }

  void expectCompactControls(WidgetTester tester, Finder root) {
    expect(root, findsOneWidget);
    for (final element in find
        .descendant(of: root, matching: find.byType(AppSegmented))
        .evaluate()) {
      expect(
        tester
            .getSize(find.byElementPredicate((item) => identical(item, element)))
            .height,
        lessThanOrEqualTo(AppDim.segmentedH + 0.5),
      );
    }
    for (final element in find
        .descendant(of: root, matching: find.byType(AppFormField))
        .evaluate()) {
      final field = element.widget as AppFormField;
      if (field.child != null || field.maxLines != 1) {
        continue;
      }
      final box = find.descendant(
        of: find.byElementPredicate((item) => identical(item, element)),
        matching: find.byType(FormInputBox),
      );
      expect(box, findsOneWidget);
      expect(
        tester.getSize(box).height,
        lessThanOrEqualTo(AppDim.formFieldH + 0.5),
      );
    }
  }

  testWidgets(
    '1. il contenuto scorrevole di Modifica cane a 360 dp è sotto i 1050',
    (tester) async {
      await pumpEdit(tester, size: const Size(360, 640));
      expect(find.byType(EditDogPage), findsOneWidget);
      expect(
        tester.getSize(find.byKey(EditDogPage.formListKey)).height,
        lessThan(1050),
      );
    },
  );

  testWidgets('2. Modifica cane non ha bottom nav né FAB', (tester) async {
    await pumpEdit(tester);
    expect(find.byType(EditDogPage), findsOneWidget);
    expect(find.byType(AppBottomNav), findsNothing);
    expect(find.byTooltip('Nuovo'), findsNothing);
  });

  testWidgets(
    '2c. in fondo a Modifica cane il testo resta sopra la barra di sistema',
    (tester) async {
      simulateSystemNavBar(tester);
      await pumpEdit(tester, size: const Size(360, 640));
      expect(find.byType(EditDogPage), findsOneWidget);
      await tester.fling(
        find.byKey(EditDogPage.formListKey),
        const Offset(0, -800),
        2000,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(EditDogPage.ultimaModificaKey), findsOneWidget);
      expectAboveSystemNav(
        tester,
        find.byKey(EditDogPage.ultimaModificaKey),
      );
    },
  );

  testWidgets('2b. il wizard non ha bottom nav né FAB', (tester) async {
    await pumpWizard(tester);
    expect(find.byType(NewDogWizardPage), findsOneWidget);
    expect(find.byType(AppBottomNav), findsNothing);
    expect(find.byTooltip('Nuovo'), findsNothing);
  });

  testWidgets(
    '3. AppSegmented ≤ 32 e campi a riga singola ≤ 34 in Modifica cane',
    (tester) async {
      await pumpEdit(tester, size: const Size(360, 1100));
      expectCompactControls(tester, find.byType(EditDogPage));
    },
  );

  testWidgets(
    '3b. AppSegmented ≤ 32 e campi a riga singola ≤ 34 nel wizard',
    (tester) async {
      await pumpWizard(tester);
      expectCompactControls(tester, find.byType(NewDogWizardPage));
    },
  );

  testWidgets(
    '4. multilinea vuoto è alto 34 e con 4 righe cresce',
    (tester) async {
      await pumpEdit(tester, size: const Size(360, 1100));

      await tester.ensureVisible(find.byKey(EditDogPage.descrizioneKey));
      await tester.enterText(find.byKey(EditDogPage.descrizioneKey), '');
      await tester.pump();

      final emptyBox = find.descendant(
        of: find.byKey(EditDogPage.descrizioneKey),
        matching: find.byType(FormInputBox),
      );
      expect(tester.getSize(emptyBox).height, closeTo(AppDim.formFieldH, 1));

      await tester.enterText(
        find.byKey(EditDogPage.descrizioneKey),
        'uno\ndue\ntre\nquattro',
      );
      await tester.pump();
      expect(
        tester.getSize(emptyBox).height,
        greaterThan(AppDim.formFieldH * 2),
      );
    },
  );

  for (final width in widths) {
    testWidgets(
      '5. Modifica cane a ${width.toInt()} dp senza overflow su FormRow2 e CompatRow',
      (tester) async {
        await pumpEdit(tester, size: Size(width, 1100));
        expect(find.byType(EditDogPage), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(horizontalScrollables(), findsNothing);
        expect(find.byType(FormRow2), findsWidgets);
        await tester.fling(
          find.byKey(EditDogPage.formListKey),
          const Offset(0, -900),
          2000,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(CompatRow), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '5b. wizard a ${width.toInt()} dp senza overflow',
      (tester) async {
        await pumpWizard(tester, size: Size(width, 1100));
        expect(find.byType(NewDogWizardPage), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(horizontalScrollables(), findsNothing);
      },
    );
  }
}
