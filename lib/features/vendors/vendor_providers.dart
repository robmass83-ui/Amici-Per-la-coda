import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
import '../../data/models/vendor.dart';

final vendorsStreamProvider = StreamProvider<List<Vendor>>((ref) {
  final repo = ref.watch(vendorRepositoryProvider);
  if (repo == null) {
    return Stream.value(const <Vendor>[]);
  }
  return repo.watchAll();
});
