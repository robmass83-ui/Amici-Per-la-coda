import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/enums.dart';
import '../../data/models/expense.dart';
import '../../data/models/health_record.dart';
import '../../data/models/vendor.dart';
import '../../router.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../affido/affido_providers.dart';
import '../dashboard/home_providers.dart';
import '../dogs/edit_permissions.dart';
import '../stats/stats_providers.dart';
import 'vendor_logic.dart';
import 'vendor_providers.dart';

// ── CONTRATTO DI LAYOUT · Veterinari e fornitori ──────────────────────────
// AppScaffold  titolo + (se canWrite) action 40×40 key fornitori-add
// ListView padding=12
// └ AppCard  OptionRow  titolo nome  subtitle tipo
//    tap: salvato → scheda; orfano → form precompilato
// Elenco = mergeVendorList(vendors, health, expenses)
// ───────────────────────────────────────────────────────────────────────────

class VendorsPage extends ConsumerWidget {
  const VendorsPage({super.key});

  static const listKey = Key('fornitori-list');
  static const addKey = Key('fornitori-add');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canWrite = canWriteRecords(ref.watch(currentVolunteerProvider));
    final saved = ref.watch(vendorsStreamProvider).maybeWhen(
          data: (items) => items,
          orElse: () => const <Vendor>[],
        );
    final health = ref.watch(healthAllProvider).maybeWhen(
          data: (items) => items,
          orElse: () => const <HealthRecord>[],
        );
    final expenses = ref.watch(expensesAllProvider).maybeWhen(
          data: (items) => items,
          orElse: () => const <Expense>[],
        );
    final vendors = mergeVendorList(
      vendors: saved,
      health: health,
      expenses: expenses,
    );

    return AppScaffold(
      title: 'Veterinari e fornitori',
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
                onTap: () => context.push(AppRoutes.fornitoreNuovo),
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
      body: vendors.isEmpty
          ? const Center(
              child: EmptyState(
                icon: IconBadge(AppIcons.fornitori),
                message: 'Nessun veterinario o fornitore ancora indicato.',
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
                      for (final item in vendors)
                        OptionRow(
                          icon: IconBadge(
                            item.tipo == VendorTipo.veterinario ||
                                    item.tipo == VendorTipo.clinica
                                ? AppIcons.visita
                                : AppIcons.fornitori,
                            size: IconBadge.inMenu,
                          ),
                          title: item.nome,
                          subtitle: vendorTipoLabel(item.tipo),
                          minHeight: AppDim.menuRowH,
                          titleSize: AppText.formCard,
                          onTap: () {
                            final savedItem = item.saved;
                            if (savedItem != null) {
                              context.push(AppRoutes.fornitore(savedItem.id));
                              return;
                            }
                            context.push(
                              AppRoutes.fornitoreOrfano(
                                nome: item.nome,
                                tipo: item.tipo.wire,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
