/// Mapping dei codici Firebase Auth → messaggi in italiano.
String italianAuthMessage(String code) {
  return switch (code) {
    'user-not-found' => 'Email non trovata. Controlla l\'indirizzo.',
    'wrong-password' => 'Password non corretta.',
    'invalid-email' => 'Indirizzo email non valido.',
    'invalid-credential' => 'Email o password non corretti.',
    'user-disabled' => 'Questo account è stato disattivato.',
    'too-many-requests' => 'Troppi tentativi. Riprova tra poco.',
    'network-request-failed' =>
      'Nessuna connessione. Riprova quando hai rete.',
    'operation-not-allowed' => 'Accesso con email non abilitato.',
    'email-already-in-use' => 'Questa email è già registrata.',
    'invalid-refresh-token' =>
      'Non è stato possibile eliminare l\'accesso. Riprova.',
    'weak-password' => 'La password è troppo debole.',
    'requires-recent-login' =>
      'Per cambiare la password accedi di nuovo, poi riprova.',
    _ => 'Accesso non riuscito. Riprova.',
  };
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

const authDeleteNeedsLoginMessage =
    'Non è stato possibile eliminare l\'accesso. '
    'Chiedi a questa persona di accedere una volta con l\'app, poi riprova.';

bool isUnusableAuthDeleteToken(AuthFailure error) {
  return error.message == authDeleteNeedsLoginMessage ||
      error.message == italianAuthMessage('invalid-refresh-token');
}

bool isEmailAlreadyInUse(AuthFailure error) {
  return error.message == italianAuthMessage('email-already-in-use');
}

bool isAuthUserMissing(AuthFailure error) {
  return error.message == italianAuthMessage('user-not-found');
}
