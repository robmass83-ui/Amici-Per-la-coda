import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_update/app_update_controller.dart';
import '../../core/app_update/app_update_state.dart';
import '../../router.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../auth/auth_providers.dart';

// ── CONTRATTO DI LAYOUT · Altro ────────────────────────────────────────────
// ListView padding=12
// └ AppCard
//    ├ OptionRow Impostazioni
//    ├ OptionRow Aggiornamenti  (versione installata + stato GitHub)
//    ├ OptionRow Catalogo UI
//    └ OptionRow Esci
// ───────────────────────────────────────────────────────────────────────────

/// Menu Altro. Schermate complete allo Step 18 e 25.
class AltroPage extends ConsumerWidget {
  const AltroPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final update = ref.watch(appUpdateControllerProvider);
    final version = update.installed?.label ?? 'in lettura…';
    final subtitle = switch (update.phase) {
      AppUpdatePhase.checking => 'Controllo su GitHub…',
      AppUpdatePhase.available =>
        'Versione $version · disponibile ${update.release?.versionName}',
      AppUpdatePhase.downloading => 'Download in corso…',
      AppUpdatePhase.installing => 'Installazione…',
      AppUpdatePhase.upToDate => 'Versione $version · sei aggiornato',
      AppUpdatePhase.failed => update.error ?? 'Controllo non riuscito',
      AppUpdatePhase.idle => 'Versione $version · tocca per controllare',
    };

    return ListView(
      padding: AppDim.pagePad,
      children: [
        AppCard(
          child: Column(
            children: [
              OptionRow(
                icon: const IconBadge(
                  AppIcons.regolazioni,
                  size: IconBadge.inMenu,
                ),
                title: 'Impostazioni',
                subtitle: 'Associazione, moduli, backup',
                onTap: () => context.push(AppRoutes.impostazioni),
              ),
              OptionRow(
                icon: const IconBadge(
                  AppIcons.aggiorna,
                  size: IconBadge.inMenu,
                ),
                title: 'Aggiornamenti',
                subtitle: subtitle,
                onTap: () => unawaited(
                  ref
                      .read(appUpdateControllerProvider.notifier)
                      .check(userInitiated: true),
                ),
              ),
              OptionRow(
                icon: const IconBadge(
                  AppIcons.catalogo,
                  size: IconBadge.inMenu,
                ),
                title: 'Catalogo UI',
                subtitle: 'Componenti di debug',
                onTap: () => context.push(AppRoutes.debugUi),
              ),
              OptionRow(
                icon: const IconBadge(AppIcons.esci, size: IconBadge.inMenu),
                title: 'Esci',
                subtitle: 'Chiudi la sessione',
                onTap: () => ref.read(authRepositoryProvider).signOut(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
