import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/auth_providers.dart';
import 'features/auth/login_page.dart';
import 'features/calendar/calendar_placeholder_page.dart';
import 'features/dashboard/home_page.dart';
import 'features/dashboard/placeholder_feature_page.dart';
import 'features/debug/debug_ui_page.dart';
import 'features/dogs/dog_detail_page.dart';
import 'features/dogs/dog_gallery_page.dart';
import 'features/dogs/dogs_page.dart';
import 'features/dogs/new_dog/new_dog_wizard_page.dart';
import 'features/settings/altro_page.dart';
import 'features/settings/app_update_listener.dart';
import 'features/shell/app_shell.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const login = '/login';
  static const animali = '/animali';
  static const calendario = '/calendario';
  static const altro = '/altro';
  static const debugUi = '/debug/ui';
  static const nuovo = '/nuovo';
  static const affido = '/affido';
  static const box = '/box';
  static const statistiche = '/statistiche';
  static const richieste = '/richieste';

  static String dog(String id) => '$animali/$id';
  static String dogFoto(String id) => '$animali/$id/foto';
}

final initialLocationProvider = Provider<String>((ref) => AppRoutes.home);

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final refresh = GoRouterRefreshStream(auth.watchUser());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: ref.watch(initialLocationProvider),
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = auth.currentUser != null;
      final onLogin = state.matchedLocation == AppRoutes.login;
      if (!loggedIn && !onLogin) {
        return AppRoutes.login;
      }
      if (loggedIn && onLogin) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.debugUi,
        builder: (context, state) => const DebugUiPage(),
      ),
      GoRoute(
        path: AppRoutes.nuovo,
        builder: (context, state) => const NewDogWizardPage(),
      ),
      GoRoute(
        path: AppRoutes.affido,
        builder: (context, state) =>
            const PlaceholderFeaturePage(title: 'Modulo affido'),
      ),
      GoRoute(
        path: AppRoutes.box,
        builder: (context, state) =>
            const PlaceholderFeaturePage(title: 'Box e settori'),
      ),
      GoRoute(
        path: AppRoutes.statistiche,
        builder: (context, state) =>
            const PlaceholderFeaturePage(title: 'Statistiche'),
      ),
      GoRoute(
        path: AppRoutes.richieste,
        builder: (context, state) =>
            const PlaceholderFeaturePage(title: 'Richieste di adozione'),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppUpdateListener(
            child: AppShell(navigationShell: navigationShell),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.animali,
                builder: (context, state) => const DogsPage(),
                routes: [
                  GoRoute(
                    path: ':dogId',
                    builder: (context, state) {
                      final id = state.pathParameters['dogId']!;
                      return DogDetailPage(dogId: id);
                    },
                    routes: [
                      GoRoute(
                        path: 'foto',
                        builder: (context, state) {
                          final id = state.pathParameters['dogId']!;
                          return DogGalleryPage(dogId: id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.calendario,
                builder: (context, state) => const CalendarPlaceholderPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.altro,
                builder: (context, state) => const AltroPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
