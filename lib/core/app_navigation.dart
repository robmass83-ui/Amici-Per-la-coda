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

const overlayLocations = {
  '/nuovo',
  '/affido',
  '/documenti',
  '/impostazioni',
  '/box',
  '/statistiche',
  '/cerca',
  '/notifiche',
  '/archiviati',
  '/adottanti',
  '/fornitori',
  '/richieste',
  '/debug/ui',
};

bool isOverlayLocation(String location) {
  final path = Uri.tryParse(location)?.path ?? location;
  if (overlayLocations.contains(path)) {
    return true;
  }
  return path.startsWith('/richieste/') ||
      path.startsWith('/impostazioni/');
}

/// Overlay da cui si è aperta una scheda (es. /archiviati → /animali/id).
String? overlayOrigin(AppNavigationHistory history) {
  final stack = history.stack;
  for (var i = stack.length - 2; i >= 0; i--) {
    if (isOverlayLocation(stack[i])) {
      return stack[i];
    }
  }
  return null;
}

bool isDogProfileLocation(String location) {
  final path = Uri.tryParse(location)?.path ?? location;
  final parts = path.split('/').where((part) => part.isNotEmpty).toList();
  return parts.length == 2 && parts.first == 'animali';
}

/// Pagina padre del path corrente (deeplink o tab senza cronologia).
String? parentLocation(String location) {
  final path = Uri.tryParse(location)?.path ?? location;
  if (path.isEmpty || path == '/' || path == '/login') {
    return null;
  }
  if (overlayLocations.contains(path)) {
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
  final current = currentLocation(router);
  final fromOverlay = overlayOrigin(history);
  if (fromOverlay != null && isDogProfileLocation(current)) {
    router.go(fromOverlay);
    return true;
  }

  final root = router.routerDelegate.navigatorKey.currentState;
  if (root != null && root.canPop()) {
    root.pop();
    return true;
  }

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
