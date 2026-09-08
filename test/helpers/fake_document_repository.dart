import 'dart:async';

import 'package:amici_per_la_coda/data/models/app_document.dart';
import 'package:amici_per_la_coda/data/repositories/data_repositories.dart';

class InMemoryDocumentRepository implements DocumentRepository {
  InMemoryDocumentRepository([List<AppDocument> items = const []])
    : _items = List.of(items);

  final List<AppDocument> _items;
  final _controller = StreamController<List<AppDocument>>.broadcast();

  @override
  Stream<List<AppDocument>> watchByDog(String dogId) async* {
    yield _of(dogId);
    yield* _controller.stream.map((_) => _of(dogId));
  }

  List<AppDocument> _of(String dogId) {
    return _items.where((item) => item.dogId == dogId).toList(growable: false);
  }

  @override
  Future<void> save(AppDocument document) async {
    _items.removeWhere((item) => item.id == document.id);
    _items.add(document);
    _controller.add(List<AppDocument>.unmodifiable(_items));
  }
}
