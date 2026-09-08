import '../../core/format_it.dart';
import '../../data/models/adoption.dart';
import '../../data/models/appointment.dart';
import '../../data/models/dog.dart';
import '../../data/models/enums.dart';
import '../../data/models/health_record.dart';
import '../../data/models/shelter_box.dart';
import '../../ui/icons.dart';
import '../dogs/dog_labels.dart';
import '../dogs/health_labels.dart';
import '../dogs/tab_labels.dart';

class TodoItem {
  const TodoItem({
    required this.icon,
    required this.nomeCane,
    required this.resto,
    required this.trailing,
    required this.priority,
  });

  final AppIconSpec icon;
  final String nomeCane;
  final String resto;
  final String trailing;
  final int priority;
}

enum OccupancyKind {
  sottoCapienza,
  oltreCapienza,
  nonConfigurato,
}

class OccupancyDisplay {
  const OccupancyDisplay({
    required this.kind,
    required this.barFill,
    required this.caption,
    this.percentuale,
  });

  final OccupancyKind kind;
  final double barFill;
  final String caption;
  final int? percentuale;

  bool get showBar => kind != OccupancyKind.nonConfigurato;
}

class HomeSummary {
  const HomeSummary({
    required this.caniInRifugio,
    required this.postiTotali,
    required this.occupancy,
    required this.adozioniAnnoCorrente,
    required this.adozioniAnnoPrecedente,
    required this.boxLiberi,
    required this.daFareOggi,
    required this.ultimiArrivi,
    required this.richiesteAperte,
    required this.richiesteNuove,
    required this.databaseVuoto,
  });

  final int caniInRifugio;
  final int postiTotali;
  final OccupancyDisplay occupancy;
  final int adozioniAnnoCorrente;
  final int adozioniAnnoPrecedente;
  final int boxLiberi;
  final List<TodoItem> daFareOggi;
  final List<Dog> ultimiArrivi;
  final List<Adoption> richiesteAperte;
  final int richiesteNuove;
  final bool databaseVuoto;

  int get deltaAdozioni => adozioniAnnoCorrente - adozioniAnnoPrecedente;
}

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

OccupancyDisplay occupazioneDi(int caniInRifugio, int postiTotali) {
  if (postiTotali <= 0) {
    return const OccupancyDisplay(
      kind: OccupancyKind.nonConfigurato,
      barFill: 0,
      caption: 'posti non configurati',
    );
  }
  final ratio = caniInRifugio / postiTotali;
  final barFill = ratio.clamp(0, 1).toDouble();
  if (ratio > 1) {
    return OccupancyDisplay(
      kind: OccupancyKind.oltreCapienza,
      barFill: barFill,
      caption: '$caniInRifugio su $postiTotali posti · oltre capienza',
    );
  }
  final percentuale = (ratio * 100).round();
  return OccupancyDisplay(
    kind: OccupancyKind.sottoCapienza,
    barFill: barFill,
    percentuale: percentuale,
    caption: '$percentuale% dei $postiTotali posti',
  );
}

int caniInRifugioDi(List<Dog> dogs) {
  return dogs
      .where((dog) => !dog.archiviato && dog.stato == DogStato.inRifugio)
      .length;
}

int postiTotaliDi(List<ShelterBox> boxes) {
  var total = 0;
  for (final box in boxes) {
    if (!box.inManutenzione) {
      total += box.capienza;
    }
  }
  return total;
}

int occupantiDelBox(ShelterBox box, List<Dog> dogs) {
  var n = 0;
  for (final dog in dogs) {
    if (dog.archiviato) {
      continue;
    }
    if (dog.settore == box.settore && dog.box == box.numero) {
      n++;
    }
  }
  return n;
}

int boxLiberiDi(List<ShelterBox> boxes, List<Dog> dogs) {
  var n = 0;
  for (final box in boxes) {
    if (box.inManutenzione) {
      continue;
    }
    if (occupantiDelBox(box, dogs) < box.capienza) {
      n++;
    }
  }
  return n;
}

int adozioniDellAnno(List<Adoption> adoptions, int year) {
  var n = 0;
  for (final adoption in adoptions) {
    if (adoption.stato != AdoptionStato.adottato) {
      continue;
    }
    if (adoption.storicoStati.isEmpty) {
      continue;
    }
    if (adoption.storicoStati.last.data.year == year) {
      n++;
    }
  }
  return n;
}

List<Dog> ultimiArriviDi(List<Dog> dogs, {int max = 3}) {
  final live = dogs.where((dog) => !dog.archiviato).toList()
    ..sort((a, b) => b.dataIngresso.compareTo(a.dataIngresso));
  if (live.length <= max) {
    return live;
  }
  return live.sublist(0, max);
}

List<Adoption> richiesteAperteDi(List<Adoption> adoptions, {int max = 2}) {
  final open = adoptions
      .where(
        (item) =>
            item.stato == AdoptionStato.ricevuta ||
            item.stato == AdoptionStato.colloquio,
      )
      .toList()
    ..sort((a, b) => b.dataRichiesta.compareTo(a.dataRichiesta));
  if (open.length <= max) {
    return open;
  }
  return open.sublist(0, max);
}

int richiesteNuoveDi(List<Adoption> adoptions) {
  return adoptions
      .where(
        (item) =>
            item.stato == AdoptionStato.ricevuta ||
            item.stato == AdoptionStato.colloquio,
      )
      .length;
}

String dogNameById(List<Dog> dogs, String? id) {
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

List<TodoItem> daFareOggiDi({
  required List<Dog> dogs,
  required List<HealthRecord> health,
  required List<Appointment> appointments,
  required List<Adoption> adoptions,
  required DateTime now,
  int max = 4,
}) {
  final today = dateOnly(now);
  final items = <TodoItem>[
    ..._scadenzeScadute(dogs, health, today),
    ..._appuntamentiOggi(dogs, appointments, today),
    ..._preaffidiInScadenza(dogs, adoptions, today),
    ..._richiesteFerme(dogs, adoptions, today),
  ];
  if (items.length <= max) {
    return items;
  }
  return items.sublist(0, max);
}

List<TodoItem> _scadenzeScadute(
  List<Dog> dogs,
  List<HealthRecord> health,
  DateTime today,
) {
  final out = <TodoItem>[];
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
    out.add(
      TodoItem(
        icon: AppIcons.scadenza,
        nomeCane: dogDisplayName(dog.nome),
        resto: ' · ${healthTipoLabel(record.tipo)} scaduto da $days gg',
        trailing: '⚠️',
        priority: 1,
      ),
    );
  }
  out.sort((a, b) => a.resto.compareTo(b.resto));
  return out;
}

List<TodoItem> _appuntamentiOggi(
  List<Dog> dogs,
  List<Appointment> appointments,
  DateTime today,
) {
  final out = <TodoItem>[];
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
      TodoItem(
        icon: AppIcons.perAppuntamento(item.tipo.wire),
        nomeCane: nome,
        resto: nome.isEmpty ? titolo : ' · $titolo',
        trailing: formatItalianTime(item.inizio),
        priority: 2,
      ),
    );
  }
  return out;
}

List<TodoItem> _preaffidiInScadenza(
  List<Dog> dogs,
  List<Adoption> adoptions,
  DateTime today,
) {
  final out = <TodoItem>[];
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
      TodoItem(
        icon: AppIcons.preaffido,
        nomeCane: nome,
        resto: nome.isEmpty
            ? 'Preaffido in scadenza'
            : ' · preaffido in scadenza',
        trailing: '→',
        priority: 3,
      ),
    );
  }
  return out;
}

List<TodoItem> _richiesteFerme(
  List<Dog> dogs,
  List<Adoption> adoptions,
  DateTime today,
) {
  final out = <TodoItem>[];
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
      TodoItem(
        icon: AppIcons.richieste,
        nomeCane: who,
        resto: nome.isEmpty ? ' · richiesta ferma' : ' → $nome',
        trailing: '→',
        priority: 4,
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

HomeSummary buildHomeSummary({
  required List<Dog> dogs,
  required List<ShelterBox> boxes,
  required List<Adoption> adoptions,
  required List<HealthRecord> health,
  required List<Appointment> appointments,
  required DateTime now,
}) {
  final cani = caniInRifugioDi(dogs);
  final posti = postiTotaliDi(boxes);
  return HomeSummary(
    caniInRifugio: cani,
    postiTotali: posti,
    occupancy: occupazioneDi(cani, posti),
    adozioniAnnoCorrente: adozioniDellAnno(adoptions, now.year),
    adozioniAnnoPrecedente: adozioniDellAnno(adoptions, now.year - 1),
    boxLiberi: boxLiberiDi(boxes, dogs),
    daFareOggi: daFareOggiDi(
      dogs: dogs,
      health: health,
      appointments: appointments,
      adoptions: adoptions,
      now: now,
    ),
    ultimiArrivi: ultimiArriviDi(dogs),
    richiesteAperte: richiesteAperteDi(adoptions),
    richiesteNuove: richiesteNuoveDi(adoptions),
    databaseVuoto: dogs.isEmpty,
  );
}

String richiestaStatoDescrittivo(Adoption adoption, DateTime now) {
  final days = dateOnly(now).difference(dateOnly(adoption.dataRichiesta)).inDays;
  final stato = adoptionStatoLabel(adoption.stato).toLowerCase();
  if (days <= 0) {
    return 'Inviata oggi · $stato';
  }
  if (days == 1) {
    return 'Inviata ieri · $stato';
  }
  return 'Inviata $days giorni fa · $stato';
}

String richiedenteNome(Adoption adoption) {
  return '${adoption.richiedente.nome} ${adoption.richiedente.cognome}'.trim();
}

String inizialiDi(String nome) {
  final parts = nome
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return '?';
  }
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}

int avatarColorValue(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  if (cleaned.length != 6) {
    return 0xFF157A3C;
  }
  final parsed = int.tryParse(cleaned, radix: 16);
  if (parsed == null) {
    return 0xFF157A3C;
  }
  return 0xFF000000 | parsed;
}
