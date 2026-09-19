import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
import '../../data/models/adopter.dart';
import '../../data/models/adoption.dart';
import '../../data/models/app_document.dart';
import '../../data/models/dog.dart';
import '../../data/models/expense.dart';
import '../../data/models/health_record.dart';
import '../../data/models/note.dart';
import '../../data/models/photo.dart';
import '../../data/models/sponsorship.dart';
import '../../data/models/volunteer.dart';
import '../../data/models/weight.dart';
import '../../data/photos/image_photo_picker.dart';
import '../../data/photos/photo_picker.dart';
import '../adoptions/family_link.dart';

/// Elenco cani. Non autoDispose: resta acceso con i tab (`indexedStack`)
/// e il listener Firestore non si riapre al cambio sezione.
final dogsStreamProvider = StreamProvider<List<Dog>>((ref) {
  final repo = ref.watch(dogRepositoryProvider);
  if (repo == null) {
    return Stream.value(const <Dog>[]);
  }
  return repo.watchAll();
});

final dogListNowProvider = Provider<DateTime>((ref) => DateTime.now());

final dogByIdProvider = Provider.autoDispose.family<AsyncValue<Dog?>, String>((
  ref,
  id,
) {
  return ref.watch(dogsStreamProvider).whenData((dogs) {
    for (final dog in dogs) {
      if (dog.id == id) {
        return dog;
      }
    }
    return null;
  });
});

final adoptionsStreamProvider = StreamProvider<List<Adoption>>((ref) {
  final repo = ref.watch(adoptionRepositoryProvider);
  if (repo == null) {
    return Stream.value(const <Adoption>[]);
  }
  return repo.watchAll();
});

final dogAdoptionCountProvider = Provider.autoDispose.family<int, String>((
  ref,
  dogId,
) {
  return familyLinkOf(ref.watch(dogAdoptionsProvider(dogId)), dogId) == null
      ? 0
      : 1;
});

final dogAdoptionsProvider = Provider.autoDispose
    .family<List<Adoption>, String>((ref, dogId) {
      return ref
          .watch(adoptionsStreamProvider)
          .maybeWhen(
            data: (items) => items
                .where((item) => item.dogId == dogId)
                .toList(growable: false),
            orElse: () => const <Adoption>[],
          );
    });

final healthByDogProvider = StreamProvider.autoDispose
    .family<List<HealthRecord>, String>((ref, dogId) {
      final repo = ref.watch(healthRepositoryProvider);
      if (repo == null) {
        return Stream.value(const <HealthRecord>[]);
      }
      return repo.watchByDog(dogId);
    });

final weightsByDogProvider = StreamProvider.autoDispose
    .family<List<Weight>, String>((ref, dogId) {
      final repo = ref.watch(weightRepositoryProvider);
      if (repo == null) {
        return Stream.value(const <Weight>[]);
      }
      return repo.watchByDog(dogId);
    });

final sponsorshipsByDogProvider = StreamProvider.autoDispose
    .family<List<Sponsorship>, String>((ref, dogId) {
      final repo = ref.watch(sponsorshipRepositoryProvider);
      if (repo == null) {
        return Stream.value(const <Sponsorship>[]);
      }
      return repo.watchByDog(dogId);
    });

final expensesByDogProvider = StreamProvider.autoDispose
    .family<List<Expense>, String>((ref, dogId) {
      final repo = ref.watch(expenseRepositoryProvider);
      if (repo == null) {
        return Stream.value(const <Expense>[]);
      }
      return repo.watchByDog(dogId);
    });

final notesByDogProvider = StreamProvider.autoDispose
    .family<List<Note>, String>((ref, dogId) {
      final repo = ref.watch(noteRepositoryProvider);
      if (repo == null) {
        return Stream.value(const <Note>[]);
      }
      return repo.watchByDog(dogId);
    });

final documentsByDogProvider = StreamProvider.autoDispose
    .family<List<AppDocument>, String>((ref, dogId) {
      final repo = ref.watch(documentRepositoryProvider);
      if (repo == null) {
        return Stream.value(const <AppDocument>[]);
      }
      return repo.watchByDog(dogId);
    });

final documentsStreamProvider = StreamProvider<List<AppDocument>>((ref) {
  final repo = ref.watch(documentRepositoryProvider);
  if (repo == null) {
    return Stream.value(const <AppDocument>[]);
  }
  return repo.watchAll();
});

final volunteersStreamProvider = StreamProvider<List<Volunteer>>((ref) {
  final repo = ref.watch(volunteerRepositoryProvider);
  if (repo == null) {
    return Stream.value(const <Volunteer>[]);
  }
  return repo.watchAll();
});

final adoptersStreamProvider = StreamProvider.autoDispose<List<Adopter>>((ref) {
  final repo = ref.watch(adopterRepositoryProvider);
  if (repo == null) {
    return Stream.value(const <Adopter>[]);
  }
  return repo.watchAll();
});

final photoPickerProvider = Provider<PhotoPicker>((ref) => ImagePhotoPicker());

/// Unica query foto per lista/home/scheda: `photos.where(isCover == true)`.
/// Non autoDispose: resta acceso con i tab (`indexedStack`) e non si riapre.
final coverPhotosProvider = StreamProvider<Map<String, Photo>>((ref) {
  final repo = ref.watch(photoRepositoryProvider);
  if (repo == null) {
    return Stream.value(const <String, Photo>{});
  }
  return repo.watchCovers();
});

final coverPhotoProvider = Provider.autoDispose.family<Photo?, String>((
  ref,
  dogId,
) {
  return ref
      .watch(coverPhotosProvider)
      .maybeWhen(data: (covers) => covers[dogId], orElse: () => null);
});

final photosByDogProvider = StreamProvider.autoDispose
    .family<List<Photo>, String>((ref, dogId) {
      final repo = ref.watch(photoRepositoryProvider);
      if (repo == null) {
        return Stream.value(const <Photo>[]);
      }
      return repo.watchByDog(dogId);
    });
