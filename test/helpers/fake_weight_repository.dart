import 'dart:async';

import 'package:amici_per_la_coda/data/models/weight.dart';
import 'package:amici_per_la_coda/data/repositories/data_repositories.dart';

import 'fake_dog_repository.dart';

class InMemoryWeightRepository implements WeightRepository {
  InMemoryWeightRepository([
    List<Weight> items = const [],
    this.dogs,
  ]) : _items = List.of(items);

  final List<Weight> _items;
  final InMemoryDogRepository? dogs;
  final _controller = StreamController<List<Weight>>.broadcast();

  @override
  Stream<List<Weight>> watchByDog(String dogId) async* {
    yield _of(dogId);
    yield* _controller.stream.map((_) => _of(dogId));
  }

  List<Weight> _of(String dogId) {
    final list = _items.where((item) => item.dogId == dogId).toList();
    list.sort((a, b) => a.data.compareTo(b.data));
    return list;
  }

  @override
  Future<void> save(Weight weight) async {
    _items.removeWhere((item) => item.id == weight.id);
    _items.add(weight);
    final dogsRepo = dogs;
    if (dogsRepo != null) {
      final dog = await dogsRepo.getById(weight.dogId);
      if (dog != null) {
        await dogsRepo.save(
          dog.withPesoKg(weight.kg, audit: weight.audit),
        );
      }
    }
    _controller.add(List<Weight>.unmodifiable(_items));
  }

  @override
  Future<void> delete(String id) async {
    Weight? removed;
    for (final item in _items) {
      if (item.id == id) {
        removed = item;
        break;
      }
    }
    _items.removeWhere((item) => item.id == id);
    final dogsRepo = dogs;
    final dogId = removed?.dogId;
    if (dogsRepo != null && dogId != null) {
      final remaining = _of(dogId);
      final latest = remaining.isEmpty ? null : remaining.last;
      final dog = await dogsRepo.getById(dogId);
      if (dog != null) {
        await dogsRepo.save(dog.withPesoKg(latest?.kg));
      }
    }
    _controller.add(List<Weight>.unmodifiable(_items));
  }
}
