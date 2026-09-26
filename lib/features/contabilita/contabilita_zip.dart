import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../data/models/documento_contabile.dart';
import '../../data/repositories/contabilita_repository.dart';
import 'contabilita_logic.dart';

class ExportContabileException implements Exception {
  const ExportContabileException();

  @override
  String toString() => contabilitaExportOffline;
}

Uint8List zipContabilita(
  List<({DocumentoContabile doc, Uint8List bytes})> files,
) {
  final named = assegnaNomiZip([for (final file in files) file.doc]);
  final byId = {for (final file in files) file.doc.id: file.bytes};
  final rows = [
    for (final row in named) (doc: row.doc, fileName: row.fileName),
  ];
  final archive = Archive();
  final csvBytes = utf8.encode(riepilogoCsv(rows));
  archive.addFile(ArchiveFile('riepilogo.csv', csvBytes.length, csvBytes));
  for (final row in rows) {
    final data = byId[row.doc.id]!;
    archive.addFile(ArchiveFile(row.fileName, data.length, data));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

String nomeZipAnno(int anno) => 'Amici_per_la_Coda_Contabilita_$anno.zip';

Future<Uint8List> esportaZipAnno({
  required ContabilitaRepository repo,
  required List<DocumentoContabile> documenti,
  required bool offline,
}) async {
  if (documenti.isEmpty) {
    throw StateError('Nessun documento da esportare.');
  }

  final named = assegnaNomiZip(documenti);
  final files = <({DocumentoContabile doc, Uint8List bytes})>[];
  for (final row in named) {
    try {
      files.add((doc: row.doc, bytes: await repo.loadBytes(row.doc.id)));
    } catch (_) {
      if (offline) {
        throw const ExportContabileException();
      }
      rethrow;
    }
  }
  return zipContabilita(files);
}
