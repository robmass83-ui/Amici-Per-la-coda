import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:amici_per_la_coda/core/app_connectivity.dart';

class ControllableAppConnectivity implements AppConnectivity {
  ControllableAppConnectivity([
    List<ConnectivityResult> current = const [ConnectivityResult.wifi],
  ]) : _current = current;

  List<ConnectivityResult> _current;
  final _controller = StreamController<List<ConnectivityResult>>.broadcast();

  @override
  Future<List<ConnectivityResult>> check() async => _current;

  @override
  Stream<List<ConnectivityResult>> get onChange => _controller.stream;

  void emit(List<ConnectivityResult> next) {
    _current = next;
    _controller.add(next);
  }

  Future<void> dispose() => _controller.close();
}
