import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/tokens.dart';
import 'web_standalone.dart'
    if (dart.library.html) 'web_standalone_web.dart';

/// Nei test: `true` simula il web, `false`/`null` lascia `kIsWeb`.
final webSurfaceIsWebProvider = Provider<bool?>((ref) => null);

bool showAndroidOnlyTools({bool? isWeb}) => !(isWeb ?? kIsWeb);

bool showWebInstallHint({bool? isWeb, bool? standalone}) {
  return (isWeb ?? kIsWeb) && !(standalone ?? isStandaloneDisplay());
}

bool showWideWebColumn({bool? isWeb, double? width}) {
  if (!(isWeb ?? kIsWeb)) {
    return false;
  }
  return (width ?? 0) > AppDim.webMaxContentWidth;
}
