import '../../core/firestore_codec.dart';
import 'enums.dart';

class Note {
  const Note({
    required this.id,
    required this.dogId,
    required this.tipo,
    required this.testo,
    required this.autoreId,
    required this.createdAt,
  });

  final String id;
  final String dogId;
  final NoteTipo tipo;
  final String testo;
  final String autoreId;
  final DateTime createdAt;

  factory Note.fromMap(String id, Map<String, dynamic> map) {
    return Note(
      id: id,
      dogId: map['dogId'] as String? ?? '',
      tipo: NoteTipo.parse(map['tipo'] as String?),
      testo: map['testo'] as String? ?? '',
      autoreId: map['autoreId'] as String? ?? '',
      createdAt: dateTimeRequired(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dogId': dogId,
      'tipo': tipo.wire,
      'testo': testo,
      'autoreId': autoreId,
      'createdAt': dateTimeTo(createdAt),
    };
  }
}
