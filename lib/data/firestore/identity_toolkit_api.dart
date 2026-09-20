import 'dart:async';
import 'dart:convert';

import '../../core/auth_errors.dart';
import '../../core/firebase_emulators.dart';
import '../repositories/auth_repository.dart';
import 'identity_toolkit_http.dart';
import 'identity_toolkit_http_factory.dart';

/// REST Identity Toolkit: crea/elimina utenti senza toccare la sessione SDK.
class IdentityToolkitApi {
  IdentityToolkitApi({
    required this.apiKey,
    IdentityToolkitHttp? http,
    String? emulatorOrigin,
  }) : _injectedHttp = http,
       emulatorOrigin = emulatorOrigin ?? identityToolkitEmulatorOrigin();

  final String apiKey;
  final IdentityToolkitHttp? _injectedHttp;
  final String? emulatorOrigin;

  Future<CreatedAuthUser> signUp({
    required String email,
    required String password,
  }) {
    return _runOwned(
      (http) => _credentialPost(http, 'accounts:signUp', {
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );
  }

  Future<CreatedAuthUser> signIn({
    required String email,
    required String password,
  }) {
    return _runOwned(
      (http) => _credentialPost(http, 'accounts:signInWithPassword', {
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );
  }

  Future<void> deleteAccount({required String refreshToken}) {
    return _runOwned((http) async {
      final idToken = await _idTokenFromRefresh(http, refreshToken);
      try {
        await _postJson(http, _authUri('accounts:delete'), {
          'idToken': idToken,
        });
      } on AuthFailure catch (error) {
        if (isAuthUserMissing(error)) {
          return;
        }
        rethrow;
      }
    });
  }

  Future<T> _runOwned<T>(
    Future<T> Function(IdentityToolkitHttp http) action,
  ) async {
    final injected = _injectedHttp;
    if (injected != null) {
      return action(injected);
    }
    final http = createIdentityToolkitHttp();
    try {
      return await action(http);
    } finally {
      http.close();
    }
  }

  Future<CreatedAuthUser> _credentialPost(
    IdentityToolkitHttp http,
    String path,
    Map<String, dynamic> body,
  ) async {
    final data = await _postJson(http, _authUri(path), body);
    final uid = data['localId'] as String? ?? '';
    if (uid.isEmpty) {
      throw const AuthFailure('Creazione account non riuscita. Riprova.');
    }
    final refresh = data['refreshToken'] as String?;
    return CreatedAuthUser(
      uid: uid,
      refreshToken: refresh == null || refresh.isEmpty ? null : refresh,
    );
  }

  Future<String> _idTokenFromRefresh(
    IdentityToolkitHttp http,
    String refreshToken,
  ) async {
    final data = await _postForm(
      http,
      Uri.https('securetoken.googleapis.com', '/v1/token', {'key': apiKey}),
      'grant_type=refresh_token&refresh_token=${Uri.encodeQueryComponent(refreshToken)}',
    );
    final idToken = data['id_token'] as String? ?? '';
    if (idToken.isEmpty) {
      throw const AuthFailure(
        'Non è stato possibile eliminare l\'accesso. Riprova.',
      );
    }
    return idToken;
  }

  Uri _authUri(String path) {
    final origin = emulatorOrigin;
    if (origin != null && origin.isNotEmpty) {
      return Uri.parse(
        '$origin/identitytoolkit.googleapis.com/v1/$path?key=$apiKey',
      );
    }
    return Uri.https('identitytoolkit.googleapis.com', '/v1/$path', {
      'key': apiKey,
    });
  }

  Future<Map<String, dynamic>> _postJson(
    IdentityToolkitHttp http,
    Uri uri,
    Map<String, dynamic> body,
  ) {
    return _send(http, uri, utf8.encode(jsonEncode(body)), 'application/json');
  }

  Future<Map<String, dynamic>> _postForm(
    IdentityToolkitHttp http,
    Uri uri,
    String body,
  ) {
    return _send(
      http,
      uri,
      utf8.encode(body),
      'application/x-www-form-urlencoded; charset=utf-8',
    );
  }

  Future<Map<String, dynamic>> _send(
    IdentityToolkitHttp http,
    Uri uri,
    List<int> bytes,
    String contentType,
  ) async {
    try {
      final response = await http
          .post(uri: uri, bytes: bytes, contentType: contentType)
          .timeout(_timeout);
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const AuthFailure('Accesso non riuscito. Riprova.');
      }
      final map = <String, dynamic>{
        for (final entry in decoded.entries) '${entry.key}': entry.value,
      };
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthFailure(italianAuthMessage(_errorCode(map)));
      }
      return map;
    } on AuthFailure {
      rethrow;
    } on TimeoutException {
      throw const AuthFailure('Il salvataggio sta impiegando troppo. Riprova.');
    } on IdentityToolkitNetworkException {
      throw AuthFailure(italianAuthMessage('network-request-failed'));
    } catch (_) {
      throw const AuthFailure('Accesso non riuscito. Riprova.');
    }
  }

  static String _errorCode(Map<String, dynamic> body) {
    final error = body['error'];
    if (error is! Map) {
      return 'unknown';
    }
    final raw = '${error['message'] ?? ''}';
    final head = raw.split(RegExp('[: ]')).first.trim().toUpperCase();
    return switch (head) {
      'EMAIL_EXISTS' => 'email-already-in-use',
      'INVALID_EMAIL' => 'invalid-email',
      'WEAK_PASSWORD' => 'weak-password',
      'EMAIL_NOT_FOUND' => 'user-not-found',
      'INVALID_PASSWORD' => 'wrong-password',
      'INVALID_LOGIN_CREDENTIALS' => 'invalid-credential',
      'USER_DISABLED' => 'user-disabled',
      'USER_NOT_FOUND' => 'user-not-found',
      'INVALID_ID_TOKEN' => 'invalid-refresh-token',
      'INVALID_REFRESH_TOKEN' => 'invalid-refresh-token',
      'TOKEN_EXPIRED' => 'invalid-refresh-token',
      'TOO_MANY_ATTEMPTS_TRY_LATER' => 'too-many-requests',
      'OPERATION_NOT_ALLOWED' => 'operation-not-allowed',
      _ => 'unknown',
    };
  }

  static const _timeout = Duration(seconds: 20);
}
