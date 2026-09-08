import '../../core/firestore_codec.dart';

class Sostenitore {
  const Sostenitore({
    required this.nome,
    required this.cognome,
    required this.email,
    required this.telefono,
  });

  final String nome;
  final String cognome;
  final String email;
  final String telefono;

  factory Sostenitore.fromMap(Map<String, dynamic>? map) {
    final data = map ?? const <String, dynamic>{};
    return Sostenitore(
      nome: data['nome'] as String? ?? '',
      cognome: data['cognome'] as String? ?? '',
      email: data['email'] as String? ?? '',
      telefono: data['telefono'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'cognome': cognome,
      'email': email,
      'telefono': telefono,
    };
  }
}

class Sponsorship {
  const Sponsorship({
    required this.id,
    required this.dogId,
    required this.sostenitore,
    required this.importoMensile,
    required this.attiva,
    required this.dal,
    required this.al,
    required this.note,
    required this.audit,
  });

  final String id;
  final String dogId;
  final Sostenitore sostenitore;
  final double importoMensile;
  final bool attiva;
  final DateTime dal;
  final DateTime? al;
  final String note;
  final Audit audit;

  factory Sponsorship.fromMap(String id, Map<String, dynamic> map) {
    final raw = map['sostenitore'];
    return Sponsorship(
      id: id,
      dogId: map['dogId'] as String? ?? '',
      sostenitore: Sostenitore.fromMap(
        raw is Map<dynamic, dynamic>
            ? Map<String, dynamic>.from(raw)
            : null,
      ),
      importoMensile: numberFrom(map['importoMensile']) ?? 0,
      attiva: map['attiva'] as bool? ?? false,
      dal: dateTimeRequired(map['dal']),
      al: dateTimeFrom(map['al']),
      note: map['note'] as String? ?? '',
      audit: Audit.fromMap(map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dogId': dogId,
      'sostenitore': sostenitore.toMap(),
      'importoMensile': importoMensile,
      'attiva': attiva,
      'dal': dateTimeTo(dal),
      'al': dateTimeTo(al),
      'note': note,
      ...audit.toMap(),
    };
  }
}
