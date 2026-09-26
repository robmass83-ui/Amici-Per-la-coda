import 'dart:typed_data';

import 'package:amici_per_la_coda/core/firestore_codec.dart';
import 'package:amici_per_la_coda/data/documents/document_codec.dart';
import 'package:amici_per_la_coda/data/firestore/firestore_contabilita_repository.dart';
import 'package:amici_per_la_coda/data/models/documento_contabile.dart';
import 'package:amici_per_la_coda/data/repositories/contabilita_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

DocumentoContabile sample({
  String id = 'c1',
  int generation = 1,
  int dimensione = 4,
  int chunkCount = 1,
  String nome = 'Fattura',
}) {
  return DocumentoContabile(
    id: id,
    anno: 2026,
    nome: nome,
    data: DateTime.utc(2026, 3, 12),
    tipologia: TipologiaContabile.fattura,
    descrizione: '',
    importo: null,
    mime: 'application/pdf',
    nomeFile: 'f.pdf',
    dimensione: dimensione,
    chunkCount: chunkCount,
    generation: generation,
    audit: Audit.seed(DateTime.utc(2026, 3, 12), by: 'uid-1'),
  );
}

void main() {
  test('il padre non contiene i byte', () async {
    final db = FakeFirebaseFirestore();
    final repo = FirestoreContabilitaRepository(db);
    final doc = sample(id: 'c1', generation: 1, dimensione: 4, chunkCount: 1);
    await repo.saveNuovo(doc, Uint8List.fromList([9, 8, 7, 6]));

    final parent = await db.collection('contabilita').doc('c1').get();
    expect(parent.data()!.containsKey('contenutoB64'), isFalse);
    expect(parent.data()!['chunkCount'], 1);
    expect(parent.data()!['dimensione'], 4);
    final chunk = await db
        .collection('contabilita')
        .doc('c1')
        .collection('g')
        .doc('1')
        .collection('chunks')
        .doc('0')
        .get();
    expect(chunk.data()!['index'], 0);
    expect(repo.loadBytes('c1'), completion(Uint8List.fromList([9, 8, 7, 6])));
  });

  test(
    'la sostituzione lascia il file vecchio se il padre non si aggiorna',
    () async {
      final db = FakeFirebaseFirestore();
      final initialRepo = FirestoreContabilitaRepository(db);
      await initialRepo.saveNuovo(
        sample(id: 'c1', dimensione: 2),
        Uint8List.fromList([1, 1]),
      );
      final repo = FirestoreContabilitaRepository(
        db,
        failBeforeParentUpdate: true,
      );

      await expectLater(
        repo.replaceFile(
          sample(id: 'c1', nome: 'nuovo', dimensione: 3),
          Uint8List.fromList([2, 2, 2]),
        ),
        throwsA(isA<StateError>()),
      );

      final parent = await db.collection('contabilita').doc('c1').get();
      expect(parent.data()!['generation'], 1);
      expect(await repo.loadBytes('c1'), Uint8List.fromList([1, 1]));
      final newChunk = await db
          .collection('contabilita')
          .doc('c1')
          .collection('g')
          .doc('2')
          .collection('chunks')
          .doc('0')
          .get();
      expect(newChunk.exists, isFalse);
    },
  );

  test(
    'la sostituzione usa la nuova generazione e poi elimina la vecchia',
    () async {
      final db = FakeFirebaseFirestore();
      final repo = FirestoreContabilitaRepository(db);
      await repo.saveNuovo(sample(dimensione: 2), Uint8List.fromList([1, 1]));

      await repo.replaceFile(
        sample(nome: 'nuovo', dimensione: 3, chunkCount: 99),
        Uint8List.fromList([2, 2, 2]),
      );

      final parent = await db.collection('contabilita').doc('c1').get();
      expect(parent.data()!['generation'], 2);
      expect(parent.data()!['chunkCount'], 1);
      expect(parent.data()!['dimensione'], 3);
      expect(await repo.loadBytes('c1'), Uint8List.fromList([2, 2, 2]));
      final oldChunk = await db
          .collection('contabilita')
          .doc('c1')
          .collection('g')
          .doc('1')
          .collection('chunks')
          .doc('0')
          .get();
      expect(oldChunk.exists, isFalse);
    },
  );

  test('un file oltre un chunk viene scritto in due documenti', () async {
    final db = FakeFirebaseFirestore();
    final repo = FirestoreContabilitaRepository(db);
    final bytes = Uint8List(documentChunkBytes + 1);

    await repo.saveNuovo(sample(dimensione: bytes.lengthInBytes), bytes);

    final chunks = await db
        .collection('contabilita')
        .doc('c1')
        .collection('g')
        .doc('1')
        .collection('chunks')
        .get();
    expect(chunks.docs, hasLength(2));
    expect(
      (await db.collection('contabilita').doc('c1').get())
          .data()!['chunkCount'],
      2,
    );
  });

  test('loadBytes lancia se manca un pezzo atteso', () async {
    final db = FakeFirebaseFirestore();
    final repo = FirestoreContabilitaRepository(db);
    await repo.saveNuovo(sample(), Uint8List.fromList([1, 2, 3, 4]));
    await db.collection('contabilita').doc('c1').update({'chunkCount': 2});

    await expectLater(repo.loadBytes('c1'), throwsA(isA<StateError>()));
  });

  test('deleteDocumento cancella padre e pezzi della generazione', () async {
    final db = FakeFirebaseFirestore();
    final repo = FirestoreContabilitaRepository(db);
    await repo.saveNuovo(sample(), Uint8List.fromList([1, 2, 3, 4]));

    await repo.deleteDocumento('c1');

    expect(
      (await db.collection('contabilita').doc('c1').get()).exists,
      isFalse,
    );
    expect(
      (await db
              .collection('contabilita')
              .doc('c1')
              .collection('g')
              .doc('1')
              .collection('chunks')
              .doc('0')
              .get())
          .exists,
      isFalse,
    );
  });

  test('createAnno due volte lancia AnnoGiaPresente', () async {
    final repo = FirestoreContabilitaRepository(FakeFirebaseFirestore());
    final now = DateTime.utc(2026, 3, 12);
    await repo.createAnno(anno: 2026, uid: 'uid-1', now: now);

    await expectLater(
      repo.createAnno(anno: 2026, uid: 'uid-1', now: now),
      throwsA(isA<AnnoGiaPresente>()),
    );
  });

  test('watchAnno non emette documenti di altri anni', () async {
    final repo = FirestoreContabilitaRepository(FakeFirebaseFirestore());
    await repo.saveNuovo(sample(id: 'c2026'), Uint8List.fromList([1]));
    await repo.saveNuovo(
      sample(id: 'c2025').copyWith(anno: 2025),
      Uint8List.fromList([2]),
    );

    final docs = await repo.watchAnno(2026).first;

    expect(docs.map((doc) => doc.id), ['c2026']);
  });

  test('saveMeta aggiorna il padre senza modificare il file', () async {
    final db = FakeFirebaseFirestore();
    final repo = FirestoreContabilitaRepository(db);
    await repo.saveNuovo(sample(), Uint8List.fromList([1, 2, 3, 4]));

    await repo.saveMeta(sample(nome: 'Aggiornata', chunkCount: 99));

    final parent = await db.collection('contabilita').doc('c1').get();
    expect(parent.data()!['nome'], 'Aggiornata');
    expect(parent.data()!['chunkCount'], 1);
    expect(await repo.loadBytes('c1'), Uint8List.fromList([1, 2, 3, 4]));
  });

  test('saveMeta non cambia la generazione corrente', () async {
    final db = FakeFirebaseFirestore();
    final repo = FirestoreContabilitaRepository(db);
    final stale = sample().copyWith(importo: 12.50);
    await repo.saveNuovo(stale, Uint8List.fromList([1, 2, 3, 4]));
    await repo.replaceFile(stale, Uint8List.fromList([5, 6]));

    await repo.saveMeta(
      stale.copyWith(nome: 'Metadati aggiornati', clearImporto: true),
    );

    final parent = await db.collection('contabilita').doc('c1').get();
    expect(parent.data()!['generation'], 2);
    expect(parent.data()!['chunkCount'], 1);
    expect(parent.data()!.containsKey('importo'), isFalse);
    expect(await repo.loadBytes('c1'), Uint8List.fromList([5, 6]));
  });

  test('saveMeta non ripristina i dati file da uno snapshot obsoleto', () async {
    final db = FakeFirebaseFirestore();
    final repo = FirestoreContabilitaRepository(db);
    final stale = sample(
      dimensione: 4,
    ).copyWith(mime: 'application/pdf', nomeFile: 'originale.pdf');
    await repo.saveNuovo(stale, Uint8List.fromList([1, 2, 3, 4]));
    final replacement = stale.copyWith(
      dimensione: 3,
      mime: 'image/jpeg',
      nomeFile: 'sostituzione.jpg',
    );
    await repo.replaceFile(replacement, Uint8List.fromList([5, 6, 7]));

    await repo.saveMeta(stale.copyWith(nome: 'Metadati aggiornati'));

    final parent = await db.collection('contabilita').doc('c1').get();
    expect(parent.data()!['dimensione'], 3);
    expect(parent.data()!['mime'], 'image/jpeg');
    expect(parent.data()!['nomeFile'], 'sostituzione.jpg');
    expect(parent.data()!['generation'], 2);
  });
}
