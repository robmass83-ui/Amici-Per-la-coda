import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format_it.dart';
import '../../data/data_providers.dart';
import '../../data/documents/template_assets.dart';
import '../../data/models/document_template.dart';
import '../../data/models/enums.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../affido/affido_providers.dart';
import '../auth/auth_providers.dart';
import '../documents/template_share.dart';
import '../dogs/dogs_providers.dart';
import '../dogs/record_actions.dart';
import 'add_modulo_sheet.dart';
import 'modulo_labels.dart';
import 'template_visibilita_picker.dart';

// ── CONTRATTO DI LAYOUT · Dettaglio modulo ─────────────────────────────────
// AppSheet titolo = nome modulo
// ├ Text versione · data  10sp muted
// ├ TemplateVisibilitaPicker  (solo presidente)  oppure testo visibilità
// ├ AppButton Condividi
// ├ se presidente: AppButton ghost Sostituisci file
// └ se presidente: AppButton ghost Rimuovi  titleColor red
// ───────────────────────────────────────────────────────────────────────────

class ModuloDetailSheet extends ConsumerStatefulWidget {
  const ModuloDetailSheet({super.key, required this.template});

  final DocumentTemplate template;

  static const condividiKey = Key('modulo-condividi');
  static const rimuoviKey = Key('modulo-rimuovi');

  static Key replaceKeyOf(String id) {
    if (id == templatePreaffidoId) {
      return const Key('settings-replace-preaffido');
    }
    if (id == templateAdozioneId) {
      return const Key('settings-replace-adozione');
    }
    return Key('modulo-replace-$id');
  }

  static Future<void> show(
    BuildContext context, {
    required DocumentTemplate template,
  }) {
    return AppSheet.present<void>(
      context: context,
      builder: (context) => ModuloDetailSheet(template: template),
    );
  }

  @override
  ConsumerState<ModuloDetailSheet> createState() => _ModuloDetailSheetState();
}

class _ModuloDetailSheetState extends ConsumerState<ModuloDetailSheet> {
  late TemplateVisibilita _visibilita;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _visibilita = widget.template.visibilita;
  }

  @override
  Widget build(BuildContext context) {
    final volunteer = ref.watch(currentVolunteerProvider);
    final isPresidente = volunteer?.ruolo == VolunteerRuolo.presidente;
    return AppSheet(
      title: widget.template.nome,
      children: [
        Text(
          'Versione ${widget.template.versione} · ${formatItalianDate(widget.template.aggiornatoIl)}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: AppText.caption,
            color: AppColor.muted,
            height: AppDim.lineH,
          ),
        ),
        const SizedBox(height: AppDim.formRowGap),
        if (isPresidente)
          TemplateVisibilitaPicker(
            value: _visibilita,
            onChanged: (value) => unawaited(_setVisibilita(value)),
          )
        else
          Text(
            templateVisibilitaDescrizione(_visibilita),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: AppText.label,
              color: AppColor.muted,
              height: AppDim.lineH,
            ),
          ),
        const SizedBox(height: AppDim.gapL),
        AppButton(
          key: ModuloDetailSheet.condividiKey,
          label: 'Condividi',
          onPressed: _busy
              ? null
              : () => unawaited(
                    shareDocumentTemplate(
                      context: context,
                      ref: ref,
                      template: widget.template,
                    ),
                  ),
        ),
        if (isPresidente) ...[
          const SizedBox(height: AppDim.gapM),
          AppButton(
            key: ModuloDetailSheet.replaceKeyOf(widget.template.id),
            label: 'Sostituisci file',
            variant: AppButtonVariant.ghost,
            onPressed: _busy ? null : () => unawaited(_replace()),
          ),
          const SizedBox(height: AppDim.gapM),
          AppButton(
            key: ModuloDetailSheet.rimuoviKey,
            label: 'Rimuovi',
            variant: AppButtonVariant.ghost,
            onPressed: _busy ? null : () => unawaited(_remove()),
          ),
        ],
      ],
    );
  }

  Future<void> _setVisibilita(TemplateVisibilita value) async {
    setState(() => _visibilita = value);
    final repo = ref.read(templateRepositoryProvider);
    if (repo == null) {
      return;
    }
    final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    final now = ref.read(dogListNowProvider);
    await repo.save(
      widget.template.copyWith(
        visibilita: value,
        aggiornatoIl: now,
        aggiornatoDa: uid,
      ),
    );
  }

  Future<void> _replace() async {
    final picked = await ref.read(documentFilePickerProvider).pickPdf();
    if (picked == null) {
      return;
    }
    final error = templatePdfError(picked.bytes.lengthInBytes);
    if (error != null) {
      if (mounted) {
        AppToast.show(context, error);
      }
      return;
    }
    final repo = ref.read(templateRepositoryProvider);
    if (repo == null) {
      if (mounted) {
        AppToast.show(context, 'Archivio moduli non disponibile.');
      }
      return;
    }
    setState(() => _busy = true);
    final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    final now = ref.read(dogListNowProvider);
    final next = widget.template.versione + 1;
    await repo.save(
      widget.template.copyWith(
        pdfB64: base64Encode(picked.bytes),
        fileName: picked.name.isEmpty ? widget.template.fileName : picked.name,
        versione: next,
        aggiornatoIl: now,
        aggiornatoDa: uid,
        visibilita: _visibilita,
      ),
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    AppToast.show(context, 'Modulo aggiornato alla versione $next.');
  }

  Future<void> _remove() async {
    final ok = await confirmAction(
      context: context,
      title: 'Rimuovi modulo',
      message: 'Eliminare «${widget.template.nome}» dai moduli caricati?',
      confirmLabel: 'Rimuovi',
    );
    if (!ok || !mounted) {
      return;
    }
    final repo = ref.read(templateRepositoryProvider);
    if (repo == null) {
      AppToast.show(context, 'Archivio moduli non disponibile.');
      return;
    }
    setState(() => _busy = true);
    await repo.delete(widget.template.id);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    AppToast.show(context, 'Modulo rimosso.');
  }
}
