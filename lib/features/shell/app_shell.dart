import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../affido/affido_providers.dart';
import '../auth/account_blocked_page.dart';
import '../dashboard/home_page.dart';
import '../dashboard/home_providers.dart';
import '../dogs/edit_permissions.dart';
import 'new_item_sheet.dart';

// ── CONTRATTO DI LAYOUT · Shell ────────────────────────────────────────────
// se volontario disattivato: AccountBlockedPage (niente nav, niente FAB)
// altrimenti:
// se staleDataProvider: StaleDataBanner h=AppDim.offlineBannerH
//   testo 10sp  «Dati non aggiornati · sei offline» | «Dati non aggiornati»
// AppScaffold(logo) + AppBottomNav  oppure Scaffold su scheda cane
// ───────────────────────────────────────────────────────────────────────────

/// Contenitore delle 4 sezioni con header logo e bottom nav.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final volunteer = ref.watch(currentVolunteerProvider);
    if (volunteer != null && !volunteer.attivo) {
      return const AccountBlockedPage(
        messageKey: HomePage.accountDeactivatedKey,
        message: 'Account disattivato',
      );
    }

    final hideLogoHeader = _isDogDetailPath(GoRouterState.of(context).uri.path);
    final canWrite = canWriteRecords(volunteer);
    final stale = ref.watch(staleDataProvider);
    final banner = stale ? const StaleDataBanner() : null;
    final nav = AppBottomNav(
      currentIndex: navigationShell.currentIndex,
      onSelect: (index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      ),
      onFab: canWrite ? () => unawaited(showNewItemSheet(context)) : null,
    );

    if (hideLogoHeader) {
      return Scaffold(
        backgroundColor: AppColor.bg,
        body: Column(
          children: [
            if (banner != null) SafeArea(bottom: false, child: banner),
            Expanded(child: navigationShell),
          ],
        ),
        bottomNavigationBar: nav,
      );
    }

    return AppScaffold(
      showLogo: true,
      body: Column(
        children: [
          ?banner,
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: nav,
    );
  }
}

bool _isDogDetailPath(String path) {
  final parts = path.split('/').where((part) => part.isNotEmpty).toList();
  return parts.length >= 2 && parts.first == 'animali';
}
