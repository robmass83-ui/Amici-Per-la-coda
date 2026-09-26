import 'dart:typed_data';

import '../../features/contabilita/contabilita_logic.dart';
import '../models/documento_contabile.dart';

abstract interface class ContabilitaRepository {
  Stream<List<AnnoContabile>> watchAnni();

  Stream<List<DocumentoContabile>> watchTutti();

  Stream<List<DocumentoContabile>> watchAnno(int anno);

  Future<void> createAnno({
    required int anno,
    required String uid,
    required DateTime now,
  });

  Future<void> saveNuovo(DocumentoContabile doc, Uint8List bytes);

  Future<void> saveMeta(DocumentoContabile doc);

  Future<void> replaceFile(DocumentoContabile doc, Uint8List bytes);

  Future<Uint8List> loadBytes(String id);

  Future<void> deleteDocumento(String id);
}

class AnnoGiaPresente implements Exception {
  const AnnoGiaPresente(this.anno);

  final int anno;

  @override
  String toString() => messaggioAnnoDuplicato(anno);
}
