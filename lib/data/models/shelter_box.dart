import '../../core/firestore_codec.dart';

class ShelterBox {
  const ShelterBox({
    required this.id,
    required this.settore,
    required this.numero,
    required this.capienza,
    required this.note,
    required this.inManutenzione,
    required this.audit,
  });

  final String id;
  final String settore;
  final String numero;
  final int capienza;
  final String note;
  final bool inManutenzione;
  final Audit audit;

  factory ShelterBox.fromMap(String id, Map<String, dynamic> map) {
    return ShelterBox(
      id: id,
      settore: map['settore'] as String? ?? '',
      numero: map['numero'] as String? ?? '',
      capienza: intFrom(map['capienza']),
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
      'note': note,
      'inManutenzione': inManutenzione,
      ...audit.toMap(),
    };
  }
}
