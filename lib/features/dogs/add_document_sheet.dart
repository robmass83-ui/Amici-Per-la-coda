import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format_it.dart';
import '../../core/new_id.dart';
import '../../data/data_providers.dart';
import '../../data/documents/document_codec.dart';
import '../../data/documents/document_file_picker.dart';
import '../../data/documents/document_upload.dart';
import '../../data/models/app_document.dart';
import '../../data/models/enums.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../auth/auth_providers.dart';
import '../documents/document_actions.dart';
import 'dogs_providers.dart';
import 'tab_labels.dart';

// ── CONTRATTO DI LAYOUT · Documento (AppDialog) ────────────────────────────
// Header  AppIcons.documenti
// Body  gap 8
// ├ TIPO  Wrap AppChip (10 tipi)
// ├ NOME  opzionale
// ├ FILE  Row 50/50  «Scegli PDF» · «Scegli foto»
// └ dopo scelta: icona · nome file · dimensione · ×
// Footer  [🗑 se existing] Annulla | Salva  (Salva solo con file in creazione)
// ───────────────────────────────────────────────────────────────────────────

class AddDocumentSheet extends ConsumerStatefulWidget {
  const AddDocumentSheet({super.key, required this.dogId, this.existing});

  static const nomeKey = Key('dog-document-nome');
  static const saveKey = Key('dog-document-save');
  static const pdfKey = Key('dog-document-pdf');
  static const fotoKey = Key('dog-document-foto');
  static const fileRowKey = Key('dog-document-file');
  static const clearFileKey = Key('dog-document-clear');

  final String dogId;
  final AppDocument? existing;

  static Future<void> open(
    BuildContext context, {
    required String dogId,
    AppDocument? existing,
  }) {
    return AppDialog.show<void>(
      context: context,
      form: AddDocumentSheet(dogId: dogId, existing: existing),
    );
  }

  @override
  ConsumerState<AddDocumentSheet> createState() => _AddDocumentSheetState();
}

class _AddDocumentSheetState extends ConsumerState<AddDocumentSheet> {
  final _nome = TextEditingController();
  DocumentTipo _tipo = DocumentTipo.altro;
  String? _error;
  var _saving = false;
  List<PickedDocumentFile> _files = const [];
  late final String _initialNome;
  late final DocumentTipo _initialTipo;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _tipo = existing.tipo;
      _nome.text = existing.nome;
    }
    _initialNome = _nome.text;
    _initialTipo = _tipo;
    _nome.addListener(_mark);
  }

  @override
  void dispose() {
    _nome.removeListener(_mark);
    _nome.dispose();
    super.dispose();
  }

  void _mark() => setState(() {});

  bool get _isEdit => widget.existing != null;

  bool get _canSave {
    if (_isEdit) {
      return _nome.text.trim().isNotEmpty;
    }
    return _files.isNotEmpty;
  }

  bool get _isDirty {
    if (_isEdit) {
      return _nome.text != _initialNome || _tipo != _initialTipo;
    }
    return _files.isNotEmpty ||
        _nome.text != _initialNome ||
        _tipo != _initialTipo;
  }

  Future<void> _pick({required bool pdf}) async {
    setState(() => _error = null);
    try {
      final picker = ref.read(documentFilePickerProvider);
      final files = pdf
          ? [
              ?await picker.pickPdf(),
            ]
          : await picker.pickImages();
      if (files.isEmpty) {
        return;
      }
      setState(() => _files = files);
    } catch (_) {
      setState(() => _error = 'Selezione non riuscita. Riprova.');
    }
  }

  Future<void> _save() async {
    final repo = ref.read(documentRepositoryProvider);
    if (repo == null) {
      setState(() => _error = 'Archivio documenti non disponibile.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final existing = widget.existing;
      if (existing != null) {
        final nome = _nome.text.trim();
        if (nome.isEmpty) {
          setState(() => _error = 'Inserisci il nome del documento.');
          return;
        }
        await repo.save(existing.copyWith(nome: nome, tipo: _tipo));
      } else {
        if (_files.isEmpty) {
          setState(() => _error = 'Scegli un PDF o una foto prima di salvare.');
          return;
        }
        final userId = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
        final now = ref.read(dogListNowProvider);
        await savePickedDocument(
          repository: repo,
          files: _files,
          meta: AppDocument(
            id: newEntityId('doc', now),
            dogId: widget.dogId,
            adoptionId: null,
            adopterId: '',
            tipo: _tipo,
            nome: _nome.text.trim(),
            mime: '',
            chunkCount: 0,
            contenutoB64: null,
            caricatoIl: now,
            caricatoDa: userId,
          ),
        );
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
    } on DocumentTooLarge catch (error) {
      setState(() => _error = error.toString());
    } catch (_) {
      setState(() => _error = 'Caricamento non riuscito. Riprova.');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) {
      return;
    }
    await deleteAppDocument(context, ref, existing);
    if (!mounted) {
      return;
    }
    Navigator.of(context, rootNavigator: true).pop();
  }

  int get _fileBytes {
    var total = 0;
    for (final file in _files) {
      total += file.bytes.length;
    }
    return total;
  }

  String get _fileName {
    if (_files.isEmpty) {
      return '';
    }
    if (_files.length == 1) {
      return _files.first.name;
    }
    return '${_files.length} file';
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      icon: AppIcons.documenti,
      title: _isEdit ? 'Modifica documento' : 'Carica documento',
      canSave: _canSave,
      isDirty: _isDirty,
      saving: _saving,
      saveKey: AddDocumentSheet.saveKey,
      onSave: _save,
      onDelete: _isEdit ? _delete : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppFormField(
            label: 'Tipo',
            child: Wrap(
              spacing: AppDim.gapS,
              runSpacing: AppDim.gapS,
              children: [
                for (final tipo in DocumentTipo.values)
                  AppChip(
                    label: documentTipoLabel(tipo),
                    selected: _tipo == tipo,
                    height: AppDim.formChipH,
                    padding: AppDim.formChipPad,
                    onSelected: () => setState(() => _tipo = tipo),
                  ),
              ],
            ),
          ),
          const DialogBodyGap(),
          AppFormField(
            key: AddDocumentSheet.nomeKey,
            label: 'Nome',
            hint: _isEdit ? 'Es. libretto sanitario' : 'Opzionale',
            controller: _nome,
          ),
          if (!_isEdit) ...[
            const DialogBodyGap(),
            AppFormField(
              label: 'File',
              child: Row(
                children: [
                  Expanded(
                    child: _FilePickButton(
                      key: AddDocumentSheet.pdfKey,
                      label: 'Scegli PDF',
                      onTap: _saving ? null : () => _pick(pdf: true),
                    ),
                  ),
                  const SizedBox(width: AppDim.formRowGap),
                  Expanded(
                    child: _FilePickButton(
                      key: AddDocumentSheet.fotoKey,
                      label: 'Scegli foto',
                      onTap: _saving ? null : () => _pick(pdf: false),
                    ),
                  ),
                ],
              ),
            ),
            if (_files.isNotEmpty) ...[
              const DialogBodyGap(),
              _PickedFileRow(
                key: AddDocumentSheet.fileRowKey,
                name: _fileName,
                sizeLabel: formatFileSize(_fileBytes),
                onClear: () => setState(() => _files = const []),
              ),
            ],
          ],
          if (_error != null) ...[
            const DialogBodyGap(),
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
        ],
      ),
    );
  }
}

class _FilePickButton extends StatelessWidget {
  const _FilePickButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDim.dialogFooterBtnH,
      child: Material(
        color: AppColor.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDim.formRad),
          side: const BorderSide(color: AppColor.line),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDim.formRad),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: AppText.body,
                fontWeight: FontWeight.w700,
                color: AppColor.ink2,
                height: AppDim.lineH,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PickedFileRow extends StatelessWidget {
  const _PickedFileRow({
    super.key,
    required this.name,
    required this.sizeLabel,
    required this.onClear,
  });

  final String name;
  final String sizeLabel;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDim.formFieldH,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColor.neutralSoft,
          borderRadius: BorderRadius.circular(AppDim.formRad),
          border: Border.all(color: AppColor.line),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDim.gapS),
          child: Row(
            children: [
              const IconBadge(AppIcons.allegato, size: IconBadge.inNotice),
              const SizedBox(width: AppDim.gapS),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: AppText.body,
                    fontWeight: FontWeight.w600,
                    color: AppColor.ink,
                    height: AppDim.lineH,
                  ),
                ),
              ),
              const SizedBox(width: AppDim.gapS),
              Text(
                sizeLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: AppText.caption,
                  color: AppColor.muted,
                  height: AppDim.lineH,
                ),
              ),
              const SizedBox(width: AppDim.gapS),
              SizedBox(
                width: AppDim.dialogClose,
                height: AppDim.dialogClose,
                child: Material(
                  color: AppColor.card,
                  shape: const CircleBorder(),
                  child: InkWell(
                    key: AddDocumentSheet.clearFileKey,
                    customBorder: const CircleBorder(),
                    onTap: onClear,
                    child: const Center(
                      child: Text(
                        '×',
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: AppText.body,
                          fontWeight: FontWeight.w700,
                          color: AppColor.muted,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
