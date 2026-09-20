import 'dart:convert';
import 'dart:typed_data';

import 'package:amici_per_la_coda/core/firestore_codec.dart';
import 'package:amici_per_la_coda/data/firestore/firestore_repositories.dart';
import 'package:amici_per_la_coda/data/models/photo.dart';
import 'package:amici_per_la_coda/data/photos/photo_codec.dart';
import 'package:amici_per_la_coda/data/photos/photo_limit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final at = DateTime.utc(2026, 9, 12);

  test('toMap scrive Blob nei campi nuovi, senza thumbB64 né b64', () {
    final photo = Photo(
      id: 'p1',
      dogId: 'fenice',
      isCover: true,
      w: 10,
      h: 8,
      mime: 'image/jpeg',
      thumb: Uint8List.fromList([1, 2, 3]),
      bytesFull: 12,
      createdAt: at,
      createdBy: 'u1',
    );
    final map = photo.toMap();
    expect(map['thumb'], isA<Blob>());
    expect(map.containsKey('thumbB64'), isFalse);
    expect((map['thumb'] as Blob).bytes, [1, 2, 3]);

    final full = PhotoFull(dati: Uint8List.fromList([9, 8, 7]));
    expect(full.toMap()['dati'], isA<Blob>());
    expect(full.toMap().containsKey('b64'), isFalse);
  });

  test('fromMap legge Blob e i campi legacy base64', () {
    final bytes = Uint8List.fromList([10, 20, 30]);
    final fromBlob = Photo.fromMap('p1', {
      'dogId': 'fenice',
      'isCover': true,
      'w': 1,
      'h': 1,
      'mime': 'image/jpeg',
      'thumb': Blob(bytes),
      'bytesFull': 3,
      'createdAt': Timestamp.fromDate(at),
      'createdBy': 'u1',
    });
    expect(fromBlob.thumb, bytes);

    final fromLegacy = Photo.fromMap('p2', {
      'dogId': 'fenice',
      'isCover': false,
      'w': 1,
      'h': 1,
      'mime': 'image/jpeg',
      'thumbB64': base64Encode(bytes),
      'bytesFull': 3,
      'createdAt': Timestamp.fromDate(at),
      'createdBy': 'u1',
    });
    expect(fromLegacy.thumb, bytes);

    expect(PhotoFull.fromMap({'dati': Blob(bytes)}).dati, bytes);
    expect(PhotoFull.fromMap({'b64': base64Encode(bytes)}).dati, bytes);
  });

  test('saveFull oltre 900 KB viene rifiutato prima della scrittura', () async {
    final db = FakeFirebaseFirestore();
    final photos = FirestorePhotoRepository(db);
    final tooBig = Uint8List(photoDocumentMaxBytes + 1);
    await expectLater(
      photos.saveFull('huge', PhotoFull(dati: tooBig)),
      throwsA(isA<PhotoTooLarge>()),
    );
    final snap = await db
        .collection('photos')
        .doc('huge')
        .collection('full')
        .doc('data')
        .get();
    expect(snap.exists, isFalse);
  });

  test('Blob pesa circa il 25% in meno del base64 a parità di bytes', () {
    final bytes = Uint8List(15 * 1024);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = i & 255;
    }
    final blobDoc = <String, dynamic>{
      'dogId': 'fenice',
      'isCover': true,
      'w': 160,
      'h': 120,
      'mime': 'image/jpeg',
      'bytesFull': 180000,
      'createdBy': 'test',
      'thumb': Blob(bytes),
    };
    final b64Doc = <String, dynamic>{
      'dogId': 'fenice',
      'isCover': true,
      'w': 160,
      'h': 120,
      'mime': 'image/jpeg',
      'bytesFull': 180000,
      'createdBy': 'test',
      'thumbB64': base64Encode(bytes),
    };
    final blobSize = firestoreMapBytes(blobDoc);
    final b64Size = firestoreMapBytes(b64Doc);
    expect(blobSize / b64Size, lessThan(0.8));
    expect(blobSize / b64Size, closeTo(0.75, 0.05));
  });

  test('repository: round-trip Blob e lettura legacy', () async {
    final db = FakeFirebaseFirestore();
    final photos = FirestorePhotoRepository(db);
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    await photos.saveMeta(
      Photo(
        id: 'blob1',
        dogId: 'fenice',
        isCover: true,
        w: 2,
        h: 2,
        mime: 'image/jpeg',
        thumb: bytes,
        bytesFull: 4,
        createdAt: at,
        createdBy: 'test',
      ),
    );
    await photos.saveFull('blob1', PhotoFull(dati: bytes));
    final stored = (await db.collection('photos').doc('blob1').get()).data()!;
    expect(stored['thumb'], isA<Blob>());
    expect(stored.containsKey('thumbB64'), isFalse);
    final loaded = await photos.watchByDog('fenice').first;
    expect(loaded.single.thumb, bytes);
    expect(await photos.loadFull('blob1'), bytes);

    await db.collection('photos').doc('legacy').set({
      'dogId': 'fenice',
      'isCover': false,
      'w': 1,
      'h': 1,
      'mime': 'image/jpeg',
      'thumbB64': base64Encode([9, 8, 7]),
      'bytesFull': 3,
      'createdAt': Timestamp.fromDate(at),
      'createdBy': 'old',
    });
    await db.collection('photos').doc('legacy').collection('full').doc('data').set({
      'b64': base64Encode([9, 8, 7]),
    });
    final all = await photos.watchByDog('fenice').first;
    final legacy = all.firstWhere((photo) => photo.id == 'legacy');
    expect(legacy.thumb, [9, 8, 7]);
    expect(await photos.loadFull('legacy'), [9, 8, 7]);
  });
}
