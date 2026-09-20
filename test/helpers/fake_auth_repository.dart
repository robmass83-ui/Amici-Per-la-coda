import 'dart:async';

import 'package:amici_per_la_coda/core/auth_errors.dart';
import 'package:amici_per_la_coda/data/repositories/auth_repository.dart';

/// Sessione in memoria: simula la persistenza locale di Firebase Auth.
class InMemoryAuthSession {
  AuthUser? user;
}

class _Account {
  _Account({required this.uid, required this.password});

  final String uid;
  String password;
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.validEmail = 'giovanna@amiciperlacoda.it',
    this.validPassword = 'corretta',
    this.uid = 'uid-1',
    InMemoryAuthSession? session,
  }) : session = session ?? InMemoryAuthSession() {
    _accounts[_key(validEmail)] = _Account(uid: uid, password: validPassword);
  }

  final String validEmail;
  final String validPassword;
  final String uid;
  final InMemoryAuthSession session;
  final _controller = StreamController<AuthUser?>.broadcast();
  final Map<String, _Account> _accounts = {};
  var _nextUid = 2;
  Object? updatePasswordError;
  var updatePasswordCalls = 0;

  @override
  AuthUser? get currentUser => session.user;

  @override
  Stream<AuthUser?> watchUser() async* {
    yield session.user;
    yield* _controller.stream;
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final account = _accounts[_key(email)];
    if (account == null) {
      throw AuthFailure(italianAuthMessage('user-not-found'));
    }
    if (account.password != password) {
      throw AuthFailure(italianAuthMessage('wrong-password'));
    }
    session.user = AuthUser(uid: account.uid, email: email.trim());
    _controller.add(session.user);
  }

  String? lastPasswordResetEmail;

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    if (!_accounts.containsKey(_key(email))) {
      throw AuthFailure(italianAuthMessage('user-not-found'));
    }
    lastPasswordResetEmail = email.trim();
  }

  @override
  Future<void> signOut() async {
    session.user = null;
    _controller.add(null);
  }

  @override
  Future<CreatedAuthUser> createUserAccount({
    required String email,
    required String password,
  }) async {
    final trimmed = email.trim();
    if (!_looksLikeEmail(trimmed)) {
      throw AuthFailure(italianAuthMessage('invalid-email'));
    }
    if (password.length < 8) {
      throw AuthFailure(italianAuthMessage('weak-password'));
    }
    if (_accounts.containsKey(_key(trimmed))) {
      throw AuthFailure(italianAuthMessage('email-already-in-use'));
    }
    final newUid = 'uid-new-$_nextUid';
    _nextUid += 1;
    _accounts[_key(trimmed)] = _Account(uid: newUid, password: password);
    return CreatedAuthUser(uid: newUid, refreshToken: 'refresh-$newUid');
  }

  @override
  Future<CreatedAuthUser> reclaimDeletedAccount({
    required String email,
    required String password,
  }) async {
    final account = _accounts[_key(email)];
    if (account == null || account.password != password) {
      throw AuthFailure(italianAuthMessage('email-already-in-use'));
    }
    await deleteUserAccount(uid: account.uid, refreshToken: 'refresh-${account.uid}');
    return createUserAccount(email: email, password: password);
  }

  @override
  Future<String?> captureRefreshToken({
    required String email,
    required String password,
  }) async {
    final account = _accounts[_key(email)];
    if (account == null || account.password != password) {
      return null;
    }
    return 'refresh-${account.uid}';
  }

  @override
  Future<void> deleteUserAccount({
    required String uid,
    String? refreshToken,
  }) async {
    _accounts.removeWhere((_, account) => account.uid == uid);
  }

  @override
  Future<void> updatePassword(
    String newPassword, {
    String? currentPassword,
  }) async {
    if (updatePasswordError != null) {
      throw updatePasswordError!;
    }
    updatePasswordCalls++;
    final user = session.user;
    if (user == null) {
      throw const AuthFailure('Sessione scaduta. Accedi di nuovo.');
    }
    if (newPassword.length < 8) {
      throw AuthFailure(italianAuthMessage('weak-password'));
    }
    final account = _accounts[_key(user.email)];
    if (account == null) {
      throw AuthFailure(italianAuthMessage('user-not-found'));
    }
    if (currentPassword != null &&
        currentPassword.isNotEmpty &&
        account.password != currentPassword) {
      throw AuthFailure(italianAuthMessage('wrong-password'));
    }
    account.password = newPassword;
  }

  static String _key(String email) => email.trim().toLowerCase();

  static bool _looksLikeEmail(String value) {
    return value.contains('@') && value.contains('.');
  }
}
