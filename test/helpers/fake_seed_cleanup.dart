import 'package:amici_per_la_coda/data/seed/seed_cleanup.dart';
import 'package:amici_per_la_coda/data/seed/seed_data.dart';
import 'package:amici_per_la_coda/data/seed/seed_ids.dart';

import 'fake_adopter_repository.dart';
import 'fake_adoption_repository.dart';
import 'fake_dog_repository.dart';
import 'fake_volunteer_repository.dart';

class InMemorySeedCleanup implements SeedCleanup {
  InMemorySeedCleanup({
    required this.dogs,
    required this.adoptions,
    required this.volunteers,
    required this.adopters,
  });

  final InMemoryDogRepository dogs;
  final InMemoryAdoptionRepository adoptions;
  final InMemoryVolunteerRepository volunteers;
  final InMemoryAdopterRepository adopters;

  @override
  Future<SeedCleanupReport> deleteSeed() async {
    final nDogs = dogs.items.where((item) => isSeedId(item.id)).length;
    final nAdoptions = adoptions.items
        .where((item) => isSeedId(item.id))
        .length;
    final nVolunteers = volunteers.items
        .where((item) => isSeedId(item.id))
        .length;
    await dogs.removePrefixed(seedIdPrefix);
    await adoptions.removePrefixed(seedIdPrefix);
    await volunteers.removePrefixed(seedIdPrefix);
    await adopters.removePrefixed(seedIdPrefix);
    return SeedCleanupReport(
      dogs: nDogs,
      adoptions: nAdoptions,
      volunteers: nVolunteers,
    );
  }
}
