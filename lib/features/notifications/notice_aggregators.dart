import 'package:flutter/material.dart';

import '../../core/format_it.dart';
import '../../data/models/adoption.dart';
import '../../data/models/appointment.dart';
import '../../data/models/dog.dart';
import '../../data/models/enums.dart';
import '../../data/models/health_record.dart';
import '../../ui/icons.dart';
import '../../ui/tokens.dart';
import '../dashboard/home_aggregators.dart';
import '../dogs/dog_labels.dart';
import '../dogs/health_labels.dart';

enum NoticeSeverity { urgente, daFare, info }

class AppNotice {
  const AppNotice({
    required this.id,
    required this.severity,
    required this.icon,
    required this.title,
    required this.body,
    required this.at,
    this.dogId,
    this.adoptionId,
    this.appointmentId,
  });

  final String id;
  final NoticeSeverity severity;
  final AppIconSpec icon;
  final String title;
  final String body;
  final DateTime at;
  final String? dogId;
  final String? adoptionId;
  final String? appointmentId;
}

class NoticeDayGroup {
  const NoticeDayGroup({required this.label, required this.items});

  final String label;
  final List<AppNotice> items;
}

Color noticeAccent(NoticeSeverity severity) {
  return switch (severity) {
    NoticeSeverity.urgente => AppColor.red,
    NoticeSeverity.daFare => AppColor.orange,
    NoticeSeverity.info => AppColor.green,
  };
}

String noticeDayLabel(DateTime at, DateTime now) {
  final day = dateOnly(at);
  final today = dateOnly(now);
  if (day == today) {
    return 'Oggi';
  }
  if (day == today.subtract(const Duration(days: 1))) {
    return 'Ieri';
  }
  return formatItalianDate(day);
}

List<AppNotice> buildNotices({
  required List<Dog> dogs,
  required List<HealthRecord> health,
  required List<Appointment> appointments,
  required List<Adoption> adoptions,
  required DateTime now,
}) {
  final today = dateOnly(now);
  final items = <AppNotice>[
    ..._scadenze(dogs, health, today),
    ..._appuntamenti(dogs, appointments, today),
    ..._preaffidi(dogs, adoptions, today),
    ..._richieste(dogs, adoptions, today),
  ];
  items.sort((a, b) => b.at.compareTo(a.at));
  return items;
}

List<NoticeDayGroup> groupNotices(List<AppNotice> notices, DateTime now) {
  final groups = <String, List<AppNotice>>{};
  final order = <String>[];
  for (final item in notices) {
    final label = noticeDayLabel(item.at, now);
    if (!groups.containsKey(label)) {
      order.add(label);
      groups[label] = [];
    }
    groups[label]!.add(item);
  }
  return [
    for (final label in order)
      NoticeDayGroup(label: label, items: groups[label]!),
  ];
}

List<AppNotice> _scadenze(
  List<Dog> dogs,
  List<HealthRecord> health,
  DateTime today,
) {
  final out = <AppNotice>[];
  for (final record in health) {
    final scadenza = record.prossimaScadenza;
    if (scadenza == null) {
      continue;
    }
    final day = dateOnly(scadenza);
    if (!day.isBefore(today)) {
      continue;
    }
    final dog = _liveDog(dogs, record.dogId);
    if (dog == null) {
      continue;
    }
    final days = today.difference(day).inDays;
    final nome = dogDisplayName(dog.nome);
    out.add(
      AppNotice(
        id: 'health-${record.id}',
        severity: NoticeSeverity.urgente,
        icon: AppIcons.scadenza,
        title: '${healthTipoLabel(record.tipo)} scaduto',
        body: '$nome: scaduto da $days gg.',
        at: scadenza,
        dogId: dog.id,
      ),
    );
  }
  return out;
}

List<AppNotice> _appuntamenti(
  List<Dog> dogs,
  List<Appointment> appointments,
  DateTime today,
) {
  final out = <AppNotice>[];
  for (final item in appointments) {
    if (item.stato == AppointmentStato.annullato) {
      continue;
    }
    if (dateOnly(item.inizio) != today) {
      continue;
    }
    final nome = dogNameById(dogs, item.dogId);
    final titolo = item.titolo.isEmpty ? 'Appuntamento' : item.titolo;
    out.add(
      AppNotice(
        id: 'appt-${item.id}',
        severity: NoticeSeverity.daFare,
        icon: AppIcons.perAppuntamento(item.tipo.wire),
        title: titolo,
        body: nome.isEmpty ? 'Oggi' : '$nome · oggi',
        at: item.inizio,
        appointmentId: item.id,
        dogId: item.dogId,
      ),
    );
  }
  return out;
}

List<AppNotice> _preaffidi(
  List<Dog> dogs,
  List<Adoption> adoptions,
  DateTime today,
) {
  final out = <AppNotice>[];
  final limit = today.add(const Duration(days: 7));
  for (final adoption in adoptions) {
    if (adoption.stato != AdoptionStato.preaffido) {
      continue;
    }
    final al = adoption.preaffidoAl;
    if (al == null) {
      continue;
    }
    final day = dateOnly(al);
    if (day.isBefore(today) || day.isAfter(limit)) {
      continue;
    }
    final nome = dogNameById(dogs, adoption.dogId);
    out.add(
      AppNotice(
        id: 'pre-${adoption.id}',
        severity: NoticeSeverity.daFare,
        icon: AppIcons.preaffido,
        title: 'Preaffido in scadenza',
        body: nome.isEmpty
            ? 'Scade il ${formatItalianDate(al)}'
            : '$nome: scade il ${formatItalianDate(al)}',
        at: al,
        adoptionId: adoption.id,
        dogId: adoption.dogId,
      ),
    );
  }
  return out;
}

List<AppNotice> _richieste(
  List<Dog> dogs,
  List<Adoption> adoptions,
  DateTime today,
) {
  final out = <AppNotice>[];
  for (final adoption in adoptions) {
    if (adoption.stato != AdoptionStato.ricevuta) {
      continue;
    }
    final elapsed = today.difference(dateOnly(adoption.dataRichiesta)).inDays;
    if (elapsed <= 7) {
      continue;
    }
    final nome = dogNameById(dogs, adoption.dogId);
    final who =
        '${adoption.richiedente.nome} ${adoption.richiedente.cognome}'.trim();
    out.add(
      AppNotice(
        id: 'req-${adoption.id}',
        severity: NoticeSeverity.info,
        icon: AppIcons.richieste,
        title: 'Richiesta ferma',
        body: nome.isEmpty ? who : '$who → $nome',
        at: adoption.dataRichiesta,
        adoptionId: adoption.id,
        dogId: adoption.dogId,
      ),
    );
  }
  return out;
}

Dog? _liveDog(List<Dog> dogs, String id) {
  for (final dog in dogs) {
    if (dog.id == id && !dog.archiviato) {
      return dog;
    }
  }
  return null;
}
