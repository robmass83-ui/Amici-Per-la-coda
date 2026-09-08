import 'package:cloud_firestore/cloud_firestore.dart';

import 'new_dog_draft.dart';

abstract interface class DogDraftStore {
  Future<NewDogDraft?> load(String uid);
  Future<void> save(String uid, NewDogDraft draft);
  Future<void> clear(String uid);
}

class InMemoryDogDraftStore implements DogDraftStore {
  final Map<String, NewDogDraft> _byUid = {};

  @override
  Future<NewDogDraft?> load(String uid) async => _byUid[uid];

  @override
  Future<void> save(String uid, NewDogDraft draft) async {
    _byUid[uid] = draft;
  }

  @override
  Future<void> clear(String uid) async {
    _byUid.remove(uid);
  }
}

class FirestoreDogDraftStore implements DogDraftStore {
  FirestoreDogDraftStore(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) {
    return _db.collection('dogDrafts').doc(uid);
  }

  @override
  Future<NewDogDraft?> load(String uid) async {
    final snap = await _doc(uid).get();
    final data = snap.data();
    if (!snap.exists || data == null) {
      return null;
    }
    return NewDogDraft.fromMap(data);
  }

  @override
  Future<void> save(String uid, NewDogDraft draft) {
    return _doc(uid).set(draft.toMap());
  }

  @override
  Future<void> clear(String uid) {
    return _doc(uid).delete();
  }
}
