import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/app_navigation.dart';
import 'features/adoptions/adoption_detail_page.dart';
import 'features/adoptions/adoptions_page.dart';
import 'features/adoptions/new_adoption_page.dart';
import 'features/auth/auth_providers.dart';
import 'features/auth/login_page.dart';
import 'features/calendar/calendar_placeholder_page.dart';
import 'features/dashboard/home_page.dart';
import 'features/dashboard/placeholder_feature_page.dart';
import 'features/debug/debug_ui_page.dart';
import 'features/dogs/change_status_page.dart';
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
  static const nuovaRichiesta = '/richieste/nuova';

  static String dog(String id) => '$animali/$id';
  static String dogFoto(String id) => '$animali/$id/foto';
  static String dogStato(String id) => '$animali/$id/stato';
  static String richiesta(String id) => '$richieste/$id';
  static String nuovaRichiestaPer(String dogId) =>
      '$nuovaRichiesta?dogId=${Uri.encodeQueryComponent(dogId)}';
}

final initialLocationProvider = Provider<String>((ref) => AppRoutes.home);

final appNavigationHistoryProvider = Provider<AppNavigationHistory>((ref) {
  return AppNavigationHistory();
});

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final refresh = GoRouterRefreshStream(auth.watchUser());
  final history = ref.read(appNavigationHistoryProvider);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
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
        builder: (context, state) => const AdoptionsPage(),
        routes: [
          GoRoute(
            path: 'nuova',
            builder: (context, state) => NewAdoptionPage(
              dogId: state.uri.queryParameters['dogId'],
            ),
          ),
          GoRoute(
            path: ':adoptionId',
            builder: (context, state) {
              final id = state.pathParameters['adoptionId']!;
              return AdoptionDetailPage(adoptionId: id);
            },
          ),
        ],
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
                      GoRoute(
                        path: 'stato',
                        builder: (context, state) {
                          final id = state.pathParameters['dogId']!;
                          return ChangeStatusPage(dogId: id);
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

  void syncHistory() {
    final matches = router.routerDelegate.currentConfiguration;
    if (matches.isEmpty) {
      return;
    }
    history.record(canonicalUri(matches.uri));
  }

  router.routerDelegate.addListener(syncHistory);
  syncHistory();
  ref.onDispose(() => router.routerDelegate.removeListener(syncHistory));
  return router;
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
