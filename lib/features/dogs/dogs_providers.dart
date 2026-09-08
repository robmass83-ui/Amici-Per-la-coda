import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
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

final dogsStreamProvider = StreamProvider<List<Dog>>((ref) {
  final repo = ref.watch(dogRepositoryProvider);
  if (repo == null) {
    return Stream.value(const <Dog>[]);
  }
  return repo.watchAll();
});

final dogListNowProvider = Provider<DateTime>((ref) => DateTime.now());

final dogByIdProvider = Provider.family<AsyncValue<Dog?>, String>((ref, id) {
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

final dogAdoptionCountProvider = Provider.family<int, String>((ref, dogId) {
  return ref.watch(dogAdoptionsProvider(dogId)).length;
});

final dogAdoptionsProvider = Provider.family<List<Adoption>, String>((ref, dogId) {
  return ref
      .watch(adoptionsStreamProvider)
      .maybeWhen(
        data: (items) =>
            items.where((item) => item.dogId == dogId).toList(growable: false),
        orElse: () => const <Adoption>[],
      );
});

final healthByDogProvider =
    StreamProvider.family<List<HealthRecord>, String>((ref, dogId) {
      final repo = ref.watch(healthRepositoryProvider);
      if (repo == null) {
        return Stream.value(const <HealthRecord>[]);
      }
      return repo.watchByDog(dogId);
    });

final weightsByDogProvider =
    StreamProvider.family<List<Weight>, String>((ref, dogId) {
      final repo = ref.watch(weightRepositoryProvider);
      if (repo == null) {
        return Stream.value(const <Weight>[]);
      }
      return repo.watchByDog(dogId);
    });

final sponsorshipsByDogProvider =
    StreamProvider.family<List<Sponsorship>, String>((ref, dogId) {
      final repo = ref.watch(sponsorshipRepositoryProvider);
      if (repo == null) {
        return Stream.value(const <Sponsorship>[]);
      }
      return repo.watchByDog(dogId);
    });

final expensesByDogProvider =
    StreamProvider.family<List<Expense>, String>((ref, dogId) {
      final repo = ref.watch(expenseRepositoryProvider);
      if (repo == null) {
        return Stream.value(const <Expense>[]);
      }
      return repo.watchByDog(dogId);
    });

final notesByDogProvider = StreamProvider.family<List<Note>, String>((ref, dogId) {
  final repo = ref.watch(noteRepositoryProvider);
  if (repo == null) {
    return Stream.value(const <Note>[]);
  }
  return repo.watchByDog(dogId);
});

final documentsByDogProvider =
    StreamProvider.family<List<AppDocument>, String>((ref, dogId) {
      final repo = ref.watch(documentRepositoryProvider);
      if (repo == null) {
        return Stream.value(const <AppDocument>[]);
      }
      return repo.watchByDog(dogId);
    });

final volunteersStreamProvider = StreamProvider<List<Volunteer>>((ref) {
  final repo = ref.watch(volunteerRepositoryProvider);
  if (repo == null) {
    return Stream.value(const <Volunteer>[]);
  }
  return repo.watchAll();
});

final photoPickerProvider = Provider<PhotoPicker>((ref) => ImagePhotoPicker());

final photosByDogProvider = StreamProvider.family<List<Photo>, String>((
  ref,
  dogId,
) {
  final repo = ref.watch(photoRepositoryProvider);
  if (repo == null) {
    return Stream.value(const <Photo>[]);
  }
  return repo.watchByDog(dogId);
});
