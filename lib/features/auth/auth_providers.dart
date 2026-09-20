import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/firestore/firebase_auth_repository.dart';
import '../../data/repositories/auth_repository.dart';

/// Password del login in corso, solo in RAM: serve a riautenticare
/// prima di `updatePassword` (Firebase lo richiede).
class SessionSecrets {
  String? loginPassword;
  bool passwordChangeCompleted = false;

  void clear() {
    loginPassword = null;
    passwordChangeCompleted = false;
  }
}

final sessionSecretsProvider = Provider<SessionSecrets>((ref) {
  return SessionSecrets();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (Firebase.apps.isEmpty) {
    return const UnconfiguredAuthRepository();
  }
  return FirebaseAuthRepository(FirebaseAuth.instance);
});

/// Si aggiorna a ogni login/logout. `authRepositoryProvider` da solo non basta:
/// l'istanza del repository resta la stessa e la home resterebbe sul nome precedente.
final authUserChangesProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).watchUser();
});

/// Incrementato dopo login/logout così la home rilegge `currentUser` anche se
/// lo stream Auth è ancora fermo sul volontario precedente.
class AuthEpoch extends Notifier<int> {
  @override
  int build() => 0;

  void bump() {
    state++;
  }
}

final authEpochProvider = NotifierProvider<AuthEpoch, int>(AuthEpoch.new);

void refreshAuthSession(WidgetRef ref) {
  ref.read(authEpochProvider.notifier).bump();
  ref.invalidate(authUserChangesProvider);
}

void onSignedOut(WidgetRef ref) {
  ref.read(sessionSecretsProvider).clear();
  refreshAuthSession(ref);
}

/// Sempre l'utente Auth corrente, non l'ultimo valore dello stream.
final signedInUserProvider = Provider<AuthUser?>((ref) {
  ref.watch(authEpochProvider);
  ref.watch(authUserChangesProvider);
  return ref.read(authRepositoryProvider).currentUser;
});
