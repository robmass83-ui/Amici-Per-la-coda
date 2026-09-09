import 'dart:async';

import 'package:amici_per_la_coda/data/models/adoption.dart';
import 'package:amici_per_la_coda/data/repositories/data_repositories.dart';

class InMemoryAdoptionRepository implements AdoptionRepository {
  InMemoryAdoptionRepository([List<Adoption> items = const []])
    : _items = List.of(items);

  final List<Adoption> _items;
  final _controller = StreamController<List<Adoption>>.broadcast();

  List<Adoption> get items => List.unmodifiable(_items);

  @override
  Stream<List<Adoption>> watchAll() async* {
    yield List<Adoption>.unmodifiable(_items);
    yield* _controller.stream;
  }

  @override
  Future<Adoption?> getById(String id) async {
    for (final item in _items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<void> save(Adoption adoption) async {
    _items.removeWhere((item) => item.id == adoption.id);
    _items.add(adoption);
    _controller.add(List<Adoption>.unmodifiable(_items));
  }
}
