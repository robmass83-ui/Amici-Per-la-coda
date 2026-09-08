import '../../core/firestore_codec.dart';

class Weight {
  const Weight({
    required this.id,
    required this.dogId,
    required this.data,
    required this.kg,
    required this.autoreId,
    required this.note,
    required this.audit,
  });

  final String id;
  final String dogId;
  final DateTime data;
  final double kg;
  final String autoreId;
  final String note;
  final Audit audit;

  factory Weight.fromMap(String id, Map<String, dynamic> map) {
    return Weight(
      id: id,
      dogId: map['dogId'] as String? ?? '',
      data: dateTimeRequired(map['data']),
      kg: numberFrom(map['kg']) ?? 0,
      autoreId: map['autoreId'] as String? ?? '',
      note: map['note'] as String? ?? '',
      audit: Audit.fromMap(map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dogId': dogId,
      'data': dateTimeTo(data),
      'kg': kg,
      'autoreId': autoreId,
      'note': note,
      ...audit.toMap(),
    };
  }
}
