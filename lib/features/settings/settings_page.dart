import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format_it.dart';
import '../../data/data_providers.dart';
import '../../data/documents/template_assets.dart';
import '../../data/models/document_template.dart';
import '../../data/models/enums.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../auth/auth_providers.dart';
import '../dogs/dogs_providers.dart';
import '../affido/affido_providers.dart';

// ── CONTRATTO DI LAYOUT · Impostazioni ────────────────────────────────────
// AppScaffold  titolo Impostazioni  back
// ListView  padding=12
// └ AppCard
//    ├ SectionTitle  Moduli  icona AppIcons.modulo
//    └ OptionRow ×2  titolo 12sp  subtitle «Versione n · dd/MM/yyyy»
//         presidente: tap = Sostituisci file
// ───────────────────────────────────────────────────────────────────────────

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const moduliKey = Key('settings-moduli');
  static const replacePreaffidoKey = Key('settings-replace-preaffido');
  static const replaceAdozioneKey = Key('settings-replace-adozione');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref
        .watch(templatesStreamProvider)
        .maybeWhen(
          data: (items) => items,
          orElse: () => const <DocumentTemplate>[],
        );
    final sorted = List<DocumentTemplate>.of(templates)
      ..sort((a, b) => a.id.compareTo(b.id));
    final volunteer = ref.watch(currentVolunteerProvider);
    final isPresidente = volunteer?.ruolo == VolunteerRuolo.presidente;

    return AppScaffold(
      title: 'Impostazioni',
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      },
      body: ListView(
        padding: AppDim.pagePad,
        children: [
          AppCard(
            key: moduliKey,
            child: Column(
              children: [
                const SectionTitle(
                  title: 'Moduli',
                  icon: IconBadge(AppIcons.modulo, size: IconBadge.inTitle),
                ),
                const SizedBox(height: AppDim.gapM),
                if (sorted.isEmpty)
                  const EmptyState(
                    icon: IconBadge(AppIcons.modulo),
                    message: 'Nessun modulo caricato.',
                    compact: true,
                  )
                else
                  for (final template in sorted)
                    OptionRow(
                      key: template.id == templatePreaffidoId
                          ? replacePreaffidoKey
                          : replaceAdozioneKey,
                      icon: const IconBadge(
                        AppIcons.modulo,
                        size: IconBadge.inMenu,
                      ),
                      title: template.nome,
                      subtitle:
                          'Versione ${template.versione} · ${formatItalianDate(template.aggiornatoIl)}${isPresidente ? ' · Sostituisci file' : ''}',
                      onTap: isPresidente
                          ? () => unawaited(
                                _replaceTemplate(context, ref, template),
                              )
                          : () {},
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _replaceTemplate(
  BuildContext context,
  WidgetRef ref,
  DocumentTemplate template,
) async {
  final picked = await ref.read(documentFilePickerProvider).pickPdf();
  if (picked == null) {
    return;
  }
  final repo = ref.read(templateRepositoryProvider);
  if (repo == null) {
    if (context.mounted) {
      AppToast.show(context, 'Archivio moduli non disponibile.');
    }
    return;
  }
  final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
  final now = ref.read(dogListNowProvider);
  await repo.save(
    template.copyWith(
      pdfB64: base64Encode(picked.bytes),
      fileName: picked.name.isEmpty ? template.fileName : picked.name,
      versione: template.versione + 1,
      aggiornatoIl: now,
      aggiornatoDa: uid,
    ),
  );
  if (context.mounted) {
    AppToast.show(context, 'Modulo aggiornato alla versione ${template.versione + 1}.');
  }
}
