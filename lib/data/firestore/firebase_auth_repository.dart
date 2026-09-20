import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../core/auth_errors.dart';
import '../../core/firebase_emulators.dart';
import '../../firebase_options.dart';
import '../repositories/auth_repository.dart';
import 'firestore_repositories.dart';
import 'identity_toolkit_api.dart';
import 'session_safe_auth.dart';

/// Implementazione Firebase Auth (email + password).
/// Su Android la sessione è persistente di default (resta loggati).
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  @override
  AuthUser? get currentUser => _map(_auth.currentUser);

  @override
  Stream<AuthUser?> watchUser() {
    return _auth.userChanges().map(_map);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(italianAuthMessage(error.code));
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(italianAuthMessage(error.code));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  IdentityToolkitApi get _toolkit {
    return IdentityToolkitApi(apiKey: _auth.app.options.apiKey);
  }

  @override
  Future<CreatedAuthUser> createUserAccount({
    required String email,
    required String password,
  }) async {
    final before = currentUser;
    final created = await _toolkit.signUp(
      email: email.trim(),
      password: password,
    );
    return ensureSameSession(
      before: before,
      after: currentUser,
      created: created,
    );
  }

  @override
  Future<CreatedAuthUser> reclaimDeletedAccount({
    required String email,
    required String password,
  }) async {
    final before = currentUser;
    final trimmed = email.trim();
    CreatedAuthUser existing;
    try {
      existing = await _toolkit.signIn(email: trimmed, password: password);
    } on AuthFailure {
      throw AuthFailure(italianAuthMessage('email-already-in-use'));
    }
    final token = existing.refreshToken;
    if (token == null || token.isEmpty) {
      throw AuthFailure(italianAuthMessage('email-already-in-use'));
    }
    await _toolkit.deleteAccount(refreshToken: token);
    final created = await _toolkit.signUp(email: trimmed, password: password);
    return ensureSameSession(
      before: before,
      after: currentUser,
      created: created,
    );
  }

  @override
  Future<String?> captureRefreshToken({
    required String email,
    required String password,
  }) async {
    try {
      final created = await _toolkit.signIn(
        email: email.trim(),
        password: password,
      );
      final token = created.refreshToken;
      if (token == null || token.isEmpty) {
        return null;
      }
      return token;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteUserAccount({
    required String uid,
    String? refreshToken,
  }) async {
    final token = refreshToken?.trim() ?? '';
    if (uid.isEmpty || token.isEmpty) {
      throw const AuthFailure(
        'Non è stato possibile eliminare l\'accesso. '
        'Chiedi a questa persona di accedere una volta con l\'app, poi riprova.',
      );
    }
    try {
      await _toolkit.deleteAccount(refreshToken: token);
    } on AuthFailure catch (error) {
      if (isAuthUserMissing(error)) {
        return;
      }
      rethrow;
    }
  }

  @override
  Future<void> updatePassword(
    String newPassword, {
    String? currentPassword,
  }) async {
    var user = _auth.currentUser;
    if (user == null) {
      throw const AuthFailure('Sessione scaduta. Accedi di nuovo.');
    }
    if (currentPassword != null &&
        currentPassword.isNotEmpty &&
        currentPassword == newPassword) {
      return;
    }
    try {
      final email = user.email;
      if (currentPassword != null &&
          currentPassword.isNotEmpty &&
          email != null &&
          email.isNotEmpty) {
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: email, password: currentPassword),
        );
        user = _auth.currentUser ?? user;
      }
      await user
          .updatePassword(newPassword)
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () => throw const AuthFailure(
              'Il salvataggio sta impiegando troppo. Riprova.',
            ),
          );
      await user.reload();
      await _auth.currentUser?.getIdToken(true);
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(italianAuthMessage(error.code));
    } on TimeoutException {
      throw const AuthFailure('Il salvataggio sta impiegando troppo. Riprova.');
    } catch (_) {
      throw const AuthFailure(
        'Non è stato possibile aggiornare la password. Riprova.',
      );
    }
  }

  static AuthUser? _map(User? user) {
    if (user == null) {
      return null;
    }
    return AuthUser(uid: user.uid, email: user.email ?? '');
  }
}

/// Usata nei test e prima di `flutterfire configure`.
class UnconfiguredAuthRepository implements AuthRepository {
  const UnconfiguredAuthRepository();

  @override
  AuthUser? get currentUser => null;

  @override
  Stream<AuthUser?> watchUser() => Stream<AuthUser?>.value(null);

  @override
  Future<void> signIn({required String email, required String password}) {
    throw const AuthFailure(
      'Firebase non è ancora configurato. Esegui flutterfire configure.',
    );
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) {
    throw const AuthFailure(
      'Firebase non è ancora configurato. Esegui flutterfire configure.',
    );
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<CreatedAuthUser> createUserAccount({
    required String email,
    required String password,
  }) {
    throw const AuthFailure(
      'Firebase non è ancora configurato. Esegui flutterfire configure.',
    );
  }

  @override
  Future<CreatedAuthUser> reclaimDeletedAccount({
    required String email,
    required String password,
  }) {
    throw const AuthFailure(
      'Firebase non è ancora configurato. Esegui flutterfire configure.',
    );
  }

  @override
  Future<String?> captureRefreshToken({
    required String email,
    required String password,
  }) {
    throw const AuthFailure(
      'Firebase non è ancora configurato. Esegui flutterfire configure.',
    );
  }

  @override
  Future<void> deleteUserAccount({required String uid, String? refreshToken}) {
    throw const AuthFailure(
      'Firebase non è ancora configurato. Esegui flutterfire configure.',
    );
  }

  @override
  Future<void> updatePassword(String newPassword, {String? currentPassword}) {
    throw const AuthFailure(
      'Firebase non è ancora configurato. Esegui flutterfire configure.',
    );
  }
}

/// Inizializza Firebase se le opzioni di piattaforma sono disponibili.
Future<void> bootstrapFirebase() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    await connectFirebaseEmulators(
      auth: FirebaseAuth.instance,
      db: FirebaseFirestore.instance,
    );
    enableFirestoreOffline(FirebaseFirestore.instance);
  } on FirebaseException {
    // Senza google-services.json / flutterfire configure l'app parte lo stesso.
  } on UnsupportedError {
    // Piattaforma senza opzioni (es. test su desktop).
  }
}
