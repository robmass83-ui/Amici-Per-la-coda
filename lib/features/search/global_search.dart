import '../../data/models/adopter.dart';
import '../../data/models/app_document.dart';
import '../../data/models/dog.dart';
import '../../data/models/volunteer.dart';
import '../dogs/dog_list_query.dart';
import '../dogs/tab_labels.dart';

enum SearchScope { tutto, microchip, box, persone }

class GlobalSearchResult {
  const GlobalSearchResult({
    required this.dogs,
    required this.documents,
    required this.adopters,
  });

  const GlobalSearchResult.empty()
    : dogs = const [],
      documents = const [],
      adopters = const [];

  final List<Dog> dogs;
  final List<AppDocument> documents;
  final List<Adopter> adopters;

  bool get isEmpty =>
      dogs.isEmpty && documents.isEmpty && adopters.isEmpty;
}

bool searchQueryReady(String raw) => raw.trim().length >= 2;

GlobalSearchResult searchGlobal({
  required String query,
  required SearchScope scope,
  required List<Dog> dogs,
  required List<AppDocument> documents,
  required List<Adopter> adopters,
  required List<Volunteer> volunteers,
}) {
  final needle = query.trim().toLowerCase();
  if (needle.length < 2) {
    return const GlobalSearchResult.empty();
  }
  final dogHits = dogs.where((dog) {
    return switch (scope) {
      SearchScope.microchip => dog.microchip.toLowerCase().contains(needle),
      SearchScope.box => _dogBoxMatches(dog, needle),
      SearchScope.persone => _dogPersonaMatches(dog, needle, volunteers),
      SearchScope.tutto =>
        dogMatchesQuery(dog, needle) ||
            _dogPersonaMatches(dog, needle, volunteers),
    };
  }).toList();
  final docHits = scope == SearchScope.persone
      ? const <AppDocument>[]
      : documents
            .where((item) => item.nome.toLowerCase().contains(needle))
            .toList();
  final adopterHits =
      (scope == SearchScope.tutto || scope == SearchScope.persone)
      ? adopters.where((item) => _adopterMatches(item, needle)).toList()
      : const <Adopter>[];
  return GlobalSearchResult(
    dogs: dogHits,
    documents: docHits,
    adopters: adopterHits,
  );
}

bool _dogBoxMatches(Dog dog, String needle) {
  final keys = <String>{
    dog.box,
    dog.settore,
    '${dog.settore}${dog.box}',
    '${dog.settore} ${dog.box}',
    '${dog.settore}-${dog.box}',
  };
  return keys.any((value) => value.toLowerCase().contains(needle));
}

bool _dogPersonaMatches(
  Dog dog,
  String needle,
  List<Volunteer> volunteers,
) {
  final nome = volunteerNomeDi(volunteers, dog.referenteId ?? '');
  return nome.toLowerCase().contains(needle);
}

bool _adopterMatches(Adopter item, String needle) {
  final blob =
      '${item.nome} ${item.cognome} ${item.telefono} ${item.email} ${item.citta}'
          .toLowerCase();
  return blob.contains(needle);
}

String searchScopeHint(SearchScope scope) {
  return switch (scope) {
    SearchScope.microchip => 'Numero microchip',
    SearchScope.box => 'Box o settore',
    SearchScope.persone => 'Adottante o volontario',
    SearchScope.tutto => 'Nome, microchip, box…',
  };
}
