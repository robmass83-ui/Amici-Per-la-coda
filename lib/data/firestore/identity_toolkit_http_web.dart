import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'identity_toolkit_http.dart';

class PlatformIdentityToolkitHttp implements IdentityToolkitHttp {
  @override
  Future<IdentityToolkitHttpResponse> post({
    required Uri uri,
    required List<int> bytes,
    required String contentType,
  }) async {
    final headers = JSObject()
      ..setProperty('Content-Type'.toJS, contentType.toJS);
    final init = JSObject()
      ..setProperty('method'.toJS, 'POST'.toJS)
      ..setProperty('headers'.toJS, headers)
      ..setProperty('body'.toJS, utf8.decode(bytes).toJS);
    final response = await _fetch(uri.toString().toJS, init).toDart;
    final status = (response.getProperty('status'.toJS) as JSNumber).toDartInt;
    final textPromise = response.callMethod('text'.toJS) as JSPromise<JSString>;
    final text = (await textPromise.toDart).toDart;
    return IdentityToolkitHttpResponse(statusCode: status, body: text);
  }

  @override
  void close() {}
}

@JS('fetch')
external JSPromise<JSObject> _fetch(JSString url, JSObject init);
