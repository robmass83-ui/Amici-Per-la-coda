import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
import '../../data/models/app_document.dart';
import '../../data/models/document_template.dart';
import '../../data/models/volunteer.dart';
import '../auth/auth_providers.dart';
import '../dogs/dogs_providers.dart';

final templatesStreamProvider = StreamProvider<List<DocumentTemplate>>((
  ref,
) async* {
  final repo = ref.watch(templateRepositoryProvider);
  if (repo == null) {
    yield const <DocumentTemplate>[];
    return;
  }
  final uid = ref.watch(authRepositoryProvider).currentUser?.uid ?? '';
  await repo.ensureDefaults(
    loader: ref.watch(assetBytesLoaderProvider),
    uid: uid,
  );
  yield* repo.watchAll();
});

final currentVolunteerProvider = Provider<Volunteer?>((ref) {
  final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
  if (uid == null) {
    return null;
  }
  return ref.watch(volunteersStreamProvider).maybeWhen(
    data: (items) {
      for (final item in items) {
        if (item.id == uid) {
          return item;
        }
      }
      return null;
    },
    orElse: () => null,
  );
});

final documentsByAdopterProvider =
    StreamProvider.family<List<AppDocument>, String>((ref, adopterId) {
      final repo = ref.watch(documentRepositoryProvider);
      if (repo == null) {
        return Stream.value(const <AppDocument>[]);
      }
      return repo.watchByAdopter(adopterId);
    });

final documentsByAdoptionProvider =
    StreamProvider.family<List<AppDocument>, String>((ref, adoptionId) {
      final repo = ref.watch(documentRepositoryProvider);
      if (repo == null) {
        return Stream.value(const <AppDocument>[]);
      }
      return repo.watchByAdoption(adoptionId);
    });
