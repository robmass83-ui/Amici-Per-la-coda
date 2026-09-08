import 'dart:async';

import 'package:amici_per_la_coda/data/models/shelter_box.dart';
import 'package:amici_per_la_coda/data/repositories/data_repositories.dart';

class InMemoryBoxRepository implements BoxRepository {
  InMemoryBoxRepository([List<ShelterBox> items = const []])
    : _items = List.of(items);

  final List<ShelterBox> _items;
  final _controller = StreamController<List<ShelterBox>>.broadcast();

  @override
  Stream<List<ShelterBox>> watchAll() async* {
    yield List<ShelterBox>.unmodifiable(_items);
    yield* _controller.stream;
  }

  @override
  Future<void> save(ShelterBox box) async {
    _items.removeWhere((item) => item.id == box.id);
    _items.add(box);
    _controller.add(List<ShelterBox>.unmodifiable(_items));
  }
}
