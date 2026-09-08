import 'dart:convert';

import 'package:amici_per_la_coda/core/firestore_codec.dart';
import 'package:amici_per_la_coda/data/firestore/firestore_repositories.dart';
import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/data/models/photo.dart';
import 'package:amici_per_la_coda/data/seed/cani_csv_parser.dart';
import 'package:amici_per_la_coda/data/seed/seed_data.dart';
import 'package:amici_per_la_coda/data/seed/seed_ids.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

(int, int, int) _ymd(DateTime? value) {
  expect(value, isNotNull);
  return (value!.year, value.month, value.day);
}

void main() {
  test('il seed crea 49 cani veri, 6 di prova, 3 volontari, 8 box e 5 richieste', () async {
    final db = FakeFirebaseFirestore();
    final report = await runSeed(db);

    expect(report.realDogs, 49);
    expect(report.demoDogs, 6);
    expect(report.dogs, 55);
    expect(report.volunteers, 3);
    expect(report.boxes, 8);
    expect(report.adoptions, 5);

    final dogs = await FirestoreDogRepository(db).watchAll().first;
    expect(dogs.where((dog) => isSeedId(dog.id)), hasLength(6));
    expect(dogs.where((dog) => !isSeedId(dog.id)), hasLength(49));
    expect(dogs.map((dog) => dog.id).toSet(), containsAll({
      'orso',
      'otto',
      'thelma',
      'seed_fenice',
      'seed_brando',
      'seed_nina',
      'seed_zeus',
      'seed_luna',
      'seed_otto',
    }));

    final nina = dogs.firstWhere((dog) => dog.id == 'seed_nina');
    expect(nina.nome, '${seedNamePrefix}Nina');
    expect(nina.stato, DogStato.inStallo);

    final fenice = dogs.firstWhere((dog) => dog.id == 'seed_fenice');
    expect(fenice.microchip, '380260043210987');
    expect(fenice.noteCarattere, contains('DATI DI PROVA'));

    final ottoVero = dogs.firstWhere((dog) => dog.id == 'otto');
    expect(ottoVero.nome, 'Otto');
    expect(ottoVero.sesso, DogSex.M);
    expect(_ymd(ottoVero.dataNascita), (2018, 1, 10));
    expect(ottoVero.sterilizzato, isFalse);
    expect(isSeedId(ottoVero.id), isFalse);

    final ottoProva = dogs.firstWhere((dog) => dog.id == 'seed_otto');
    expect(ottoProva.nome, '${seedNamePrefix}Otto');
    expect(ottoProva.stato, DogStato.adottato);

    final volunteers = await FirestoreVolunteerRepository(db).watchAll().first;
    expect(volunteers, hasLength(3));
    expect(volunteers.every((item) => isSeedId(item.id)), isTrue);

    final boxes = await FirestoreBoxRepository(db).watchAll().first;
    expect(boxes, hasLength(8));

    final adoptions = await FirestoreAdoptionRepository(db).watchAll().first;
    expect(adoptions, hasLength(5));
    expect(
      adoptions.firstWhere((item) => item.id == 'seed_ad_marta_luna').dogId,
      'seed_luna',
    );

    final settings = await FirestoreSettingsRepository(db).getAssociation();
    expect(settings?.denominazione, 'Amici per la Coda ODV');
  });

  test('Rimuovi dati di prova cancella solo i documenti seed_*', () async {
    final db = FakeFirebaseFirestore();
    await runSeed(db);

    final cleanup = await deleteSeedData(db);
    expect(cleanup.dogs, 6);
    expect(cleanup.adoptions, 5);
    expect(cleanup.volunteers, 3);

    final dogs = await FirestoreDogRepository(db).watchAll().first;
    expect(dogs, hasLength(49));
    expect(dogs.every((dog) => !isSeedId(dog.id)), isTrue);
    expect(dogs.any((dog) => dog.id == 'orso'), isTrue);
    expect(dogs.any((dog) => dog.id == 'seed_fenice'), isFalse);

    final adoptions = await FirestoreAdoptionRepository(db).watchAll().first;
    expect(adoptions, isEmpty);

    final volunteers = await FirestoreVolunteerRepository(db).watchAll().first;
    expect(volunteers, isEmpty);
  });

  test('il parser CSV assegna id univoci e Totò diventa toto', () {
    expect(slugDogId('Totò'), 'toto');
    expect(slugDogId('Dartagnan'), 'dartagnan');
    expect(slugDogId('Cicorietta'), 'cicorietta');

    final parsed = dogsFromCaniCsv(
      Audit.seed(DateTime.utc(2024, 6, 25, 10)),
    );
    expect(parsed, hasLength(49));
    expect(parsed.map((dog) => dog.id).toSet(), hasLength(49));
    expect(parsed.firstWhere((dog) => dog.id == 'orso').dataNascita, DateTime.utc(2021, 3, 17));
    expect(parsed.firstWhere((dog) => dog.id == 'toto').nome, 'Totò');
  });

  test('repository: save e getById di un cane', () async {
    final db = FakeFirebaseFirestore();
    await runSeed(db);
    final repo = FirestoreDogRepository(db);

    final fenice = await repo.getById('seed_fenice');
    expect(fenice, isNotNull);
    expect(fenice!.nome, '${seedNamePrefix}Fenice');
    expect(fenice.dataNascita, isNotNull);

    final orso = await repo.getById('orso');
    expect(orso, isNotNull);
    expect(orso!.nome, 'Orso');
    expect(_ymd(orso.dataNascita), (2021, 3, 17));
  });

  test('repository foto: meta, full e copertina', () async {
    final db = FakeFirebaseFirestore();
    await runSeed(db);
    final photos = FirestorePhotoRepository(db);
    final at = DateTime.utc(2026, 9, 8);

    await photos.saveMeta(
      Photo(
        id: 'ph1',
        dogId: 'seed_fenice',
        isCover: false,
        w: 160,
        h: 120,
        mime: 'image/jpeg',
        thumbB64: 'thumb',
        bytesFull: 1000,
        createdAt: at,
        createdBy: 'seed',
      ),
    );
    await photos.saveFull(
      'ph1',
      PhotoFull(b64: base64Encode(utf8.encode('full-bytes'))),
    );
    expect(await photos.loadFull('ph1'), utf8.encode('full-bytes'));

    await photos.setCover('seed_fenice', 'ph1');
    final list = await photos.watchByDog('seed_fenice').first;
    expect(list.single.isCover, isTrue);
    expect(
      (await FirestoreDogRepository(db).getById('seed_fenice'))?.fotoCopertinaId,
      'ph1',
    );
  });
}
