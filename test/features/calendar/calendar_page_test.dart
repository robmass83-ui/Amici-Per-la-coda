import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/data/repositories/data_repositories.dart';
import 'package:amici_per_la_coda/features/calendar/calendar_page.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:amici_per_la_coda/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';
import '../../helpers/fake_appointment_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_dog_repository.dart';
import '../../helpers/fake_health_repository.dart';
import '../../helpers/fake_volunteer_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  const widths = [320.0, 360.0, 411.0, 430.0];
  final now = DateTime(2026, 9, 8, 9, 0);

  Finder dayCells() {
    return find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> &&
          key.value.startsWith('calendar-cell-');
    });
  }

  Finder horizontalScrollables() {
    return find.byWidgetPredicate((widget) {
      if (widget is! Scrollable) {
        return false;
      }
      if (axisDirectionToAxis(widget.axisDirection) != Axis.horizontal) {
        return false;
      }
      return widget.restorationId != 'editable';
    });
  }

  Future<void> pumpCalendar(
    WidgetTester tester, {
    Size size = const Size(360, 900),
    HealthRepository? health,
    AppointmentRepository? appointments,
    VolunteerRepository? volunteers,
    FakeAuthRepository? auth,
  }) async {
    final signed = auth ?? FakeAuthRepository();
    if (signed.currentUser == null) {
      await signed.signIn(
        email: 'giovanna@amiciperlacoda.it',
        password: 'corretta',
      );
    }
    await pumpApp(
      tester,
      auth: signed,
      size: size,
      initialLocation: AppRoutes.calendario,
      dogs: InMemoryDogRepository(testListDogs()),
      health: health ?? InMemoryHealthRepository(),
      appointments: appointments ?? InMemoryAppointmentRepository(),
      volunteers: volunteers,
      dogListNow: now,
    );
  }

  testWidgets('un vaccino in scadenza il 15/09 compare nel calendario', (
    tester,
  ) async {
    await pumpCalendar(
      tester,
      health: InMemoryHealthRepository([
        testHealth(
          id: 'vax-zeus',
          dogId: 'zeus',
          tipo: HealthTipo.vaccino,
          descrizione: 'Richiamo vaccino',
          prossimaScadenza: DateTime(2026, 9, 15),
        ),
      ]),
    );

    expect(find.byType(CalendarPage), findsOneWidget);
    expect(find.textContaining('15/09'), findsWidgets);
    expect(find.textContaining('Richiamo vaccino · Zeus'), findsOneWidget);

    await tester.tap(find.byKey(CalendarPage.dayKey(DateTime(2026, 9, 15))));
    await tester.pumpAndSettle();
    expect(find.textContaining('martedì 15'), findsOneWidget);
    expect(find.text('tutto il g.'), findsWidgets);
  });

  testWidgets('cambiando mese la griglia resta di 6 righe (42 celle)', (
    tester,
  ) async {
    await pumpCalendar(tester);

    expect(dayCells(), findsNWidgets(42));
    expect(find.text('Settembre 2026'), findsOneWidget);

    await tester.tap(find.byKey(CalendarPage.nextKey));
    await tester.pump();
    expect(dayCells(), findsNWidgets(42));
    expect(find.text('Ottobre 2026'), findsOneWidget);

    await tester.tap(find.byKey(CalendarPage.prevKey));
    await tester.pump();
    await tester.tap(find.byKey(CalendarPage.prevKey));
    await tester.pump();
    expect(dayCells(), findsNWidgets(42));
    expect(find.text('Agosto 2026'), findsOneWidget);
  });

  testWidgets('il giorno corrente è evidenziato in verde', (tester) async {
    await pumpCalendar(tester);

    expect(find.byKey(CalendarPage.todayKey), findsOneWidget);
    final material = tester.widget<Material>(
      find.byKey(CalendarPage.todayKey),
    );
    expect(material.color, AppColor.green);

    await tester.tap(find.byKey(CalendarPage.dayKey(DateTime(2026, 9, 12))));
    await tester.pump();
    expect(tester.widget<Material>(find.byKey(CalendarPage.todayKey)).color, AppColor.green);
  });

  for (final width in widths) {
    testWidgets(
      'griglia calendario a ${width.toInt()} dp senza overflow né scroll orizzontale',
      (tester) async {
        await pumpCalendar(
          tester,
          size: Size(width, 900),
          health: InMemoryHealthRepository([
            testHealth(
              dogId: 'zeus',
              tipo: HealthTipo.vaccino,
              descrizione: 'Richiamo vaccino',
              prossimaScadenza: DateTime(2026, 9, 15),
            ),
          ]),
          appointments: InMemoryAppointmentRepository([
            testAppointment(
              titolo: 'Visita veterinaria · Nina',
              dogId: 'nina',
              inizio: DateTime(2026, 9, 8, 16),
            ),
          ]),
        );

        expect(find.byType(CalendarPage), findsOneWidget);
        expect(dayCells(), findsNWidgets(42));
        expect(tester.takeException(), isNull);
        expect(horizontalScrollables(), findsNothing);
      },
    );
  }

  testWidgets('il presidente vede Nuovo appuntamento', (tester) async {
    await pumpCalendar(tester);
    expect(find.byKey(CalendarPage.addKey), findsOneWidget);
    expect(find.text('Nuovo appuntamento'), findsOneWidget);
  });

  testWidgets('il volontario non vede Nuovo appuntamento', (tester) async {
    await pumpCalendar(
      tester,
      volunteers: InMemoryVolunteerRepository([
        testVolunteer(ruolo: VolunteerRuolo.volontario),
      ]),
    );
    expect(find.byKey(CalendarPage.addKey), findsNothing);
    expect(find.text('Nuovo appuntamento'), findsNothing);
  });
}
