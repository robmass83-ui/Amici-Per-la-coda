import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/adopter.dart';
import '../../router.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../affido/affido_providers.dart';
import '../dogs/dogs_providers.dart';
import '../dogs/edit_permissions.dart';

// ── CONTRATTO DI LAYOUT · Famiglie adottanti ──────────────────────────────
// AppScaffold  titolo + (se canWrite) action 40×40 key adottanti-add
// ListView padding=12
// └ AppCard  OptionRow  icona famiglie  titolo nome  subtitle città
//    tap → profilo
// ───────────────────────────────────────────────────────────────────────────

class AdoptersPage extends ConsumerWidget {
  const AdoptersPage({super.key});

  static const listKey = Key('adottanti-list');
  static const addKey = Key('adottanti-add');
  static Key rowKey(String id) => Key('adottante-$id');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canWrite = canWriteRecords(ref.watch(currentVolunteerProvider));
    final adopters = ref.watch(adoptersStreamProvider).maybeWhen(
          data: (items) => items,
          orElse: () => const <Adopter>[],
        );
    final sorted = List<Adopter>.of(adopters)
      ..sort(
        (a, b) => a.nomeCompleto.toLowerCase().compareTo(
              b.nomeCompleto.toLowerCase(),
            ),
      );

    return AppScaffold(
      title: 'Famiglie adottanti',
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.altro);
        }
      },
      headerActions: canWrite
          ? [
              GestureDetector(
                key: addKey,
                behavior: HitTestBehavior.opaque,
                onTap: () => context.push(AppRoutes.adottanteNuovo),
                child: const SizedBox(
                  width: AppDim.minTouch,
                  height: AppDim.minTouch,
                  child: Center(
                    child: IconBadge(AppIcons.aggiungi, size: IconBadge.inMenu),
                  ),
                ),
              ),
            ]
          : null,
      body: sorted.isEmpty
          ? const Center(
              child: EmptyState(
                icon: IconBadge(AppIcons.famiglie),
                message: 'Nessuna famiglia in anagrafe.',
                compact: true,
              ),
            )
          : ListView(
              key: listKey,
              padding: AppDim.pagePad,
              children: [
                AppCard(
                  child: Column(
                    children: [
                      for (final item in sorted)
                        OptionRow(
                          key: AdoptersPage.rowKey(item.id),
                          icon: const IconBadge(
                            AppIcons.famiglie,
                            size: IconBadge.inMenu,
                          ),
                          title: item.nomeCompleto.isEmpty
                              ? 'Senza nome'
                              : item.nomeCompleto,
                          subtitle: item.citta.isEmpty ? '—' : item.citta,
                          minHeight: AppDim.menuRowH,
                          titleSize: AppText.formCard,
                          onTap: () =>
                              context.push(AppRoutes.adottante(item.id)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
