import 'dart:async';

import 'package:amici_per_la_coda/data/models/volunteer.dart';
import 'package:amici_per_la_coda/data/repositories/data_repositories.dart';

class InMemoryVolunteerRepository implements VolunteerRepository {
  InMemoryVolunteerRepository([List<Volunteer> items = const []])
    : _items = List.of(items);

  final List<Volunteer> _items;
  final _controller = StreamController<List<Volunteer>>.broadcast();

  @override
  Stream<List<Volunteer>> watchAll() async* {
    yield List<Volunteer>.unmodifiable(_items);
    yield* _controller.stream;
  }

  @override
  Future<Volunteer?> getById(String id) async {
    for (final item in _items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<void> save(Volunteer volunteer) async {
    _items.removeWhere((item) => item.id == volunteer.id);
    _items.add(volunteer);
    _controller.add(List<Volunteer>.unmodifiable(_items));
  }
}
