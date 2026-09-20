import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
import '../../data/models/app_document.dart';
import '../../data/search_recents_store.dart';
import '../auth/auth_providers.dart';

final searchRecentsStoreProvider = Provider<SearchRecentsStore>((ref) {
  final db = ref.watch(firestoreProvider);
  final uid = ref.watch(authRepositoryProvider).currentUser?.uid ?? '';
  if (db == null) {
    return MemorySearchRecentsStore();
  }
  return FirestoreSearchRecentsStore(db, uid);
});

final documentsAllProvider = StreamProvider.autoDispose<List<AppDocument>>((
  ref,
) {
  final repo = ref.watch(documentRepositoryProvider);
  if (repo == null) {
    return Stream.value(const <AppDocument>[]);
  }
  return repo.watchAll();
});
