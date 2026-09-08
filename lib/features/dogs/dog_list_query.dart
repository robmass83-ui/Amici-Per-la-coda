import '../../data/models/dog.dart';
import '../../data/models/enums.dart';

const dogListPageSize = 20;

enum DogQuickFilter { tutti, inRifugio, inStallo, adottabili, cuccioli }

List<Dog> filterDogs(
  List<Dog> dogs, {
  required String query,
  required DogQuickFilter filter,
  required DateTime now,
}) {
  final needle = query.trim().toLowerCase();
  final filtered = dogs.where((dog) {
    if (!_matchesFilter(dog, filter, now)) {
      return false;
    }
    if (needle.isEmpty) {
      return true;
    }
    return dogMatchesQuery(dog, needle);
  }).toList();
  filtered.sort(
    (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
  );
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

int countForFilter(List<Dog> dogs, DogQuickFilter filter, DateTime now) {
  return dogs.where((dog) => _matchesFilter(dog, filter, now)).length;
}

bool _matchesFilter(Dog dog, DogQuickFilter filter, DateTime now) {
  return switch (filter) {
    DogQuickFilter.tutti => true,
    DogQuickFilter.inRifugio => dog.stato == DogStato.inRifugio,
    DogQuickFilter.inStallo => dog.stato == DogStato.inStallo,
    DogQuickFilter.adottabili => dog.adottabile,
    DogQuickFilter.cuccioli => isCucciolo(dog, now),
  };
}

String resultCountLabel(int count) {
  if (count == 1) {
    return '1 risultato';
  }
  return '$count risultati';
}
