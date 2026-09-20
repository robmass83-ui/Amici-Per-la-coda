import 'package:flutter/material.dart';

import '../../core/format_it.dart';
import '../../data/models/adoption.dart';
import '../../data/models/appointment.dart';
import '../../data/models/dog.dart';
import '../../data/models/enums.dart';
import '../../data/models/health_record.dart';
import '../../ui/icons.dart';
import '../../ui/tokens.dart';
import '../dogs/dog_labels.dart';
import '../dogs/health_labels.dart';
import '../dogs/tab_labels.dart';

enum CalendarDotKind { affido, vet }

enum CalendarEventSource { appointment, health, preaffido }

class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.at,
    required this.allDay,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.source,
    this.dot,
    this.appointment,
    this.dogId,
    this.adoptionId,
  });

  final String id;
  final DateTime at;
  final bool allDay;
  final String title;
  final String subtitle;
  final Color accent;
  final AppIconSpec icon;
  final CalendarEventSource source;
  final CalendarDotKind? dot;
  final Appointment? appointment;
  final String? dogId;
  final String? adoptionId;
}

DateTime calendarDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool sameCalendarDay(DateTime a, DateTime b) => calendarDay(a) == calendarDay(b);

/// Lunedì-domenica, sempre 42 celle (6 settimane), mesi adiacenti inclusi.
List<DateTime> monthGridDays(DateTime month) {
  final first = DateTime(month.year, month.month, 1);
  final monday = DateTime(
    first.year,
    first.month,
    first.day - (first.weekday - DateTime.monday),
  );
  return [
    for (var i = 0; i < 42; i++)
      DateTime(monday.year, monday.month, monday.day + i),
  ];
}

const calendarWeekdays = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];

List<CalendarEvent> calendarEventsFrom({
  required List<Appointment> appointments,
  required List<HealthRecord> health,
  required List<Dog> dogs,
  required List<Adoption> adoptions,
}) {
  final events = <CalendarEvent>[
    ..._fromAppointments(appointments, dogs),
    ..._fromHealth(health, dogs),
    ..._fromPreaffido(adoptions, dogs),
  ];
  events.sort((a, b) => a.at.compareTo(b.at));
  return events;
}

List<CalendarEvent> eventsOnDay(List<CalendarEvent> events, DateTime day) {
  final needle = calendarDay(day);
  return [
    for (final event in events)
      if (calendarDay(event.at) == needle) event,
  ];
}

List<CalendarEvent> upcomingEvents(
  List<CalendarEvent> events, {
  required DateTime after,
  int max = 4,
}) {
  final start = calendarDay(after).add(const Duration(days: 1));
  final next = [
    for (final event in events)
      if (!calendarDay(event.at).isBefore(start)) event,
  ];
  if (next.length <= max) {
    return next;
  }
  return next.sublist(0, max);
}

Set<CalendarDotKind> calendarDotsOn(
  List<CalendarEvent> events,
  DateTime day,
) {
  return {
    for (final event in events)
      if (sameCalendarDay(event.at, day) && event.dot != null) event.dot!,
  };
}

String calendarTimeLabel(CalendarEvent event) {
  if (event.allDay) {
    return 'tutto il g.';
  }
  return formatItalianTime(event.at);
}

String calendarDaySectionTitle({
  required DateTime selected,
  required DateTime now,
}) {
  if (sameCalendarDay(selected, now)) {
    return 'Oggi · ${formatItalianWeekdayDay(selected)}';
  }
  if (selected.year != now.year || selected.month != now.month) {
    return formatItalianLongDate(selected);
  }
  return formatItalianWeekdayDay(selected);
}

List<CalendarEvent> _fromAppointments(
  List<Appointment> appointments,
  List<Dog> dogs,
) {
  final out = <CalendarEvent>[];
  for (final item in appointments) {
    if (item.stato == AppointmentStato.annullato) {
      continue;
    }
    final nome = _dogName(dogs, item.dogId);
    final titolo = item.titolo.trim().isEmpty
        ? appointmentTipoLabel(item.tipo)
        : item.titolo.trim();
    out.add(
      CalendarEvent(
        id: 'apt-${item.id}',
        at: item.inizio,
        allDay: item.tuttoIlGiorno,
        title: titolo,
        subtitle: _appointmentSubtitle(item, nome),
        accent: _appointmentAccent(item.tipo),
        icon: AppIcons.perAppuntamento(item.tipo.wire),
        source: CalendarEventSource.appointment,
        dot: _appointmentDot(item.tipo),
        appointment: item,
        dogId: item.dogId,
        adoptionId: item.adoptionId,
      ),
    );
  }
  return out;
}

List<CalendarEvent> _fromHealth(List<HealthRecord> health, List<Dog> dogs) {
  final out = <CalendarEvent>[];
  for (final record in health) {
    final scadenza = record.prossimaScadenza;
    if (scadenza == null) {
      continue;
    }
    final dog = _liveDog(dogs, record.dogId);
    if (dog == null) {
      continue;
    }
    final nome = dogDisplayName(dog.nome);
    final head = record.descrizione.trim().isEmpty
        ? healthTipoLabel(record.tipo)
        : record.descrizione.trim();
    final midnight = scadenza.hour == 0 && scadenza.minute == 0;
    out.add(
      CalendarEvent(
        id: 'health-${record.id}',
        at: scadenza,
        allDay: midnight,
        title: nome.isEmpty ? head : '$head · $nome',
        subtitle: healthTipoLabel(record.tipo),
        accent: AppColor.blue,
        icon: _healthIcon(record.tipo),
        source: CalendarEventSource.health,
        dot: CalendarDotKind.vet,
        dogId: dog.id,
      ),
    );
  }
  return out;
}

List<CalendarEvent> _fromPreaffido(List<Adoption> adoptions, List<Dog> dogs) {
  final out = <CalendarEvent>[];
  for (final adoption in adoptions) {
    if (adoption.stato != AdoptionStato.preaffido) {
      continue;
    }
    final al = adoption.preaffidoAl;
    if (al == null) {
      continue;
    }
    final nome = _dogName(dogs, adoption.dogId);
    out.add(
      CalendarEvent(
        id: 'preaffido-${adoption.id}',
        at: al,
        allDay: true,
        title: nome.isEmpty ? 'Fine preaffido' : 'Fine preaffido · $nome',
        subtitle: 'verifica',
        accent: AppColor.orange,
        icon: AppIcons.preaffido,
        source: CalendarEventSource.preaffido,
        dot: CalendarDotKind.affido,
        dogId: adoption.dogId,
        adoptionId: adoption.id,
      ),
    );
  }
  return out;
}

String _appointmentSubtitle(Appointment item, String dogName) {
  final parts = <String>[];
  if (item.luogo.trim().isNotEmpty) {
    parts.add(item.luogo.trim());
  }
  if (parts.isEmpty && dogName.isNotEmpty && !item.titolo.contains(dogName)) {
    parts.add(dogName);
  }
  return parts.join(' · ');
}

Color _appointmentAccent(AppointmentTipo tipo) {
  return switch (tipo) {
    AppointmentTipo.visita || AppointmentTipo.scadenza => AppColor.blue,
    AppointmentTipo.colloquio ||
    AppointmentTipo.verificaPreaffido => AppColor.orange,
    AppointmentTipo.altro => AppColor.muted,
  };
}

CalendarDotKind? _appointmentDot(AppointmentTipo tipo) {
  return switch (tipo) {
    AppointmentTipo.visita || AppointmentTipo.scadenza => CalendarDotKind.vet,
    AppointmentTipo.colloquio ||
    AppointmentTipo.verificaPreaffido => CalendarDotKind.affido,
    AppointmentTipo.altro => null,
  };
}

AppIconSpec _healthIcon(HealthTipo tipo) {
  return switch (tipo) {
    HealthTipo.vaccino => AppIcons.vaccino,
    HealthTipo.visita => AppIcons.visita,
    HealthTipo.esame => AppIcons.esame,
    HealthTipo.terapia => AppIcons.terapia,
    HealthTipo.sterilizzazione => AppIcons.sterilizzato,
    HealthTipo.sverminazione ||
    HealthTipo.antiparassitario => AppIcons.antiparass,
    HealthTipo.altro => AppIcons.visita,
  };
}

String _dogName(List<Dog> dogs, String? id) {
  if (id == null || id.isEmpty) {
    return '';
  }
  for (final dog in dogs) {
    if (dog.id == id) {
      return dogDisplayName(dog.nome);
    }
  }
  return '';
}

Dog? _liveDog(List<Dog> dogs, String id) {
  for (final dog in dogs) {
    if (dog.id == id && !dog.archiviato) {
      return dog;
    }
  }
  return null;
}
