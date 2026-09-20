import '../../core/auth_errors.dart';
import '../repositories/auth_repository.dart';

CreatedAuthUser ensureSameSession({
  required AuthUser? before,
  required AuthUser? after,
  required CreatedAuthUser created,
}) {
  if (before == null) {
    throw const AuthFailure('Sessione scaduta. Accedi di nuovo.');
  }
  if (after == null || after.uid != before.uid) {
    throw const AuthFailure(
      'La creazione ha sostituito la sessione del presidente. Non pubblicare.',
    );
  }
  if (created.uid == before.uid) {
    throw const AuthFailure(
      'La creazione ha restituito l’utente già in sessione.',
    );
  }
  return created;
}
