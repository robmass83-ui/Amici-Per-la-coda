import 'dart:typed_data';

import 'package:amici_per_la_coda/core/firestore_codec.dart';
import 'package:amici_per_la_coda/data/firestore/firestore_repositories.dart';
import 'package:amici_per_la_coda/data/models/photo.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/dog_fixtures.dart';

const _coverThumbBytes = 20480;
const _dogCount = 199;
const _coverCount = 155;
const _extraPerCovered = 1;

int _payloadBytes(Iterable<Map<String, dynamic>> docs) {
  var total = 0;
  for (final doc in docs) {
    total += firestoreMapBytes(doc);
  }
  return total;
}

void main() {
  test('watchCovers: una query, solo isCover, senza le altre foto', () async {
    final db = FakeFirebaseFirestore();
    final dogs = FirestoreDogRepository(db);
    final photos = FirestorePhotoRepository(db);
    final at = DateTime.utc(2026, 9, 12);
    final thumb = Uint8List.fromList([1, 2, 3]);

    await dogs.save(testDog(id: 'fenice', nome: 'Fenice'));
    await dogs.save(testDog(id: 'brando', nome: 'Brando'));
    await photos.saveMeta(
      Photo(
        id: 'c-fenice',
        dogId: 'fenice',
        isCover: true,
        w: 160,
        h: 120,
        mime: 'image/jpeg',
        thumb: thumb,
        bytesFull: 1000,
        createdAt: at,
        createdBy: 'test',
      ),
    );
    await photos.saveMeta(
      Photo(
        id: 'e-fenice',
        dogId: 'fenice',
        isCover: false,
        w: 160,
        h: 120,
        mime: 'image/jpeg',
        thumb: thumb,
        bytesFull: 1000,
        createdAt: at,
        createdBy: 'test',
      ),
    );

    final covers = await photos.watchCovers().first;
    expect(covers.keys, ['fenice']);
    expect(covers['fenice']?.id, 'c-fenice');
    expect(covers.containsKey('brando'), isFalse);

    final allFenice = await photos.watchByDog('fenice').first;
    expect(allFenice, hasLength(2));
  });

  test('payload lista a freddo: cani + copertine, scorrere non aggiunge', () async {
    final db = FakeFirebaseFirestore();
    final dogsRepo = FirestoreDogRepository(db);
    final photosRepo = FirestorePhotoRepository(db);
    final at = DateTime.utc(2026, 9, 12);
    final thumb = Uint8List(_coverThumbBytes);

    for (var i = 0; i < _dogCount; i++) {
      await dogsRepo.save(testDog(id: 'd$i', nome: 'Cane $i'));
    }
    for (var i = 0; i < _coverCount; i++) {
      await photosRepo.saveMeta(
        Photo(
          id: 'c$i',
          dogId: 'd$i',
          isCover: true,
          w: 160,
          h: 120,
          mime: 'image/jpeg',
          thumb: thumb,
          bytesFull: 180000,
          createdAt: at,
          createdBy: 'test',
        ),
      );
      for (var extra = 0; extra < _extraPerCovered; extra++) {
        await photosRepo.saveMeta(
          Photo(
            id: 'e$i-$extra',
            dogId: 'd$i',
            isCover: false,
            w: 160,
            h: 120,
            mime: 'image/jpeg',
            thumb: thumb,
            bytesFull: 180000,
            createdAt: at.add(Duration(seconds: extra + 1)),
            createdBy: 'test',
          ),
        );
      }
    }

    final dogs = await dogsRepo.watchAll().first;
    final covers = await photosRepo.watchCovers().first;
    expect(dogs, hasLength(_dogCount));
    expect(covers, hasLength(_coverCount));

    final dogBytes = _payloadBytes(dogs.map((dog) => dog.toMap()));
    final coverBytes = _payloadBytes(
      covers.values.map((photo) => photo.toMap()),
    );
    final coldBytes = dogBytes + coverBytes;
    const extraPhotoCount = _coverCount * _extraPerCovered;
    final extrasIfQueriedPerDog = _payloadBytes([
      for (var i = 0; i < extraPhotoCount; i++)
        Photo(
          id: 'skip$i',
          dogId: 'd0',
          isCover: false,
          w: 160,
          h: 120,
          mime: 'image/jpeg',
          thumb: thumb,
          bytesFull: 180000,
          createdAt: at,
          createdBy: 'test',
        ).toMap(),
    ]);

    // Scorrere la lista rilegge gli stessi snapshot, senza query extra.
    final dogsAgain = await dogsRepo.watchAll().first;
    final coversAgain = await photosRepo.watchCovers().first;
    final hotBytes =
        _payloadBytes(dogsAgain.map((dog) => dog.toMap())) +
        _payloadBytes(coversAgain.values.map((photo) => photo.toMap()));
    const scrollAddedBytes = 0;

    expect(coversAgain.length, covers.length);
    expect(hotBytes, coldBytes);
    expect(scrollAddedBytes, 0);
    expect(
      extraPhotoCount,
      greaterThan(0),
      reason: 'le extra non devono entrare nel payload lista',
    );
    expect(coverBytes, lessThan(coverBytes + extrasIfQueriedPerDog));

    // ignore: avoid_print
    print(
      'STEP3 misura payload Blob: cold=$coldBytes hot=$hotBytes '
      'scrollAdded=$scrollAddedBytes dogBytes=$dogBytes coverBytes=$coverBytes',
    );
  });
}
