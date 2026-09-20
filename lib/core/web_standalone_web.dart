import 'dart:js_interop';
import 'dart:js_interop_unsafe';

bool isStandaloneDisplay() {
  final nav = globalContext.getProperty('navigator'.toJS);
  if (nav == null) {
    return false;
  }
  final standalone = (nav as JSObject).getProperty('standalone'.toJS);
  if (standalone != null &&
      standalone.isA<JSBoolean>() &&
      (standalone as JSBoolean).toDart) {
    return true;
  }
  return false;
}
