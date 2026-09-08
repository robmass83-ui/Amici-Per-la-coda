import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../ui/components.dart';
import '../../ui/tokens.dart';
import 'new_item_sheet.dart';

/// Contenitore delle 4 sezioni con header logo e bottom nav.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final hideLogoHeader = _isDogDetailPath(
      GoRouterState.of(context).uri.path,
    );
    final nav = AppBottomNav(
      currentIndex: navigationShell.currentIndex,
      onSelect: (index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      ),
      onFab: () => unawaited(showNewItemSheet(context)),
    );

    if (hideLogoHeader) {
      return Scaffold(
        backgroundColor: AppColor.bg,
        body: navigationShell,
        bottomNavigationBar: nav,
      );
    }

    return AppScaffold(
      showLogo: true,
      body: navigationShell,
      bottomNavigationBar: nav,
    );
  }
}

bool _isDogDetailPath(String path) {
  final parts = path.split('/').where((part) => part.isNotEmpty).toList();
  return parts.length >= 2 && parts.first == 'animali';
}
