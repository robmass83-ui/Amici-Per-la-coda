import '../../data/models/adoption.dart';
import '../../data/models/association_settings.dart';
import '../../data/models/dog.dart';
import '../../data/models/enums.dart';
import '../../data/models/health_record.dart';
import '../dashboard/home_aggregators.dart';
import '../dogs/dog_labels.dart';
import '../dogs/health_labels.dart';

const localNoticeHour = 8;

enum LocalNoticeRepeat { none, daily, weeklyMonday }

class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    this.payload,
    this.repeat = LocalNoticeRepeat.none,
  });

  final int id;
  final DateTime at;
  final String title;
  final String body;
  final String? payload;
  final LocalNoticeRepeat repeat;
}

class NotificationSwitches {
  const NotificationSwitches({
    this.scadenzeSanitarie = true,
    this.nuoveRichieste = true,
    this.scadenzaPreaffidi = true,
    this.riepilogoSettimanale = false,
  });

  final bool scadenzeSanitarie;
  final bool nuoveRichieste;
  final bool scadenzaPreaffidi;
  final bool riepilogoSettimanale;

  factory NotificationSwitches.fromSettings(AssociationSettings? settings) {
    return NotificationSwitches(
      scadenzeSanitarie: settings?.notificheScadenzeSanitarie ?? true,
      nuoveRichieste: settings?.notificheNuoveRichieste ?? true,
      scadenzaPreaffidi: settings?.notificheScadenzaPreaffidi ?? true,
      riepilogoSettimanale: settings?.notificheRiepilogoSettimanale ?? false,
    );
  }
}

DateTime atEight(DateTime day) =>
    DateTime(day.year, day.month, day.day, localNoticeHour);

DateTime nextEightAm(DateTime now) {
  final todayEight = atEight(now);
  if (!now.isAfter(todayEight)) {
    return todayEight;
  }
  return atEight(now.add(const Duration(days: 1)));
}

DateTime nextMondayEight(DateTime now) {
  final today = dateOnly(now);
  var daysUntilMonday = DateTime.monday - today.weekday;
  if (daysUntilMonday < 0) {
    daysUntilMonday += 7;
  }
  var monday = today.add(Duration(days: daysUntilMonday));
  var at = atEight(monday);
  if (!now.isBefore(at)) {
    monday = monday.add(const Duration(days: 7));
    at = atEight(monday);
  }
  return at;
}

List<PlannedNotification> buildLocalNotificationPlan({
  required List<Dog> dogs,
  required List<HealthRecord> health,
  required List<Adoption> adoptions,
  required NotificationSwitches switches,
  required DateTime now,
}) {
  final today = dateOnly(now);
  final digestAt = nextEightAm(now);
  final out = <PlannedNotification>[];

  if (switches.scadenzeSanitarie) {
    final due = <_HealthDue>[];
    for (final record in health) {
      final scadenza = record.prossimaScadenza;
      if (scadenza == null) {
        continue;
      }
      final dog = _liveDog(dogs, record.dogId);
      if (dog == null) {
        continue;
      }
      final day = dateOnly(scadenza);
      if (day.isAfter(today)) {
        out.add(
          PlannedNotification(
            id: _healthId(record.id),
            at: atEight(day),
            title: _healthTitle(record.tipo),
            body: _healthBody(dog, record, today: day),
            payload: 'dog:${dog.id}',
          ),
        );
        continue;
      }
      due.add(_HealthDue(record: record, dog: dog, day: day));
    }
    if (due.isNotEmpty) {
      out.add(_healthDigest(due, today, digestAt));
    }
  }

  if (switches.scadenzaPreaffidi) {
    final limit = today.add(const Duration(days: 7));
    final due = <Adoption>[];
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
      due.add(adoption);
    }
    if (due.length == 1) {
      final adoption = due.first;
      final nome = dogNameById(dogs, adoption.dogId);
      out.add(
        PlannedNotification(
          id: _preId(adoption.id),
          at: digestAt,
          title: 'Preaffido in scadenza',
          body: nome.isEmpty
              ? 'Pianifica la verifica'
              : '$nome: pianifica la verifica',
          payload: 'adoption:${adoption.id}',
          repeat: LocalNoticeRepeat.daily,
        ),
      );
    } else if (due.length > 1) {
      out.add(
        PlannedNotification(
          id: 1002,
          at: digestAt,
          title: 'Preaffidi in scadenza',
          body: '${due.length} preaffidi entro 7 giorni',
          repeat: LocalNoticeRepeat.daily,
        ),
      );
    }
  }

  if (switches.nuoveRichieste) {
    final fresh = adoptions.where((adoption) {
      if (adoption.stato != AdoptionStato.ricevuta) {
        return false;
      }
      return now.difference(adoption.dataRichiesta).inHours <= 24;
    }).toList();
    if (fresh.isNotEmpty) {
      out.add(
        PlannedNotification(
          id: 1003,
          at: digestAt,
          title: fresh.length == 1
              ? 'Nuova richiesta di adozione'
              : 'Nuove richieste di adozione',
          body: fresh.length == 1
              ? '${fresh.first.richiedente.nome} ${fresh.first.richiedente.cognome}'
                    .trim()
              : '${fresh.length} richieste nelle ultime 24 ore',
          payload: fresh.length == 1 ? 'adoption:${fresh.first.id}' : null,
        ),
      );
    }
  }

  if (switches.riepilogoSettimanale) {
    final nHealth = health.where((record) {
      final scadenza = record.prossimaScadenza;
      if (scadenza == null) {
        return false;
      }
      return !dateOnly(scadenza).isAfter(today);
    }).length;
    out.add(
      PlannedNotification(
        id: 1001,
        at: nextMondayEight(now),
        title: 'Riepilogo settimanale',
        body: nHealth == 0
            ? 'Nessuna scadenza sanitaria in ritardo'
            : '$nHealth scadenze sanitarie da aggiornare',
        repeat: LocalNoticeRepeat.weeklyMonday,
      ),
    );
  }

  return out;
}

class _HealthDue {
  const _HealthDue({
    required this.record,
    required this.dog,
    required this.day,
  });

  final HealthRecord record;
  final Dog dog;
  final DateTime day;
}

PlannedNotification _healthDigest(
  List<_HealthDue> due,
  DateTime today,
  DateTime digestAt,
) {
  if (due.length == 1) {
    final item = due.first;
    return PlannedNotification(
      id: 1000,
      at: digestAt,
      title: _healthTitle(item.record.tipo),
      body: _healthBody(item.dog, item.record, today: today),
      payload: 'dog:${item.dog.id}',
      repeat: LocalNoticeRepeat.daily,
    );
  }
  return PlannedNotification(
    id: 1000,
    at: digestAt,
    title: 'Scadenze sanitarie',
    body: '${due.length} scadenze da aggiornare',
    repeat: LocalNoticeRepeat.daily,
  );
}

String _healthTitle(HealthTipo tipo) {
  if (tipo == HealthTipo.vaccino) {
    return 'Scadenza vaccino';
  }
  return 'Scadenza sanitaria';
}

String _healthBody(Dog dog, HealthRecord record, {required DateTime today}) {
  final nome = dogDisplayName(dog.nome);
  final tipo = healthTipoLabel(record.tipo).toLowerCase();
  final day = dateOnly(record.prossimaScadenza!);
  if (day == today) {
    return '$nome · $tipo scade oggi';
  }
  final days = today.difference(day).inDays;
  return '$nome · $tipo scaduto da $days gg';
}

int _healthId(String id) => 2000 + (id.hashCode.abs() % 7000);

int _preId(String id) => 9000 + (id.hashCode.abs() % 900);

Dog? _liveDog(List<Dog> dogs, String id) {
  for (final dog in dogs) {
    if (dog.id == id && !dog.archiviato) {
      return dog;
    }
  }
  return null;
}
