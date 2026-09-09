import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firestore/firestore_repositories.dart';
import 'repositories/data_repositories.dart';

final firestoreProvider = Provider<FirebaseFirestore?>((ref) {
  if (Firebase.apps.isEmpty) {
    return null;
  }
  return FirebaseFirestore.instance;
});

final dogRepositoryProvider = Provider<DogRepository?>((ref) {
  final db = ref.watch(firestoreProvider);
  return db == null ? null : FirestoreDogRepository(db);
});

final volunteerRepositoryProvider = Provider<VolunteerRepository?>((ref) {
  final db = ref.watch(firestoreProvider);
  return db == null ? null : FirestoreVolunteerRepository(db);
});

final boxRepositoryProvider = Provider<BoxRepository?>((ref) {
  final db = ref.watch(firestoreProvider);
  return db == null ? null : FirestoreBoxRepository(db);
});

final adopterRepositoryProvider = Provider<AdopterRepository?>((ref) {
  final db = ref.watch(firestoreProvider);
  return db == null ? null : FirestoreAdopterRepository(db);
});

final adoptionRepositoryProvider = Provider<AdoptionRepository?>((ref) {
  final db = ref.watch(firestoreProvider);
  return db == null ? null : FirestoreAdoptionRepository(db);
});

final healthRepositoryProvider = Provider<HealthRepository?>((ref) {
  final db = ref.watch(firestoreProvider);
  return db == null ? null : FirestoreHealthRepository(db);
});

final weightRepositoryProvider = Provider<WeightRepository?>((ref) {
  final db = ref.watch(firestoreProvider);
  return db == null ? null : FirestoreWeightRepository(db);
});

final sponsorshipRepositoryProvider = Provider<SponsorshipRepository?>((ref) {
  final db = ref.watch(firestoreProvider);
  return db == null ? null : FirestoreSponsorshipRepository(db);
});

final expenseRepositoryProvider = Provider<ExpenseRepository?>((ref) {
  final db = ref.watch(firestoreProvider);
  return db == null ? null : FirestoreExpenseRepository(db);
});

final noteRepositoryProvider = Provider<NoteRepository?>((ref) {
  final db = ref.watch(firestoreProvider);
  return db == null ? null : FirestoreNoteRepository(db);
});

final documentRepositoryProvider = Provider<DocumentRepository?>((ref) {
  final db = ref.watch(firestoreProvider);
  return db == null ? null : FirestoreDocumentRepository(db);
});

final photoRepositoryProvider = Provider<PhotoRepository?>((ref) {
  final db = ref.watch(firestoreProvider);
  return db == null ? null : FirestorePhotoRepository(db);
});

final appointmentRepositoryProvider = Provider<AppointmentRepository?>((ref) {
  final db = ref.watch(firestoreProvider);
  return db == null ? null : FirestoreAppointmentRepository(db);
});
