import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
import '../auth/auth_providers.dart';
import 'volunteer_account_service.dart';

final volunteerAccountServiceProvider = Provider<VolunteerAccountService?>((
  ref,
) {
  final volunteers = ref.watch(volunteerRepositoryProvider);
  if (volunteers == null) {
    return null;
  }
  return VolunteerAccountService(
    auth: ref.watch(authRepositoryProvider),
    volunteers: volunteers,
  );
});
