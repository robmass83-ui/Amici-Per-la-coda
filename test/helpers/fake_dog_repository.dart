import 'dart:async';

import 'package:amici_per_la_coda/data/dog_archive.dart';
import 'package:amici_per_la_coda/data/models/dog.dart';
import 'package:amici_per_la_coda/data/repositories/data_repositories.dart';

class InMemoryDogRepository implements DogRepository {
  InMemoryDogRepository([List<Dog> dogs = const []]) : _dogs = List.of(dogs);

  final List<Dog> _dogs;
  final _controller = StreamController<List<Dog>>.broadcast();

  List<Dog> get items => List.unmodifiable(_dogs);

  @override
  Stream<List<Dog>> watchAll() async* {
    yield List<Dog>.from(_dogs);
    yield* _controller.stream;
  }

  @override
  Future<Dog?> getById(String id) async {
    for (final dog in _dogs) {
      if (dog.id == id) {
        return dog;
      }
    }
    return null;
  }

  @override
  Future<void> save(Dog dog) async {
    _dogs.removeWhere((item) => item.id == dog.id);
    _dogs.add(dog);
    _controller.add(List<Dog>.from(_dogs));
  }

  @override
  Future<void> delete(String id) async {
    _dogs.removeWhere((item) => item.id == id);
    _controller.add(List<Dog>.from(_dogs));
  }

  Future<void> removePrefixed(String prefix) async {
    _dogs.removeWhere((item) => item.id.startsWith(prefix));
    _controller.add(List<Dog>.from(_dogs));
  }

  @override
  Future<void> ripristina(
    String id, {
    required String autoreId,
    DateTime? now,
  }) async {
    final dog = await getById(id);
    if (dog == null || !dogInArchivio(dog)) {
      return;
    }
    await save(
      applyRipristina(dog: dog, autoreId: autoreId, now: now ?? DateTime.now()),
    );
  }
}
