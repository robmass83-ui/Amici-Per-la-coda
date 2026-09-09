import '../../core/firestore_codec.dart';

class DocumentTemplate {
  const DocumentTemplate({
    required this.id,
    required this.nome,
    required this.descrizione,
    required this.fileName,
    required this.mime,
    required this.pdfB64,
    required this.versione,
    required this.aggiornatoIl,
    required this.aggiornatoDa,
  });

  final String id;
  final String nome;
  final String descrizione;
  final String fileName;
  final String mime;
  final String pdfB64;
  final int versione;
  final DateTime aggiornatoIl;
  final String aggiornatoDa;

  factory DocumentTemplate.fromMap(String id, Map<String, dynamic> map) {
    return DocumentTemplate(
      id: id,
      nome: map['nome'] as String? ?? '',
      descrizione: map['descrizione'] as String? ?? '',
      fileName: map['fileName'] as String? ?? '',
      mime: map['mime'] as String? ?? 'application/pdf',
      pdfB64: map['pdfB64'] as String? ?? '',
      versione: intFrom(map['versione'], fallback: 1),
      aggiornatoIl: dateTimeRequired(map['aggiornatoIl']),
      aggiornatoDa: map['aggiornatoDa'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'descrizione': descrizione,
      'fileName': fileName,
      'mime': mime,
      'pdfB64': pdfB64,
      'versione': versione,
      'aggiornatoIl': dateTimeTo(aggiornatoIl),
      'aggiornatoDa': aggiornatoDa,
    };
  }

  DocumentTemplate copyWith({
    String? pdfB64,
    int? versione,
    DateTime? aggiornatoIl,
    String? aggiornatoDa,
    String? fileName,
  }) {
    return DocumentTemplate(
      id: id,
      nome: nome,
      descrizione: descrizione,
      fileName: fileName ?? this.fileName,
      mime: mime,
      pdfB64: pdfB64 ?? this.pdfB64,
      versione: versione ?? this.versione,
      aggiornatoIl: aggiornatoIl ?? this.aggiornatoIl,
      aggiornatoDa: aggiornatoDa ?? this.aggiornatoDa,
    );
  }
}
