import 'dart:typed_data';

/// Cache LRU in memoria, capacità fissa (20 full).
class LruBytesCache {
  LruBytesCache({this.capacity = 20});

  final int capacity;
  final _map = <String, Uint8List>{};

  Uint8List? operator [](String key) {
    final value = _map.remove(key);
    if (value != null) {
      _map[key] = value;
    }
    return value;
  }

  void operator []=(String key, Uint8List value) {
    _map.remove(key);
    _map[key] = value;
    while (_map.length > capacity) {
      _map.remove(_map.keys.first);
    }
  }

  void remove(String key) => _map.remove(key);

  int get length => _map.length;
}
