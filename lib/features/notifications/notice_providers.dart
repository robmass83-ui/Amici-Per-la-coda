import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/adoption.dart';
import '../../data/models/appointment.dart';
import '../../data/models/dog.dart';
import '../../data/models/health_record.dart';
import '../dashboard/home_providers.dart';
import '../dogs/dogs_providers.dart';
import 'notice_aggregators.dart';

final noticesProvider = Provider<List<AppNotice>>((ref) {
  final now = ref.watch(dogListNowProvider);
  final dogs = ref.watch(dogsStreamProvider).maybeWhen(
        data: (items) => items,
        orElse: () => const <Dog>[],
      );
  final health = ref.watch(healthAllProvider).maybeWhen(
        data: (items) => items,
        orElse: () => const <HealthRecord>[],
      );
  final appointments = ref.watch(appointmentsStreamProvider).maybeWhen(
        data: (items) => items,
        orElse: () => const <Appointment>[],
      );
  final adoptions = ref.watch(adoptionsStreamProvider).maybeWhen(
        data: (items) => items,
        orElse: () => const <Adoption>[],
      );
  return buildNotices(
    dogs: dogs,
    health: health,
    appointments: appointments,
    adoptions: adoptions,
    now: now,
  );
});

class ReadNoticeIds extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void markAll(Iterable<String> ids) {
    state = {...state, ...ids};
  }
}

final readNoticeIdsProvider =
    NotifierProvider<ReadNoticeIds, Set<String>>(ReadNoticeIds.new);
