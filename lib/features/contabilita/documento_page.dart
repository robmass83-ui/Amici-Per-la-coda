// DocumentoContabilePage
// Column a tutta altezza, nessuno scorrimento orizzontale
//   SafeArea AppHeader compatto con indietro e titolo maxLines 1
//   Expanded anteprima: Image.memory contain oppure PdfPreview
//   Padding pagePad
//     nome maxLines 1 ellipsis
//     gapS, Wrap azioni compatte: Scarica, Condividi, [Modifica], [Elimina]
// Tutti i testi variabili in riga sono limitati con ellissi.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../data/data_providers.dart';
import '../../data/models/documento_contabile.dart';
import '../../ui/components/app_button.dart';
import '../../ui/components/app_header.dart';
import '../../ui/tokens.dart';
import '../affido/affido_providers.dart';
import '../dogs/edit_permissions.dart';
import 'contabilita_logic.dart';
import 'documento_sheet.dart';

class DocumentoContabilePage extends ConsumerWidget {
  const DocumentoContabilePage({
    super.key,
    required this.anno,
    required this.id,
  });

  final int anno;
  final String id;

  static const modificaKey = Key('contabilita-modifica');
  static const eliminaKey = Key('contabilita-elimina');
  static const condividiKey = Key('contabilita-condividi');
  static const scaricaKey = Key('contabilita-scarica');

  Future<void> _scarica(
    WidgetRef ref,
    DocumentoContabile doc,
    Uint8List bytes,
  ) {
    return ref
        .read(fileOpenerProvider)
        .openFile(bytes: bytes, fileName: doc.nomeFile, mime: doc.mime);
  }

  Future<void> _condividi(
    WidgetRef ref,
    DocumentoContabile doc,
    Uint8List bytes,
  ) {
    return ref
        .read(fileShareProvider)
        .shareFile(
          bytes: bytes,
          fileName: doc.nomeFile,
          mime: doc.mime,
          text: doc.nome,
        );
  }

  Future<void> _elimina(
    BuildContext context,
    WidgetRef ref,
    DocumentoContabile doc,
  ) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text(contabilitaElimina),
        actions: [
          AppButton(
            label: 'Annulla',
            variant: AppButtonVariant.grey,
            expand: false,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          AppButton(
            label: 'Elimina',
            expand: false,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (conferma != true || !context.mounted) {
      return;
    }
    await ref.read(contabilitaRepositoryProvider)!.deleteDocumento(doc.id);
    if (context.mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(contabilitaRepositoryProvider);
    if (repo == null) {
      return const Center(child: Text('Archivio contabile non disponibile.'));
    }
    final canWrite = canWriteRecords(ref.watch(currentVolunteerProvider));
    return StreamBuilder<List<DocumentoContabile>>(
      stream: repo.watchAnno(anno),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        DocumentoContabile? doc;
        for (final item in snapshot.data!) {
          if (item.id == id) {
            doc = item;
            break;
          }
        }
        if (doc == null) {
          return const Center(child: Text('Documento non trovato.'));
        }
        final documento = doc;
        return FutureBuilder<Uint8List>(
          future: repo.loadBytes(documento.id),
          builder: (context, bytesSnapshot) {
            final bytes = bytesSnapshot.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SafeArea(
                  bottom: false,
                  child: AppHeader(
                    title: documento.nome,
                    compact: true,
                    onBack: () => context.pop(),
                  ),
                ),
                Expanded(
                  child: bytes == null
                      ? const Center(child: CircularProgressIndicator())
                      : _Anteprima(documento: documento, bytes: bytes),
                ),
                Padding(
                  padding: AppDim.pagePad,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        documento.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: AppText.h2,
                          fontWeight: FontWeight.w700,
                          color: AppColor.ink,
                          height: AppDim.lineH,
                        ),
                      ),
                      const SizedBox(height: AppDim.gapS),
                      Wrap(
                        spacing: AppDim.gapS,
                        runSpacing: AppDim.gapS,
                        children: [
                          AppButton(
                            key: scaricaKey,
                            label: 'Scarica',
                            variant: AppButtonVariant.ghost,
                            expand: false,
                            onPressed: bytes == null
                                ? null
                                : () => _scarica(ref, documento, bytes),
                          ),
                          AppButton(
                            key: condividiKey,
                            label: 'Condividi',
                            variant: AppButtonVariant.ghost,
                            expand: false,
                            onPressed: bytes == null
                                ? null
                                : () => _condividi(ref, documento, bytes),
                          ),
                          if (canWrite)
                            AppButton(
                              key: modificaKey,
                              label: 'Modifica',
                              variant: AppButtonVariant.ghost,
                              expand: false,
                              onPressed: () => DocumentoContabileSheet.open(
                                context,
                                anno: anno,
                                existing: documento,
                              ),
                            ),
                          if (canWrite)
                            AppButton(
                              key: eliminaKey,
                              label: 'Elimina',
                              variant: AppButtonVariant.grey,
                              expand: false,
                              onPressed: () =>
                                  _elimina(context, ref, documento),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _Anteprima extends StatelessWidget {
  const _Anteprima({required this.documento, required this.bytes});

  final DocumentoContabile documento;
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    if (documento.mime == 'image/jpeg') {
      return Image.memory(bytes, fit: BoxFit.contain);
    }
    return PdfPreview(
      build: (_) async => bytes,
      allowPrinting: false,
      allowSharing: false,
      canChangePageFormat: false,
    );
  }
}
