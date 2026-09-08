/// Utente autenticato (UID Firebase + email).
class AuthUser {
  const AuthUser({required this.uid, required this.email});

  final String uid;
  final String email;
}

/// Contratto di autenticazione. L'implementazione Firebase è intercambiabile.
abstract interface class AuthRepository {
  AuthUser? get currentUser;
  Stream<AuthUser?> watchUser();
  Future<void> signIn({required String email, required String password});
  Future<void> signOut();
}
