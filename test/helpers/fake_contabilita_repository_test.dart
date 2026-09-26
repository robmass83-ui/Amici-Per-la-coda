import 'dart:typed_data';

import 'package:amici_per_la_coda/core/firestore_codec.dart';
import 'package:amici_per_la_coda/data/models/documento_contabile.dart';
import 'package:amici_per_la_coda/data/repositories/contabilita_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_contabilita_repository.dart';

void main() {
  late InMemoryContabilitaRepository repository;

  setUp(() {
    repository = InMemoryContabilitaRepository();
  });

  test('createAnno rifiuta un anno già presente senza duplicarlo', () async {
    final now = DateTime.utc(2026, 9, 26);

    await repository.createAnno(anno: 2026, uid: 'uid-1', now: now);

    await expectLater(
      repository.createAnno(anno: 2026, uid: 'uid-2', now: now),
      throwsA(
        isA<AnnoGiaPresente>()
            .having((error) => error.anno, 'anno', 2026)
            .having(
              (error) => error.toString(),
              'messaggio',
              'Il 2026 è già presente.',
            ),
      ),
    );
    expect(await repository.watchAnni().first, hasLength(1));
  });

  test('ogni ascolto riceve subito lo snapshot e gli aggiornamenti', () async {
    final original = _documento();
    await repository.createAnno(
      anno: original.anno,
      uid: 'uid-1',
      now: original.data,
    );
    await repository.saveNuovo(original, Uint8List.fromList([1, 2, 3, 4]));

    final firstAnniListener = repository.watchAnni().first;
    final secondAnniListener = repository.watchAnni().first;
    final firstTuttiListener = repository.watchTutti().first;
    final secondTuttiListener = repository.watchTutti().first;

    final initialAnniSnapshots = await Future.wait([
      firstAnniListener,
      secondAnniListener,
    ]).timeout(const Duration(seconds: 1));
    expect(initialAnniSnapshots[0].single.anno, original.anno);
    expect(
      initialAnniSnapshots[1].single.toMap(),
      initialAnniSnapshots[0].single.toMap(),
    );

    final initialDocumentSnapshots = await Future.wait([
      firstTuttiListener,
      secondTuttiListener,
    ]).timeout(const Duration(seconds: 1));
    expect(initialDocumentSnapshots[0].single.toMap(), {
      ...original.toMap(),
      'chunkCount': 1,
    });
    expect(
      initialDocumentSnapshots[1].single.toMap(),
      initialDocumentSnapshots[0].single.toMap(),
    );

    final firstAnniUpdates = repository.watchAnni().take(2).toList();
    final secondAnniUpdates = repository.watchAnni().take(2).toList();
    final firstAnnoUpdates = repository
        .watchAnno(original.anno)
        .take(2)
        .toList();
    final secondAnnoUpdates = repository
        .watchAnno(original.anno)
        .take(2)
        .toList();
    await repository.createAnno(anno: 2027, uid: 'uid-1', now: original.data);
    await repository.saveMeta(original.copyWith(nome: 'Nome aggiornato'));

    final anniUpdateSnapshots = await Future.wait([
      firstAnniUpdates,
      secondAnniUpdates,
    ]).timeout(const Duration(seconds: 1));
    for (final snapshots in anniUpdateSnapshots) {
      expect(snapshots.first, hasLength(1));
      expect(snapshots.last, hasLength(2));
    }

    final annoUpdateSnapshots = await Future.wait([
      firstAnnoUpdates,
      secondAnnoUpdates,
    ]).timeout(const Duration(seconds: 1));
    for (final snapshots in annoUpdateSnapshots) {
      expect(snapshots.first.single.nome, original.nome);
      expect(snapshots.last.single.nome, 'Nome aggiornato');
    }
  });

  test('saveNuovo salva metadati e un pezzo senza esporre i byte', () async {
    final doc = _documento(dimensione: 999);
    final bytes = Uint8List.fromList([1, 2, 3, 4]);

    await repository.saveNuovo(doc, bytes);

    expect(await repository.loadBytes(doc.id), bytes);
    final saved = (await repository.watchAnno(doc.anno).first).single;
    expect(saved.toMap().keys, isNot(contains('bytes')));
    expect(saved.generation, 1);
    expect(saved.chunkCount, 1);
    expect(saved.dimensione, 999);
  });

  test('saveMeta cambia il nome senza cambiare file o generazione', () async {
    final original = _documento();
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    await repository.saveNuovo(original, bytes);

    await repository.saveMeta(original.copyWith(nome: 'Nome aggiornato'));

    final saved = (await repository.watchTutti().first).single;
    expect(saved.nome, 'Nome aggiornato');
    expect(saved.generation, 1);
    expect(await repository.loadBytes(original.id), bytes);
  });

  test(
    'replaceFile pubblica il nuovo file con generation incrementata',
    () async {
      final original = _documento();
      await repository.saveNuovo(original, Uint8List.fromList([1, 2, 3, 4]));
      final replacement = Uint8List.fromList([9, 8, 7]);

      await repository.replaceFile(
        original.copyWith(dimensione: 500),
        replacement,
      );

      expect(await repository.loadBytes(original.id), replacement);
      final saved = (await repository.watchTutti().first).single;
      expect(saved.generation, 2);
      expect(saved.chunkCount, 1);
      expect(saved.dimensione, 500);
    },
  );

  test('replaceFile fallito lascia visibile il file precedente', () async {
    final original = _documento();
    final oldBytes = Uint8List.fromList([1, 2, 3, 4]);
    await repository.saveNuovo(original, oldBytes);
    repository.failNextReplaceWrite = true;

    await expectLater(
      repository.replaceFile(original, Uint8List.fromList([9, 8, 7])),
      throwsStateError,
    );

    expect(await repository.loadBytes(original.id), oldBytes);
    expect((await repository.watchTutti().first).single.generation, 1);
  });

  test('deleteDocumento rimuove metadati e byte', () async {
    final doc = _documento();
    await repository.saveNuovo(doc, Uint8List.fromList([1, 2, 3, 4]));

    await repository.deleteDocumento(doc.id);

    expect(await repository.watchTutti().first, isEmpty);
    await expectLater(repository.loadBytes(doc.id), throwsStateError);
  });
}

DocumentoContabile _documento({int dimensione = 4}) {
  final now = DateTime.utc(2026, 9, 26);
  return DocumentoContabile(
    id: 'doc-1',
    anno: 2026,
    nome: 'Fattura veterinaria',
    data: now,
    tipologia: TipologiaContabile.fattura,
    descrizione: 'Visita',
    importo: 42,
    mime: 'application/pdf',
    nomeFile: 'fattura.pdf',
    dimensione: dimensione,
    chunkCount: 0,
    generation: 1,
    audit: Audit.seed(now, by: 'uid-1'),
  );
}
