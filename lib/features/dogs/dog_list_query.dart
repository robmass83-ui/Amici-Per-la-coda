import '../../data/dog_archive.dart';
import '../../data/models/dog.dart';
import '../../data/models/enums.dart';
import '../../data/models/health_record.dart';

const dogListPageSize = 20;

enum DogQuickFilter { inRifugio, inStallo, adottabili, cuccioli, adottati }

const dogQuickFilterLabels = [
  'Rifugio',
  'Stallo',
  'Adottab.',
  'Cuccioli',
  'Adottati',
];

const dogQuickFilterTooltips = [
  'In rifugio',
  'In stallo',
  'Adottabili',
  'Cuccioli',
  'Adottati',
];

enum DogListSort { nomeAz, ingressoDesc, permanenza }

enum DogSessoEta { femmine, maschi, cuccioli, senior }

enum DogSanitario { sterilizzati, daSterilizzare, vacciniScaduti, inTerapia }

enum DogCompat { cani, gatti, bambini }

class DogListFilters {
  const DogListFilters({
    this.stati = const <DogStato>{},
    this.taglie = const <Taglia>{},
    this.sessoEta = const <DogSessoEta>{},
    this.sanitari = const <DogSanitario>{},
    this.compatibilita = const <DogCompat>{},
    this.sort = DogListSort.nomeAz,
  });

  final Set<DogStato> stati;
  final Set<Taglia> taglie;
  final Set<DogSessoEta> sessoEta;
  final Set<DogSanitario> sanitari;
  final Set<DogCompat> compatibilita;
  final DogListSort sort;

  bool get isActive =>
      stati.isNotEmpty ||
      taglie.isNotEmpty ||
      sessoEta.isNotEmpty ||
      sanitari.isNotEmpty ||
      compatibilita.isNotEmpty ||
      sort != DogListSort.nomeAz;

  /// Solo il filtro vaccini scaduti legge `healthAllProvider`.
  bool get needsHealthAll => sanitari.contains(DogSanitario.vacciniScaduti);

  DogListFilters copyWith({
    Set<DogStato>? stati,
    Set<Taglia>? taglie,
    Set<DogSessoEta>? sessoEta,
    Set<DogSanitario>? sanitari,
    Set<DogCompat>? compatibilita,
    DogListSort? sort,
  }) {
    return DogListFilters(
      stati: stati ?? this.stati,
      taglie: taglie ?? this.taglie,
      sessoEta: sessoEta ?? this.sessoEta,
      sanitari: sanitari ?? this.sanitari,
      compatibilita: compatibilita ?? this.compatibilita,
      sort: sort ?? this.sort,
    );
  }
}

List<Dog> filterDogs(
  List<Dog> dogs, {
  required String query,
  DogQuickFilter? filter,
  required DateTime now,
  DogListFilters extra = const DogListFilters(),
  List<HealthRecord> health = const [],
}) {
  final needle = query.trim().toLowerCase();
  final filtered = dogs.where((dog) {
    if (!_matchesFilter(dog, filter, now)) {
      return false;
    }
    if (!_matchesExtra(dog, extra, health, now)) {
      return false;
    }
    if (needle.isEmpty) {
      return true;
    }
    return dogMatchesQuery(dog, needle);
  }).toList();
  _sortDogs(filtered, extra.sort);
  return filtered;
}

List<Dog> pageDogs(List<Dog> dogs, int visibleCount) {
  if (visibleCount >= dogs.length) {
    return List<Dog>.of(dogs);
  }
  return dogs.take(visibleCount).toList();
}

bool dogMatchesQuery(Dog dog, String needle) {
  final boxKeys = <String>{
    dog.nome,
    dog.microchip,
    dog.box,
    dog.settore,
    '${dog.settore}${dog.box}',
    '${dog.settore} ${dog.box}',
    '${dog.settore}-${dog.box}',
  };
  return boxKeys.any((value) => value.toLowerCase().contains(needle));
}

bool isCucciolo(Dog dog, DateTime now) {
  final birth = dog.dataNascita;
  if (birth == null) {
    return false;
  }
  return now.difference(birth).inDays < 365;
}

bool isSenior(Dog dog, DateTime now) {
  final birth = dog.dataNascita;
  if (birth == null) {
    return false;
  }
  return now.difference(birth).inDays ~/ 365 >= 8;
}

int countForFilter(
  List<Dog> dogs,
  DogQuickFilter filter,
  DateTime now, {
  DogListFilters extra = const DogListFilters(),
  List<HealthRecord> health = const [],
}) {
  return dogs
      .where(
        (dog) =>
            _matchesExtra(dog, extra, health, now) &&
            _matchesFilter(dog, filter, now),
      )
      .length;
}

bool _matchesFilter(Dog dog, DogQuickFilter? filter, DateTime now) {
  if (filter == DogQuickFilter.adottati) {
    return dog.stato == DogStato.adottato;
  }
  if (dogInArchivio(dog)) {
    return false;
  }
  return switch (filter) {
    null => true,
    DogQuickFilter.inRifugio => dog.stato == DogStato.inRifugio,
    DogQuickFilter.inStallo => dog.stato == DogStato.inStallo,
    DogQuickFilter.adottabili => dog.adottabile == true,
    DogQuickFilter.cuccioli => isCucciolo(dog, now),
    DogQuickFilter.adottati => false,
  };
}

bool _matchesExtra(
  Dog dog,
  DogListFilters extra,
  List<HealthRecord> health,
  DateTime now,
) {
  if (extra.stati.isNotEmpty && !extra.stati.contains(dog.stato)) {
    return false;
  }
  if (extra.taglie.isNotEmpty && !extra.taglie.contains(dog.taglia)) {
    return false;
  }
  if (extra.sessoEta.isNotEmpty &&
      !extra.sessoEta.any((item) => _matchesSessoEta(dog, item, now))) {
    return false;
  }
  if (extra.sanitari.isNotEmpty &&
      !extra.sanitari.any(
        (item) => _matchesSanitario(dog, item, health, now),
      )) {
    return false;
  }
  if (extra.compatibilita.isNotEmpty &&
      !extra.compatibilita.any((item) => _matchesCompat(dog, item))) {
    return false;
  }
  return true;
}

bool _matchesSessoEta(Dog dog, DogSessoEta item, DateTime now) {
  return switch (item) {
    DogSessoEta.femmine => dog.sesso == DogSex.F,
    DogSessoEta.maschi => dog.sesso == DogSex.M,
    DogSessoEta.cuccioli => isCucciolo(dog, now),
    DogSessoEta.senior => isSenior(dog, now),
  };
}

bool _matchesSanitario(
  Dog dog,
  DogSanitario item,
  List<HealthRecord> health,
  DateTime now,
) {
  return switch (item) {
    DogSanitario.sterilizzati => dog.sterilizzato == true,
    DogSanitario.daSterilizzare => dog.sterilizzato == false,
    DogSanitario.vacciniScaduti => _vaccinoScaduto(dog, health, now),
    DogSanitario.inTerapia => dog.stato == DogStato.inCura,
  };
}

bool _matchesCompat(Dog dog, DogCompat item) {
  return switch (item) {
    DogCompat.cani => dog.conCani == ConCani.si,
    DogCompat.gatti => dog.conGatti == ConGatti.si,
    DogCompat.bambini => dog.conBambini == ConBambini.si,
  };
}

bool _vaccinoScaduto(Dog dog, List<HealthRecord> health, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  for (final record in health) {
    if (record.dogId != dog.id || record.tipo != HealthTipo.vaccino) {
      continue;
    }
    final scadenza = record.prossimaScadenza;
    if (scadenza == null) {
      continue;
    }
    final day = DateTime(scadenza.year, scadenza.month, scadenza.day);
    if (day.isBefore(today)) {
      return true;
    }
  }
  return false;
}

void _sortDogs(List<Dog> dogs, DogListSort sort) {
  dogs.sort((a, b) {
    return switch (sort) {
      DogListSort.nomeAz => a.nome.toLowerCase().compareTo(
        b.nome.toLowerCase(),
      ),
      DogListSort.ingressoDesc => b.dataIngresso.compareTo(a.dataIngresso),
      DogListSort.permanenza => a.dataIngresso.compareTo(b.dataIngresso),
    };
  });
}

String resultCountLabel(int count) {
  if (count == 1) {
    return '1 risultato';
  }
  return '$count risultati';
}
