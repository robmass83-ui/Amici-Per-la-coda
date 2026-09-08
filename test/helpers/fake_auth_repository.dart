import 'dart:async';

import 'package:amici_per_la_coda/core/auth_errors.dart';
import 'package:amici_per_la_coda/data/repositories/auth_repository.dart';

/// Sessione in memoria: simula la persistenza locale di Firebase Auth.
class InMemoryAuthSession {
  AuthUser? user;
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.validEmail = 'giovanna@amiciperlacoda.it',
    this.validPassword = 'corretta',
    InMemoryAuthSession? session,
  }) : session = session ?? InMemoryAuthSession();

  final String validEmail;
  final String validPassword;
  final InMemoryAuthSession session;
  final _controller = StreamController<AuthUser?>.broadcast();

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
    if (email != validEmail) {
      throw AuthFailure(italianAuthMessage('user-not-found'));
    }
    if (password != validPassword) {
      throw AuthFailure(italianAuthMessage('wrong-password'));
    }
    session.user = AuthUser(uid: 'uid-1', email: email);
    _controller.add(session.user);
  }

  @override
  Future<void> signOut() async {
    session.user = null;
    _controller.add(null);
  }
}
