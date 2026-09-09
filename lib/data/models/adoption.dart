import '../../core/firestore_codec.dart';
import 'enums.dart';

class Richiedente {
  const Richiedente({
    required this.nome,
    required this.cognome,
    required this.telefono,
    required this.email,
    required this.citta,
    required this.indirizzo,
    required this.docTipo,
    required this.docNumero,
    required this.eta,
  });

  final String nome;
  final String cognome;
  final String telefono;
  final String email;
  final String citta;
  final String indirizzo;
  final String docTipo;
  final String docNumero;
  final int eta;

  factory Richiedente.fromMap(Map<String, dynamic>? map) {
    final data = map ?? const <String, dynamic>{};
    return Richiedente(
      nome: data['nome'] as String? ?? '',
      cognome: data['cognome'] as String? ?? '',
      telefono: data['telefono'] as String? ?? '',
      email: data['email'] as String? ?? '',
      citta: data['citta'] as String? ?? '',
      indirizzo: data['indirizzo'] as String? ?? '',
      docTipo: data['docTipo'] as String? ?? '',
      docNumero: data['docNumero'] as String? ?? '',
      eta: intFrom(data['eta']),
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
      'eta': eta,
    };
  }

  String get nomeCompleto => '$nome $cognome'.trim();
}

class Questionario {
  const Questionario({
    required this.abitazione,
    required this.giardinoRecintato,
    required this.altezzaRecinzione,
    required this.altriAnimali,
    required this.bambini,
    required this.oreDaSolo,
    required this.esperienzaCani,
    required this.doveDormira,
    required this.note,
  });

  final String abitazione;
  final bool giardinoRecintato;
  final String altezzaRecinzione;
  final String altriAnimali;
  final String bambini;
  final String oreDaSolo;
  final String esperienzaCani;
  final String doveDormira;
  final String note;

  factory Questionario.fromMap(Map<String, dynamic>? map) {
    final data = map ?? const <String, dynamic>{};
    return Questionario(
      abitazione: data['abitazione'] as String? ?? '',
      giardinoRecintato: data['giardinoRecintato'] as bool? ?? false,
      altezzaRecinzione: data['altezzaRecinzione'] as String? ?? '',
      altriAnimali: data['altriAnimali'] as String? ?? '',
      bambini: data['bambini'] as String? ?? '',
      oreDaSolo: data['oreDaSolo'] as String? ?? '',
      esperienzaCani: data['esperienzaCani'] as String? ?? '',
      doveDormira: data['doveDormira'] as String? ?? '',
      note: data['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'abitazione': abitazione,
      'giardinoRecintato': giardinoRecintato,
      'altezzaRecinzione': altezzaRecinzione,
      'altriAnimali': altriAnimali,
      'bambini': bambini,
      'oreDaSolo': oreDaSolo,
      'esperienzaCani': esperienzaCani,
      'doveDormira': doveDormira,
      'note': note,
    };
  }
}

class AdoptionStatoVoce {
  const AdoptionStatoVoce({
    required this.stato,
    required this.data,
    required this.note,
    required this.autoreId,
  });

  final AdoptionStato stato;
  final DateTime data;
  final String note;
  final String autoreId;

  factory AdoptionStatoVoce.fromMap(Map<String, dynamic> map) {
    return AdoptionStatoVoce(
      stato: AdoptionStato.parse(map['stato'] as String?),
      data: dateTimeRequired(map['data']),
      note: map['note'] as String? ?? '',
      autoreId: map['autoreId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stato': stato.wire,
      'data': dateTimeTo(data),
      'note': note,
      'autoreId': autoreId,
    };
  }
}

class Adoption {
  const Adoption({
    required this.id,
    required this.dogId,
    this.adopterId = '',
    required this.richiedente,
    required this.questionario,
    required this.stato,
    required this.storicoStati,
    required this.preaffidoDal,
    required this.preaffidoAl,
    required this.referenteId,
    required this.dataRichiesta,
    required this.audit,
  });

  final String id;
  final String dogId;
  final String adopterId;
  final Richiedente richiedente;
  final Questionario questionario;
  final AdoptionStato stato;
  final List<AdoptionStatoVoce> storicoStati;
  final DateTime? preaffidoDal;
  final DateTime? preaffidoAl;
  final String referenteId;
  final DateTime dataRichiesta;
  final Audit audit;

  factory Adoption.fromMap(String id, Map<String, dynamic> map) {
    final storico = (map['storicoStati'] as List<dynamic>? ?? const [])
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (item) => AdoptionStatoVoce.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList();
    return Adoption(
      id: id,
      dogId: map['dogId'] as String? ?? '',
      adopterId: map['adopterId'] as String? ?? '',
      richiedente: Richiedente.fromMap(
        map['richiedente'] is Map
            ? Map<String, dynamic>.from(map['richiedente'] as Map)
            : null,
      ),
      questionario: Questionario.fromMap(
        map['questionario'] is Map
            ? Map<String, dynamic>.from(map['questionario'] as Map)
            : null,
      ),
      stato: AdoptionStato.parse(map['stato'] as String?),
      storicoStati: storico,
      preaffidoDal: dateTimeFrom(map['preaffidoDal']),
      preaffidoAl: dateTimeFrom(map['preaffidoAl']),
      referenteId: map['referenteId'] as String? ?? '',
      dataRichiesta: dateTimeRequired(map['dataRichiesta']),
      audit: Audit.fromMap(map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dogId': dogId,
      'adopterId': adopterId,
      'richiedente': richiedente.toMap(),
      'questionario': questionario.toMap(),
      'stato': stato.wire,
      'storicoStati': storicoStati.map((item) => item.toMap()).toList(),
      'preaffidoDal': dateTimeTo(preaffidoDal),
      'preaffidoAl': dateTimeTo(preaffidoAl),
      'referenteId': referenteId,
      'dataRichiesta': dateTimeTo(dataRichiesta),
      ...audit.toMap(),
    };
  }

  Adoption withQuestionario(Questionario questionario, {Audit? audit}) {
    return Adoption(
      id: id,
      dogId: dogId,
      adopterId: adopterId,
      richiedente: richiedente,
      questionario: questionario,
      stato: stato,
      storicoStati: storicoStati,
      preaffidoDal: preaffidoDal,
      preaffidoAl: preaffidoAl,
      referenteId: referenteId,
      dataRichiesta: dataRichiesta,
      audit: audit ?? this.audit,
    );
  }

  Adoption withWorkflow({
    required AdoptionStato stato,
    required List<AdoptionStatoVoce> storicoStati,
    DateTime? preaffidoDal,
    DateTime? preaffidoAl,
    Audit? audit,
  }) {
    return Adoption(
      id: id,
      dogId: dogId,
      adopterId: adopterId,
      richiedente: richiedente,
      questionario: questionario,
      stato: stato,
      storicoStati: storicoStati,
      preaffidoDal: preaffidoDal ?? this.preaffidoDal,
      preaffidoAl: preaffidoAl ?? this.preaffidoAl,
      referenteId: referenteId,
      dataRichiesta: dataRichiesta,
      audit: audit ?? this.audit,
    );
  }
}
