import '../../data/models/app_document.dart';
import '../../data/models/dog.dart';

class DogDocumentsGroup {
  const DogDocumentsGroup({
    required this.dogId,
    required this.dogName,
    required this.documents,
  });

  final String? dogId;
  final String dogName;
  final List<AppDocument> documents;
}

/// Raggruppa i file caricati per scheda cane, nome A-Z, più recenti prima.
/// I documenti senza `dogId` finiscono in «Altri documenti».
List<DogDocumentsGroup> groupDocumentsByDog({
  required List<AppDocument> documents,
  required List<Dog> dogs,
}) {
  final names = <String, String>{
    for (final dog in dogs) dog.id: dog.nome,
  };
  final byDog = <String?, List<AppDocument>>{};
  for (final doc in documents) {
    final id = doc.dogId;
    final key = (id == null || id.isEmpty) ? null : id;
    (byDog[key] ??= <AppDocument>[]).add(doc);
  }
  for (final list in byDog.values) {
    list.sort((a, b) => b.caricatoIl.compareTo(a.caricatoIl));
  }

  final groups = <DogDocumentsGroup>[];
  final dogIds = byDog.keys.whereType<String>().toList()
    ..sort((a, b) {
      final left = names[a] ?? a;
      final right = names[b] ?? b;
      return left.toLowerCase().compareTo(right.toLowerCase());
    });
  for (final id in dogIds) {
    groups.add(
      DogDocumentsGroup(
        dogId: id,
        dogName: names[id] ?? 'Cane rimosso',
        documents: byDog[id]!,
      ),
    );
  }
  final others = byDog[null];
  if (others != null && others.isNotEmpty) {
    groups.add(
      DogDocumentsGroup(
        dogId: null,
        dogName: 'Altri documenti',
        documents: others,
      ),
    );
  }
  return groups;
}
