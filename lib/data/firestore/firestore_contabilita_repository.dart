import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firestore_codec.dart';
import '../../features/contabilita/contabilita_bytes.dart';
import '../documents/document_codec.dart';
import '../models/documento_contabile.dart';
import '../repositories/contabilita_repository.dart';

class FirestoreContabilitaRepository implements ContabilitaRepository {
  FirestoreContabilitaRepository(
    this._db, {
    this.failBeforeParentUpdate = false,
  });

  final FirebaseFirestore _db;
  final bool failBeforeParentUpdate;

  CollectionReference<Map<String, dynamic>> get _anni =>
      _db.collection('anniContabili');

  CollectionReference<Map<String, dynamic>> get _documenti =>
      _db.collection('contabilita');

  CollectionReference<Map<String, dynamic>> _chunks(String id, int generation) {
    return _documenti
        .doc(id)
        .collection('g')
        .doc('$generation')
        .collection('chunks');
  }

  @override
  Stream<List<AnnoContabile>> watchAnni() {
    return _anni.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => AnnoContabile.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  @override
  Stream<List<DocumentoContabile>> watchTutti() {
    return _documenti.snapshots().map(_mapDocumenti);
  }

  @override
  Stream<List<DocumentoContabile>> watchAnno(int anno) {
    return _documenti
        .where('anno', isEqualTo: anno)
        .snapshots()
        .map(_mapDocumenti);
  }

  @override
  Future<void> createAnno({
    required int anno,
    required String uid,
    required DateTime now,
  }) async {
    final reference = _anni.doc('$anno');
    if ((await reference.get()).exists) {
      throw AnnoGiaPresente(anno);
    }
    await reference.set(
      AnnoContabile(
        id: '$anno',
        anno: anno,
        audit: Audit.seed(now, by: uid),
      ).toMap(),
    );
  }

  @override
  Future<void> saveNuovo(DocumentoContabile doc, Uint8List bytes) async {
    final chunks = splitContabilitaBytes(bytes);
    try {
      await _writeChunks(doc.id, doc.generation, chunks);
      await _documenti.doc(doc.id).set({
        ...doc.toMap(),
        'chunkCount': chunks.length,
        'dimensione': doc.dimensione,
      });
    } catch (_) {
      await _deleteGenerationIgnoringErrors(doc.id, doc.generation);
      rethrow;
    }
  }

  @override
  Future<void> saveMeta(DocumentoContabile doc) async {
    final reference = _documenti.doc(doc.id);
    final current = await reference.get();
    if (!current.exists) {
      throw StateError('Documento contabile non trovato.');
    }
    final data = current.data()!;
    await reference.set({
      ...doc.toMap(),
      'chunkCount': data['chunkCount'],
      'dimensione': data['dimensione'],
      'generation': data['generation'],
    });
  }

  @override
  Future<void> replaceFile(DocumentoContabile doc, Uint8List bytes) async {
    final newGeneration = doc.generation + 1;
    final chunks = splitContabilitaBytes(bytes);
    try {
      await _writeChunks(doc.id, newGeneration, chunks);
      if (failBeforeParentUpdate) {
        throw StateError('stop');
      }
      await _documenti.doc(doc.id).set({
        ...doc.toMap(),
        'generation': newGeneration,
        'chunkCount': chunks.length,
        'dimensione': doc.dimensione,
      });
    } catch (_) {
      await _deleteGenerationIgnoringErrors(doc.id, newGeneration);
      rethrow;
    }

    await _deleteGenerationIgnoringErrors(doc.id, doc.generation);
  }

  @override
  Future<Uint8List> loadBytes(String id) async {
    final parent = await _documenti.doc(id).get();
    if (!parent.exists) {
      throw StateError('Documento contabile non trovato.');
    }
    final data = parent.data()!;
    final generation = intFrom(data['generation']);
    final chunkCount = intFrom(data['chunkCount']);
    final chunks = <Uint8List>[];
    for (var index = 0; index < chunkCount; index++) {
      final chunk = await _chunks(id, generation).doc('$index').get();
      final encoded = chunk.data()?['b64'] as String? ?? '';
      chunks.add(base64Decode(encoded));
    }
    return joinDocumentChunks(chunks);
  }

  @override
  Future<void> deleteDocumento(String id) async {
    final parent = await _documenti.doc(id).get();
    if (!parent.exists) {
      return;
    }
    final generation = intFrom(parent.data()?['generation']);
    for (var current = 1; current <= generation + 1; current++) {
      await _deleteGeneration(id, current);
    }
    await _documenti.doc(id).delete();
  }

  List<DocumentoContabile> _mapDocumenti(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map((doc) => DocumentoContabile.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> _writeChunks(
    String id,
    int generation,
    List<Uint8List> chunks,
  ) async {
    for (var start = 0; start < chunks.length; start += 8) {
      final batch = _db.batch();
      final end = (start + 8).clamp(0, chunks.length);
      for (var index = start; index < end; index++) {
        batch.set(_chunks(id, generation).doc('$index'), {
          'index': index,
          'b64': base64Encode(chunks[index]),
        });
      }
      await batch.commit();
    }
  }

  Future<void> _deleteGeneration(String id, int generation) async {
    final snapshot = await _chunks(id, generation).get();
    for (final chunk in snapshot.docs) {
      await chunk.reference.delete();
    }
  }

  Future<void> _deleteGenerationIgnoringErrors(
    String id,
    int generation,
  ) async {
    try {
      await _deleteGeneration(id, generation);
    } catch (_) {}
  }
}
