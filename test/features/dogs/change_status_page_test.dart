import 'package:amici_per_la_coda/data/models/dog.dart';
import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/features/dogs/change_status_page.dart';
import 'package:amici_per_la_coda/features/dogs/dog_detail_page.dart';
import 'package:amici_per_la_coda/features/dogs/dogs_page.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:amici_per_la_coda/ui/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_dog_repository.dart';
import '../../helpers/fake_volunteer_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  const widths = [320.0, 360.0, 411.0, 430.0];
  final now = DateTime(2026, 9, 8);

  Finder tabLabel(String label) {
    return find.descendant(
      of: find.byKey(DogDetailPage.tabBarKey),
      matching: find.text(label),
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

  Future<InMemoryDogRepository> pumpLogged(
    WidgetTester tester, {
    String location = '/animali/fenice/stato',
    List<Dog>? dogs,
    Size size = const Size(360, 1100),
  }) async {
    final auth = FakeAuthRepository();
    await auth.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    final repo = InMemoryDogRepository(dogs ?? testListDogs());
    await pumpApp(
      tester,
      auth: auth,
      initialLocation: location,
      size: size,
      dogs: repo,
      volunteers: InMemoryVolunteerRepository([testVolunteer()]),
      dogListNow: now,
    );
    return repo;
  }

  testWidgets('cambiando stato la pill nella scheda cambia colore e testo', (
    tester,
  ) async {
    await pumpLogged(tester, location: AppRoutes.dog('fenice'));

    final before = tester.widget<MiniBadge>(
      find.byKey(DogDetailPage.statoPillKey),
    );
    expect(before.label, 'In rifugio');
    expect(before.variant, MiniBadgeVariant.green);

    await tester.ensureVisible(tabLabel('Altro'));
    await tester.tap(tabLabel('Altro'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Cambia stato del cane'));
    await tester.tap(find.text('Cambia stato del cane'));
    await tester.pumpAndSettle();

    expect(find.byType(ChangeStatusPage), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(ChangeStatusPage.optionKey(DogStato.inStallo)),
    );
    await tester.tap(find.byKey(ChangeStatusPage.optionKey(DogStato.inStallo)));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(ChangeStatusPage.noteKey),
      'Trasferita da Giovanna',
    );
    await tester.ensureVisible(find.byKey(ChangeStatusPage.saveKey));
    await tester.tap(find.byKey(ChangeStatusPage.saveKey));
    await tester.pumpAndSettle();

    expect(find.byType(ChangeStatusPage), findsNothing);
    expect(find.byType(DogDetailPage), findsOneWidget);
    final after = tester.widget<MiniBadge>(
      find.byKey(DogDetailPage.statoPillKey, skipOffstage: false),
    );
    expect(after.label, 'In stallo');
    expect(after.variant, MiniBadgeVariant.blue);
  });

  testWidgets('lo storico mostra la voce nuova in cima', (tester) async {
    await pumpLogged(tester);

    await tester.tap(find.byKey(ChangeStatusPage.optionKey(DogStato.inStallo)));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(ChangeStatusPage.noteKey),
      'Trasferita da Giovanna',
    );
    await tester.ensureVisible(find.byKey(ChangeStatusPage.saveKey));
    await tester.tap(find.byKey(ChangeStatusPage.saveKey));
    await tester.pumpAndSettle();

    await tester.ensureVisible(tabLabel('Altro'));
    await tester.tap(tabLabel('Altro'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('08/09/2026 · In stallo'));
    expect(find.text('08/09/2026 · In stallo'), findsOneWidget);
    expect(find.text('Trasferita da Giovanna'), findsOneWidget);
    await tester.ensureVisible(find.text('25/06/2024 · In rifugio'));
    final nuova = tester.getRect(find.text('08/09/2026 · In stallo'));
    final precedente = tester.getRect(find.text('25/06/2024 · In rifugio'));
    expect(nuova.top, lessThan(precedente.top));
  });

  testWidgets('il filtro dell\'elenco riflette subito il nuovo stato', (
    tester,
  ) async {
    await pumpLogged(tester);

    await tester.tap(find.byKey(ChangeStatusPage.optionKey(DogStato.inStallo)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(ChangeStatusPage.saveKey));
    await tester.tap(find.byKey(ChangeStatusPage.saveKey));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Indietro'));
    await tester.pumpAndSettle();
    expect(find.byType(DogsPage), findsOneWidget);

    await tester.tap(find.text('Stallo'));
    await tester.pumpAndSettle();

    expect(find.text('[PROVA] Fenice'), findsOneWidget);
    expect(find.text('[PROVA] Nina'), findsOneWidget);
    expect(find.text('[PROVA] Brando'), findsNothing);
  });

  testWidgets('adottato chiede conferma e Annulla non salva', (tester) async {
    await pumpLogged(tester, location: AppRoutes.dog('fenice'));

    await tester.ensureVisible(tabLabel('Altro'));
    await tester.tap(tabLabel('Altro'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Cambia stato del cane'));
    await tester.tap(find.text('Cambia stato del cane'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(ChangeStatusPage.optionKey(DogStato.adottato)),
    );
    await tester.tap(find.byKey(ChangeStatusPage.optionKey(DogStato.adottato)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(ChangeStatusPage.saveKey));
    await tester.tap(find.byKey(ChangeStatusPage.saveKey));
    await tester.pumpAndSettle();

    expect(find.text('Conferma cambio stato'), findsOneWidget);
    await tester.tap(find.byKey(ChangeStatusPage.cancelKey));
    await tester.pumpAndSettle();

    expect(find.byType(ChangeStatusPage), findsOneWidget);
    await tester.tap(find.byTooltip('Indietro'));
    await tester.pumpAndSettle();
    expect(find.byType(DogDetailPage), findsOneWidget);
    final badge = tester.widget<MiniBadge>(
      find.byKey(DogDetailPage.statoPillKey, skipOffstage: false),
    );
    expect(badge.label, 'In rifugio');
  });

  testWidgets('confermando adottato la pill diventa Adottato', (tester) async {
    await pumpLogged(tester);

    await tester.ensureVisible(
      find.byKey(ChangeStatusPage.optionKey(DogStato.adottato)),
    );
    await tester.tap(find.byKey(ChangeStatusPage.optionKey(DogStato.adottato)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(ChangeStatusPage.saveKey));
    await tester.tap(find.byKey(ChangeStatusPage.saveKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ChangeStatusPage.confirmKey));
    await tester.pumpAndSettle();

    final badge = tester.widget<MiniBadge>(
      find.byKey(DogDetailPage.statoPillKey),
    );
    expect(badge.label, 'Adottato');
    expect(badge.variant, MiniBadgeVariant.purple);
  });

  for (final width in widths) {
    testWidgets(
      'cambio stato a ${width.toInt()} dp senza overflow né scroll orizzontale',
      (tester) async {
        await pumpLogged(
          tester,
          dogs: [
            testDog(
              id: 'fenice',
              nome: 'SupercalifragilistichespiralidosoFeniceLunghissima',
              settore: 'B',
              box: '7',
            ),
          ],
          size: Size(width, 1100),
        );

        expect(find.byType(ChangeStatusPage), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(horizontalScrollables(), findsNothing);

        await tester.fling(find.byType(ListView), const Offset(0, -400), 2000);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
