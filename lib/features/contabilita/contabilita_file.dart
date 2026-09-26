import 'dart:typed_data';

import '../../data/documents/document_codec.dart';
import '../../data/documents/document_file_picker.dart';
import '../../data/photos/photo_codec.dart';
import 'contabilita_logic.dart';

class FileContabilePreparato {
  const FileContabilePreparato({
    required this.bytes,
    required this.mime,
    required this.nomeFile,
  });

  final Uint8List bytes;
  final String mime;
  final String nomeFile;
}

class _FileContabileRifiutato implements Exception {
  const _FileContabileRifiutato();

  @override
  String toString() => contabilitaFileRifiutato;
}

bool fileContabileAccettato(String mime, String name) {
  final mimeNormalizzato = mime.toLowerCase();
  final nomeNormalizzato = name.toLowerCase();
  return mimeNormalizzato.contains('pdf') ||
      mimeNormalizzato.contains('jpeg') ||
      mimeNormalizzato.contains('jpg') ||
      mimeNormalizzato.contains('png') ||
      nomeNormalizzato.endsWith('.pdf') ||
      nomeNormalizzato.endsWith('.jpg') ||
      nomeNormalizzato.endsWith('.jpeg') ||
      nomeNormalizzato.endsWith('.png');
}

Future<FileContabilePreparato> preparaFileContabile(
  PickedDocumentFile file,
) async {
  if (!fileContabileAccettato(file.mime, file.name)) {
    throw const _FileContabileRifiutato();
  }

  final mimeNormalizzato = file.mime.toLowerCase();
  final nomeNormalizzato = file.name.toLowerCase();
  final pdf =
      mimeNormalizzato.contains('pdf') || nomeNormalizzato.endsWith('.pdf');
  if (pdf) {
    return FileContabilePreparato(
      bytes: file.bytes,
      mime: 'application/pdf',
      nomeFile: file.name,
    );
  }

  final bytes = await compressDocumentImage(file.bytes);
  ensureDocumentSizeAllowed(bytes.lengthInBytes);
  return FileContabilePreparato(
    bytes: bytes,
    mime: 'image/jpeg',
    nomeFile: _nomeJpeg(file.name),
  );
}

String _nomeJpeg(String name) {
  final dot = name.lastIndexOf('.');
  if (dot <= 0) {
    return '$name.jpg';
  }
  return '${name.substring(0, dot)}.jpg';
}
