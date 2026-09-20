import 'package:cloud_firestore/cloud_firestore.dart';

const searchRecentsMax = 6;

abstract interface class SearchRecentsStore {
  Future<List<String>> load();
  Future<void> save(List<String> queries);
}

List<String> pushSearchRecent(List<String> current, String raw) {
  final query = raw.trim();
  if (query.length < 2) {
    return List<String>.of(current);
  }
  final next = <String>[query];
  for (final item in current) {
    if (item.toLowerCase() == query.toLowerCase()) {
      continue;
    }
    next.add(item);
    if (next.length >= searchRecentsMax) {
      break;
    }
  }
  return next;
}

class MemorySearchRecentsStore implements SearchRecentsStore {
  MemorySearchRecentsStore([List<String> items = const []])
    : _items = List.of(items);

  List<String> _items;

  List<String> get items => List.unmodifiable(_items);

  @override
  Future<List<String>> load() async => List<String>.of(_items);

  @override
  Future<void> save(List<String> queries) async {
    _items = List.of(queries.take(searchRecentsMax));
  }
}

class FirestoreSearchRecentsStore implements SearchRecentsStore {
  FirestoreSearchRecentsStore(this._db, this._uid);

  final FirebaseFirestore _db;
  final String _uid;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection('searchRecents').doc(_uid);

  @override
  Future<List<String>> load() async {
    if (_uid.isEmpty) {
      return const [];
    }
    final snap = await _doc.get();
    final data = snap.data();
    if (!snap.exists || data == null) {
      return const [];
    }
    final raw = data['queries'] as List<dynamic>? ?? const [];
    return [
      for (final item in raw.take(searchRecentsMax)) item.toString(),
    ];
  }

  @override
  Future<void> save(List<String> queries) async {
    if (_uid.isEmpty) {
      return;
    }
    await _doc.set({
      'queries': queries.take(searchRecentsMax).toList(),
    });
  }
}
