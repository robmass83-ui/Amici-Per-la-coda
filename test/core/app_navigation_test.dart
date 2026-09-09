import 'package:amici_per_la_coda/core/app_navigation.dart';
import 'package:amici_per_la_coda/router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('i path overlay coincidono con AppRoutes', () {
    expect(parentLocation(AppRoutes.nuovo), AppRoutes.home);
    expect(parentLocation(AppRoutes.affido), AppRoutes.home);
    expect(parentLocation(AppRoutes.impostazioni), AppRoutes.home);
    expect(parentLocation(AppRoutes.box), AppRoutes.home);
    expect(parentLocation(AppRoutes.statistiche), AppRoutes.home);
    expect(parentLocation(AppRoutes.richieste), AppRoutes.home);
    expect(parentLocation(AppRoutes.debugUi), AppRoutes.home);
    expect(parentLocation(AppRoutes.login), isNull);
    expect(parentLocation(AppRoutes.home), isNull);
  });

  test('il padre di una scheda è l\'elenco, il padre di una tab è Home', () {
    expect(parentLocation(AppRoutes.dog('fenice')), AppRoutes.animali);
    expect(parentLocation(AppRoutes.dogFoto('fenice')), AppRoutes.dog('fenice'));
    expect(parentLocation(AppRoutes.dogStato('fenice')), AppRoutes.dog('fenice'));
    expect(parentLocation(AppRoutes.animali), AppRoutes.home);
    expect(parentLocation(AppRoutes.calendario), AppRoutes.home);
    expect(parentLocation(AppRoutes.altro), AppRoutes.home);
  });

  test('la cronologia ricorda la pagina precedente e tratta A→B→A come indietro', () {
    final history = AppNavigationHistory();
    history.record('/');
    history.record('/animali');
    history.record('/calendario');
    expect(history.previous, '/animali');
    expect(history.stack, ['/', '/animali', '/calendario']);

    history.record('/animali');
    expect(history.stack, ['/', '/animali']);
    expect(history.previous, '/');

    history.record('/');
    expect(history.stack, ['/']);
    expect(history.previous, isNull);
  });

  test('login svuota la cronologia e i duplicati consecutivi si ignorano', () {
    final history = AppNavigationHistory();
    history.record('/');
    history.record('/animali');
    history.record('/animali');
    expect(history.stack, ['/', '/animali']);

    history.record('/login');
    expect(history.stack, isEmpty);
    expect(history.previous, isNull);

    history.record('/');
    expect(history.stack, ['/']);
  });
}
