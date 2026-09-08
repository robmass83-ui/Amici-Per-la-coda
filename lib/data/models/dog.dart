import '../../core/firestore_codec.dart';
import 'enums.dart';

class StatoVoce {
  const StatoVoce({
    required this.stato,
    required this.dal,
    required this.note,
    required this.autoreId,
  });

  final DogStato stato;
  final DateTime dal;
  final String note;
  final String autoreId;

  factory StatoVoce.fromMap(Map<String, dynamic> map) {
    return StatoVoce(
      stato: DogStato.parse(map['stato'] as String?),
      dal: dateTimeRequired(map['dal']),
      note: map['note'] as String? ?? '',
      autoreId: map['autoreId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stato': stato.wire,
      'dal': dateTimeTo(dal),
      'note': note,
      'autoreId': autoreId,
    };
  }
}

class Dog {
  const Dog({
    required this.id,
    required this.nome,
    required this.sesso,
    required this.dataNascita,
    required this.nascitaPresunta,
    required this.razza,
    required this.taglia,
    required this.pesoKg,
    required this.mantello,
    required this.microchip,
    required this.iscrittoAnagrafe,
    required this.provenienza,
    required this.modalitaIngresso,
    required this.dataIngresso,
    required this.settore,
    required this.box,
    required this.stato,
    required this.statoDal,
    required this.adottabile,
    required this.sterilizzato,
    required this.dataSterilizzazione,
    required this.slogan,
    required this.descrizione,
    required this.carattere,
    required this.conPersone,
    required this.conCani,
    required this.conGatti,
    required this.conBambini,
    required this.noteCarattere,
    required this.fotoCopertinaId,
    required this.referenteId,
    required this.pubblicato,
    required this.dataPubblicazione,
    required this.archiviato,
    required this.storicoStati,
    required this.audit,
  });

  final String id;
  final String nome;
  final DogSex sesso;
  final DateTime? dataNascita;
  final bool nascitaPresunta;
  final String razza;
  final Taglia taglia;
  final double? pesoKg;
  final String mantello;
  final String microchip;
  final IscrittoAnagrafe iscrittoAnagrafe;
  final String provenienza;
  final ModalitaIngresso modalitaIngresso;
  final DateTime dataIngresso;
  final String settore;
  final String box;
  final DogStato stato;
  final DateTime statoDal;
  final bool adottabile;
  final bool sterilizzato;
  final DateTime? dataSterilizzazione;
  final String slogan;
  final String descrizione;
  final List<String> carattere;
  final ConPersone conPersone;
  final ConCani conCani;
  final ConGatti conGatti;
  final ConBambini conBambini;
  final String noteCarattere;
  final String? fotoCopertinaId;
  final String? referenteId;
  final bool pubblicato;
  final DateTime? dataPubblicazione;
  final bool archiviato;
  final List<StatoVoce> storicoStati;
  final Audit audit;

  factory Dog.fromMap(String id, Map<String, dynamic> map) {
    final storico = (map['storicoStati'] as List<dynamic>? ?? const [])
        .whereType<Map<dynamic, dynamic>>()
        .map((item) => StatoVoce.fromMap(Map<String, dynamic>.from(item)))
        .toList();
    return Dog(
      id: id,
      nome: map['nome'] as String? ?? '',
      sesso: DogSex.parse(map['sesso'] as String?),
      dataNascita: dateTimeFrom(map['dataNascita']),
      nascitaPresunta: map['nascitaPresunta'] as bool? ?? false,
      razza: map['razza'] as String? ?? '',
      taglia: Taglia.parse(map['taglia'] as String?),
      pesoKg: numberFrom(map['pesoKg']),
      mantello: map['mantello'] as String? ?? '',
      microchip: map['microchip'] as String? ?? '',
      iscrittoAnagrafe: IscrittoAnagrafe.parse(
        map['iscrittoAnagrafe'] as String?,
      ),
      provenienza: map['provenienza'] as String? ?? '',
      modalitaIngresso: ModalitaIngresso.parse(
        map['modalitaIngresso'] as String?,
      ),
      dataIngresso: dateTimeRequired(map['dataIngresso']),
      settore: map['settore'] as String? ?? '',
      box: map['box'] as String? ?? '',
      stato: DogStato.parse(map['stato'] as String?),
      statoDal: dateTimeRequired(map['statoDal']),
      adottabile: map['adottabile'] as bool? ?? false,
      sterilizzato: map['sterilizzato'] as bool? ?? false,
      dataSterilizzazione: dateTimeFrom(map['dataSterilizzazione']),
      slogan: map['slogan'] as String? ?? '',
      descrizione: map['descrizione'] as String? ?? '',
      carattere: (map['carattere'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      conPersone: ConPersone.parse(map['conPersone'] as String?),
      conCani: ConCani.parse(map['conCani'] as String?),
      conGatti: ConGatti.parse(map['conGatti'] as String?),
      conBambini: ConBambini.parse(map['conBambini'] as String?),
      noteCarattere: map['noteCarattere'] as String? ?? '',
      fotoCopertinaId: map['fotoCopertinaId'] as String?,
      referenteId: map['referenteId'] as String?,
      pubblicato: map['pubblicato'] as bool? ?? false,
      dataPubblicazione: dateTimeFrom(map['dataPubblicazione']),
      archiviato: map['archiviato'] as bool? ?? false,
      storicoStati: storico,
      audit: Audit.fromMap(map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'sesso': sesso.wire,
      'dataNascita': dateTimeTo(dataNascita),
      'nascitaPresunta': nascitaPresunta,
      'razza': razza,
      'taglia': taglia.wire,
      'pesoKg': pesoKg,
      'mantello': mantello,
      'microchip': microchip,
      'iscrittoAnagrafe': iscrittoAnagrafe.wire,
      'provenienza': provenienza,
      'modalitaIngresso': modalitaIngresso.wire,
      'dataIngresso': dateTimeTo(dataIngresso),
      'settore': settore,
      'box': box,
      'stato': stato.wire,
      'statoDal': dateTimeTo(statoDal),
      'adottabile': adottabile,
      'sterilizzato': sterilizzato,
      'dataSterilizzazione': dateTimeTo(dataSterilizzazione),
      'slogan': slogan,
      'descrizione': descrizione,
      'carattere': carattere,
      'conPersone': conPersone.wire,
      'conCani': conCani.wire,
      'conGatti': conGatti.wire,
      'conBambini': conBambini.wire,
      'noteCarattere': noteCarattere,
      'fotoCopertinaId': fotoCopertinaId,
      'referenteId': referenteId,
      'pubblicato': pubblicato,
      'dataPubblicazione': dateTimeTo(dataPubblicazione),
      'archiviato': archiviato,
      'storicoStati': storicoStati.map((item) => item.toMap()).toList(),
      ...audit.toMap(),
    };
  }

  Dog withFotoCopertinaId(String? id) {
    return Dog(
      id: this.id,
      nome: nome,
      sesso: sesso,
      dataNascita: dataNascita,
      nascitaPresunta: nascitaPresunta,
      razza: razza,
      taglia: taglia,
      pesoKg: pesoKg,
      mantello: mantello,
      microchip: microchip,
      iscrittoAnagrafe: iscrittoAnagrafe,
      provenienza: provenienza,
      modalitaIngresso: modalitaIngresso,
      dataIngresso: dataIngresso,
      settore: settore,
      box: box,
      stato: stato,
      statoDal: statoDal,
      adottabile: adottabile,
      sterilizzato: sterilizzato,
      dataSterilizzazione: dataSterilizzazione,
      slogan: slogan,
      descrizione: descrizione,
      carattere: carattere,
      conPersone: conPersone,
      conCani: conCani,
      conGatti: conGatti,
      conBambini: conBambini,
      noteCarattere: noteCarattere,
      fotoCopertinaId: id,
      referenteId: referenteId,
      pubblicato: pubblicato,
      dataPubblicazione: dataPubblicazione,
      archiviato: archiviato,
      storicoStati: storicoStati,
      audit: audit,
    );
  }

  Dog withPesoKg(double? kg, {Audit? audit}) {
    return Dog(
      id: id,
      nome: nome,
      sesso: sesso,
      dataNascita: dataNascita,
      nascitaPresunta: nascitaPresunta,
      razza: razza,
      taglia: taglia,
      pesoKg: kg,
      mantello: mantello,
      microchip: microchip,
      iscrittoAnagrafe: iscrittoAnagrafe,
      provenienza: provenienza,
      modalitaIngresso: modalitaIngresso,
      dataIngresso: dataIngresso,
      settore: settore,
      box: box,
      stato: stato,
      statoDal: statoDal,
      adottabile: adottabile,
      sterilizzato: sterilizzato,
      dataSterilizzazione: dataSterilizzazione,
      slogan: slogan,
      descrizione: descrizione,
      carattere: carattere,
      conPersone: conPersone,
      conCani: conCani,
      conGatti: conGatti,
      conBambini: conBambini,
      noteCarattere: noteCarattere,
      fotoCopertinaId: fotoCopertinaId,
      referenteId: referenteId,
      pubblicato: pubblicato,
      dataPubblicazione: dataPubblicazione,
      archiviato: archiviato,
      storicoStati: storicoStati,
      audit: audit ?? this.audit,
    );
  }

  Dog withStato({
    required DogStato stato,
    required DateTime statoDal,
    required List<StatoVoce> storicoStati,
    Audit? audit,
  }) {
    return Dog(
      id: id,
      nome: nome,
      sesso: sesso,
      dataNascita: dataNascita,
      nascitaPresunta: nascitaPresunta,
      razza: razza,
      taglia: taglia,
      pesoKg: pesoKg,
      mantello: mantello,
      microchip: microchip,
      iscrittoAnagrafe: iscrittoAnagrafe,
      provenienza: provenienza,
      modalitaIngresso: modalitaIngresso,
      dataIngresso: dataIngresso,
      settore: settore,
      box: box,
      stato: stato,
      statoDal: statoDal,
      adottabile: adottabile,
      sterilizzato: sterilizzato,
      dataSterilizzazione: dataSterilizzazione,
      slogan: slogan,
      descrizione: descrizione,
      carattere: carattere,
      conPersone: conPersone,
      conCani: conCani,
      conGatti: conGatti,
      conBambini: conBambini,
      noteCarattere: noteCarattere,
      fotoCopertinaId: fotoCopertinaId,
      referenteId: referenteId,
      pubblicato: pubblicato,
      dataPubblicazione: dataPubblicazione,
      archiviato: archiviato,
      storicoStati: storicoStati,
      audit: audit ?? this.audit,
    );
  }
}
