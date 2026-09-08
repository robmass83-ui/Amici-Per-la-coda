import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/firestore/firebase_auth_repository.dart';
import '../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (Firebase.apps.isEmpty) {
    return const UnconfiguredAuthRepository();
  }
  return FirebaseAuthRepository(FirebaseAuth.instance);
});
