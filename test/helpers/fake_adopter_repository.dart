import 'dart:async';

import 'package:amici_per_la_coda/data/models/adopter.dart';
import 'package:amici_per_la_coda/data/repositories/data_repositories.dart';

class InMemoryAdopterRepository implements AdopterRepository {
  InMemoryAdopterRepository([List<Adopter> items = const []])
    : _items = List.of(items);

  final List<Adopter> _items;
  final _controller = StreamController<List<Adopter>>.broadcast();

  @override
  Stream<List<Adopter>> watchAll() async* {
    yield List<Adopter>.unmodifiable(_items);
    yield* _controller.stream;
  }

  @override
  Future<Adopter?> getById(String id) async {
    for (final item in _items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<void> save(Adopter adopter) async {
    _items.removeWhere((item) => item.id == adopter.id);
    _items.add(adopter);
    _controller.add(List<Adopter>.unmodifiable(_items));
  }
}
