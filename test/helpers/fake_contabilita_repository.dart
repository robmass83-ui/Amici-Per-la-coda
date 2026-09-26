import 'dart:async';
import 'dart:typed_data';

import 'package:amici_per_la_coda/core/firestore_codec.dart';
import 'package:amici_per_la_coda/data/documents/document_codec.dart';
import 'package:amici_per_la_coda/data/models/documento_contabile.dart';
import 'package:amici_per_la_coda/data/repositories/contabilita_repository.dart';
import 'package:amici_per_la_coda/features/contabilita/contabilita_bytes.dart';

class InMemoryContabilitaRepository implements ContabilitaRepository {
  InMemoryContabilitaRepository() {
    _anniController = StreamController<List<AnnoContabile>>.broadcast();
    _documentiController =
        StreamController<List<DocumentoContabile>>.broadcast();
  }

  final Map<String, AnnoContabile> _anni = {};
  final Map<String, DocumentoContabile> _documenti = {};
  final Map<String, Map<int, List<Uint8List>>> _pezzi = {};
  late final StreamController<List<AnnoContabile>> _anniController;
  late final StreamController<List<DocumentoContabile>> _documentiController;

  bool failNextReplaceWrite = false;

  @override
  Stream<List<AnnoContabile>> watchAnni() =>
      _watchCurrent(_anniController, () => List.unmodifiable(_anni.values));

  @override
  Stream<List<DocumentoContabile>> watchTutti() => _watchCurrent(
    _documentiController,
    () => List.unmodifiable(_documenti.values),
  );

  @override
  Stream<List<DocumentoContabile>> watchAnno(int anno) => watchTutti().map(
    (documenti) => documenti.where((doc) => doc.anno == anno).toList(),
  );

  @override
  Future<void> createAnno({
    required int anno,
    required String uid,
    required DateTime now,
  }) async {
    final id = '$anno';
    if (_anni.containsKey(id)) {
      throw AnnoGiaPresente(anno);
    }
    _anni[id] = AnnoContabile(
      id: id,
      anno: anno,
      audit: Audit.seed(now, by: uid),
    );
    _emitAnni();
  }

  @override
  Future<void> saveNuovo(DocumentoContabile doc, Uint8List bytes) async {
    if (doc.generation != 1) {
      throw ArgumentError.value(
        doc.generation,
        'doc.generation',
        'Un nuovo documento deve avere generation 1.',
      );
    }
    final chunks = splitContabilitaBytes(bytes);
    _pezzi[doc.id] = {1: chunks};
    _documenti[doc.id] = doc.copyWith(chunkCount: chunks.length);
    _emitDocumenti();
  }

  @override
  Future<void> saveMeta(DocumentoContabile doc) async {
    final current = _documenti[doc.id];
    if (current == null) {
      throw StateError('Documento ${doc.id} non trovato.');
    }
    _documenti[doc.id] = doc.copyWith(
      generation: current.generation,
      chunkCount: current.chunkCount,
      dimensione: current.dimensione,
      mime: current.mime,
      nomeFile: current.nomeFile,
    );
    _emitDocumenti();
  }

  @override
  Future<void> replaceFile(DocumentoContabile doc, Uint8List bytes) async {
    if (!_documenti.containsKey(doc.id)) {
      throw StateError('Documento ${doc.id} non trovato.');
    }
    final chunks = splitContabilitaBytes(bytes);
    final generation = doc.generation + 1;
    (_pezzi[doc.id] ??= {})[generation] = chunks;
    if (failNextReplaceWrite) {
      failNextReplaceWrite = false;
      throw StateError('Scrittura sostitutiva fallita.');
    }
    _documenti[doc.id] = doc.copyWith(
      generation: generation,
      chunkCount: chunks.length,
    );
    _emitDocumenti();
  }

  @override
  Future<Uint8List> loadBytes(String id) async {
    final doc = _documenti[id];
    final chunks = doc == null ? null : _pezzi[id]?[doc.generation];
    if (chunks == null) {
      throw StateError('File del documento $id non trovato.');
    }
    return joinDocumentChunks(chunks);
  }

  @override
  Future<void> deleteDocumento(String id) async {
    _documenti.remove(id);
    _pezzi.remove(id);
    _emitDocumenti();
  }

  void _emitAnni() {
    if (!_anniController.isClosed) {
      _anniController.add(List.unmodifiable(_anni.values));
    }
  }

  void _emitDocumenti() {
    if (!_documentiController.isClosed) {
      _documentiController.add(List.unmodifiable(_documenti.values));
    }
  }

  Stream<List<T>> _watchCurrent<T>(
    StreamController<List<T>> source,
    List<T> Function() current,
  ) {
    return Stream<List<T>>.multi((listener) {
      final subscription = source.stream.listen(
        listener.add,
        onError: listener.addError,
        onDone: listener.close,
      );
      listener.onCancel = subscription.cancel;
      listener.add(current());
    }, isBroadcast: true);
  }
}
