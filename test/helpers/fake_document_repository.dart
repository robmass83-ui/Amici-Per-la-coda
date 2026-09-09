import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:amici_per_la_coda/data/documents/document_codec.dart';
import 'package:amici_per_la_coda/data/models/app_document.dart';
import 'package:amici_per_la_coda/data/repositories/data_repositories.dart';

class InMemoryDocumentRepository implements DocumentRepository {
  InMemoryDocumentRepository([List<AppDocument> items = const []])
    : _items = List.of(items);

  final List<AppDocument> _items;
  final _bytes = <String, Uint8List>{};
  final _controller = StreamController<List<AppDocument>>.broadcast();

  List<AppDocument> get items => List.unmodifiable(_items);

  @override
  Stream<List<AppDocument>> watchByDog(String dogId) async* {
    yield _ofDog(dogId);
    yield* _controller.stream.map((_) => _ofDog(dogId));
  }

  @override
  Stream<List<AppDocument>> watchByAdopter(String adopterId) async* {
    yield _ofAdopter(adopterId);
    yield* _controller.stream.map((_) => _ofAdopter(adopterId));
  }

  @override
  Stream<List<AppDocument>> watchByAdoption(String adoptionId) async* {
    yield _ofAdoption(adoptionId);
    yield* _controller.stream.map((_) => _ofAdoption(adoptionId));
  }

  List<AppDocument> _ofDog(String dogId) {
    return _items.where((item) => item.dogId == dogId).toList(growable: false);
  }

  List<AppDocument> _ofAdopter(String adopterId) {
    return _items
        .where((item) => item.adopterId == adopterId)
        .toList(growable: false);
  }

  List<AppDocument> _ofAdoption(String adoptionId) {
    return _items
        .where((item) => item.adoptionId == adoptionId)
        .toList(growable: false);
  }

  void _emit() => _controller.add(List<AppDocument>.unmodifiable(_items));

  @override
  Future<void> save(AppDocument document) async {
    _items.removeWhere((item) => item.id == document.id);
    _items.add(document);
    _emit();
  }

  @override
  Future<AppDocument> saveBytes(AppDocument document, Uint8List bytes) async {
    ensureDocumentSizeAllowed(bytes.lengthInBytes);
    final count = documentChunkCount(bytes.lengthInBytes);
    final saved = document.copyWith(
      chunkCount: count,
      contenutoB64: count == 0 ? base64Encode(bytes) : null,
      clearContenuto: count > 0,
    );
    _bytes[saved.id] = Uint8List.fromList(bytes);
    await save(saved);
    return saved;
  }

  @override
  Future<Uint8List> loadBytes(String id) async {
    final cached = _bytes[id];
    if (cached != null) {
      return cached;
    }
    for (final item in _items) {
      if (item.id == id && item.contenutoB64 != null) {
        return base64Decode(item.contenutoB64!);
      }
    }
    return Uint8List(0);
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((item) => item.id == id);
    _bytes.remove(id);
    _emit();
  }
}
