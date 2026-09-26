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
    expect(
      italianAuthMessage('email-already-in-use'),
      'Questa email è già registrata.',
    );
    expect(
      italianAuthMessage('invalid-refresh-token'),
      'Non è stato possibile eliminare l\'accesso. Riprova.',
    );
    expect(
      italianAuthMessage('weak-password'),
      'La password è troppo debole.',
    );
    expect(
      italianAuthMessage('requires-recent-login'),
      'Per cambiare la password accedi di nuovo, poi riprova.',
    );
    expect(italianAuthMessage('unknown-code'), 'Accesso non riuscito. Riprova.');
  });

  test('token Auth assente o scaduto non blocca la cancellazione del profilo', () {
    expect(
      isUnusableAuthDeleteToken(const AuthFailure(authDeleteNeedsLoginMessage)),
      isTrue,
    );
    expect(
      isUnusableAuthDeleteToken(
        AuthFailure(italianAuthMessage('invalid-refresh-token')),
      ),
      isTrue,
    );
    expect(
      isUnusableAuthDeleteToken(
        AuthFailure(italianAuthMessage('network-request-failed')),
      ),
      isFalse,
    );
  });
}
