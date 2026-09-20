import 'dart:async';

import 'package:amici_per_la_coda/data/models/volunteer.dart';
import 'package:amici_per_la_coda/data/repositories/data_repositories.dart';

class InMemoryVolunteerRepository implements VolunteerRepository {
  InMemoryVolunteerRepository([List<Volunteer> items = const []])
    : _items = List.of(items);

  final List<Volunteer> _items;
  final _controller = StreamController<List<Volunteer>>.broadcast();
  final Map<String, String> authTokens = {};

  List<Volunteer> get items => List.unmodifiable(_items);

  Future<void> removePrefixed(String prefix) async {
    _items.removeWhere((item) => item.id.startsWith(prefix));
    _controller.add(List<Volunteer>.unmodifiable(_items));
  }

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

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((item) => item.id == id);
    _controller.add(List<Volunteer>.unmodifiable(_items));
  }

  @override
  Future<void> updateSelf({
    required String id,
    bool? mustChangePassword,
    DateTime? ultimoAccesso,
    String? coloreAvatar,
  }) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0) {
      throw StateError('Profilo volontario non trovato.');
    }
    _items[index] = _items[index].copyWith(
      mustChangePassword: mustChangePassword,
      ultimoAccesso: ultimoAccesso,
      coloreAvatar: coloreAvatar,
    );
    _controller.add(List<Volunteer>.unmodifiable(_items));
  }

  @override
  Future<void> saveAuthRefreshToken({
    required String id,
    required String token,
  }) async {
    authTokens[id] = token;
  }

  @override
  Future<String?> getAuthRefreshToken(String id) async {
    return authTokens[id];
  }

  @override
  Future<void> deleteAuthRefreshToken(String id) async {
    authTokens.remove(id);
  }
}
