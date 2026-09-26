import 'package:amici_per_la_coda/core/web_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('il testo di condivisione contiene l\'indirizzo della web app', () {
    expect(webAppUrl, 'https://amici-per-la-coda.web.app');
    expect(webAppShareText, contains(webAppUrl));
    expect(webAppShareText, contains('Amici per la Coda'));
  });
}
