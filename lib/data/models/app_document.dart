import '../../core/firestore_codec.dart';
import 'enums.dart';

class AppDocument {
  const AppDocument({
    required this.id,
    required this.dogId,
    required this.adoptionId,
    required this.adopterId,
    required this.tipo,
    required this.nome,
    required this.mime,
    required this.chunkCount,
    required this.contenutoB64,
    required this.caricatoIl,
    required this.caricatoDa,
  });

  final String id;
  final String? dogId;
  final String? adoptionId;
  final String adopterId;
  final DocumentTipo tipo;
  final String nome;
  final String mime;
  final int chunkCount;
  final String? contenutoB64;
  final DateTime caricatoIl;
  final String caricatoDa;

  DateTime get createdAt => caricatoIl;
  String get createdBy => caricatoDa;
  String? get pdfB64 => contenutoB64;

  factory AppDocument.fromMap(String id, Map<String, dynamic> map) {
    return AppDocument(
      id: id,
      dogId: map['dogId'] as String?,
      adoptionId: map['adoptionId'] as String?,
      adopterId: map['adopterId'] as String? ?? '',
      tipo: DocumentTipo.parse(map['tipo'] as String?),
      nome: map['nome'] as String? ?? '',
      mime: map['mime'] as String? ?? '',
      chunkCount: intFrom(map['chunkCount']),
      contenutoB64:
          map['contenutoB64'] as String? ?? map['pdfB64'] as String?,
      caricatoIl: dateTimeRequired(map['caricatoIl'] ?? map['createdAt']),
      caricatoDa:
          map['caricatoDa'] as String? ?? map['createdBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dogId': dogId,
      'adoptionId': adoptionId,
      'adopterId': adopterId,
      'tipo': tipo.wire,
      'nome': nome,
      'mime': mime,
      'chunkCount': chunkCount,
      'contenutoB64': contenutoB64,
      'caricatoIl': dateTimeTo(caricatoIl),
      'caricatoDa': caricatoDa,
    };
  }

  AppDocument copyWith({
    String? dogId,
    String? adoptionId,
    String? adopterId,
    DocumentTipo? tipo,
    String? nome,
    String? mime,
    int? chunkCount,
    String? contenutoB64,
    bool clearContenuto = false,
    DateTime? caricatoIl,
    String? caricatoDa,
  }) {
    return AppDocument(
      id: id,
      dogId: dogId ?? this.dogId,
      adoptionId: adoptionId ?? this.adoptionId,
      adopterId: adopterId ?? this.adopterId,
      tipo: tipo ?? this.tipo,
      nome: nome ?? this.nome,
      mime: mime ?? this.mime,
      chunkCount: chunkCount ?? this.chunkCount,
      contenutoB64: clearContenuto
          ? null
          : (contenutoB64 ?? this.contenutoB64),
      caricatoIl: caricatoIl ?? this.caricatoIl,
      caricatoDa: caricatoDa ?? this.caricatoDa,
    );
  }
}
