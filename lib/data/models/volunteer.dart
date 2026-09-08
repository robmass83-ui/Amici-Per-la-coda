import '../../core/firestore_codec.dart';
import 'enums.dart';

class Volunteer {
  const Volunteer({
    required this.id,
    required this.nome,
    required this.email,
    required this.ruolo,
    required this.attivo,
    required this.coloreAvatar,
    required this.audit,
  });

  final String id;
  final String nome;
  final String email;
  final VolunteerRuolo ruolo;
  final bool attivo;
  final String coloreAvatar;
  final Audit audit;

  factory Volunteer.fromMap(String id, Map<String, dynamic> map) {
    return Volunteer(
      id: id,
      nome: map['nome'] as String? ?? '',
      email: map['email'] as String? ?? '',
      ruolo: VolunteerRuolo.parse(map['ruolo'] as String?),
      attivo: map['attivo'] as bool? ?? false,
      coloreAvatar: map['coloreAvatar'] as String? ?? '#157A3C',
      audit: Audit.fromMap(map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'email': email,
      'ruolo': ruolo.wire,
      'attivo': attivo,
      'coloreAvatar': coloreAvatar,
      ...audit.toMap(),
    };
  }
}
