import '../../core/firestore_codec.dart';
import 'enums.dart';

class Appointment {
  const Appointment({
    required this.id,
    required this.tipo,
    required this.titolo,
    required this.dogId,
    required this.adoptionId,
    required this.inizio,
    required this.fine,
    required this.tuttoIlGiorno,
    required this.luogo,
    required this.volontariIds,
    required this.stato,
    required this.audit,
  });

  final String id;
  final AppointmentTipo tipo;
  final String titolo;
  final String? dogId;
  final String? adoptionId;
  final DateTime inizio;
  final DateTime? fine;
  final bool tuttoIlGiorno;
  final String luogo;
  final List<String> volontariIds;
  final AppointmentStato stato;
  final Audit audit;

  factory Appointment.fromMap(String id, Map<String, dynamic> map) {
    return Appointment(
      id: id,
      tipo: AppointmentTipo.parse(map['tipo'] as String?),
      titolo: map['titolo'] as String? ?? '',
      dogId: map['dogId'] as String?,
      adoptionId: map['adoptionId'] as String?,
      inizio: dateTimeRequired(map['inizio']),
      fine: dateTimeFrom(map['fine']),
      tuttoIlGiorno: map['tuttoIlGiorno'] as bool? ?? false,
      luogo: map['luogo'] as String? ?? '',
      volontariIds: (map['volontariIds'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      stato: AppointmentStato.parse(map['stato'] as String?),
      audit: Audit.fromMap(map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo.wire,
      'titolo': titolo,
      'dogId': dogId,
      'adoptionId': adoptionId,
      'inizio': dateTimeTo(inizio),
      'fine': dateTimeTo(fine),
      'tuttoIlGiorno': tuttoIlGiorno,
      'luogo': luogo,
      'volontariIds': volontariIds,
      'stato': stato.wire,
      ...audit.toMap(),
    };
  }
}
