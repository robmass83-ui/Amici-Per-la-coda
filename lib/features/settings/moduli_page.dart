import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format_it.dart';
import '../../data/models/app_document.dart';
import '../../data/models/document_template.dart';
import '../../data/models/dog.dart';
import '../../data/models/enums.dart';
import '../../router.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../affido/affido_providers.dart';
import '../documents/document_actions.dart';
import '../documents/documenti_groups.dart';
import '../dogs/dogs_providers.dart';
import '../dogs/edit_permissions.dart';
import '../dogs/tab_labels.dart';
import 'add_modulo_sheet.dart';
import 'modulo_detail_sheet.dart';
import 'modulo_labels.dart';

// ── CONTRATTO DI LAYOUT · Documenti e modulistica ─────────────────────────
// AppScaffold  titolo Documenti e modulistica  back
// ListView padding=12
// ├ SectionTitle  Moduli  icona AppIcons.modulo
// ├ SizedBox 9
// ├ AppCard  lista OptionRow  titolo 12sp  subtitle versione · data · visibilità
// │    stato vuoto: EmptyState «Nessun modulo caricato.»
// ├ se presidente: SizedBox 12 + AppButton Aggiungi modulo
// ├ SizedBox 12
// ├ SectionTitle  Documenti caricati  icona AppIcons.documenti
// ├ SizedBox 9
// └ AppCard  gruppi per cane (nome 10sp muted) + OptionRow file
//      tap → Apri / Condividi / Rinomina / Elimina
//      vuoto: EmptyState «Nessun documento caricato.»
// ───────────────────────────────────────────────────────────────────────────

class ModuliPage extends ConsumerWidget {
  const ModuliPage({super.key});

  static const listKey = Key('moduli-list');
  static const addKey = Key('moduli-aggiungi');
  static const documentiKey = Key('documenti-caricati');
  static const replacePreaffidoKey = Key('settings-replace-preaffido');
  static const replaceAdozioneKey = Key('settings-replace-adozione');

  static Key rowKey(String id) => Key('moduli-row-$id');
  static Key dogGroupKey(String dogId) => Key('documenti-cane-$dogId');
  static Key documentRowKey(String id) => Key('documenti-file-$id');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref
        .watch(templatesStreamProvider)
        .maybeWhen(
          data: (items) => items,
          orElse: () => const <DocumentTemplate>[],
        );
    final sorted = List<DocumentTemplate>.of(templates)
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    final volunteer = ref.watch(currentVolunteerProvider);
    final isPresidente = volunteer?.ruolo == VolunteerRuolo.presidente;
    final canWrite = canWriteRecords(volunteer);
    final dogs = ref.watch(dogsStreamProvider).maybeWhen(
          data: (items) => items,
          orElse: () => const <Dog>[],
        );
    final docs = ref.watch(documentsStreamProvider).maybeWhen(
          data: (items) => items,
          orElse: () => const <AppDocument>[],
        );
    final groups = groupDocumentsByDog(documents: docs, dogs: dogs);

    return AppScaffold(
      title: 'Documenti e modulistica',
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.altro);
        }
      },
      body: ListView(
        key: listKey,
        padding: AppDim.pagePad,
        children: [
          const SectionTitle(
            title: 'Moduli',
            icon: IconBadge(AppIcons.modulo, size: IconBadge.inTitle),
          ),
          const SizedBox(height: AppDim.gapM),
          AppCard(
            child: sorted.isEmpty
                ? const EmptyState(
                    icon: IconBadge(AppIcons.modulo),
                    message: 'Nessun modulo caricato.',
                    compact: true,
                  )
                : Column(
                    children: [
                      for (var i = 0; i < sorted.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppDim.gapXs),
                        OptionRow(
                          key: rowKey(sorted[i].id),
                          icon: const IconBadge(
                            AppIcons.modulo,
                            size: IconBadge.inMenu,
                          ),
                          title: sorted[i].nome,
                          subtitle:
                              'Versione ${sorted[i].versione} · ${formatItalianDate(sorted[i].aggiornatoIl)} · ${templateVisibilitaDescrizione(sorted[i].visibilita)}',
                          onTap: () => unawaited(
                            ModuloDetailSheet.show(
                              context,
                              template: sorted[i],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
          if (isPresidente) ...[
            const SizedBox(height: AppDim.gapL),
            AppButton(
              key: addKey,
              label: 'Aggiungi modulo',
              onPressed: () => unawaited(AddModuloSheet.show(context)),
            ),
          ],
          const SizedBox(height: AppDim.gapL),
          const SectionTitle(
            title: 'Documenti caricati',
            icon: IconBadge(AppIcons.documenti, size: IconBadge.inTitle),
          ),
          const SizedBox(height: AppDim.gapM),
          AppCard(
            key: documentiKey,
            child: groups.isEmpty
                ? const EmptyState(
                    icon: IconBadge(AppIcons.allegato),
                    message: 'Nessun documento caricato.',
                    compact: true,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var g = 0; g < groups.length; g++) ...[
                        if (g > 0) ...[
                          const SizedBox(height: AppDim.gapS),
                          const ColoredBox(
                            color: AppColor.line2,
                            child: SizedBox(
                              height: AppDim.gapHair,
                              width: double.infinity,
                            ),
                          ),
                          const SizedBox(height: AppDim.gapS),
                        ],
                        Text(
                          groups[g].dogName,
                          key: groups[g].dogId == null
                              ? null
                              : dogGroupKey(groups[g].dogId!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: AppText.caption,
                            fontWeight: FontWeight.w700,
                            color: AppColor.muted,
                            height: AppDim.lineH,
                          ),
                        ),
                        const SizedBox(height: AppDim.gapXs),
                        for (var i = 0; i < groups[g].documents.length; i++) ...[
                          if (i > 0) const SizedBox(height: AppDim.gapXs),
                          OptionRow(
                            key: documentRowKey(groups[g].documents[i].id),
                            icon: IconBadge(
                              AppIcons.perDocumento(
                                groups[g].documents[i].tipo.wire,
                              ),
                              size: IconBadge.inMenu,
                            ),
                            title: documentDisplayName(groups[g].documents[i]),
                            subtitle:
                                '${documentTipoLabel(groups[g].documents[i].tipo)} · ${formatItalianDate(groups[g].documents[i].caricatoIl)}',
                            onTap: () => unawaited(
                              showDocumentActions(
                                context,
                                ref,
                                groups[g].documents[i],
                                canWrite: canWrite,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
