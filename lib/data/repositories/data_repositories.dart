import 'dart:typed_data';

import '../documents/template_assets.dart';
import '../models/adopter.dart';
import '../models/adoption.dart';
import '../models/app_document.dart';
import '../models/appointment.dart';
import '../models/association_settings.dart';
import '../models/document_template.dart';
import '../models/dog.dart';
import '../models/expense.dart';
import '../models/health_record.dart';
import '../models/note.dart';
import '../models/photo.dart';
import '../models/shelter_box.dart';
import '../models/sponsorship.dart';
import '../models/volunteer.dart';
import '../models/weight.dart';

abstract interface class DogRepository {
  Stream<List<Dog>> watchAll();
  Future<Dog?> getById(String id);
  Future<void> save(Dog dog);
}

abstract interface class PhotoRepository {
  Future<Photo> upload(
    String dogId,
    Uint8List bytes, {
    bool asCover = false,
    required String createdBy,
  });
  Stream<List<Photo>> watchByDog(String dogId);
  Future<Uint8List?> loadFull(String photoId);
  Future<void> setCover(String dogId, String photoId);
  Future<void> delete(String photoId);
}

abstract interface class HealthRepository {
  Stream<List<HealthRecord>> watchByDog(String dogId);
  Stream<List<HealthRecord>> watchAll();
  Future<void> save(HealthRecord record);
}

abstract interface class WeightRepository {
  Stream<List<Weight>> watchByDog(String dogId);
  Future<void> save(Weight weight);
}

abstract interface class SponsorshipRepository {
  Stream<List<Sponsorship>> watchByDog(String dogId);
  Future<void> save(Sponsorship sponsorship);
}

abstract interface class ExpenseRepository {
  Stream<List<Expense>> watchByDog(String? dogId);
  Future<void> save(Expense expense);
}

abstract interface class AdopterRepository {
  Stream<List<Adopter>> watchAll();
  Future<Adopter?> getById(String id);
  Future<void> save(Adopter adopter);
}

abstract interface class AdoptionRepository {
  Stream<List<Adoption>> watchAll();
  Future<Adoption?> getById(String id);
  Future<void> save(Adoption adoption);
}

abstract interface class DocumentRepository {
  Stream<List<AppDocument>> watchByDog(String dogId);
  Stream<List<AppDocument>> watchByAdopter(String adopterId);
  Stream<List<AppDocument>> watchByAdoption(String adoptionId);
  Future<void> save(AppDocument document);
  Future<AppDocument> saveBytes(AppDocument document, Uint8List bytes);
  Future<Uint8List> loadBytes(String id);
  Future<void> delete(String id);
}

abstract interface class TemplateRepository {
  Stream<List<DocumentTemplate>> watchAll();
  Future<DocumentTemplate?> getById(String id);
  Future<void> save(DocumentTemplate template);
  Future<void> ensureDefaults({
    required AssetBytesLoader loader,
    required String uid,
    DateTime? now,
  });
}

abstract interface class NoteRepository {
  Stream<List<Note>> watchByDog(String dogId);
  Future<void> save(Note note);
}

abstract interface class AppointmentRepository {
  Stream<List<Appointment>> watchAll();
  Future<void> save(Appointment appointment);
}

abstract interface class VolunteerRepository {
  Stream<List<Volunteer>> watchAll();
  Future<Volunteer?> getById(String id);
  Future<void> save(Volunteer volunteer);
}

abstract interface class BoxRepository {
  Stream<List<ShelterBox>> watchAll();
  Future<void> save(ShelterBox box);
}

abstract interface class SettingsRepository {
  Future<AssociationSettings?> getAssociation();
  Future<void> saveAssociation(AssociationSettings settings);
}
