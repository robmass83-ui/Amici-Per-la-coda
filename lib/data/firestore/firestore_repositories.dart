import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firestore_codec.dart';
import '../dog_archive.dart';
import '../documents/document_codec.dart';
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
import '../models/vendor.dart';
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

  late final _allSnaps = SharedQuerySnapshots(_col);

  @override
  Stream<List<Dog>> watchAll() {
    return _allSnaps.snapshots().map(
      (snap) =>
          snap.docs.map((doc) => Dog.fromMap(doc.id, doc.data())).toList(),
    );
  }

  Stream<bool> watchAllFromCacheFlags() {
    return _allSnaps.snapshots().map((snap) => snap.metadata.isFromCache);
  }

  Future<void> confirmDogsServer() {
    return _col.limit(1).get(const GetOptions(source: Source.server));
  }

  Stream<bool> watchAllFromCache() {
    return freshnessFromCacheFlags(
      watchAllFromCacheFlags(),
      confirmDogsServer,
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

  @override
  Future<void> delete(String id) => _col.doc(id).delete();

  @override
  Future<void> ripristina(
    String id, {
    required String autoreId,
    DateTime? now,
  }) async {
    final dog = await getById(id);
    if (dog == null || !dogInArchivio(dog)) {
      return;
    }
    await save(
      applyRipristina(dog: dog, autoreId: autoreId, now: now ?? DateTime.now()),
    );
  }
}

class FirestorePhotoRepository implements PhotoRepository {
  FirestorePhotoRepository(this._db);
  final FirebaseFirestore _db;
  final _cache = LruBytesCache();

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('photos');

  late final _coverSnaps = SharedQuerySnapshots(
    _col.where('isCover', isEqualTo: true),
  );

  @override
  Stream<List<Photo>> watchByDog(String dogId) {
    return _col.where('dogId', isEqualTo: dogId).snapshots().map((snap) {
      final list = snap.docs
          .map((doc) => Photo.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Stream<Map<String, Photo>> watchCovers() {
    return _coverSnaps.snapshots().map((snap) {
      final covers = <String, Photo>{};
      for (final doc in snap.docs) {
        final photo = Photo.fromMap(doc.id, doc.data());
        if (photo.dogId.isEmpty) {
          continue;
        }
        covers[photo.dogId] = photo;
      }
      return covers;
    });
  }

  Stream<bool> watchCoversFromCacheFlags() {
    return _coverSnaps.snapshots().map((snap) => snap.metadata.isFromCache);
  }

  Future<void> confirmCoversServer() {
    return _col.limit(1).get(const GetOptions(source: Source.server));
  }

  Stream<bool> watchCoversFromCache() {
    return freshnessFromCacheFlags(
      watchCoversFromCacheFlags(),
      confirmCoversServer,
    );
  }

  Future<void> saveMeta(Photo photo) async {
    final data = photo.toMap();
    ensurePhotoDocumentFits(data);
    await _col.doc(photo.id).set(data);
  }

  Future<void> saveFull(String photoId, PhotoFull full) async {
    final data = full.toMap();
    ensurePhotoDocumentFits(data);
    await _col.doc(photoId).collection('full').doc('data').set(data);
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
    if (compressed.full.lengthInBytes > photoFullMaxBytes ||
        compressed.thumb.lengthInBytes > photoThumbMaxBytes) {
      throw const PhotoTooLarge();
    }
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
      thumb: compressed.thumb,
      bytesFull: compressed.full.lengthInBytes,
      createdAt: now,
      createdBy: createdBy,
    );
    final meta = photo.toMap();
    final full = PhotoFull(dati: compressed.full).toMap();
    ensurePhotoDocumentFits(meta);
    ensurePhotoDocumentFits(full);
    final batch = _db.batch();
    batch.set(_col.doc(id), meta);
    batch.set(_col.doc(id).collection('full').doc('data'), full);
    if (cover) {
      for (final doc in existing) {
        batch.update(_col.doc(doc.id), {'isCover': false});
      }
    }
    batch.update(_db.collection('dogs').doc(dogId), {
      'fotoCount': FieldValue.increment(1),
      if (cover) 'fotoCopertinaId': id,
    });
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
    if (full.dati.isEmpty) {
      return null;
    }
    _cache[photoId] = full.dati;
    return full.dati;
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

  /// Una sola query: tutte le copertine. Usata dalla lista, non `watchByDog`.

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
    final dogRef = _db.collection('dogs').doc(dogId);
    if (wasCover) {
      final rest = await watchByDog(dogId).first;
      if (rest.isEmpty) {
        await dogRef.update({
          'fotoCopertinaId': null,
          'fotoCount': FieldValue.increment(-1),
        });
      } else {
        await setCover(dogId, rest.first.id);
        await dogRef.update({'fotoCount': FieldValue.increment(-1)});
      }
    } else {
      await dogRef.update({'fotoCount': FieldValue.increment(-1)});
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
    return _db
        .collection('health')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => HealthRecord.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Future<void> save(HealthRecord record) {
    return _db.collection('health').doc(record.id).set(record.toMap());
  }

  @override
  Future<void> delete(String id) {
    return _db.collection('health').doc(id).delete();
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
        .map((snap) {
          final list = snap.docs
              .map((doc) => Weight.fromMap(doc.id, doc.data()))
              .toList();
          list.sort((a, b) => a.data.compareTo(b.data));
          return list;
        });
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

  @override
  Future<void> delete(String id) async {
    final snap = await _db.collection('weights').doc(id).get();
    final dogId = snap.data()?['dogId'] as String? ?? '';
    final batch = _db.batch();
    batch.delete(_db.collection('weights').doc(id));
    if (dogId.isNotEmpty) {
      final remaining = await _db
          .collection('weights')
          .where('dogId', isEqualTo: dogId)
          .get();
      final others =
          remaining.docs
              .where((doc) => doc.id != id)
              .map((doc) => Weight.fromMap(doc.id, doc.data()))
              .toList()
            ..sort((a, b) => a.data.compareTo(b.data));
      final latest = others.isEmpty ? null : others.last;
      batch.update(_db.collection('dogs').doc(dogId), {'pesoKg': latest?.kg});
    }
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
  Stream<List<Sponsorship>> watchAll() {
    return _db
        .collection('sponsorships')
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

  @override
  Future<void> delete(String id) {
    return _db.collection('sponsorships').doc(id).delete();
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

  @override
  Future<void> delete(String id) {
    return _db.collection('expenses').doc(id).delete();
  }
}

class FirestoreAdopterRepository implements AdopterRepository {
  FirestoreAdopterRepository(this._db);
  final FirebaseFirestore _db;

  @override
  Stream<List<Adopter>> watchAll() {
    return _db
        .collection('adopters')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Adopter.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Future<Adopter?> getById(String id) async {
    final snap = await _db.collection('adopters').doc(id).get();
    if (!snap.exists) {
      return null;
    }
    return Adopter.fromMap(snap.id, _data(snap));
  }

  @override
  Future<void> save(Adopter adopter) {
    return _db.collection('adopters').doc(adopter.id).set(adopter.toMap());
  }
}

class FirestoreVendorRepository implements VendorRepository {
  FirestoreVendorRepository(this._db);
  final FirebaseFirestore _db;

  @override
  Stream<List<Vendor>> watchAll() {
    return _db
        .collection('vendors')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Vendor.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Future<Vendor?> getById(String id) async {
    final snap = await _db.collection('vendors').doc(id).get();
    if (!snap.exists) {
      return null;
    }
    return Vendor.fromMap(snap.id, _data(snap));
  }

  @override
  Future<void> save(Vendor vendor) {
    return _db.collection('vendors').doc(vendor.id).set(vendor.toMap());
  }
}

class FirestoreAdoptionRepository implements AdoptionRepository {
  FirestoreAdoptionRepository(this._db);
  final FirebaseFirestore _db;

  @override
  Stream<List<Adoption>> watchAll() {
    return _db
        .collection('adoptions')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Adoption.fromMap(doc.id, doc.data()))
              .toList(),
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

  @override
  Future<void> delete(String id) {
    return _db.collection('adoptions').doc(id).delete();
  }
}

class FirestoreDocumentRepository implements DocumentRepository {
  FirestoreDocumentRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('documents');

  @override
  Stream<List<AppDocument>> watchAll() {
    return _col.snapshots().map(
      (snap) => snap.docs
          .map((doc) => AppDocument.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  Stream<List<AppDocument>> _watchWhere(String field, String value) {
    return _col
        .where(field, isEqualTo: value)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => AppDocument.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Stream<List<AppDocument>> watchByDog(String dogId) =>
      _watchWhere('dogId', dogId);

  @override
  Stream<List<AppDocument>> watchByAdopter(String adopterId) =>
      _watchWhere('adopterId', adopterId);

  @override
  Stream<List<AppDocument>> watchByAdoption(String adoptionId) =>
      _watchWhere('adoptionId', adoptionId);

  @override
  Future<void> save(AppDocument document) {
    ensureDocumentHasContent(document);
    return _col.doc(document.id).set(document.toMap());
  }

  @override
  Future<AppDocument> saveBytes(AppDocument document, Uint8List bytes) async {
    if (bytes.isEmpty) {
      throw ArgumentError(
        'Un documento deve avere un file: contenutoB64 e chunkCount non possono essere entrambi vuoti.',
      );
    }
    ensureDocumentSizeAllowed(bytes.lengthInBytes);
    final count = documentChunkCount(bytes.lengthInBytes);
    if (count == 0) {
      final saved = document.copyWith(
        chunkCount: 0,
        contenutoB64: base64Encode(bytes),
      );
      await _col.doc(saved.id).set(saved.toMap());
      return saved;
    }
    final chunks = splitDocumentBytes(bytes);
    final saved = document.copyWith(
      chunkCount: chunks.length,
      clearContenuto: true,
    );
    final batch = _db.batch();
    batch.set(_col.doc(saved.id), saved.toMap());
    for (var i = 0; i < chunks.length; i++) {
      batch.set(_col.doc(saved.id).collection('chunks').doc('$i'), {
        'b64': base64Encode(chunks[i]),
        'index': i,
      });
    }
    await batch.commit();
    return saved;
  }

  @override
  Future<Uint8List> loadBytes(String id) async {
    final snap = await _col.doc(id).get();
    if (!snap.exists) {
      throw StateError('Documento non trovato.');
    }
    final doc = AppDocument.fromMap(snap.id, _data(snap));
    if (doc.chunkCount == 0) {
      final b64 = doc.contenutoB64 ?? '';
      if (b64.isEmpty) {
        return Uint8List(0);
      }
      return base64Decode(b64);
    }
    final chunks = <Uint8List>[];
    for (var i = 0; i < doc.chunkCount; i++) {
      final chunk = await _col.doc(id).collection('chunks').doc('$i').get();
      final b64 = chunk.data()?['b64'] as String? ?? '';
      chunks.add(base64Decode(b64));
    }
    return joinDocumentChunks(chunks);
  }

  @override
  Future<void> delete(String id) async {
    final snap = await _col.doc(id).get();
    final count = intFrom(snap.data()?['chunkCount']);
    for (var i = 0; i < count; i++) {
      await _col.doc(id).collection('chunks').doc('$i').delete();
    }
    await _col.doc(id).delete();
  }
}

class FirestoreTemplateRepository implements TemplateRepository {
  FirestoreTemplateRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('templates');

  @override
  Stream<List<DocumentTemplate>> watchAll() {
    return _col.snapshots().map(
      (snap) => snap.docs
          .map((doc) => DocumentTemplate.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  @override
  Future<DocumentTemplate?> getById(String id) async {
    final snap = await getCacheThenServer(_col.doc(id));
    if (!snap.exists) {
      return null;
    }
    return DocumentTemplate.fromMap(snap.id, _data(snap));
  }

  @override
  Future<void> save(DocumentTemplate template) {
    return _col.doc(template.id).set(template.toMap());
  }

  @override
  Future<void> delete(String id) {
    return _col.doc(id).delete();
  }

  @override
  Future<void> ensureDefaults({
    required AssetBytesLoader loader,
    required String uid,
    DateTime? now,
  }) async {
    final existing = await getQueryCacheThenServer(_col.limit(1));
    if (existing.docs.isNotEmpty) {
      return;
    }
    final at = now ?? DateTime.now();
    for (final spec in defaultTemplates) {
      final bytes = await loader.load(spec.assetPath);
      await save(
        DocumentTemplate(
          id: spec.id,
          nome: spec.nome,
          descrizione: spec.descrizione,
          fileName: spec.fileName,
          mime: 'application/pdf',
          pdfB64: base64Encode(bytes),
          versione: 1,
          aggiornatoIl: at,
          aggiornatoDa: uid,
        ),
      );
    }
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

  @override
  Future<void> delete(String id) {
    return _db.collection('notes').doc(id).delete();
  }
}

class FirestoreAppointmentRepository implements AppointmentRepository {
  FirestoreAppointmentRepository(this._db);
  final FirebaseFirestore _db;

  @override
  Stream<List<Appointment>> watchAll() {
    return _db
        .collection('appointments')
        .snapshots()
        .map(
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

  @override
  Future<void> delete(String id) {
    return _db.collection('appointments').doc(id).delete();
  }
}

class FirestoreVolunteerRepository implements VolunteerRepository {
  FirestoreVolunteerRepository(this._db);
  final FirebaseFirestore _db;

  @override
  Stream<List<Volunteer>> watchAll() {
    return _db
        .collection('volunteers')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Volunteer.fromMap(doc.id, doc.data()))
              .toList(),
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
    return _db
        .collection('volunteers')
        .doc(volunteer.id)
        .set(volunteer.toMap());
  }

  @override
  Future<void> delete(String id) {
    return _db.collection('volunteers').doc(id).delete();
  }

  @override
  Future<void> updateSelf({
    required String id,
    bool? mustChangePassword,
    DateTime? ultimoAccesso,
    String? coloreAvatar,
  }) async {
    final data = <String, dynamic>{};
    if (mustChangePassword != null) {
      data['mustChangePassword'] = mustChangePassword;
    }
    if (ultimoAccesso != null) {
      data['ultimoAccesso'] = dateTimeTo(ultimoAccesso);
    }
    if (coloreAvatar != null) {
      data['coloreAvatar'] = coloreAvatar;
    }
    if (data.isEmpty) {
      return;
    }
    final doc = _db.collection('volunteers').doc(id);
    await doc.update(data);
    try {
      await _db.waitForPendingWrites().timeout(const Duration(seconds: 20));
    } on TimeoutException {
      // La verifica a valle (getById) intercetta se il flag non è persistito.
    }
  }

  CollectionReference<Map<String, dynamic>> get _authTokens =>
      _db.collection('authTokens');

  @override
  Future<void> saveAuthRefreshToken({
    required String id,
    required String token,
  }) {
    return _authTokens.doc(id).set({
      'refreshToken': token,
      'updatedAt': dateTimeTo(DateTime.now()),
    });
  }

  @override
  Future<String?> getAuthRefreshToken(String id) async {
    final snap = await _authTokens.doc(id).get();
    if (!snap.exists) {
      return null;
    }
    final token = _data(snap)['refreshToken'] as String?;
    if (token == null || token.isEmpty) {
      return null;
    }
    return token;
  }

  @override
  Future<void> deleteAuthRefreshToken(String id) {
    return _authTokens.doc(id).delete();
  }
}

class FirestoreBoxRepository implements BoxRepository {
  FirestoreBoxRepository(this._db);
  final FirebaseFirestore _db;

  @override
  Stream<List<ShelterBox>> watchAll() {
    return _db
        .collection('boxes')
        .snapshots()
        .map(
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
    final snap = await getCacheThenServer(_doc);
    if (!snap.exists) {
      return null;
    }
    return AssociationSettings.fromMap(_data(snap));
  }

  @override
  Stream<AssociationSettings?> watchAssociation() {
    return _doc.snapshots().map((snap) {
      if (!snap.exists) {
        return null;
      }
      return AssociationSettings.fromMap(_data(snap));
    });
  }

  @override
  Future<void> saveAssociation(AssociationSettings settings) {
    return _doc.set(settings.toMap());
  }
}

/// Persistenza esplicita. Su Android è la cache nativa; sul web IndexedDB.
/// Se il browser rifiuta, `settings` lancia e il catch lascia l'app online-only.
void enableFirestoreOffline(FirebaseFirestore db) {
  try {
    db.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (_) {
    // settings va impostato prima di qualsiasi lettura/scrittura.
  }
}
