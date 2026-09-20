import 'dart:convert';

import 'package:amici_per_la_coda/data/firestore/identity_toolkit_api.dart';
import 'package:amici_per_la_coda/data/firestore/identity_toolkit_http.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHttp implements IdentityToolkitHttp {
  Uri? lastUri;
  @override
  Future<IdentityToolkitHttpResponse> post({
    required Uri uri,
    required List<int> bytes,
    required String contentType,
  }) async {
    lastUri = uri;
    return IdentityToolkitHttpResponse(
      statusCode: 200,
      body: jsonEncode({
        'localId': 'uid-new',
        'refreshToken': 'refresh-new',
      }),
    );
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
}
