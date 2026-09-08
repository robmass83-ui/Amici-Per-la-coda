import 'dart:async';

import 'package:amici_per_la_coda/data/models/health_record.dart';
import 'package:amici_per_la_coda/data/repositories/data_repositories.dart';

class InMemoryHealthRepository implements HealthRepository {
  InMemoryHealthRepository([List<HealthRecord> items = const []])
    : _items = List.of(items);

  final List<HealthRecord> _items;
  final _controller = StreamController<List<HealthRecord>>.broadcast();

  @override
  Stream<List<HealthRecord>> watchByDog(String dogId) async* {
    yield _of(dogId);
    yield* _controller.stream.map((_) => _of(dogId));
  }

  @override
  Stream<List<HealthRecord>> watchAll() async* {
    yield List<HealthRecord>.unmodifiable(_items);
    yield* _controller.stream;
  }

  List<HealthRecord> _of(String dogId) {
    return _items
        .where((item) => item.dogId == dogId)
        .toList(growable: false);
  }

  @override
  Future<void> save(HealthRecord record) async {
    _items.removeWhere((item) => item.id == record.id);
    _items.add(record);
    _controller.add(List<HealthRecord>.unmodifiable(_items));
  }
}
