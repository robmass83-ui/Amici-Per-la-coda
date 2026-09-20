import 'dart:convert';
import 'dart:io';

import 'identity_toolkit_http.dart';

class PlatformIdentityToolkitHttp implements IdentityToolkitHttp {
  PlatformIdentityToolkitHttp([HttpClient? client]) : _client = client ?? HttpClient();

  final HttpClient _client;

  @override
  Future<IdentityToolkitHttpResponse> post({
    required Uri uri,
    required List<int> bytes,
    required String contentType,
  }) async {
    try {
      final request = await _client.postUrl(uri);
      request.headers.contentType = ContentType.parse(contentType);
      request.add(bytes);
      final response = await request.close();
      final text = await utf8.decodeStream(response);
      return IdentityToolkitHttpResponse(
        statusCode: response.statusCode,
        body: text,
      );
    } on IdentityToolkitNetworkException {
      rethrow;
    } on IOException {
      throw const IdentityToolkitNetworkException();
    }
  }

  @override
  void close() => _client.close(force: true);
}
