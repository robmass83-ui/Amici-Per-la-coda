import 'identity_toolkit_http.dart';
import 'identity_toolkit_http_io.dart'
    if (dart.library.html) 'identity_toolkit_http_web.dart';

IdentityToolkitHttp createIdentityToolkitHttp() => PlatformIdentityToolkitHttp();
