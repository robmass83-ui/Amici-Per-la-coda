import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
import '../../data/models/adoption.dart';
import '../../data/models/appointment.dart';
import '../../data/models/health_record.dart';
import '../../data/models/shelter_box.dart';
import '../../data/models/volunteer.dart';
import '../auth/auth_providers.dart';
import '../dogs/dogs_providers.dart';
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

final healthAllProvider = StreamProvider<List<HealthRecord>>((ref) {
  final repo = ref.watch(healthRepositoryProvider);
  if (repo == null) {
    return Stream.value(const <HealthRecord>[]);
  }
  return repo.watchAll();
});

final homeOfflineProvider = Provider<bool>((ref) => false);

final homeVolunteerNameProvider = Provider<String>((ref) {
  final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
  final volunteers = ref
      .watch(volunteersStreamProvider)
      .maybeWhen(data: (items) => items, orElse: () => const <Volunteer>[]);
  if (uid != null) {
    for (final volunteer in volunteers) {
      if (volunteer.id == uid) {
        return volunteer.nome;
      }
    }
  }
  final email = ref.watch(authRepositoryProvider).currentUser?.email ?? '';
  final at = email.indexOf('@');
  if (at > 0) {
    final raw = email.substring(0, at);
    if (raw.isEmpty) {
      return 'volontario';
    }
    return '${raw[0].toUpperCase()}${raw.substring(1)}';
  }
  return 'volontario';
});

final homeSummaryProvider = Provider<AsyncValue<HomeSummary>>((ref) {
  final dogs = ref.watch(dogsStreamProvider);
  final boxes = ref.watch(boxesStreamProvider);
  final adoptions = ref.watch(adoptionsStreamProvider);
  final health = ref.watch(healthAllProvider);
  final appointments = ref.watch(appointmentsStreamProvider);
  final now = ref.watch(dogListNowProvider);

  if ((dogs.isLoading && !dogs.hasValue) ||
      (boxes.isLoading && !boxes.hasValue) ||
      (adoptions.isLoading && !adoptions.hasValue) ||
      (health.isLoading && !health.hasValue) ||
      (appointments.isLoading && !appointments.hasValue)) {
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
    ),
  );
});
