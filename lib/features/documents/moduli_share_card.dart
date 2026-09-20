import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/adoption.dart';
import '../../data/models/document_template.dart';
import '../../data/models/dog.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../dogs/dogs_providers.dart';
import 'template_share.dart';

// ── CONTRATTO DI LAYOUT · Card moduli da condividere ────────────────────────
// AppCard
// ├ SectionTitle  Moduli  icona AppIcons.modulo
// └ OptionRow per ciascun template  titolo 12sp  subtitle Invia · versione
// ───────────────────────────────────────────────────────────────────────────

class ModuliShareCard extends ConsumerWidget {
  const ModuliShareCard({
    super.key,
    required this.templates,
    this.dog,
  });

  final List<DocumentTemplate> templates;
  final Dog? dog;

  static Key rowKey(String id) => Key('modulo-share-$id');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adoptions = dog == null
        ? const <Adoption>[]
        : ref
            .watch(adoptionsStreamProvider)
            .maybeWhen(
              data: (items) => items,
              orElse: () => const <Adoption>[],
            );
    final adoption = dog == null ? null : adoptionForDog(adoptions, dog!.id);
    return AppCard(
      child: Column(
        children: [
          const SectionTitle(
            title: 'Moduli',
            icon: IconBadge(AppIcons.modulo, size: IconBadge.inTitle),
          ),
          const SizedBox(height: AppDim.gapS),
          for (var i = 0; i < templates.length; i++) ...[
            if (i > 0) const SizedBox(height: AppDim.gapXs),
            OptionRow(
              key: rowKey(templates[i].id),
              icon: const IconBadge(AppIcons.condividi, size: IconBadge.inMenu),
              title: templates[i].nome,
              subtitle: 'Versione ${templates[i].versione} · Invia',
              onTap: () => unawaited(
                shareDocumentTemplate(
                  context: context,
                  ref: ref,
                  template: templates[i],
                  adoption: adoption,
                  dog: dog,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
