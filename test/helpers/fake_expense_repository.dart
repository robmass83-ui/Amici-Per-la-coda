import 'dart:async';

import 'package:amici_per_la_coda/data/models/expense.dart';
import 'package:amici_per_la_coda/data/repositories/data_repositories.dart';

class InMemoryExpenseRepository implements ExpenseRepository {
  InMemoryExpenseRepository([List<Expense> items = const []])
    : _items = List.of(items);

  final List<Expense> _items;
  final _controller = StreamController<List<Expense>>.broadcast();

  @override
  Stream<List<Expense>> watchByDog(String? dogId) async* {
    yield _of(dogId);
    yield* _controller.stream.map((_) => _of(dogId));
  }

  List<Expense> _of(String? dogId) {
    if (dogId == null) {
      return List<Expense>.unmodifiable(_items);
    }
    return _items
        .where((item) => item.dogId == dogId)
        .toList(growable: false);
  }

  @override
  Future<void> save(Expense expense) async {
    _items.removeWhere((item) => item.id == expense.id);
    _items.add(expense);
    _controller.add(List<Expense>.unmodifiable(_items));
  }
}
