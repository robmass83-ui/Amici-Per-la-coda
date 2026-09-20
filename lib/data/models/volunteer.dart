import '../../core/firestore_codec.dart';
import 'enums.dart';

class Volunteer {
  const Volunteer({
    required this.id,
    required this.nome,
    this.cognome = '',
    required this.email,
    required this.ruolo,
    required this.attivo,
    required this.coloreAvatar,
    required this.audit,
    this.mustChangePassword = false,
    this.ultimoAccesso,
  });

  final String id;
  final String nome;
  final String cognome;
  final String email;
  final VolunteerRuolo ruolo;
  final bool attivo;
  final String coloreAvatar;
  final bool mustChangePassword;
  final DateTime? ultimoAccesso;
  final Audit audit;

  factory Volunteer.fromMap(String id, Map<String, dynamic> map) {
    return Volunteer(
      id: id,
      nome: map['nome'] as String? ?? '',
      cognome: map['cognome'] as String? ?? '',
      email: map['email'] as String? ?? '',
      ruolo: VolunteerRuolo.parse(map['ruolo'] as String?),
      attivo: map['attivo'] as bool? ?? false,
      coloreAvatar: map['coloreAvatar'] as String? ?? '#157A3C',
      mustChangePassword: map['mustChangePassword'] as bool? ?? false,
      ultimoAccesso: dateTimeFrom(map['ultimoAccesso']),
      audit: Audit.fromMap(map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'cognome': cognome,
      'email': email,
      'ruolo': ruolo.wire,
      'attivo': attivo,
      'coloreAvatar': coloreAvatar,
      'mustChangePassword': mustChangePassword,
      if (ultimoAccesso != null) 'ultimoAccesso': dateTimeTo(ultimoAccesso),
      ...audit.toMap(),
    };
  }

  Volunteer copyWith({
    String? nome,
    String? cognome,
    String? email,
    VolunteerRuolo? ruolo,
    bool? attivo,
    String? coloreAvatar,
    bool? mustChangePassword,
    DateTime? ultimoAccesso,
    bool clearUltimoAccesso = false,
    Audit? audit,
  }) {
    return Volunteer(
      id: id,
      nome: nome ?? this.nome,
      cognome: cognome ?? this.cognome,
      email: email ?? this.email,
      ruolo: ruolo ?? this.ruolo,
      attivo: attivo ?? this.attivo,
      coloreAvatar: coloreAvatar ?? this.coloreAvatar,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      ultimoAccesso: clearUltimoAccesso
          ? null
          : (ultimoAccesso ?? this.ultimoAccesso),
      audit: audit ?? this.audit,
    );
  }
}
