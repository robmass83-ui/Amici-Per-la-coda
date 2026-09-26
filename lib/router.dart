import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/app_navigation.dart';
import 'core/web_surface.dart';
import 'data/data_providers.dart';
import 'data/models/enums.dart';
import 'data/models/volunteer.dart';
import 'features/adoptions/adopter_detail_page.dart';
import 'features/adoptions/adopter_form_page.dart';
import 'features/adoptions/adopters_page.dart';
import 'features/adoptions/adoption_detail_page.dart';
import 'features/adoptions/adoptions_page.dart';
import 'features/adoptions/new_adoption_page.dart';
import 'features/affido/affido_page.dart';
import 'features/auth/auth_providers.dart';
import 'features/auth/change_password_page.dart';
import 'features/auth/login_page.dart';
import 'features/boxes/boxes_page.dart';
import 'features/calendar/calendar_page.dart';
import 'features/contabilita/anni_page.dart';
import 'features/dashboard/home_page.dart';
import 'features/notifications/app_runtime_listener.dart';
import 'features/notifications/notifications_page.dart';
import 'features/search/search_page.dart';
import 'features/stats/stats_page.dart';
import 'features/vendors/vendor_detail_page.dart';
import 'features/vendors/vendor_form_page.dart';
import 'features/vendors/vendors_page.dart';
import 'features/debug/debug_ui_page.dart';
import 'features/dogs/archived_dogs_page.dart';
import 'features/dogs/change_status_page.dart';
import 'features/dogs/dog_detail_page.dart';
import 'features/dogs/dog_gallery_page.dart';
import 'features/dogs/dogs_page.dart';
import 'features/dogs/edit_dog_page.dart';
import 'features/dogs/edit_permissions.dart';
import 'features/dogs/new_dog/new_dog_wizard_page.dart';
import 'features/settings/altro_page.dart';
import 'features/settings/app_update_listener.dart';
import 'features/settings/moduli_page.dart';
import 'features/settings/settings_page.dart';
import 'features/settings/volunteer_detail_page.dart';
import 'features/shell/app_shell.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const login = '/login';
  static const animali = '/animali';
  static const calendario = '/calendario';
  static const contabilita = '/contabilita';
  static const altro = '/altro';
  static const debugUi = '/debug/ui';
  static const nuovo = '/nuovo';
  static const affido = '/affido';
  static const documenti = '/documenti';
  static const impostazioni = '/impostazioni';
  static const moduli = documenti;
  static const cambiaPassword = '/cambia-password';
  static const box = '/box';
  static String boxPerCane(String dogId) =>
      Uri(path: box, queryParameters: {'dogId': dogId}).toString();
  static const statistiche = '/statistiche';
  static const cerca = '/cerca';
  static const notifiche = '/notifiche';
  static const archiviati = '/archiviati';
  static const adottanti = '/adottanti';
  static const adottanteNuovo = '/adottanti/nuovo';
  static const fornitori = '/fornitori';
  static const fornitoreNuovo = '/fornitori/nuovo';
  static const richieste = '/richieste';
  static const nuovaRichiesta = '/richieste/nuova';
  static String contabilitaAnno(int anno) => '$contabilita/$anno';
  static String contabilitaDocumento(int anno, String id) =>
      '$contabilita/$anno/$id';

  static String dog(String id, {String? from}) {
    final path = '$animali/$id';
    if (from == null || from.isEmpty) {
      return path;
    }
    return Uri(path: path, queryParameters: {'from': from}).toString();
  }

  /// Da un overlay (`/archiviati`, `/cerca`, …) non si può `push` nella shell:
  /// i due navigator condividono la stessa key e in release resta una pagina vuota.
  static void openDog(BuildContext context, String id, {String? from}) {
    GoRouter.of(context).go(dog(id, from: from));
  }

  static String dogFoto(String id, {bool aggiungi = false}) {
    final path = '$animali/$id/foto';
    if (!aggiungi) {
      return path;
    }
    return Uri(path: path, queryParameters: {'aggiungi': '1'}).toString();
  }

  static String dogStato(String id, {String? stato}) {
    final path = '$animali/$id/stato';
    if (stato == null || stato.isEmpty) {
      return path;
    }
    return Uri(path: path, queryParameters: {'stato': stato}).toString();
  }

  static String dogModifica(String id, {String? sezione}) {
    final path = '$animali/$id/modifica';
    if (sezione == null || sezione.isEmpty) {
      return path;
    }
    return Uri(path: path, queryParameters: {'sezione': sezione}).toString();
  }

  static String richiesta(String id) => '$richieste/$id';
  static String modificaRichiesta(String id) => '$richieste/$id/modifica';
  static String nuovaRichiestaPer(String dogId) =>
      '$nuovaRichiesta?dogId=${Uri.encodeQueryComponent(dogId)}';
  static String affidoPer({String? adoptionId, String? dogId}) {
    final params = <String, String>{'adoptionId': ?adoptionId, 'dogId': ?dogId};
    if (params.isEmpty) {
      return affido;
    }
    return Uri(path: affido, queryParameters: params).toString();
  }

  static String volontario(String id) => '$impostazioni/utenti/$id';

  static String adottante(String id) => '$adottanti/$id';
  static String adottanteModifica(String id) => '$adottanti/$id/modifica';
  static String adottanteNuovoPer(String dogId) =>
      Uri(path: adottanteNuovo, queryParameters: {'dogId': dogId}).toString();

  static String fornitore(String id) => '$fornitori/$id';
  static String fornitoreModifica(String id) => '$fornitori/$id/modifica';
  static String fornitoreOrfano({required String nome, required String tipo}) =>
      Uri(
        path: fornitoreNuovo,
        queryParameters: {'nome': nome, 'tipo': tipo},
      ).toString();
}

final initialLocationProvider = Provider<String>((ref) => AppRoutes.home);

final appNavigationHistoryProvider = Provider<AppNavigationHistory>((ref) {
  return AppNavigationHistory();
});

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final volunteerRepo = ref.read(volunteerRepositoryProvider);
  final refresh = _AuthVolunteersRefresh(
    auth: auth.watchUser(),
    volunteersOf: () => volunteerRepo?.watchAll(),
  );
  final history = ref.read(appNavigationHistoryProvider);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: ref.watch(initialLocationProvider),
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = auth.currentUser != null;
      final onLogin = state.matchedLocation == AppRoutes.login;
      final onChangePassword =
          state.matchedLocation == AppRoutes.cambiaPassword;
      if (!loggedIn && !onLogin) {
        return AppRoutes.login;
      }
      if (!loggedIn) {
        return onLogin ? null : AppRoutes.login;
      }
      final user = auth.currentUser!;
      if (!refresh.volunteersReady) {
        return null;
      }
      Volunteer? byUid;
      for (final item in refresh.volunteers) {
        if (item.id == user.uid) {
          byUid = item;
          break;
        }
      }
      final volunteer = volunteerForAuth(
        refresh.volunteers,
        uid: user.uid,
        email: user.email,
      );
      final passwordGate = byUid ?? volunteer;
      final skipMustChange = ref
          .read(sessionSecretsProvider)
          .passwordChangeCompleted;
      final mustChange =
          passwordGate != null &&
          passwordGate.attivo &&
          passwordGate.mustChangePassword &&
          !skipMustChange;
      if (onLogin) {
        return mustChange ? AppRoutes.cambiaPassword : AppRoutes.home;
      }
      if (mustChange && !onChangePassword) {
        return AppRoutes.cambiaPassword;
      }
      if (!mustChange && onChangePassword) {
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
        path: AppRoutes.cambiaPassword,
        builder: (context, state) => const ChangePasswordPage(),
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
        path: '${AppRoutes.animali}/:dogId/modifica',
        builder: (context, state) {
          final id = state.pathParameters['dogId']!;
          return EditDogPage(
            dogId: id,
            sezione: state.uri.queryParameters['sezione'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.affido,
        builder: (context, state) => AffidoPage(
          adoptionId: state.uri.queryParameters['adoptionId'],
          dogId: state.uri.queryParameters['dogId'],
        ),
      ),
      GoRoute(
        path: AppRoutes.impostazioni,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.documenti,
        builder: (context, state) => const ModuliPage(),
      ),
      GoRoute(
        path: '${AppRoutes.impostazioni}/utenti/:volunteerId',
        builder: (context, state) {
          final id = state.pathParameters['volunteerId']!;
          return VolunteerDetailPage(volunteerId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.box,
        builder: (context, state) =>
            BoxesPage(initialDogId: state.uri.queryParameters['dogId']),
      ),
      GoRoute(
        path: AppRoutes.statistiche,
        builder: (context, state) => const StatsPage(),
      ),
      GoRoute(
        path: AppRoutes.cerca,
        builder: (context, state) => const SearchPage(),
      ),
      GoRoute(
        path: AppRoutes.notifiche,
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: AppRoutes.archiviati,
        builder: (context, state) => const ArchivedDogsPage(),
      ),
      GoRoute(
        path: AppRoutes.adottanti,
        builder: (context, state) => const AdoptersPage(),
        routes: [
          GoRoute(
            path: 'nuovo',
            builder: (context, state) =>
                AdopterFormPage(dogId: state.uri.queryParameters['dogId']),
          ),
          GoRoute(
            path: ':adopterId',
            builder: (context, state) => AdopterDetailPage(
              adopterId: state.pathParameters['adopterId']!,
            ),
            routes: [
              GoRoute(
                path: 'modifica',
                builder: (context, state) => AdopterFormPage(
                  adopterId: state.pathParameters['adopterId'],
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.fornitori,
        builder: (context, state) => const VendorsPage(),
        routes: [
          GoRoute(
            path: 'nuovo',
            builder: (context, state) => VendorFormPage(
              prefillNome: state.uri.queryParameters['nome'],
              prefillTipo: state.uri.queryParameters['tipo'],
            ),
          ),
          GoRoute(
            path: ':vendorId',
            builder: (context, state) =>
                VendorDetailPage(vendorId: state.pathParameters['vendorId']!),
            routes: [
              GoRoute(
                path: 'modifica',
                builder: (context, state) =>
                    VendorFormPage(vendorId: state.pathParameters['vendorId']),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.richieste,
        builder: (context, state) => const AdoptionsPage(),
        routes: [
          GoRoute(
            path: 'nuova',
            builder: (context, state) =>
                NewAdoptionPage(dogId: state.uri.queryParameters['dogId']),
          ),
          GoRoute(
            path: ':adoptionId',
            builder: (context, state) {
              final id = state.pathParameters['adoptionId']!;
              return AdoptionDetailPage(adoptionId: id);
            },
            routes: [
              GoRoute(
                path: 'modifica',
                builder: (context, state) {
                  final id = state.pathParameters['adoptionId']!;
                  return NewAdoptionPage(existingId: id);
                },
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        // I tab restano montati: i listener `dogs` e copertine non si ricreano.
        builder: (context, state, navigationShell) {
          final shell = AppRuntimeListener(
            child: AppShell(navigationShell: navigationShell),
          );
          if (!showAndroidOnlyTools()) {
            return shell;
          }
          return AppUpdateListener(child: shell);
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
                          return DogGalleryPage(
                            dogId: id,
                            openAddOnStart:
                                state.uri.queryParameters['aggiungi'] == '1',
                          );
                        },
                      ),
                      GoRoute(
                        path: 'stato',
                        builder: (context, state) {
                          final id = state.pathParameters['dogId']!;
                          return ChangeStatusPage(
                            dogId: id,
                            initialStato: _dogStatoFromQuery(
                              state.uri.queryParameters['stato'],
                            ),
                          );
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
                builder: (context, state) => const CalendarPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.contabilita,
                builder: (context, state) => const AnniContabiliPage(),
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

class _AuthVolunteersRefresh extends ChangeNotifier {
  _AuthVolunteersRefresh({
    required Stream<dynamic> auth,
    required this.volunteersOf,
  }) {
    _subs.add(
      auth.listen((_) {
        _listenVolunteers();
        notifyListeners();
      }),
    );
    _listenVolunteers();
  }

  final Stream<List<Volunteer>>? Function() volunteersOf;
  StreamSubscription<List<Volunteer>>? _volSub;
  List<Volunteer> volunteers = const [];
  bool volunteersReady = false;
  final _subs = <StreamSubscription<dynamic>>[];

  void _listenVolunteers() {
    unawaited(_volSub?.cancel());
    _volSub = null;
    volunteers = const [];
    volunteersReady = false;
    final stream = volunteersOf();
    if (stream == null) {
      volunteersReady = true;
      return;
    }
    _volSub = stream.listen(
      (items) {
        volunteers = items;
        volunteersReady = true;
        notifyListeners();
      },
      onError: (_) {
        volunteersReady = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    unawaited(_volSub?.cancel());
    for (final sub in _subs) {
      unawaited(sub.cancel());
    }
    super.dispose();
  }
}

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

DogStato? _dogStatoFromQuery(String? raw) {
  if (raw == null || raw.isEmpty) {
    return null;
  }
  for (final value in DogStato.values) {
    if (value.wire == raw) {
      return value;
    }
  }
  return null;
}
