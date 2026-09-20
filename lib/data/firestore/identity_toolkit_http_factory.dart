import 'package:flutter/foundation.dart';

import 'identity_toolkit_http.dart';
import 'identity_toolkit_http_io.dart'
    if (dart.library.html) 'identity_toolkit_http_web.dart';

/// Test-only replacement for [createIdentityToolkitHttp].
@visibleForTesting
IdentityToolkitHttp Function()? debugCreateIdentityToolkitHttp;

IdentityToolkitHttp createIdentityToolkitHttp() {
  final override = debugCreateIdentityToolkitHttp;
  if (override != null) {
    return override();
  }
  return PlatformIdentityToolkitHttp();
}
