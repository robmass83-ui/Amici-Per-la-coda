import 'dart:typed_data';

import 'package:amici_per_la_coda/data/dog_purge.dart';
import 'package:amici_per_la_coda/data/models/app_document.dart';
import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/data/models/note.dart';
import 'package:amici_per_la_coda/data/models/photo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/dog_fixtures.dart';
import '../helpers/fake_adoption_repository.dart';
import '../helpers/fake_appointment_repository.dart';
import '../helpers/fake_document_repository.dart';
import '../helpers/fake_dog_repository.dart';
import '../helpers/fake_expense_repository.dart';
import '../helpers/fake_health_repository.dart';
import '../helpers/fake_note_repository.dart';
import '../helpers/fake_photo_repository.dart';
import '../helpers/fake_sponsorship_repository.dart';
import '../helpers/fake_weight_repository.dart';

Photo _photo(String id, String dogId) {
  return Photo(
    id: id,
    dogId: dogId,
    isCover: id.endsWith('-cover'),
    w: 1,
    h: 1,
    mime: 'image/jpeg',
    thumb: Uint8List.fromList([1]),
    bytesFull: 10,
    createdAt: DateTime.utc(2026, 9, 1),
    createdBy: 'uid-1',
  );
}

AppDocument _doc({required String id, String? dogId, String? adoptionId}) {
  return AppDocument(
    id: id,
    dogId: dogId,
    adoptionId: adoptionId,
    adopterId: '',
    tipo: DocumentTipo.altro,
    nome: id,
    mime: 'application/pdf',
    chunkCount: 0,
    contenutoB64: 'YQ==',
    caricatoIl: DateTime.utc(2026, 9, 1),
    caricatoDa: 'uid-1',
  );
}

void main() {
  test(
    'purgeDogProfile cancella la scheda e i dati del cane, non gli altri',
    () async {
      final dogs = InMemoryDogRepository([
        testDog(id: 'fenice', nome: 'Fenice'),
        testDog(id: 'zeus', nome: 'Zeus'),
      ]);
      final photos = InMemoryPhotoRepository(
        photos: [_photo('p-fenice-cover', 'fenice'), _photo('p-zeus', 'zeus')],
        dogs: dogs,
      );
      final health = InMemoryHealthRepository([
        testHealth(id: 'h-fenice', dogId: 'fenice'),
        testHealth(id: 'h-zeus', dogId: 'zeus'),
      ]);
      final weights = InMemoryWeightRepository([
        testWeight(id: 'w-fenice', dogId: 'fenice'),
        testWeight(id: 'w-zeus', dogId: 'zeus'),
      ], dogs);
      final expenses = InMemoryExpenseRepository([
        testExpense(id: 'e-fenice', dogId: 'fenice'),
        testExpense(id: 'e-zeus', dogId: 'zeus'),
      ]);
      final notes = InMemoryNoteRepository([
        Note(
          id: 'n-fenice',
          dogId: 'fenice',
          tipo: NoteTipo.generale,
          testo: 'Nota Fenice',
          autoreId: 'uid-1',
          createdAt: DateTime.utc(2026, 9, 1),
        ),
        Note(
          id: 'n-zeus',
          dogId: 'zeus',
          tipo: NoteTipo.generale,
          testo: 'Nota Zeus',
          autoreId: 'uid-1',
          createdAt: DateTime.utc(2026, 9, 1),
        ),
      ]);
      final documents = InMemoryDocumentRepository([
        _doc(id: 'd-fenice', dogId: 'fenice'),
        _doc(id: 'd-adozione', dogId: null, adoptionId: 'ad-fenice'),
        _doc(id: 'd-zeus', dogId: 'zeus'),
      ]);
      final sponsorships = InMemorySponsorshipRepository([
        testSponsorship(id: 's-fenice', dogId: 'fenice'),
        testSponsorship(id: 's-zeus', dogId: 'zeus'),
      ]);
      final appointments = InMemoryAppointmentRepository([
        testAppointment(id: 'ap-fenice', dogId: 'fenice'),
        testAppointment(id: 'ap-zeus', dogId: 'zeus'),
      ]);
      final adoptions = InMemoryAdoptionRepository([
        testAdoption(id: 'ad-fenice', dogId: 'fenice'),
        testAdoption(id: 'ad-zeus', dogId: 'zeus'),
      ]);

      await purgeDogProfile(
        dogId: 'fenice',
        dogs: dogs,
        photos: photos,
        health: health,
        weights: weights,
        expenses: expenses,
        notes: notes,
        documents: documents,
        sponsorships: sponsorships,
        appointments: appointments,
        adoptions: adoptions,
      );

      expect(await dogs.getById('fenice'), isNull);
      expect(await dogs.getById('zeus'), isNotNull);

      expect(await photos.watchByDog('fenice').first, isEmpty);
      expect(await photos.watchByDog('zeus').first, hasLength(1));

      expect(await health.watchByDog('fenice').first, isEmpty);
      expect(await health.watchByDog('zeus').first, hasLength(1));

      expect(await weights.watchByDog('fenice').first, isEmpty);
      expect(await weights.watchByDog('zeus').first, hasLength(1));

      expect(await expenses.watchByDog('fenice').first, isEmpty);
      expect(await expenses.watchByDog('zeus').first, hasLength(1));

      expect(await notes.watchByDog('fenice').first, isEmpty);
      expect(await notes.watchByDog('zeus').first, hasLength(1));

      expect(documents.items.map((item) => item.id), ['d-zeus']);
      expect(await sponsorships.watchByDog('fenice').first, isEmpty);
      expect(await sponsorships.watchByDog('zeus').first, hasLength(1));
      expect(appointments.items.map((item) => item.id), ['ap-zeus']);
      expect(adoptions.items.map((item) => item.id), ['ad-zeus']);
    },
  );
}
