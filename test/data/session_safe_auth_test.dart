import 'package:amici_per_la_coda/core/auth_errors.dart';
import 'package:amici_per_la_coda/data/firestore/session_safe_auth.dart';
import 'package:amici_per_la_coda/data/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const president = AuthUser(uid: 'uid-presidente', email: 'p@a.it');

  test('sessione invariata: ok', () {
    final created = ensureSameSession(
      before: president,
      after: president,
      created: const CreatedAuthUser(uid: 'uid-nuovo', refreshToken: 'r'),
    );
    expect(created.uid, 'uid-nuovo');
  });

  test('se currentUser diventa il nuovo account: errore', () {
    expect(
      () => ensureSameSession(
        before: president,
        after: const AuthUser(uid: 'uid-nuovo', email: 'n@a.it'),
        created: const CreatedAuthUser(uid: 'uid-nuovo'),
      ),
      throwsA(isA<AuthFailure>()),
    );
  });

  test('se currentUser sparisce: errore', () {
    expect(
      () => ensureSameSession(
        before: president,
        after: null,
        created: const CreatedAuthUser(uid: 'uid-nuovo'),
      ),
      throwsA(isA<AuthFailure>()),
    );
  });

  test('se before è null: errore', () {
    expect(
      () => ensureSameSession(
        before: null,
        after: president,
        created: const CreatedAuthUser(uid: 'uid-nuovo'),
      ),
      throwsA(isA<AuthFailure>()),
    );
  });

  test('se created.uid è quello già in sessione: errore', () {
    expect(
      () => ensureSameSession(
        before: president,
        after: president,
        created: const CreatedAuthUser(uid: 'uid-presidente'),
      ),
      throwsA(isA<AuthFailure>()),
    );
  });
}
