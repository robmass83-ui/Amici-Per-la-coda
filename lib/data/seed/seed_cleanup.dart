import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data_providers.dart';
import 'seed_data.dart';
import 'seed_ids.dart';

abstract interface class SeedCleanup {
  Future<SeedCleanupReport> deleteSeed();
}

class FirestoreSeedCleanup implements SeedCleanup {
  const FirestoreSeedCleanup(this.db);

  final FirebaseFirestore db;

  @override
  Future<SeedCleanupReport> deleteSeed() => deleteSeedData(db);
}

int countSeedDocuments({
  required Iterable<String> dogIds,
  required Iterable<String> adoptionIds,
  required Iterable<String> volunteerIds,
  required Iterable<String> adopterIds,
}) {
  return dogIds.where(isSeedId).length +
      adoptionIds.where(isSeedId).length +
      volunteerIds.where(isSeedId).length +
      adopterIds.where(isSeedId).length;
}

final seedCleanupProvider = Provider<SeedCleanup?>((ref) {
  final db = ref.watch(firestoreProvider);
  if (db == null) {
    return null;
  }
  return FirestoreSeedCleanup(db);
});
