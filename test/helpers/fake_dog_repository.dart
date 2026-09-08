import 'dart:async';

import 'package:amici_per_la_coda/data/models/dog.dart';
import 'package:amici_per_la_coda/data/repositories/data_repositories.dart';

class InMemoryDogRepository implements DogRepository {
  InMemoryDogRepository([List<Dog> dogs = const []]) : _dogs = List.of(dogs);

  final List<Dog> _dogs;
  final _controller = StreamController<List<Dog>>.broadcast();

  @override
  Stream<List<Dog>> watchAll() async* {
    yield List<Dog>.unmodifiable(_dogs);
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
    _controller.add(List<Dog>.unmodifiable(_dogs));
  }
}
