import 'models/adoption.dart';
import 'repositories/data_repositories.dart';

/// Cancella la scheda del cane e i dati collegati (foto, salute, spese, note,
/// documenti, adozioni, appuntamenti, adozioni a distanza). Gli adottanti
/// restano: non appartengono al profilo del cane.
Future<void> purgeDogProfile({
  required String dogId,
  required DogRepository dogs,
  PhotoRepository? photos,
  HealthRepository? health,
  WeightRepository? weights,
  ExpenseRepository? expenses,
  NoteRepository? notes,
  DocumentRepository? documents,
  SponsorshipRepository? sponsorships,
  AppointmentRepository? appointments,
  AdoptionRepository? adoptions,
}) async {
  final adoptionList = adoptions == null
      ? const <Adoption>[]
      : (await adoptions.watchAll().first)
            .where((item) => item.dogId == dogId)
            .toList(growable: false);

  if (photos != null) {
    for (final photo in await photos.watchByDog(dogId).first) {
      await photos.delete(photo.id);
    }
  }
  if (health != null) {
    for (final record in await health.watchByDog(dogId).first) {
      await health.delete(record.id);
    }
  }
  if (weights != null) {
    for (final weight in await weights.watchByDog(dogId).first) {
      await weights.delete(weight.id);
    }
  }
  if (expenses != null) {
    for (final expense in await expenses.watchByDog(dogId).first) {
      await expenses.delete(expense.id);
    }
  }
  if (notes != null) {
    for (final note in await notes.watchByDog(dogId).first) {
      await notes.delete(note.id);
    }
  }
  if (sponsorships != null) {
    for (final item in await sponsorships.watchByDog(dogId).first) {
      await sponsorships.delete(item.id);
    }
  }
  if (appointments != null) {
    for (final item in await appointments.watchAll().first) {
      if (item.dogId == dogId) {
        await appointments.delete(item.id);
      }
    }
  }
  if (documents != null) {
    final seen = <String>{};
    for (final doc in await documents.watchByDog(dogId).first) {
      seen.add(doc.id);
      await documents.delete(doc.id);
    }
    for (final adoption in adoptionList) {
      for (final doc in await documents.watchByAdoption(adoption.id).first) {
        if (seen.add(doc.id)) {
          await documents.delete(doc.id);
        }
      }
    }
  }
  for (final adoption in adoptionList) {
    await adoptions!.delete(adoption.id);
  }
  await dogs.delete(dogId);
}
