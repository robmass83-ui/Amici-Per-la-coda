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
    'weak-password' => 'La password è troppo debole.',
    _ => 'Accesso non riuscito. Riprova.',
  };
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
