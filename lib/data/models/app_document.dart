import '../../core/firestore_codec.dart';
import 'enums.dart';

class AppDocument {
  const AppDocument({
    required this.id,
    required this.dogId,
    required this.adoptionId,
    required this.tipo,
    required this.nome,
    required this.mime,
    required this.pdfB64,
    required this.firmaAffidatarioB64,
    required this.firmaReferenteB64,
    required this.createdAt,
    required this.createdBy,
  });

  final String id;
  final String? dogId;
  final String? adoptionId;
  final DocumentTipo tipo;
  final String nome;
  final String mime;
  final String? pdfB64;
  final String? firmaAffidatarioB64;
  final String? firmaReferenteB64;
  final DateTime createdAt;
  final String createdBy;

  factory AppDocument.fromMap(String id, Map<String, dynamic> map) {
    return AppDocument(
      id: id,
      dogId: map['dogId'] as String?,
      adoptionId: map['adoptionId'] as String?,
      tipo: DocumentTipo.parse(map['tipo'] as String?),
      nome: map['nome'] as String? ?? '',
      mime: map['mime'] as String? ?? '',
      pdfB64: map['pdfB64'] as String?,
      firmaAffidatarioB64: map['firmaAffidatarioB64'] as String?,
      firmaReferenteB64: map['firmaReferenteB64'] as String?,
      createdAt: dateTimeRequired(map['createdAt']),
      createdBy: map['createdBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dogId': dogId,
      'adoptionId': adoptionId,
      'tipo': tipo.wire,
      'nome': nome,
      'mime': mime,
      'pdfB64': pdfB64,
      'firmaAffidatarioB64': firmaAffidatarioB64,
      'firmaReferenteB64': firmaReferenteB64,
      'createdAt': dateTimeTo(createdAt),
      'createdBy': createdBy,
    };
  }
}
