import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/documents/document_file_picker.dart';
import '../../data/photos/photo_codec.dart';

Future<({Uint8List bytes, String mime, String name})> prepareSignedUpload(
  List<PickedDocumentFile> files,
) async {
  if (files.isEmpty) {
    throw ArgumentError('Nessun file selezionato.');
  }
  final first = files.first;
  final isPdf = first.mime.contains('pdf') ||
      first.name.toLowerCase().endsWith('.pdf');
  if (isPdf) {
    return (bytes: first.bytes, mime: 'application/pdf', name: first.name);
  }
  final compressed = <Uint8List>[];
  for (final file in files) {
    compressed.add(await compressDocumentImage(file.bytes));
  }
  if (compressed.length == 1) {
    return (
      bytes: compressed.first,
      mime: 'image/jpeg',
      name: _asJpegName(first.name),
    );
  }
  final pdfBytes = await jpegPagesToPdf(compressed);
  return (
    bytes: pdfBytes,
    mime: 'application/pdf',
    name: 'modulo-firmato.pdf',
  );
}

String _asJpegName(String name) {
  final dot = name.lastIndexOf('.');
  if (dot <= 0) {
    return '$name.jpg';
  }
  return '${name.substring(0, dot)}.jpg';
}

Future<Uint8List> jpegPagesToPdf(List<Uint8List> images) async {
  final doc = pw.Document();
  for (final bytes in images) {
    final image = pw.MemoryImage(bytes);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => pw.Center(
          child: pw.Image(image, fit: pw.BoxFit.contain),
        ),
      ),
    );
  }
  return Uint8List.fromList(await doc.save());
}
