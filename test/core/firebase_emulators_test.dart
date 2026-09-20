import 'package:amici_per_la_coda/core/firebase_emulators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('localhost web usa l’emulatore', () {
    expect(
      shouldUseEmulators(isWeb: true, host: 'localhost', dartDefine: false),
      isTrue,
    );
    expect(
      shouldUseEmulators(isWeb: true, host: '127.0.0.1', dartDefine: false),
      isTrue,
    );
  });

  test('hosting di produzione non usa l’emulatore', () {
    expect(
      shouldUseEmulators(
        isWeb: true,
        host: 'amici-per-la-coda.web.app',
        dartDefine: false,
      ),
      isFalse,
    );
  });

  test('APK non usa l’emulatore', () {
    expect(
      shouldUseEmulators(isWeb: false, host: 'localhost', dartDefine: false),
      isFalse,
    );
  });

  test('dart-define forza l’emulatore anche fuori localhost', () {
    expect(
      shouldUseEmulators(
        isWeb: true,
        host: 'amici-per-la-coda.web.app',
        dartDefine: true,
      ),
      isTrue,
    );
  });

  test('origin Identity Toolkit emulator solo se si usano gli emulatori', () {
    expect(identityToolkitEmulatorOrigin(useEmulators: false), isNull);
    expect(
      identityToolkitEmulatorOrigin(useEmulators: true),
      'http://127.0.0.1:9099',
    );
  });
}
