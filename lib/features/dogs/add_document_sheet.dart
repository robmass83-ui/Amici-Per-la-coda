import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
import '../../data/models/app_document.dart';
import '../../data/models/enums.dart';
import '../auth/auth_providers.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import 'dogs_providers.dart';
import 'tab_labels.dart';

// ── CONTRATTO DI LAYOUT · Carica documento ─────────────────────────────────
// Padding 12 + tastiera o barra di sistema
// maniglia · titolo · Wrap chip tipo · AppTextField nome · Salva
// ───────────────────────────────────────────────────────────────────────────

class AddDocumentSheet extends ConsumerStatefulWidget {
  const AddDocumentSheet({super.key, required this.dogId});

  static const nomeKey = Key('dog-document-nome');
  static const saveKey = Key('dog-document-save');

  final String dogId;

  static Future<void> open(BuildContext context, {required String dogId}) {
    return AppSheet.present<void>(
      context: context,
      builder: (context) => AddDocumentSheet(dogId: dogId),
    );
  }

  @override
  ConsumerState<AddDocumentSheet> createState() => _AddDocumentSheetState();
}

class _AddDocumentSheetState extends ConsumerState<AddDocumentSheet> {
  final _nome = TextEditingController();
  DocumentTipo _tipo = DocumentTipo.altro;
  String? _error;

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final nome = _nome.text.trim();
    if (nome.isEmpty) {
      setState(() => _error = 'Inserisci il nome del documento.');
      return;
    }
    final repo = ref.read(documentRepositoryProvider);
    if (repo == null) {
      setState(() => _error = 'Archivio documenti non disponibile.');
      return;
    }
    final userId = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    final now = ref.read(dogListNowProvider);
    await repo.save(
      AppDocument(
        id: 'd_${DateTime.now().microsecondsSinceEpoch}',
        dogId: widget.dogId,
        adoptionId: null,
        tipo: _tipo,
        nome: nome,
        mime: 'application/pdf',
        pdfB64: null,
        firmaAffidatarioB64: null,
        firmaReferenteB64: null,
        createdAt: now,
        createdBy: userId,
      ),
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppDim.pagePad,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: AppDim.gapXl * 2,
              height: AppDim.gapXs,
              decoration: BoxDecoration(
                color: AppColor.line,
                borderRadius: BorderRadius.circular(AppDim.radChip),
              ),
            ),
          ),
          const SizedBox(height: AppDim.gapM),
          const Text(
            'Carica documento',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: AppText.h2,
              fontWeight: FontWeight.w700,
              color: AppColor.ink,
              height: AppDim.lineH,
            ),
          ),
          const SizedBox(height: AppDim.gapM),
          Wrap(
            spacing: AppDim.gapS,
            runSpacing: AppDim.gapS,
            children: [
              for (final tipo in DocumentTipo.values)
                AppChip(
                  label: documentTipoLabel(tipo),
                  selected: _tipo == tipo,
                  onSelected: () => setState(() => _tipo = tipo),
                ),
            ],
          ),
          const SizedBox(height: AppDim.gapM),
          AppTextField(
            key: AddDocumentSheet.nomeKey,
            label: 'Nome',
            hint: 'Es. libretto sanitario',
            controller: _nome,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppDim.gapS),
            Text(
              _error!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: AppText.caption,
                color: AppColor.red,
                height: AppDim.lineH,
              ),
            ),
          ],
          const SizedBox(height: AppDim.gapM),
          AppButton(
            key: AddDocumentSheet.saveKey,
            label: 'Salva',
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
