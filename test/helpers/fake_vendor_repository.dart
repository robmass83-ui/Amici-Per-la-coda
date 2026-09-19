import 'dart:async';

import 'package:amici_per_la_coda/data/models/vendor.dart';
import 'package:amici_per_la_coda/data/repositories/data_repositories.dart';

class InMemoryVendorRepository implements VendorRepository {
  InMemoryVendorRepository([List<Vendor> items = const []])
    : _items = List.of(items);

  final List<Vendor> _items;
  final _controller = StreamController<List<Vendor>>.broadcast();

  List<Vendor> get items => List.unmodifiable(_items);

  @override
  Stream<List<Vendor>> watchAll() async* {
    yield List<Vendor>.unmodifiable(_items);
    yield* _controller.stream;
  }

  @override
  Future<Vendor?> getById(String id) async {
    for (final item in _items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<void> save(Vendor vendor) async {
    _items.removeWhere((item) => item.id == vendor.id);
    _items.add(vendor);
    _controller.add(List<Vendor>.unmodifiable(_items));
  }
}
