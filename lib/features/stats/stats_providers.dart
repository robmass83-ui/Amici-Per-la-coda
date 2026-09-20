import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
import '../../data/models/adoption.dart';
import '../../data/models/dog.dart';
import '../../data/models/expense.dart';
import '../../data/models/sponsorship.dart';
import '../dogs/dogs_providers.dart';
import 'stats_aggregators.dart';

final expensesAllProvider = StreamProvider.autoDispose<List<Expense>>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  if (repo == null) {
    return Stream.value(const <Expense>[]);
  }
  return repo.watchByDog(null);
});

final sponsorshipsAllProvider = StreamProvider.autoDispose<List<Sponsorship>>((
  ref,
) {
  final repo = ref.watch(sponsorshipRepositoryProvider);
  if (repo == null) {
    return Stream.value(const <Sponsorship>[]);
  }
  return repo.watchAll();
});

class StatsYear extends Notifier<int> {
  @override
  int build() => ref.read(dogListNowProvider).year;

  void setYear(int year) {
    state = year;
  }
}

final statsYearProvider = NotifierProvider<StatsYear, int>(StatsYear.new);

final yearStatsProvider = Provider<YearStats>((ref) {
  final year = ref.watch(statsYearProvider);
  final now = ref.watch(dogListNowProvider);
  final dogs = ref
      .watch(dogsStreamProvider)
      .maybeWhen(data: (items) => items, orElse: () => const <Dog>[]);
  final adoptions = ref
      .watch(adoptionsStreamProvider)
      .maybeWhen(data: (items) => items, orElse: () => const <Adoption>[]);
  final expenses = ref
      .watch(expensesAllProvider)
      .maybeWhen(data: (items) => items, orElse: () => const <Expense>[]);
  final sponsorships = ref
      .watch(sponsorshipsAllProvider)
      .maybeWhen(data: (items) => items, orElse: () => const <Sponsorship>[]);
  return buildYearStats(
    dogs: dogs,
    adoptions: adoptions,
    expenses: expenses,
    sponsorships: sponsorships,
    year: year,
    now: now,
  );
});
