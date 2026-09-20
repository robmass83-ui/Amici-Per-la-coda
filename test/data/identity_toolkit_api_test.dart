import 'dart:convert';

import 'package:amici_per_la_coda/core/auth_errors.dart';
import 'package:amici_per_la_coda/data/firestore/identity_toolkit_api.dart';
import 'package:amici_per_la_coda/data/firestore/identity_toolkit_http.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHttp implements IdentityToolkitHttp {
  Uri? lastUri;
  int closeCount = 0;
  final List<Uri> uris = [];

  @override
  Future<IdentityToolkitHttpResponse> post({
    required Uri uri,
    required List<int> bytes,
    required String contentType,
  }) async {
    lastUri = uri;
    uris.add(uri);
    if (uri.path.contains('/token')) {
      return IdentityToolkitHttpResponse(
        statusCode: 200,
        body: jsonEncode({'id_token': 'id-token-1'}),
      );
    }
    return IdentityToolkitHttpResponse(
      statusCode: 200,
      body: jsonEncode({
        'localId': 'uid-new',
        'refreshToken': 'refresh-new',
      }),
    );
  }

  @override
  void close() => closeCount++;
}

class _NetworkFailingHttp implements IdentityToolkitHttp {
  @override
  Future<IdentityToolkitHttpResponse> post({
    required Uri uri,
    required List<int> bytes,
    required String contentType,
  }) {
    throw const IdentityToolkitNetworkException();
  }

  @override
  void close() {}
}

void main() {
  test('signUp non tocca un URI di produzione se c’è l’emulatore', () async {
    final http = _FakeHttp();
    final api = IdentityToolkitApi(
      apiKey: 'fake',
      http: http,
      emulatorOrigin: 'http://127.0.0.1:9099',
    );
    final created = await api.signUp(email: 'a@b.it', password: 'Password1');
    expect(created.uid, 'uid-new');
    expect(http.lastUri?.host, '127.0.0.1');
    expect(http.lastUri?.port, 9099);
  });

  test('signUp in produzione usa identitytoolkit.googleapis.com', () async {
    final http = _FakeHttp();
    final api = IdentityToolkitApi(apiKey: 'fake', http: http);
    await api.signUp(email: 'a@b.it', password: 'Password1');
    expect(http.lastUri?.host, 'identitytoolkit.googleapis.com');
  });

  test(
    'un fallimento di rete dell’adapter diventa il messaggio italiano',
    () async {
      final api = IdentityToolkitApi(apiKey: 'fake', http: _NetworkFailingHttp());
      try {
        await api.signUp(email: 'a@b.it', password: 'Password1');
        fail('atteso AuthFailure');
      } on AuthFailure catch (error) {
        expect(
          error.message,
          italianAuthMessage('network-request-failed'),
        );
        expect(error.message, 'Nessuna connessione. Riprova quando hai rete.');
      }
    },
  );

  test(
    'deleteAccount fa refresh e delete sulla stessa istanza senza chiudere l’http iniettato',
    () async {
      final http = _FakeHttp();
      final api = IdentityToolkitApi(apiKey: 'fake', http: http);
      await api.deleteAccount(refreshToken: 'refresh-1');
      expect(http.uris.length, 2);
      expect(http.uris[0].host, 'securetoken.googleapis.com');
      expect(http.uris[1].path, contains('accounts:delete'));
      expect(http.closeCount, 0);
      await api.signUp(email: 'a@b.it', password: 'Password1');
      expect(http.uris.length, 3);
      expect(http.closeCount, 0);
    },
  );
}
