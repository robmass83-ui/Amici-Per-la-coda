import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_navigation.dart';
import 'router.dart';
import 'ui/theme.dart';

/// Radice dell'applicazione.
class AmiciPerLaCodaApp extends ConsumerStatefulWidget {
  const AmiciPerLaCodaApp({super.key});

  @override
  ConsumerState<AmiciPerLaCodaApp> createState() => _AmiciPerLaCodaAppState();
}

class _AmiciPerLaCodaAppState extends ConsumerState<AmiciPerLaCodaApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() {
    return handleSystemBack(
      router: ref.read(routerProvider),
      history: ref.read(appNavigationHistoryProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Amici per la Coda',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}
