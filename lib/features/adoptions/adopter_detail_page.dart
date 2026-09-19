import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format_it.dart';
import '../../data/models/adoption.dart';
import '../../data/models/dog.dart';
import '../../router.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../affido/affido_providers.dart';
import '../dogs/dog_labels.dart';
import '../dogs/dogs_providers.dart';
import '../dogs/edit_permissions.dart';

// ── CONTRATTO DI LAYOUT · Profilo famiglia ────────────────────────────────
// AppScaffold  titolo=nomeCompleto  onEdit se canWrite
// ListView padding=12
// ├ AppCard  KeyValueRow ×9  gap 9
// │    nome, cognome, telefono, email, città, indirizzo,
// │    documento, data nascita, note. vuoto → —
// └ se cani: SizedBox 9 + SectionTitle + AppCard OptionRow
// ───────────────────────────────────────────────────────────────────────────

class AdopterDetailPage extends ConsumerWidget {
  const AdopterDetailPage({super.key, required this.adopterId});

  final String adopterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canWrite = canWriteRecords(ref.watch(currentVolunteerProvider));
    final adopter = ref.watch(adoptersStreamProvider).maybeWhen(
          data: (items) {
            for (final item in items) {
              if (item.id == adopterId) {
                return item;
              }
            }
            return null;
          },
          orElse: () => null,
        );
    final adoptions = ref.watch(adoptionsStreamProvider).maybeWhen(
          data: (items) => items,
          orElse: () => const <Adoption>[],
        );
    final dogs = ref.watch(dogsStreamProvider).maybeWhen(
          data: (items) => items,
          orElse: () => const <Dog>[],
        );

    final linked = <Dog>[];
    if (adopter != null) {
      for (final adoptionId in adopter.adozioniIds) {
        Adoption? link;
        for (final item in adoptions) {
          if (item.id == adoptionId) {
            link = item;
            break;
          }
        }
        if (link == null) {
          continue;
        }
        for (final dog in dogs) {
          if (dog.id == link.dogId) {
            linked.add(dog);
            break;
          }
        }
      }
    }

    final documento = adopter == null
        ? '—'
        : dashIfEmpty('${adopter.docTipo} ${adopter.docNumero}'.trim());

    return AppScaffold(
      title: adopter?.nomeCompleto ?? 'Famiglia',
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.adottanti);
        }
      },
      onEdit: canWrite && adopter != null
          ? () => context.push(AppRoutes.adottanteModifica(adopterId))
          : null,
      body: adopter == null
          ? const Center(
              child: EmptyState(
                icon: IconBadge(AppIcons.famiglie),
                message: 'Famiglia non trovata.',
                compact: true,
              ),
            )
          : ListView(
              padding: AppDim.pagePad,
              children: [
                AppCard(
                  child: Column(
                    children: [
                      KeyValueRow(label: 'Nome', value: dashIfEmpty(adopter.nome)),
                      const SizedBox(height: AppDim.gapM),
                      KeyValueRow(
                        label: 'Cognome',
                        value: dashIfEmpty(adopter.cognome),
                      ),
                      const SizedBox(height: AppDim.gapM),
                      KeyValueRow(
                        label: 'Telefono',
                        value: dashIfEmpty(adopter.telefono),
                      ),
                      const SizedBox(height: AppDim.gapM),
                      KeyValueRow(
                        label: 'Email',
                        value: dashIfEmpty(adopter.email),
                      ),
                      const SizedBox(height: AppDim.gapM),
                      KeyValueRow(
                        label: 'Città',
                        value: dashIfEmpty(adopter.citta),
                      ),
                      const SizedBox(height: AppDim.gapM),
                      KeyValueRow(
                        label: 'Indirizzo',
                        value: dashIfEmpty(adopter.indirizzo),
                      ),
                      const SizedBox(height: AppDim.gapM),
                      KeyValueRow(label: 'Documento', value: documento),
                      const SizedBox(height: AppDim.gapM),
                      KeyValueRow(
                        label: 'Data di nascita',
                        value: adopter.dataNascita == null
                            ? '—'
                            : formatItalianDate(adopter.dataNascita!),
                      ),
                      const SizedBox(height: AppDim.gapM),
                      KeyValueRow(
                        label: 'Note',
                        value: dashIfEmpty(adopter.note),
                      ),
                    ],
                  ),
                ),
                if (linked.isNotEmpty) ...[
                  const SizedBox(height: AppDim.gapM),
                  const SectionTitle(title: 'Cani collegati'),
                  const SizedBox(height: AppDim.gapS),
                  AppCard(
                    child: Column(
                      children: [
                        for (final dog in linked)
                          OptionRow(
                            icon: const IconBadge(
                              AppIcons.razza,
                              size: IconBadge.inMenu,
                            ),
                            title: dogDisplayName(dog.nome),
                            minHeight: AppDim.menuRowH,
                            titleSize: AppText.formCard,
                            onTap: () => AppRoutes.openDog(context, dog.id),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
