// DocumentoContabileSheet
// AppSheet, larghezza disponibile, nessuno scorrimento orizzontale
//   SingleChildScrollView verticale
//     Nome h=minTouch
//     gapM, Data read-only h=minTouch
//     gapM, Tipologia AppSegmented cinque segmenti uguali
//     gapM, Nota tre righe
//     gapM, Importo h=minTouch
//     gapM, file corrente maxLines 1 ellipsis
//     gapS, Wrap azioni compatte Scatta/Galleria/File h=minTouch
//     errore maxLines 3
//     gapM, Salva primary full-width h=minTouch

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firestore_codec.dart';
import '../../core/format_it.dart';
import '../../data/data_providers.dart';
import '../../data/documents/document_file_picker.dart';
import '../../data/models/documento_contabile.dart';
import '../../ui/components/app_button.dart';
import '../../ui/components/app_segmented.dart';
import '../../ui/components/app_sheet.dart';
import '../../ui/components/app_text_field.dart';
import '../../ui/tokens.dart';
import '../affido/affido_providers.dart';
import '../dogs/dogs_providers.dart';
import 'contabilita_bytes.dart';
import 'contabilita_file.dart';
import 'contabilita_logic.dart';

class DocumentoContabileSheet extends ConsumerStatefulWidget {
  const DocumentoContabileSheet({super.key, required this.anno, this.existing});

  final int anno;
  final DocumentoContabile? existing;

  static const nomeKey = Key('contabilita-nome');
  static const importoKey = Key('contabilita-importo');

  static Future<void> open(
    BuildContext context, {
    required int anno,
    DocumentoContabile? existing,
  }) {
    return AppSheet.present<void>(
      context: context,
      builder: (context) => AppSheet(
        title: existing == null ? 'Nuovo documento' : 'Modifica documento',
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: DocumentoContabileSheet(anno: anno, existing: existing),
            ),
          ),
        ],
      ),
    );
  }

  @override
  ConsumerState<DocumentoContabileSheet> createState() =>
      _DocumentoContabileSheetState();
}

class _DocumentoContabileSheetState
    extends ConsumerState<DocumentoContabileSheet> {
  late final TextEditingController _nome;
  late final TextEditingController _dataController;
  late final TextEditingController _nota;
  late final TextEditingController _importo;
  late DateTime _data;
  late int _tipologia;
  FileContabilePreparato? _file;
  String? _errore;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nome = TextEditingController(text: existing?.nome ?? '');
    _dataController = TextEditingController(
      text: formatItalianDate(existing?.data ?? DateTime.now()),
    );
    _nota = TextEditingController(text: existing?.descrizione ?? '');
    _importo = TextEditingController(
      text: existing?.importo?.toString().replaceAll('.', ',') ?? '',
    );
    _data = existing?.data ?? DateTime.now();
    _tipologia = existing == null
        ? 0
        : TipologiaContabile.values.indexOf(existing.tipologia);
  }

  @override
  void dispose() {
    _nome.dispose();
    _dataController.dispose();
    _nota.dispose();
    _importo.dispose();
    super.dispose();
  }

  Future<void> _scegliData() async {
    final scelta = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100, 12, 31),
    );
    if (scelta != null && mounted) {
      setState(() {
        _data = scelta;
        _dataController.text = formatItalianDate(scelta);
      });
    }
  }

  Future<void> _prepara(PickedDocumentFile? picked) async {
    if (picked == null) {
      return;
    }
    try {
      final preparato = await preparaFileContabile(picked);
      if (mounted) {
        setState(() {
          _file = preparato;
          _errore = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errore = error.toString());
      }
    }
  }

  Future<void> _scatta() async {
    final bytes = await ref.read(photoPickerProvider).pickFromCamera();
    if (bytes != null) {
      await _prepara(
        PickedDocumentFile(
          bytes: bytes,
          name: 'scatto.jpg',
          mime: 'image/jpeg',
        ),
      );
    }
  }

  Future<void> _galleria() async {
    final files = await ref.read(documentFilePickerProvider).pickImages();
    if (files.isNotEmpty) {
      await _prepara(files.first);
    }
  }

  Future<void> _pdf() async {
    await _prepara(await ref.read(documentFilePickerProvider).pickPdf());
  }

  Future<void> _salva() async {
    final nomeError = erroreNome(_nome.text);
    final notaError = erroreNota(_nota.text);
    final importoError = erroreImporto(_importo.text);
    final fileError = widget.existing == null && _file == null
        ? contabilitaFileMancante
        : null;
    final error = nomeError ?? notaError ?? importoError ?? fileError;
    if (error != null) {
      setState(() => _errore = error);
      return;
    }

    final repo = ref.read(contabilitaRepositoryProvider);
    if (repo == null) {
      setState(() => _errore = 'Archivio contabile non disponibile.');
      return;
    }
    setState(() => _salvando = true);
    try {
      final all = await repo.watchTutti().first;
      final existing = widget.existing;
      final nuova = _file?.bytes.length ?? existing!.dimensione;
      final quota = valutaQuota(
        usato: sommaDimensioni(all),
        nuova: nuova,
        vecchia: existing?.dimensione,
      );
      if (quota.rifiuto != null) {
        if (mounted) {
          setState(() {
            _errore = quota.rifiuto;
            _salvando = false;
          });
        }
        return;
      }

      final now = DateTime.now();
      final uid = ref.read(currentVolunteerProvider)?.id ?? '';
      final file = _file;
      final doc = DocumentoContabile(
        id: existing?.id ?? now.microsecondsSinceEpoch.toString(),
        anno: widget.anno,
        nome: _nome.text.trim(),
        data: _data,
        tipologia: TipologiaContabile.values[_tipologia],
        descrizione: _nota.text,
        importo: leggiImporto(_importo.text),
        mime: file?.mime ?? existing!.mime,
        nomeFile: file?.nomeFile ?? existing!.nomeFile,
        dimensione: file?.bytes.length ?? existing!.dimensione,
        chunkCount: file == null
            ? existing!.chunkCount
            : splitContabilitaBytes(file.bytes).length,
        generation: existing?.generation ?? 1,
        audit: existing == null
            ? Audit.seed(now, by: uid)
            : existing.audit.copyWith(updatedAt: now, updatedBy: uid),
      );
      if (existing == null) {
        await repo.saveNuovo(doc, file!.bytes);
      } else if (file == null) {
        await repo.saveMeta(doc);
      } else {
        await repo.replaceFile(doc, file.bytes);
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errore = error.toString();
          _salvando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nomeFile = _file?.nomeFile ?? widget.existing?.nomeFile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          key: DocumentoContabileSheet.nomeKey,
          label: 'Nome',
          controller: _nome,
        ),
        const SizedBox(height: AppDim.gapM),
        AppTextField(
          label: 'Data',
          controller: _dataController,
          readOnly: true,
          onTap: _scegliData,
        ),
        const SizedBox(height: AppDim.gapM),
        AppSegmented(
          values: [
            for (final value in TipologiaContabile.values) value.etichetta,
          ],
          selectedIndex: _tipologia,
          onChanged: (value) => setState(() => _tipologia = value),
        ),
        const SizedBox(height: AppDim.gapM),
        AppTextField(
          label: 'Nota',
          controller: _nota,
          maxLines: 3,
          fieldHeight: AppDim.descFieldH,
        ),
        const SizedBox(height: AppDim.gapM),
        AppTextField(
          key: DocumentoContabileSheet.importoKey,
          label: 'Importo',
          controller: _importo,
          keyboardType: TextInputType.number,
        ),
        if (nomeFile != null) ...[
          const SizedBox(height: AppDim.gapM),
          Text(
            nomeFile,
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
        const SizedBox(height: AppDim.gapS),
        Wrap(
          spacing: AppDim.gapS,
          runSpacing: AppDim.gapS,
          children: [
            AppButton(
              label: 'Scatta',
              variant: AppButtonVariant.ghost,
              expand: false,
              onPressed: _scatta,
            ),
            AppButton(
              label: 'Galleria',
              variant: AppButtonVariant.ghost,
              expand: false,
              onPressed: _galleria,
            ),
            AppButton(
              label: 'File',
              variant: AppButtonVariant.ghost,
              expand: false,
              onPressed: _pdf,
            ),
          ],
        ),
        if (_errore != null) ...[
          const SizedBox(height: AppDim.gapS),
          Text(
            _errore!,
            maxLines: 3,
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
        AppButton(label: 'Salva', onPressed: _salvando ? null : _salva),
      ],
    );
  }
}
