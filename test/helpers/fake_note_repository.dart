import 'dart:async';

import 'package:amici_per_la_coda/data/models/note.dart';
import 'package:amici_per_la_coda/data/repositories/data_repositories.dart';

class InMemoryNoteRepository implements NoteRepository {
  InMemoryNoteRepository([List<Note> items = const []]) : _items = List.of(items);

  final List<Note> _items;
  final _controller = StreamController<List<Note>>.broadcast();

  @override
  Stream<List<Note>> watchByDog(String dogId) async* {
    yield _of(dogId);
    yield* _controller.stream.map((_) => _of(dogId));
  }

  List<Note> _of(String dogId) {
    return _items.where((item) => item.dogId == dogId).toList(growable: false);
  }

  @override
  Future<void> save(Note note) async {
    _items.removeWhere((item) => item.id == note.id);
    _items.add(note);
    _controller.add(List<Note>.unmodifiable(_items));
  }
}
