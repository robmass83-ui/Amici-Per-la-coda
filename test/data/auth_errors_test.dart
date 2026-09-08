import 'package:amici_per_la_coda/core/auth_errors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('i codici Firebase Auth diventano messaggi italiani', () {
    expect(
      italianAuthMessage('user-not-found'),
      'Email non trovata. Controlla l\'indirizzo.',
    );
    expect(italianAuthMessage('wrong-password'), 'Password non corretta.');
    expect(
      italianAuthMessage('invalid-email'),
      'Indirizzo email non valido.',
    );
    expect(
      italianAuthMessage('invalid-credential'),
      'Email o password non corretti.',
    );
    expect(
      italianAuthMessage('user-disabled'),
      'Questo account è stato disattivato.',
    );
    expect(
      italianAuthMessage('too-many-requests'),
      'Troppi tentativi. Riprova tra poco.',
    );
    expect(
      italianAuthMessage('network-request-failed'),
      'Nessuna connessione. Riprova quando hai rete.',
    );
    expect(
      italianAuthMessage('operation-not-allowed'),
      'Accesso con email non abilitato.',
    );
    expect(italianAuthMessage('unknown-code'), 'Accesso non riuscito. Riprova.');
  });
}
