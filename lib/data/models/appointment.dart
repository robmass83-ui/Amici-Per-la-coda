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
      'stato': stato.wire,
      ...audit.toMap(),
    };
  }

  Appointment copyWith({
    AppointmentTipo? tipo,
    String? titolo,
    String? dogId,
    bool clearDogId = false,
    String? adoptionId,
    bool clearAdoptionId = false,
    DateTime? inizio,
    DateTime? fine,
    bool clearFine = false,
    bool? tuttoIlGiorno,
    String? luogo,
    AppointmentStato? stato,
    Audit? audit,
  }) {
    return Appointment(
      id: id,
      tipo: tipo ?? this.tipo,
      titolo: titolo ?? this.titolo,
      dogId: clearDogId ? null : (dogId ?? this.dogId),
      adoptionId: clearAdoptionId ? null : (adoptionId ?? this.adoptionId),
      inizio: inizio ?? this.inizio,
      fine: clearFine ? null : (fine ?? this.fine),
      tuttoIlGiorno: tuttoIlGiorno ?? this.tuttoIlGiorno,
      luogo: luogo ?? this.luogo,
      stato: stato ?? this.stato,
      audit: audit ?? this.audit,
    );
  }
}
