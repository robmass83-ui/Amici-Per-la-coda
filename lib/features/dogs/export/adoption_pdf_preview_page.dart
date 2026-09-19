import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../data/data_providers.dart';
import '../../../ui/components.dart';
import '../../../ui/tokens.dart';
import 'adoption_pdf.dart';
import 'adoption_post_text.dart';
import 'adoption_profile.dart';

class AdoptionPdfPreviewPage extends ConsumerStatefulWidget {
  const AdoptionPdfPreviewPage({super.key, required this.profile});

  static const pageKey = Key('adoption-pdf-preview');
  static const shareKey = Key('adoption-pdf-share');
  static const saveKey = Key('adoption-pdf-save');

  final AdoptionProfile profile;

  @override
  ConsumerState<AdoptionPdfPreviewPage> createState() =>
      _AdoptionPdfPreviewPageState();
}

class _AdoptionPdfPreviewPageState
    extends ConsumerState<AdoptionPdfPreviewPage> {
  Uint8List? _bytes;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _build());
  }

  Future<void> _build() async {
    try {
      final fonts = await AdoptionPdfFonts.load(
        ref.read(assetBytesLoaderProvider),
      );
      final bytes = await buildAdoptionPdf(widget.profile, fonts: fonts);
      if (mounted) {
        setState(() => _bytes = bytes);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Anteprima non disponibile.');
      }
    }
  }

  Future<void> _share() async {
    final bytes = _bytes;
    if (bytes == null) {
      return;
    }
    await ref.read(fileShareProvider).shareFile(
      bytes: bytes,
      fileName: fileNameSchedaPdf(widget.profile.nome),
      mime: 'application/pdf',
      text: 'Scheda di adozione di ${widget.profile.nome}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: AdoptionPdfPreviewPage.pageKey,
      backgroundColor: AppColor.bg,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: AppHeader(
              title: 'Scheda di adozione',
              compact: true,
              onBack: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: _bytes == null
                ? Center(
                    child: Text(
                      _error ?? 'Preparo la scheda…',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: AppText.body,
                        color: AppColor.muted,
                      ),
                    ),
                  )
                : PdfPreview(
                    build: (format) async => _bytes!,
                    initialPageFormat: PdfPageFormat.a4,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    canDebug: false,
                    allowPrinting: false,
                    allowSharing: false,
                    pdfPreviewPageDecoration: const BoxDecoration(
                      color: AppColor.card,
                    ),
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDim.gapL,
                AppDim.gapS,
                AppDim.gapL,
                AppDim.gapL,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      key: AdoptionPdfPreviewPage.shareKey,
                      label: 'Condividi',
                      onPressed: _bytes == null ? null : () => _share(),
                    ),
                  ),
                  const SizedBox(width: AppDim.gapM),
                  Expanded(
                    child: AppButton(
                      key: AdoptionPdfPreviewPage.saveKey,
                      label: 'Salva',
                      variant: AppButtonVariant.grey,
                      onPressed: _bytes == null ? null : () => _share(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
