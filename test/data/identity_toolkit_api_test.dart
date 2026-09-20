import 'dart:async';
import 'dart:convert';

import 'package:amici_per_la_coda/core/auth_errors.dart';
import 'package:amici_per_la_coda/data/firestore/identity_toolkit_api.dart';
import 'package:amici_per_la_coda/data/firestore/identity_toolkit_http.dart';
import 'package:amici_per_la_coda/data/firestore/identity_toolkit_http_factory.dart';
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
      body: jsonEncode({'localId': 'uid-new', 'refreshToken': 'refresh-new'}),
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

class _OwnedProbeHttp implements IdentityToolkitHttp {
  _OwnedProbeHttp({required this.beforeFirstPost});

  final Future<void> Function() beforeFirstPost;
  final List<Uri> uris = [];
  int closeCount = 0;
  var _firstPost = true;

  @override
  Future<IdentityToolkitHttpResponse> post({
    required Uri uri,
    required List<int> bytes,
    required String contentType,
  }) async {
    if (_firstPost) {
      _firstPost = false;
      await beforeFirstPost();
    }
    uris.add(uri);
    if (uri.path.contains('/token')) {
      return IdentityToolkitHttpResponse(
        statusCode: 200,
        body: jsonEncode({'id_token': 'id-token-1'}),
      );
    }
    return IdentityToolkitHttpResponse(
      statusCode: 200,
      body: jsonEncode({'localId': 'uid-new', 'refreshToken': 'refresh-new'}),
    );
  }

  @override
  void close() => closeCount++;
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
      final api = IdentityToolkitApi(
        apiKey: 'fake',
        http: _NetworkFailingHttp(),
      );
      try {
        await api.signUp(email: 'a@b.it', password: 'Password1');
        fail('atteso AuthFailure');
      } on AuthFailure catch (error) {
        expect(error.message, italianAuthMessage('network-request-failed'));
        expect(error.message, 'Nessuna connessione. Riprova quando hai rete.');
      }
    },
  );

  test('deleteAccount fa refresh e delete sulla stessa istanza senza chiudere l’http iniettato', () async {
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
  });

  test('deleteAccount sull’emulatore fa refresh e delete su 127.0.0.1:9099', () async {
    final http = _FakeHttp();
    final api = IdentityToolkitApi(
      apiKey: 'fake',
      http: http,
      emulatorOrigin: 'http://127.0.0.1:9099',
    );
    await api.deleteAccount(refreshToken: 'refresh-1');
    expect(http.uris.length, 2);
    expect(http.uris[0].host, '127.0.0.1');
    expect(http.uris[0].port, 9099);
    expect(http.uris[0].path, contains('securetoken.googleapis.com'));
    expect(http.uris[0].path, contains('/v1/token'));
    expect(http.uris[1].host, '127.0.0.1');
    expect(http.uris[1].port, 9099);
    expect(http.uris[1].path, contains('accounts:delete'));
  });

  test('chiamate owned sovrapposte usano adapter distinti e chiudono ciascuno una volta', () async {
    final adapters = <_OwnedProbeHttp>[];
    final refreshStarted = Completer<void>();
    final releaseRefresh = Completer<void>();
    final signUpStarted = Completer<void>();
    final releaseSignUp = Completer<void>();

    debugCreateIdentityToolkitHttp = () {
      final index = adapters.length;
      final http = _OwnedProbeHttp(
        beforeFirstPost: () async {
          if (index == 0) {
            if (!refreshStarted.isCompleted) {
              refreshStarted.complete();
            }
            await releaseRefresh.future;
          } else {
            if (!signUpStarted.isCompleted) {
              signUpStarted.complete();
            }
            await releaseSignUp.future;
          }
        },
      );
      adapters.add(http);
      return http;
    };
    addTearDown(() => debugCreateIdentityToolkitHttp = null);

    final api = IdentityToolkitApi(apiKey: 'fake');
    final deleteFuture = api.deleteAccount(refreshToken: 'refresh-1');
    await refreshStarted.future;

    final signUpFuture = api.signUp(email: 'a@b.it', password: 'Password1');
    await signUpStarted.future;

    releaseRefresh.complete();
    await Future<void>.delayed(Duration.zero);
    releaseSignUp.complete();

    await Future.wait<void>([deleteFuture, signUpFuture]);

    expect(adapters, hasLength(2));
    expect(identical(adapters[0], adapters[1]), isFalse);
    expect(adapters[0].uris, hasLength(2));
    expect(adapters[0].uris[0].host, 'securetoken.googleapis.com');
    expect(adapters[0].uris[1].path, contains('accounts:delete'));
    expect(adapters[1].uris, hasLength(1));
    expect(adapters[1].uris[0].path, contains('accounts:signUp'));
    expect(adapters[0].closeCount, 1);
    expect(adapters[1].closeCount, 1);
  });
}
