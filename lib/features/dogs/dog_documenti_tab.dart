import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format_it.dart';
import '../../data/models/app_document.dart';
import '../../data/models/dog.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import 'add_document_sheet.dart';
import 'dogs_providers.dart';
import 'tab_labels.dart';

// ── CONTRATTO DI LAYOUT · Tab Documenti ────────────────────────────────────
// Padding 12/9  Column stretch
// ├ AppCard  Documenti del cane
// │  riga: IconBadge 27 · Expanded nome+meta maxLines=1 · chevron 18
// ├ SizedBox 9
// ├ AppCard  Modulistica  OptionRow ×3
// ├ SizedBox 9
// └ AppButton ghost  Carica documento
// ───────────────────────────────────────────────────────────────────────────

class DogDocumentiTab extends ConsumerWidget {
  const DogDocumentiTab({super.key, required this.dog});

  static const addKey = Key('dog-add-document');

  final Dog dog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  _DocRow(document: sorted[i]),
                ],
            ],
          ),
        ),
        const SizedBox(height: AppDim.gapM),
        AppCard(
          child: Column(
            children: [
              const SectionTitle(
                title: 'Modulistica affido',
                icon: IconBadge(AppIcons.firma, size: IconBadge.inTitle),
              ),
              OptionRow(
                icon: const IconBadge(AppIcons.modulo, size: IconBadge.inMenu),
                title: 'Modulo di preaffido',
                subtitle: 'Genera precompilato',
                onTap: () => _soon(context, 'Genera modulo'),
              ),
              OptionRow(
                icon: const IconBadge(AppIcons.modulo, size: IconBadge.inMenu),
                title: 'Contratto di adozione',
                subtitle: 'Genera precompilato',
                onTap: () => _soon(context, 'Genera contratto'),
              ),
              OptionRow(
                icon: const IconBadge(AppIcons.microchip, size: IconBadge.inMenu),
                title: 'Passaggio proprietà microchip',
                subtitle: 'Modello ASL',
                onTap: () => _soon(context, 'Genera passaggio microchip'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDim.gapM),
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

void _soon(BuildContext context, String label) {
  AppToast.show(context, '$label: disponibile negli step successivi.');
}

class _DocRow extends StatelessWidget {
  const _DocRow({required this.document});

  final AppDocument document;

  @override
  Widget build(BuildContext context) {
    final mime = document.mime.isEmpty ? 'file' : document.mime;
    final meta = '$mime · ${formatItalianDate(document.createdAt)}';
    return Row(
      children: [
        IconBadge(AppIcons.perDocumento(document.tipo.wire)),
        const SizedBox(width: AppDim.gapS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                document.nome.isEmpty
                    ? documentTipoLabel(document.tipo)
                    : document.nome,
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
        const Icon(
          Icons.chevron_right_rounded,
          size: AppDim.iconNav,
          color: AppColor.faint,
        ),
      ],
    );
  }
}
