import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/new_id.dart';
import '../../data/data_providers.dart';
import '../../data/documents/document_codec.dart';
import '../../data/documents/document_file_picker.dart';
import '../../data/models/document_template.dart';
import '../../data/models/enums.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../auth/auth_providers.dart';
import '../dogs/dogs_providers.dart';
import 'template_visibilita_picker.dart';

// ── CONTRATTO DI LAYOUT · Aggiungi modulo ──────────────────────────────────
// AppSheet titolo AGGIUNGI MODULO
// ├ AppFormField NOME *
// ├ AppFormField FILE PDF  tap → scegli PDF  valore = nome file
// ├ TemplateVisibilitaPicker
// └ AppButton Aggiungi
// ───────────────────────────────────────────────────────────────────────────

class AddModuloSheet extends ConsumerStatefulWidget {
  const AddModuloSheet({super.key});

  static const nomeKey = Key('add-modulo-nome');
  static const fileKey = Key('add-modulo-file');
  static const aggiungiKey = Key('add-modulo-salva');

  static Future<void> show(BuildContext context) {
    return AppSheet.present<void>(
      context: context,
      builder: (context) => const AddModuloSheet(),
    );
  }

  @override
  ConsumerState<AddModuloSheet> createState() => _AddModuloSheetState();
}

class _AddModuloSheetState extends ConsumerState<AddModuloSheet> {
  final _nome = TextEditingController();
  PickedDocumentFile? _file;
  var _visibilita = TemplateVisibilita.entrambi;
  String? _nomeError;
  String? _fileError;
  bool _busy = false;

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: 'Aggiungi modulo',
      children: [
        AppFormField(
          key: AddModuloSheet.nomeKey,
          label: 'Nome *',
          controller: _nome,
          hint: 'Es. Liberatoria uscita',
          errorText: _nomeError,
        ),
        const SizedBox(height: AppDim.formRowGap),
        AppFormField(
          key: AddModuloSheet.fileKey,
          label: 'File PDF *',
          hint: _file == null || _file!.name.isEmpty
              ? 'Scegli PDF'
              : _file!.name,
          errorText: _fileError,
          onTap: () => unawaited(_pickPdf()),
        ),
        const SizedBox(height: AppDim.formRowGap),
        TemplateVisibilitaPicker(
          value: _visibilita,
          onChanged: (value) => setState(() => _visibilita = value),
        ),
        const SizedBox(height: AppDim.gapL),
        AppButton(
          key: AddModuloSheet.aggiungiKey,
          label: 'Aggiungi',
          onPressed: _busy ? null : () => unawaited(_save()),
        ),
      ],
    );
  }

  Future<void> _pickPdf() async {
    final picked = await ref.read(documentFilePickerProvider).pickPdf();
    if (picked == null || !mounted) {
      return;
    }
    final error = templatePdfError(picked.bytes.lengthInBytes);
    setState(() {
      _file = error == null ? picked : null;
      _fileError = error;
    });
  }

  Future<void> _save() async {
    final nome = _nome.text.trim();
    var ok = true;
    setState(() {
      _nomeError = nome.isEmpty ? 'Indica il nome del modulo.' : null;
      _fileError = _file == null ? 'Scegli un file PDF.' : null;
      ok = _nomeError == null && _fileError == null;
    });
    if (!ok) {
      return;
    }
    final repo = ref.read(templateRepositoryProvider);
    if (repo == null) {
      AppToast.show(context, 'Archivio moduli non disponibile.');
      return;
    }
    setState(() => _busy = true);
    final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    final now = ref.read(dogListNowProvider);
    final picked = _file!;
    await repo.save(
      DocumentTemplate(
        id: newEntityId('modulo', now),
        nome: nome,
        descrizione: '',
        fileName: picked.name.isEmpty ? 'modulo.pdf' : picked.name,
        mime: picked.mime.isEmpty ? 'application/pdf' : picked.mime,
        pdfB64: base64Encode(picked.bytes),
        versione: 1,
        aggiornatoIl: now,
        aggiornatoDa: uid,
        visibilita: _visibilita,
      ),
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    AppToast.show(context, 'Modulo aggiunto.');
  }
}

String? templatePdfError(int byteLength) {
  if (byteLength <= 0) {
    return 'Scegli un file PDF.';
  }
  if (byteLength > documentInlineMaxBytes) {
    return 'Il PDF deve pesare meno di 700 KB.';
  }
  return null;
}
