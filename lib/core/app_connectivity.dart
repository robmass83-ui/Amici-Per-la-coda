import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class AppConnectivity {
  Future<List<ConnectivityResult>> check();
  Stream<List<ConnectivityResult>> get onChange;
}

class PluginAppConnectivity implements AppConnectivity {
  PluginAppConnectivity([Connectivity? plugin])
    : _plugin = plugin ?? Connectivity();

  final Connectivity _plugin;

  @override
  Future<List<ConnectivityResult>> check() => _plugin.checkConnectivity();

  @override
  Stream<List<ConnectivityResult>> get onChange =>
      _plugin.onConnectivityChanged;
}

final appConnectivityProvider = Provider<AppConnectivity>(
  (ref) => PluginAppConnectivity(),
);

final connectivityResultsProvider =
    StreamProvider<List<ConnectivityResult>>((ref) async* {
      final plugin = ref.watch(appConnectivityProvider);
      yield await plugin.check();
      yield* plugin.onChange;
    });

bool isOfflineConnectivity(List<ConnectivityResult> results) {
  if (results.isEmpty) {
    return true;
  }
  return results.every((item) => item == ConnectivityResult.none);
}
