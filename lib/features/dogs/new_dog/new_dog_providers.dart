import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/data_providers.dart';
import 'microchip_scanner.dart';
import 'new_dog_draft_store.dart';

final dogDraftStoreProvider = Provider<DogDraftStore>((ref) {
  final db = ref.watch(firestoreProvider);
  if (db == null) {
    return InMemoryDogDraftStore();
  }
  return FirestoreDogDraftStore(db);
});

final microchipScannerProvider = Provider<MicrochipScanner>((ref) {
  return const MobileMicrochipScanner();
});
