import '../../core/firestore_codec.dart';
import 'enums.dart';

class Adopter {
  const Adopter({
    required this.id,
    required this.nome,
    required this.cognome,
    required this.telefono,
    required this.email,
    required this.citta,
    required this.indirizzo,
    required this.docTipo,
    required this.docNumero,
    required this.dataNascita,
    required this.note,
    required this.adozioniIds,
    required this.affidabilita,
    required this.audit,
  });

  final String id;
  final String nome;
  final String cognome;
  final String telefono;
  final String email;
  final String citta;
  final String indirizzo;
  final String docTipo;
  final String docNumero;
  final DateTime? dataNascita;
  final String note;
  final List<String> adozioniIds;
  final Affidabilita affidabilita;
  final Audit audit;

  String get nomeCompleto => '$nome $cognome'.trim();

  factory Adopter.fromMap(String id, Map<String, dynamic> map) {
    return Adopter(
      id: id,
      nome: map['nome'] as String? ?? '',
      cognome: map['cognome'] as String? ?? '',
      telefono: map['telefono'] as String? ?? '',
      email: map['email'] as String? ?? '',
      citta: map['citta'] as String? ?? '',
      indirizzo: map['indirizzo'] as String? ?? '',
      docTipo: map['docTipo'] as String? ?? '',
      docNumero: map['docNumero'] as String? ?? '',
      dataNascita: dateTimeFrom(map['dataNascita']),
      note: map['note'] as String? ?? '',
      adozioniIds: (map['adozioniIds'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      affidabilita: Affidabilita.parse(map['affidabilita'] as String?),
      audit: Audit.fromMap(map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'cognome': cognome,
      'telefono': telefono,
      'email': email,
      'citta': citta,
      'indirizzo': indirizzo,
      'docTipo': docTipo,
      'docNumero': docNumero,
      'dataNascita': dateTimeTo(dataNascita),
      'note': note,
      'adozioniIds': adozioniIds,
      'affidabilita': affidabilita.wire,
      ...audit.toMap(),
    };
  }

  Adopter withAdozioneId(String adoptionId, {Audit? audit}) {
    if (adozioniIds.contains(adoptionId)) {
      return this;
    }
    return Adopter(
      id: id,
      nome: nome,
      cognome: cognome,
      telefono: telefono,
      email: email,
      citta: citta,
      indirizzo: indirizzo,
      docTipo: docTipo,
      docNumero: docNumero,
      dataNascita: dataNascita,
      note: note,
      adozioniIds: [...adozioniIds, adoptionId],
      affidabilita: affidabilita,
      audit: audit ?? this.audit,
    );
  }
}
