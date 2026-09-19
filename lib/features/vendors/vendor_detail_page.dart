import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../affido/affido_providers.dart';
import '../dogs/dog_labels.dart';
import '../dogs/edit_permissions.dart';
import 'vendor_logic.dart';
import 'vendor_providers.dart';

// ── CONTRATTO DI LAYOUT · Scheda fornitore ────────────────────────────────
// AppScaffold  titolo=nome  onEdit se canWrite
// ListView padding=12
// └ AppCard padding=10
//    KeyValueRow ×6  (tipo, telefono, email, indirizzo, convenzionato, note)
//    vuoto → —
//    gap fra righe = 9
// ───────────────────────────────────────────────────────────────────────────

class VendorDetailPage extends ConsumerWidget {
  const VendorDetailPage({super.key, required this.vendorId});

  final String vendorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canWrite = canWriteRecords(ref.watch(currentVolunteerProvider));
    final vendor = ref.watch(vendorsStreamProvider).maybeWhen(
          data: (items) {
            for (final item in items) {
              if (item.id == vendorId) {
                return item;
              }
            }
            return null;
          },
          orElse: () => null,
        );

    return AppScaffold(
      title: vendor?.nome ?? 'Fornitore',
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.fornitori);
        }
      },
      onEdit: canWrite && vendor != null
          ? () => context.push(AppRoutes.fornitoreModifica(vendorId))
          : null,
      body: vendor == null
          ? const Center(
              child: EmptyState(
                icon: IconBadge(AppIcons.fornitori),
                message: 'Fornitore non trovato.',
                compact: true,
              ),
            )
          : ListView(
              padding: AppDim.pagePad,
              children: [
                AppCard(
                  child: Column(
                    children: [
                      KeyValueRow(
                        label: 'Tipo',
                        value: vendorTipoLabel(vendor.tipo),
                      ),
                      const SizedBox(height: AppDim.gapM),
                      KeyValueRow(
                        label: 'Telefono',
                        value: dashIfEmpty(vendor.telefono),
                      ),
                      const SizedBox(height: AppDim.gapM),
                      KeyValueRow(
                        label: 'Email',
                        value: dashIfEmpty(vendor.email),
                      ),
                      const SizedBox(height: AppDim.gapM),
                      KeyValueRow(
                        label: 'Indirizzo',
                        value: dashIfEmpty(vendor.indirizzo),
                      ),
                      const SizedBox(height: AppDim.gapM),
                      KeyValueRow(
                        label: 'Convenzionato',
                        value: yesNo(vendor.convenzionato),
                      ),
                      const SizedBox(height: AppDim.gapM),
                      KeyValueRow(
                        label: 'Note',
                        value: dashIfEmpty(vendor.note),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
