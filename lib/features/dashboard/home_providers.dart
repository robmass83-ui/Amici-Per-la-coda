import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_connectivity.dart';
import '../../data/data_providers.dart';
import '../../data/models/adoption.dart';
import '../../data/models/appointment.dart';
import '../../data/models/health_record.dart';
import '../../data/models/shelter_box.dart';
import '../../data/models/association_settings.dart';
import '../../data/models/volunteer.dart';
import '../auth/auth_providers.dart';
import '../dogs/dogs_providers.dart';
import '../dogs/edit_permissions.dart';
import 'home_aggregators.dart';

final boxesStreamProvider = StreamProvider<List<ShelterBox>>((ref) {
  final repo = ref.watch(boxRepositoryProvider);
  if (repo == null) {
    return Stream.value(const <ShelterBox>[]);
  }
  return repo.watchAll();
});

final appointmentsStreamProvider = StreamProvider<List<Appointment>>((ref) {
  final repo = ref.watch(appointmentRepositoryProvider);
  if (repo == null) {
    return Stream.value(const <Appointment>[]);
  }
  return repo.watchAll();
});

/// Tutti i record sanitari. Resta acceso: Home (scadenze), calendario,
/// avvisi. La lista Animali lo ascolta solo col filtro vaccini scaduti.
final healthAllProvider = StreamProvider<List<HealthRecord>>((ref) {
  final repo = ref.watch(healthRepositoryProvider);
  if (repo == null) {
    return Stream.value(const <HealthRecord>[]);
  }
  return repo.watchAll();
});

final associationSettingsProvider = StreamProvider<AssociationSettings?>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  if (repo == null) {
    return Stream.value(null);
  }
  return repo.watchAssociation();
});

final homeOfflineProvider = Provider<bool>((ref) {
  final async = ref.watch(connectivityResultsProvider);
  return async.maybeWhen(data: isOfflineConnectivity, orElse: () => false);
});

bool _fromCacheFlag(AsyncValue<bool> async) {
  return async.maybeWhen(data: (value) => value, orElse: () => false);
}

/// Offline o snapshot Firestore ancora dalla cache locale.
final staleDataProvider = Provider<bool>((ref) {
  if (ref.watch(homeOfflineProvider)) {
    return true;
  }
  return _fromCacheFlag(ref.watch(dogsFromCacheProvider)) ||
      _fromCacheFlag(ref.watch(coversFromCacheProvider));
});

/// Lista volontari arrivata e l'utente loggato non ha riga in `volunteers`.
final volunteerAccountMissingProvider = Provider<bool>((ref) {
  final volunteers = ref.watch(volunteersStreamProvider);
  if (!volunteers.hasValue) {
    return false;
  }
  final user = ref.watch(signedInUserProvider);
  if (user == null) {
    return false;
  }
  return volunteerForAuth(
        volunteers.requireValue,
        uid: user.uid,
        email: user.email,
      ) ==
      null;
});

final homeVolunteerNameProvider = Provider<String>((ref) {
  final user = ref.watch(signedInUserProvider);
  final volunteers = ref
      .watch(volunteersStreamProvider)
      .maybeWhen(data: (items) => items, orElse: () => const <Volunteer>[]);
  final volunteer = user == null
      ? null
      : volunteerForAuth(volunteers, uid: user.uid, email: user.email);
  return greetingName(volunteer: volunteer, email: user?.email);
});

final homeSummaryProvider = Provider<AsyncValue<HomeSummary>>((ref) {
  final dogs = ref.watch(dogsStreamProvider);
  final boxes = ref.watch(boxesStreamProvider);
  final adoptions = ref.watch(adoptionsStreamProvider);
  final health = ref.watch(healthAllProvider);
  final appointments = ref.watch(appointmentsStreamProvider);
  final settings = ref.watch(associationSettingsProvider);
  final now = ref.watch(dogListNowProvider);

  if ((dogs.isLoading && !dogs.hasValue) ||
      (boxes.isLoading && !boxes.hasValue) ||
      (adoptions.isLoading && !adoptions.hasValue) ||
      (health.isLoading && !health.hasValue) ||
      (appointments.isLoading && !appointments.hasValue) ||
      (settings.isLoading && !settings.hasValue)) {
    return const AsyncLoading();
  }

  return AsyncData(
    buildHomeSummary(
      dogs: dogs.maybeWhen(data: (items) => items, orElse: () => const []),
      boxes: boxes.maybeWhen(data: (items) => items, orElse: () => const []),
      adoptions: adoptions.maybeWhen(
        data: (items) => items,
        orElse: () => const <Adoption>[],
      ),
      health: health.maybeWhen(data: (items) => items, orElse: () => const []),
      appointments: appointments.maybeWhen(
        data: (items) => items,
        orElse: () => const [],
      ),
      now: now,
      capienzaAutorizzata: settings.maybeWhen(
        data: (item) => item?.capienzaAutorizzata ?? 0,
        orElse: () => 0,
      ),
    ),
  );
});
