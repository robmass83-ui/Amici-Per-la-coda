import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format_it.dart';
import '../../data/models/app_document.dart';
import '../../data/models/document_template.dart';
import '../../data/models/dog.dart';
import '../affido/affido_providers.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../documents/document_actions.dart';
import '../documents/moduli_share_card.dart';
import '../documents/template_share.dart';
import 'add_document_sheet.dart';
import 'dogs_providers.dart';
import 'edit_permissions.dart';
import 'record_actions.dart';

// ── CONTRATTO DI LAYOUT · Tab Documenti ────────────────────────────────────
// Padding 12/9  Column stretch
// ├ AppCard  Documenti del cane
// │  riga: IconBadge 27 · Expanded nome+meta maxLines=1 · ⋮ 40×40
// │  tap riga → apre il file; ⋮ → Apri / Condividi / Rinomina / Elimina
// ├ SizedBox 9
// ├ se moduli visibili in scheda: AppCard Moduli  OptionRow Invia
// ├ SizedBox 9
// └ AppButton ghost  Carica documento
// ───────────────────────────────────────────────────────────────────────────

class DogDocumentiTab extends ConsumerWidget {
  const DogDocumentiTab({super.key, required this.dog});

  static const addKey = Key('dog-add-document');

  final Dog dog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canWrite = canWriteRecords(ref.watch(currentVolunteerProvider));
    final docs = ref
        .watch(documentsByDogProvider(dog.id))
        .maybeWhen(
          data: (items) => items,
          orElse: () => const <AppDocument>[],
        );
    final sorted = List<AppDocument>.of(docs)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle(
                title: 'Documenti del cane',
                icon: IconBadge(AppIcons.documenti, size: IconBadge.inTitle),
              ),
              const SizedBox(height: AppDim.gapM),
              if (sorted.isEmpty)
                const Text(
                  'Nessun documento.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: AppText.caption,
                    color: AppColor.muted,
                    height: AppDim.lineH,
                  ),
                )
              else
                for (var i = 0; i < sorted.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppDim.gapS),
                  _DocRow(
                    document: sorted[i],
                    canWrite: canWrite,
                    onOpen: () => unawaited(
                      openAppDocument(context, ref, sorted[i]),
                    ),
                    onMenu: () => unawaited(
                      showDocumentActions(
                        context,
                        ref,
                        sorted[i],
                        canWrite: canWrite,
                      ),
                    ),
                  ),
                ],
            ],
          ),
        ),
        _DogModuli(dog: dog),
        const SizedBox(height: AppDim.gapM),
        if (canWrite)
          AppButton(
            key: addKey,
            label: 'Carica documento',
            variant: AppButtonVariant.ghost,
            onPressed: () => AddDocumentSheet.open(context, dogId: dog.id),
          ),
      ],
    );
  }
}

class _DogModuli extends ConsumerWidget {
  const _DogModuli({required this.dog});

  final Dog dog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = templatesInScheda(
      ref.watch(templatesStreamProvider).maybeWhen(
            data: (items) => items,
            orElse: () => const <DocumentTemplate>[],
          ),
    );
    if (templates.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppDim.gapM),
        ModuliShareCard(templates: templates, dog: dog),
      ],
    );
  }
}

class _DocRow extends StatelessWidget {
  const _DocRow({
    required this.document,
    required this.canWrite,
    required this.onOpen,
    required this.onMenu,
  });

  final AppDocument document;
  final bool canWrite;
  final VoidCallback onOpen;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final mime = document.mime.isEmpty ? 'file' : document.mime;
    final meta = '$mime · ${formatItalianDate(document.createdAt)}';
    final nome = documentDisplayName(document);
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onOpen,
            onLongPress: canWrite ? onMenu : null,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                IconBadge(AppIcons.perDocumento(document.tipo.wire)),
                const SizedBox(width: AppDim.gapS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: AppText.value,
                          fontWeight: FontWeight.w600,
                          color: AppColor.ink,
                          height: AppDim.lineH,
                        ),
                      ),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: AppText.caption,
                          color: AppColor.muted,
                          height: AppDim.lineH,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (canWrite)
          GestureDetector(
            key: recordMenuKey(document.id),
            behavior: HitTestBehavior.opaque,
            onTap: onMenu,
            child: const SizedBox(
              width: AppDim.minTouch,
              height: AppDim.minTouch,
              child: Center(
                child: IconBadge(AppIcons.menu, size: IconBadge.inTitle),
              ),
            ),
          ),
      ],
    );
  }
}
