class IdentityToolkitHttpResponse {
  const IdentityToolkitHttpResponse({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;
}

/// Fallimento di trasporto (niente rete, DNS, connessione rifiutata).
class IdentityToolkitNetworkException implements Exception {
  const IdentityToolkitNetworkException();
}

abstract interface class IdentityToolkitHttp {
  Future<IdentityToolkitHttpResponse> post({
    required Uri uri,
    required List<int> bytes,
    required String contentType,
  });
  void close();
}
