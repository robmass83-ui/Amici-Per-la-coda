import '../../core/firestore_codec.dart';
import 'enums.dart';

class HealthRecord {
  const HealthRecord({
    required this.id,
    required this.dogId,
    required this.tipo,
    required this.data,
    required this.descrizione,
    required this.veterinario,
    required this.lotto,
    required this.prossimaScadenza,
    required this.costo,
    required this.audit,
  });

  final String id;
  final String dogId;
  final HealthTipo tipo;
  final DateTime data;
  final String descrizione;
  final String veterinario;
  final String lotto;
  final DateTime? prossimaScadenza;
  final double? costo;
  final Audit audit;

  factory HealthRecord.fromMap(String id, Map<String, dynamic> map) {
    return HealthRecord(
      id: id,
      dogId: map['dogId'] as String? ?? '',
      tipo: HealthTipo.parse(map['tipo'] as String?),
      data: dateTimeRequired(map['data']),
      descrizione: map['descrizione'] as String? ?? '',
      veterinario: map['veterinario'] as String? ?? '',
      lotto: map['lotto'] as String? ?? '',
      prossimaScadenza: dateTimeFrom(map['prossimaScadenza']),
      costo: numberFrom(map['costo']),
      audit: Audit.fromMap(map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dogId': dogId,
      'tipo': tipo.wire,
      'data': dateTimeTo(data),
      'descrizione': descrizione,
      'veterinario': veterinario,
      'lotto': lotto,
      'prossimaScadenza': dateTimeTo(prossimaScadenza),
      'costo': costo,
      ...audit.toMap(),
    };
  }

  HealthRecord copyWith({
    HealthTipo? tipo,
    DateTime? data,
    String? descrizione,
    String? veterinario,
    String? lotto,
    DateTime? prossimaScadenza,
    bool clearProssimaScadenza = false,
    double? costo,
    bool clearCosto = false,
    Audit? audit,
  }) {
    return HealthRecord(
      id: id,
      dogId: dogId,
      tipo: tipo ?? this.tipo,
      data: data ?? this.data,
      descrizione: descrizione ?? this.descrizione,
      veterinario: veterinario ?? this.veterinario,
      lotto: lotto ?? this.lotto,
      prossimaScadenza: clearProssimaScadenza
          ? null
          : (prossimaScadenza ?? this.prossimaScadenza),
      costo: clearCosto ? null : (costo ?? this.costo),
      audit: audit ?? this.audit,
    );
  }
}
