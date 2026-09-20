import 'package:amici_per_la_coda/core/web_surface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('voci APK solo fuori dal web', () {
    expect(showAndroidOnlyTools(isWeb: false), isTrue);
    expect(showAndroidOnlyTools(isWeb: true), isFalse);
  });

  test('hint Home solo web non standalone', () {
    expect(showWebInstallHint(isWeb: true, standalone: false), isTrue);
    expect(showWebInstallHint(isWeb: true, standalone: true), isFalse);
    expect(showWebInstallHint(isWeb: false, standalone: false), isFalse);
  });

  test('colonna larga solo web oltre 430', () {
    expect(showWideWebColumn(isWeb: true, width: 1280), isTrue);
    expect(showWideWebColumn(isWeb: true, width: 430), isFalse);
    expect(showWideWebColumn(isWeb: false, width: 1280), isFalse);
  });
}
