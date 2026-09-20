import '../../core/firestore_codec.dart';
import 'enums.dart';

class ShelterBox {
  const ShelterBox({
    required this.id,
    required this.settore,
    required this.numero,
    required this.capienza,
    required this.tipo,
    required this.note,
    required this.inManutenzione,
    required this.audit,
  });

  final String id;
  final String settore;
  final String numero;
  final int capienza;
  final BoxTipo tipo;
  final String note;
  final bool inManutenzione;
  final Audit audit;

  factory ShelterBox.fromMap(String id, Map<String, dynamic> map) {
    return ShelterBox(
      id: id,
      settore: map['settore'] as String? ?? '',
      numero: map['numero'] as String? ?? '',
      capienza: intFrom(map['capienza']),
      tipo: BoxTipo.parse(map['tipo'] as String?),
      note: map['note'] as String? ?? '',
      inManutenzione: map['inManutenzione'] as bool? ?? false,
      audit: Audit.fromMap(map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'settore': settore,
      'numero': numero,
      'capienza': capienza,
      'tipo': tipo.wire,
      'note': note,
      'inManutenzione': inManutenzione,
      ...audit.toMap(),
    };
  }

  ShelterBox copyWith({
    String? settore,
    String? numero,
    int? capienza,
    BoxTipo? tipo,
    String? note,
    bool? inManutenzione,
    Audit? audit,
  }) {
    return ShelterBox(
      id: id,
      settore: settore ?? this.settore,
      numero: numero ?? this.numero,
      capienza: capienza ?? this.capienza,
      tipo: tipo ?? this.tipo,
      note: note ?? this.note,
      inManutenzione: inManutenzione ?? this.inManutenzione,
      audit: audit ?? this.audit,
    );
  }
}
