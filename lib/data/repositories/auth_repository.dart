/// Utente autenticato (UID Firebase + email).
class AuthUser {
  const AuthUser({required this.uid, required this.email});

  final String uid;
  final String email;
}

/// Account Auth appena creato, senza toccare la sessione corrente.
class CreatedAuthUser {
  const CreatedAuthUser({required this.uid, this.refreshToken});

  final String uid;
  final String? refreshToken;
}

/// Contratto di autenticazione. L'implementazione Firebase è intercambiabile.
abstract interface class AuthRepository {
  AuthUser? get currentUser;
  Stream<AuthUser?> watchUser();
  Future<void> signIn({required String email, required String password});
  Future<void> sendPasswordResetEmail({required String email});
  Future<void> signOut();

  /// Crea un account senza sostituire la sessione corrente.
  Future<CreatedAuthUser> createUserAccount({
    required String email,
    required String password,
  });

  /// Se Auth ha ancora l'email (profilo già cancellato) e la password
  /// coincide, elimina quell'accesso e ne crea uno nuovo.
  Future<CreatedAuthUser> reclaimDeletedAccount({
    required String email,
    required String password,
  });

  /// Token per eliminare in seguito l'account Auth di un altro utente.
  Future<String?> captureRefreshToken({
    required String email,
    required String password,
  });

  /// Elimina l'account Auth [uid]. Senza [refreshToken] non si può
  /// cancellare un altro utente dal client.
  Future<void> deleteUserAccount({
    required String uid,
    String? refreshToken,
  });

  Future<void> updatePassword(String newPassword, {String? currentPassword});
}
