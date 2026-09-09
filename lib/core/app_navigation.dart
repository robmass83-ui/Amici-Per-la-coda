import 'package:go_router/go_router.dart';

/// Cronologia delle pagine visibili, per il tasto indietro di sistema.
///
/// `go` e i cambi di tab della shell non lasciano uno stack su cui
/// [GoRouter.pop] possa tornare: qui si ricorda la pagina precedente.
final class AppNavigationHistory {
  AppNavigationHistory();

  static const _max = 40;
  static const _login = '/login';

  final List<String> _stack = [];

  List<String> get stack => List<String>.unmodifiable(_stack);

  String? get previous => _stack.length >= 2 ? _stack[_stack.length - 2] : null;

  void record(String location) {
    if (location == _login) {
      _stack.clear();
      return;
    }
    if (_stack.isEmpty) {
      _stack.add(location);
      return;
    }
    if (_stack.last == location) {
      return;
    }
    if (_stack.length >= 2 && _stack[_stack.length - 2] == location) {
      _stack.removeLast();
      return;
    }
    _stack.add(location);
    if (_stack.length > _max) {
      _stack.removeAt(0);
    }
  }
}

String canonicalUri(Uri uri) {
  final path = uri.path.isEmpty ? '/' : uri.path;
  if (uri.hasQuery) {
    return '$path?${uri.query}';
  }
  return path;
}

String currentLocation(GoRouter router) {
  final matches = router.routerDelegate.currentConfiguration;
  if (matches.isEmpty) {
    return '/';
  }
  return canonicalUri(matches.uri);
}

/// Pagina padre del path corrente (deeplink o tab senza cronologia).
String? parentLocation(String location) {
  final path = Uri.tryParse(location)?.path ?? location;
  if (path.isEmpty || path == '/' || path == '/login') {
    return null;
  }
  const overlays = {
    '/nuovo',
    '/affido',
    '/impostazioni',
    '/box',
    '/statistiche',
    '/richieste',
    '/debug/ui',
  };
  if (overlays.contains(path)) {
    return '/';
  }
  final parts = path.split('/').where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) {
    return null;
  }
  parts.removeLast();
  if (parts.isEmpty) {
    return '/';
  }
  return '/${parts.join('/')}';
}

/// Gestisce la freccia indietro della barra di sistema Android.
///
/// Restituisce `true` se l'app resta aperta sulla pagina precedente.
Future<bool> handleSystemBack({
  required GoRouter router,
  required AppNavigationHistory history,
}) async {
  final root = router.routerDelegate.navigatorKey.currentState;
  if (root != null && root.canPop()) {
    root.pop();
    return true;
  }

  final current = currentLocation(router);
  final previous = history.previous;
  final parent = parentLocation(current);

  if (router.canPop()) {
    if (previous != null && previous != parent) {
      router.go(previous);
      return true;
    }
    router.pop();
    return true;
  }

  if (previous != null) {
    router.go(previous);
    return true;
  }

  if (parent != null) {
    router.go(parent);
    return true;
  }

  return false;
}
