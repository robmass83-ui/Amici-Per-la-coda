import 'dart:typed_data';

import 'package:amici_per_la_coda/data/photos/lru_bytes_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('LRU da 20 scarta la full meno recente', () {
    final cache = LruBytesCache(capacity: 20);
    for (var i = 0; i < 21; i++) {
      cache['p$i'] = Uint8List.fromList([i]);
    }
    expect(cache.length, 20);
    expect(cache['p0'], isNull);
    expect(cache['p1'], isNotNull);
    expect(cache['p20'], isNotNull);
  });
}
