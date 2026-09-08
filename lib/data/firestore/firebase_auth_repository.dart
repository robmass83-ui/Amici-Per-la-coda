import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../core/auth_errors.dart';
import '../../firebase_options.dart';
import '../repositories/auth_repository.dart';
import 'firestore_repositories.dart';

/// Implementazione Firebase Auth (email + password).
/// Su Android la sessione è persistente di default (resta loggati).
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  @override
  AuthUser? get currentUser => _map(_auth.currentUser);

  @override
  Stream<AuthUser?> watchUser() {
    return _auth.authStateChanges().map(_map);
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
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
  Future<void> signOut() => _auth.signOut();

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
  Future<void> signOut() async {}
}

/// Inizializza Firebase se le opzioni di piattaforma sono disponibili.
Future<void> bootstrapFirebase() async {
  if (Firebase.apps.isNotEmpty) {
    return;
  }
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    enableFirestoreOffline(FirebaseFirestore.instance);
  } on FirebaseException {
    // Senza google-services.json / flutterfire configure l'app parte lo stesso.
  } on UnsupportedError {
    // Piattaforma senza opzioni (es. test su desktop).
  }
}
