import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('robots.txt vieta tutto', () {
    final text = File('web/robots.txt').readAsStringSync();
    expect(text, contains('User-agent: *'));
    expect(text, contains('Disallow: /'));
  });

  test('index.html ha noindex e meta iOS', () {
    final html = File('web/index.html').readAsStringSync();
    expect(html, contains('noindex'));
    expect(html, contains('apple-mobile-web-app-capable'));
    expect(html, contains('apple-touch-icon'));
    expect(html, contains('viewport'));
  });

  test('manifest standalone con colori del tema', () {
    final raw = File('web/manifest.json').readAsStringSync();
    expect(raw, contains('"display": "standalone"'));
    expect(raw, contains('#157A3C'));
    expect(raw, contains('#F5F7F3'));
    expect(raw, contains('Amici per la Coda'));
    expect(raw, contains('192'));
    expect(raw, contains('512'));
    expect(raw, contains('maskable'));
  });

  test('icone 192 e 512 esistono', () {
    expect(File('web/icons/Icon-192.png').existsSync(), isTrue);
    expect(File('web/icons/Icon-512.png').existsSync(), isTrue);
  });
}
