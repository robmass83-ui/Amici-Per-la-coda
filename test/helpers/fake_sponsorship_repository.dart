import 'dart:async';

import 'package:amici_per_la_coda/data/models/sponsorship.dart';
import 'package:amici_per_la_coda/data/repositories/data_repositories.dart';

class InMemorySponsorshipRepository implements SponsorshipRepository {
  InMemorySponsorshipRepository([List<Sponsorship> items = const []])
    : _items = List.of(items);

  final List<Sponsorship> _items;
  final _controller = StreamController<List<Sponsorship>>.broadcast();

  @override
  Stream<List<Sponsorship>> watchByDog(String dogId) async* {
    yield _of(dogId);
    yield* _controller.stream.map((_) => _of(dogId));
  }

  @override
  Stream<List<Sponsorship>> watchAll() async* {
    yield List<Sponsorship>.unmodifiable(_items);
    yield* _controller.stream;
  }

  List<Sponsorship> _of(String dogId) {
    return _items.where((item) => item.dogId == dogId).toList(growable: false);
  }

  @override
  Future<void> save(Sponsorship sponsorship) async {
    _items.removeWhere((item) => item.id == sponsorship.id);
    _items.add(sponsorship);
    _controller.add(List<Sponsorship>.unmodifiable(_items));
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((item) => item.id == id);
    _controller.add(List<Sponsorship>.unmodifiable(_items));
  }
}
