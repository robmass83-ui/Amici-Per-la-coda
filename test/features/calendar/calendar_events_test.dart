import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/features/calendar/calendar_events.dart';
import 'package:amici_per_la_coda/ui/tokens.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';

void main() {
  test('un vaccino con scadenza al 15/09 crea un evento il 15/09', () {
    final events = calendarEventsFrom(
      appointments: const [],
      health: [
        testHealth(
          id: 'vax-zeus',
          dogId: 'zeus',
          tipo: HealthTipo.vaccino,
          descrizione: 'Richiamo vaccino',
          prossimaScadenza: DateTime(2026, 9, 15),
        ),
      ],
      dogs: [testDog(id: 'zeus', nome: 'Zeus')],
      adoptions: const [],
    );

    expect(events, hasLength(1));
    expect(calendarDay(events.single.at), DateTime(2026, 9, 15));
    expect(events.single.title, 'Richiamo vaccino · Zeus');
    expect(events.single.dot, CalendarDotKind.vet);
    expect(events.single.accent, AppColor.blue);
    expect(events.single.source, CalendarEventSource.health);
  });

  test('la griglia del mese è sempre di 42 celle lunedì-domenica', () {
    final september = monthGridDays(DateTime(2026, 9));
    expect(september, hasLength(42));
    expect(september.first, DateTime(2026, 8, 31));
    expect(september[1], DateTime(2026, 9, 1));
    expect(september.last.month, 10);

    final february = monthGridDays(DateTime(2026, 2));
    expect(february, hasLength(42));
    expect(february.first.weekday, DateTime.monday);

    final october = monthGridDays(DateTime(2026, 10));
    expect(october, hasLength(42));
  });

  test('appuntamento annullato e cane archiviato non generano eventi', () {
    final events = calendarEventsFrom(
      appointments: [
        testAppointment(
          id: 'skip',
          stato: AppointmentStato.annullato,
          inizio: DateTime(2026, 9, 8, 10),
        ),
      ],
      health: [
        testHealth(
          dogId: 'old',
          tipo: HealthTipo.vaccino,
          prossimaScadenza: DateTime(2026, 9, 15),
        ),
      ],
      dogs: [testDog(id: 'old', nome: 'Archivio', archiviato: true)],
      adoptions: const [],
    );
    expect(events, isEmpty);
  });

  test('fine preaffido diventa un evento arancione tutto il giorno', () {
    final events = calendarEventsFrom(
      appointments: const [],
      health: const [],
      dogs: [testDog(id: 'otto', nome: 'Otto')],
      adoptions: [
        testAdoption(
          id: 'ad-otto',
          dogId: 'otto',
          stato: AdoptionStato.preaffido,
          preaffidoAl: DateTime(2026, 9, 20),
        ),
      ],
    );
    expect(events, hasLength(1));
    expect(calendarDay(events.single.at), DateTime(2026, 9, 20));
    expect(events.single.allDay, isTrue);
    expect(events.single.dot, CalendarDotKind.affido);
    expect(events.single.title, 'Fine preaffido · Otto');
  });
}
