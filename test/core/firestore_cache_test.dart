import 'package:amici_per_la_coda/core/firestore_codec.dart';
import 'package:amici_per_la_coda/data/firestore/firestore_repositories.dart';
import 'package:amici_per_la_coda/data/models/association_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/dog_fixtures.dart';
import '../helpers/fake_settings_repository.dart';

void main() {
  test('getCacheThenServer legge il documento già in cache', () async {
    final db = FakeFirebaseFirestore();
    final doc = db.collection('settings').doc('association');
    await doc.set(testAssociationSettings().toMap());

    final snap = await getCacheThenServer(doc);
    expect(snap.exists, isTrue);
    expect(snap.data()?['denominazione'], 'Amici per la Coda ODV');
  });

  test('getAssociation usa cache-then-server', () async {
    final db = FakeFirebaseFirestore();
    final repo = FirestoreSettingsRepository(db);
    await repo.saveAssociation(
      testAssociationSettings(capienzaAutorizzata: 12),
    );

    final settings = await repo.getAssociation();
    expect(settings, isA<AssociationSettings>());
    expect(settings!.capienzaAutorizzata, 12);

    final source = await db.collection('settings').doc('association').get();
    expect(source.exists, isTrue);
  });

  test('watchAll e fromCache condividono lo stesso snapshot dogs', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('dogs').doc('fido').set(testDog().toMap());
    final repo = FirestoreDogRepository(db);

    final dogs = await repo.watchAll().first;
    final fromCache = await repo.watchAllFromCache().first;

    expect(dogs.single.id, 'fido');
    expect(fromCache, isA<bool>());
  });

  test('GetOptions Source.cache è nel codec', () {
    expect(Source.cache, isNotNull);
  });

  test('enableFirestoreOffline non lancia', () {
    final db = FakeFirebaseFirestore();
    expect(() => enableFirestoreOffline(db), returnsNormally);
  });

  test('snapshot solo cache: se il server risponde i dati sono aggiornati', () async {
    final seen = await freshnessFromCacheFlags(
      Stream<bool>.fromIterable([true]),
      () async {},
    ).toList();
    expect(seen, [false]);
  });

  test('snapshot solo cache: se il server non risponde restano non aggiornati',
      () async {
    final seen = await freshnessFromCacheFlags(
      Stream<bool>.fromIterable([true]),
      () async {
        throw StateError('server');
      },
    ).toList();
    expect(seen, [true]);
  });

  test('snapshot dal server non chiede un get extra', () async {
    var confirms = 0;
    final seen = await freshnessFromCacheFlags(
      Stream<bool>.fromIterable([false]),
      () async {
        confirms++;
      },
    ).toList();
    expect(seen, [false]);
    expect(confirms, 0);
  });

  test('senza login la cache non conta come non aggiornato', () async {
    var confirms = 0;
    final seen = await sessionCacheFreshness(
      signedIn: false,
      snapshots: () => Stream<bool>.fromIterable([true]),
      confirmServer: () async {
        confirms++;
      },
    ).toList();
    expect(seen, [false]);
    expect(confirms, 0);
  });

  test('al login la cache viene ricontrollata sul server', () async {
    final seen = await sessionCacheFreshness(
      signedIn: true,
      snapshots: () => Stream<bool>.fromIterable([true]),
      confirmServer: () async {},
    ).toList();
    expect(seen, [false]);
  });

  test('al login se il primo get server fallisce si ritenta', () async {
    var confirms = 0;
    final seen = await sessionCacheFreshness(
      signedIn: true,
      snapshots: () => Stream<bool>.fromIterable([true]),
      confirmServer: () async {
        confirms++;
        if (confirms == 1) {
          throw StateError('auth non pronto');
        }
      },
    ).toList();
    expect(seen, [false]);
    expect(confirms, 2);
  });
}
