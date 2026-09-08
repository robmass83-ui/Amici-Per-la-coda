import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firestore_codec.dart';
import '../models/adoption.dart';
import '../models/app_document.dart';
import '../models/appointment.dart';
import '../models/association_settings.dart';
import '../models/dog.dart';
import '../models/expense.dart';
import '../models/health_record.dart';
import '../models/note.dart';
import '../models/photo.dart';
import '../models/shelter_box.dart';
import '../models/sponsorship.dart';
import '../models/volunteer.dart';
import '../models/weight.dart';
import '../photos/lru_bytes_cache.dart';
import '../photos/photo_codec.dart';
import '../photos/photo_limit.dart';
import '../repositories/data_repositories.dart';

Map<String, dynamic> _data(DocumentSnapshot<Map<String, dynamic>> snap) {
  return snap.data() ?? <String, dynamic>{};
}

class FirestoreDogRepository implements DogRepository {
  FirestoreDogRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('dogs');

  @override
  Stream<List<Dog>> watchAll() {
    return _col.snapshots().map(
      (snap) => snap.docs.map((doc) => Dog.fromMap(doc.id, doc.data())).toList(),
    );
  }

  @override
  Future<Dog?> getById(String id) async {
    final snap = await _col.doc(id).get();
    if (!snap.exists) {
      return null;
    }
    return Dog.fromMap(snap.id, _data(snap));
  }

  @override
  Future<void> save(Dog dog) => _col.doc(dog.id).set(dog.toMap());
}

class FirestorePhotoRepository implements PhotoRepository {
  FirestorePhotoRepository(this._db);
  final FirebaseFirestore _db;
  final _cache = LruBytesCache();

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('photos');

  @override
  Stream<List<Photo>> watchByDog(String dogId) {
    return _col
        .where('dogId', isEqualTo: dogId)
        .snapshots()
        .map(
          (snap) {
            final list = snap.docs
                .map((doc) => Photo.fromMap(doc.id, doc.data()))
                .toList();
            list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return list;
          },
        );
  }

  Future<void> saveMeta(Photo photo) => _col.doc(photo.id).set(photo.toMap());

  Future<void> saveFull(String photoId, PhotoFull full) {
    return _col.doc(photoId).collection('full').doc('data').set(full.toMap());
  }

  @override
  Future<Photo> upload(
    String dogId,
    Uint8List bytes, {
    bool asCover = false,
    required String createdBy,
  }) async {
    final existing = await watchByDog(dogId).first;
    if (existing.length >= photoMaxPerDog) {
      throw const PhotoLimitReached();
    }
    final compressed = await compressDogPhoto(bytes);
    final now = DateTime.now();
    final id = 'p_${now.microsecondsSinceEpoch}';
    final cover = asCover || existing.isEmpty;
    final photo = Photo(
      id: id,
      dogId: dogId,
      isCover: cover,
      w: compressed.width,
      h: compressed.height,
      mime: compressed.mime,
      thumbB64: base64Encode(compressed.thumb),
      bytesFull: compressed.full.lengthInBytes,
      createdAt: now,
      createdBy: createdBy,
    );
    final batch = _db.batch();
    batch.set(_col.doc(id), photo.toMap());
    batch.set(_col.doc(id).collection('full').doc('data'), {
      'b64': base64Encode(compressed.full),
    });
    if (cover) {
      for (final doc in existing) {
        batch.update(_col.doc(doc.id), {'isCover': false});
      }
      batch.update(_db.collection('dogs').doc(dogId), {
        'fotoCopertinaId': id,
      });
    }
    await batch.commit();
    _cache[id] = compressed.full;
    return photo;
  }

  @override
  Future<Uint8List?> loadFull(String photoId) async {
    final cached = _cache[photoId];
    if (cached != null) {
      return cached;
    }
    final snap = await _col.doc(photoId).collection('full').doc('data').get();
    if (!snap.exists) {
      return null;
    }
    final full = PhotoFull.fromMap(_data(snap));
    if (full.b64.isEmpty) {
      return null;
    }
    final bytes = base64Decode(full.b64);
    _cache[photoId] = bytes;
    return bytes;
  }

  @override
  Future<void> setCover(String dogId, String photoId) async {
    final batch = _db.batch();
    final current = await _col.where('dogId', isEqualTo: dogId).get();
    for (final doc in current.docs) {
      batch.update(doc.reference, {'isCover': doc.id == photoId});
    }
    batch.update(_db.collection('dogs').doc(dogId), {
      'fotoCopertinaId': photoId,
    });
    await batch.commit();
  }

  @override
  Future<void> delete(String photoId) async {
    final snap = await _col.doc(photoId).get();
    final data = snap.data();
    final dogId = data?['dogId'] as String?;
    final wasCover = data?['isCover'] as bool? ?? false;
    await _col.doc(photoId).collection('full').doc('data').delete();
    await _col.doc(photoId).delete();
    _cache.remove(photoId);
    if (dogId == null) {
      return;
    }
    if (wasCover) {
      final rest = await watchByDog(dogId).first;
      if (rest.isEmpty) {
        await _db.collection('dogs').doc(dogId).update({
          'fotoCopertinaId': null,
        });
      } else {
        await setCover(dogId, rest.first.id);
      }
    }
  }
}

class FirestoreHealthRepository implements HealthRepository {
  FirestoreHealthRepository(this._db);
  final FirebaseFirestore _db;

  @override
  Stream<List<HealthRecord>> watchByDog(String dogId) {
    return _db
        .collection('health')
        .where('dogId', isEqualTo: dogId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => HealthRecord.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Stream<List<HealthRecord>> watchAll() {
    return _db.collection('health').snapshots().map(
      (snap) => snap.docs
          .map((doc) => HealthRecord.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  @override
  Future<void> save(HealthRecord record) {
    return _db.collection('health').doc(record.id).set(record.toMap());
  }
}

class FirestoreWeightRepository implements WeightRepository {
  FirestoreWeightRepository(this._db);
  final FirebaseFirestore _db;

  @override
  Stream<List<Weight>> watchByDog(String dogId) {
    return _db
        .collection('weights')
        .where('dogId', isEqualTo: dogId)
        .snapshots()
        .map(
          (snap) {
            final list = snap.docs
                .map((doc) => Weight.fromMap(doc.id, doc.data()))
                .toList();
            list.sort((a, b) => a.data.compareTo(b.data));
            return list;
          },
        );
  }

  @override
  Future<void> save(Weight weight) async {
    final batch = _db.batch();
    batch.set(_db.collection('weights').doc(weight.id), weight.toMap());
    batch.update(_db.collection('dogs').doc(weight.dogId), {
      'pesoKg': weight.kg,
      'updatedAt': dateTimeTo(weight.audit.updatedAt),
      'updatedBy': weight.audit.updatedBy,
    });
    await batch.commit();
  }
}

class FirestoreSponsorshipRepository implements SponsorshipRepository {
  FirestoreSponsorshipRepository(this._db);
  final FirebaseFirestore _db;

  @override
  Stream<List<Sponsorship>> watchByDog(String dogId) {
    return _db
        .collection('sponsorships')
        .where('dogId', isEqualTo: dogId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Sponsorship.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Future<void> save(Sponsorship sponsorship) {
    return _db
        .collection('sponsorships')
        .doc(sponsorship.id)
        .set(sponsorship.toMap());
  }
}

class FirestoreExpenseRepository implements ExpenseRepository {
  FirestoreExpenseRepository(this._db);
  final FirebaseFirestore _db;

  @override
  Stream<List<Expense>> watchByDog(String? dogId) {
    Query<Map<String, dynamic>> query = _db.collection('expenses');
    if (dogId != null) {
      query = query.where('dogId', isEqualTo: dogId);
    }
    return query.snapshots().map(
      (snap) =>
          snap.docs.map((doc) => Expense.fromMap(doc.id, doc.data())).toList(),
    );
  }

  @override
  Future<void> save(Expense expense) {
    return _db.collection('expenses').doc(expense.id).set(expense.toMap());
  }
}

class FirestoreAdoptionRepository implements AdoptionRepository {
  FirestoreAdoptionRepository(this._db);
  final FirebaseFirestore _db;

  @override
  Stream<List<Adoption>> watchAll() {
    return _db.collection('adoptions').snapshots().map(
      (snap) =>
          snap.docs.map((doc) => Adoption.fromMap(doc.id, doc.data())).toList(),
    );
  }

  @override
  Future<Adoption?> getById(String id) async {
    final snap = await _db.collection('adoptions').doc(id).get();
    if (!snap.exists) {
      return null;
    }
    return Adoption.fromMap(snap.id, _data(snap));
  }

  @override
  Future<void> save(Adoption adoption) {
    return _db.collection('adoptions').doc(adoption.id).set(adoption.toMap());
  }
}

class FirestoreDocumentRepository implements DocumentRepository {
  FirestoreDocumentRepository(this._db);
  final FirebaseFirestore _db;

  @override
  Stream<List<AppDocument>> watchByDog(String dogId) {
    return _db
        .collection('documents')
        .where('dogId', isEqualTo: dogId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => AppDocument.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Future<void> save(AppDocument document) {
    return _db.collection('documents').doc(document.id).set(document.toMap());
  }
}

class FirestoreNoteRepository implements NoteRepository {
  FirestoreNoteRepository(this._db);
  final FirebaseFirestore _db;

  @override
  Stream<List<Note>> watchByDog(String dogId) {
    return _db
        .collection('notes')
        .where('dogId', isEqualTo: dogId)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => Note.fromMap(doc.id, doc.data())).toList(),
        );
  }

  @override
  Future<void> save(Note note) {
    return _db.collection('notes').doc(note.id).set(note.toMap());
  }
}

class FirestoreAppointmentRepository implements AppointmentRepository {
  FirestoreAppointmentRepository(this._db);
  final FirebaseFirestore _db;

  @override
  Stream<List<Appointment>> watchAll() {
    return _db.collection('appointments').snapshots().map(
      (snap) => snap.docs
          .map((doc) => Appointment.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  @override
  Future<void> save(Appointment appointment) {
    return _db
        .collection('appointments')
        .doc(appointment.id)
        .set(appointment.toMap());
  }
}

class FirestoreVolunteerRepository implements VolunteerRepository {
  FirestoreVolunteerRepository(this._db);
  final FirebaseFirestore _db;

  @override
  Stream<List<Volunteer>> watchAll() {
    return _db.collection('volunteers').snapshots().map(
      (snap) =>
          snap.docs.map((doc) => Volunteer.fromMap(doc.id, doc.data())).toList(),
    );
  }

  @override
  Future<Volunteer?> getById(String id) async {
    final snap = await _db.collection('volunteers').doc(id).get();
    if (!snap.exists) {
      return null;
    }
    return Volunteer.fromMap(snap.id, _data(snap));
  }

  @override
  Future<void> save(Volunteer volunteer) {
    return _db.collection('volunteers').doc(volunteer.id).set(volunteer.toMap());
  }
}

class FirestoreBoxRepository implements BoxRepository {
  FirestoreBoxRepository(this._db);
  final FirebaseFirestore _db;

  @override
  Stream<List<ShelterBox>> watchAll() {
    return _db.collection('boxes').snapshots().map(
      (snap) => snap.docs
          .map((doc) => ShelterBox.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  @override
  Future<void> save(ShelterBox box) {
    return _db.collection('boxes').doc(box.id).set(box.toMap());
  }
}

class FirestoreSettingsRepository implements SettingsRepository {
  FirestoreSettingsRepository(this._db);
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection('settings').doc('association');

  @override
  Future<AssociationSettings?> getAssociation() async {
    final snap = await _doc.get();
    if (!snap.exists) {
      return null;
    }
    return AssociationSettings.fromMap(_data(snap));
  }

  @override
  Future<void> saveAssociation(AssociationSettings settings) {
    return _doc.set(settings.toMap());
  }
}

void enableFirestoreOffline(FirebaseFirestore db) {
  db.settings = const Settings(persistenceEnabled: true);
}
