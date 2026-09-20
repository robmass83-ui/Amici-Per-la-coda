import '../../core/firestore_codec.dart';
import 'enums.dart';

class StatoVoce {
  const StatoVoce({
    required this.stato,
    required this.dal,
    required this.note,
    required this.autoreId,
    this.strutturaDestinazione,
  });

  final DogStato stato;
  final DateTime dal;
  final String note;
  final String autoreId;
  final String? strutturaDestinazione;

  factory StatoVoce.fromMap(Map<String, dynamic> map) {
    final dest = (map['strutturaDestinazione'] as String?)?.trim();
    return StatoVoce(
      stato: DogStato.parse(map['stato'] as String?),
      dal: dateTimeRequired(map['dal']),
      note: map['note'] as String? ?? '',
      autoreId: map['autoreId'] as String? ?? '',
      strutturaDestinazione: (dest == null || dest.isEmpty) ? null : dest,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stato': stato.wire,
      'dal': dateTimeTo(dal),
      'note': note,
      'autoreId': autoreId,
      'strutturaDestinazione': strutturaDestinazione,
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
    this.modalitaIngresso,
    required this.dataIngresso,
    required this.settore,
    required this.box,
    required this.stato,
    required this.statoDal,
    this.adottabile,
    this.sterilizzato,
    required this.dataSterilizzazione,
    required this.slogan,
    required this.descrizione,
    required this.carattere,
    this.conPersone,
    required this.conCani,
    required this.conGatti,
    required this.conBambini,
    required this.noteCarattere,
    required this.fotoCopertinaId,
    this.fotoCount = 0,
    required this.referenteId,
    required this.pubblicato,
    required this.dataPubblicazione,
    required this.archiviato,
    required this.storicoStati,
    this.patologie = '',
    this.tipoPelo,
    this.purezza,
    this.dataApplicazioneChip,
    this.zonaApplicazioneChip = '',
    this.veterinarioApplicatore = '',
    this.dataIscrizioneAnagrafe,
    this.ultimaUbicazione = '',
    this.dataIngressoStimata = false,
    required this.audit,
  });

  final String id;
  final String nome;
  final DogSex? sesso;
  final DateTime? dataNascita;
  final bool nascitaPresunta;
  final String razza;
  final Taglia taglia;
  final double? pesoKg;
  final String mantello;
  final String microchip;
  final IscrittoAnagrafe iscrittoAnagrafe;
  final String provenienza;
  final ModalitaIngresso? modalitaIngresso;
  final DateTime dataIngresso;
  final String settore;
  final String box;
  final DogStato stato;
  final DateTime statoDal;
  final bool? adottabile;
  final bool? sterilizzato;
  final DateTime? dataSterilizzazione;
  final String slogan;
  final String descrizione;
  final List<String> carattere;
  final ConPersone? conPersone;
  final ConCani conCani;
  final ConGatti conGatti;
  final ConBambini conBambini;
  final String noteCarattere;
  final String? fotoCopertinaId;
  final int fotoCount;
  final String? referenteId;
  final bool pubblicato;
  final DateTime? dataPubblicazione;
  final bool archiviato;
  final List<StatoVoce> storicoStati;
  final String patologie;
  final TipoPelo? tipoPelo;
  final Purezza? purezza;
  final DateTime? dataApplicazioneChip;
  final String zonaApplicazioneChip;
  final String veterinarioApplicatore;
  final DateTime? dataIscrizioneAnagrafe;
  final String ultimaUbicazione;
  final bool dataIngressoStimata;
  final Audit audit;

  factory Dog.fromMap(String id, Map<String, dynamic> map) {
    final storico = (map['storicoStati'] as List<dynamic>? ?? const [])
        .whereType<Map<dynamic, dynamic>>()
        .map((item) => StatoVoce.fromMap(Map<String, dynamic>.from(item)))
        .toList();
    return Dog(
      id: id,
      nome: map['nome'] as String? ?? '',
      sesso: _sessoFromMap(map['sesso']),
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
      modalitaIngresso: ModalitaIngresso.parseOrNull(
        map['modalitaIngresso'] as String?,
      ),
      dataIngresso: dateTimeRequired(map['dataIngresso']),
      settore: map['settore'] as String? ?? '',
      box: map['box'] as String? ?? '',
      stato: DogStato.parse(map['stato'] as String?),
      statoDal: dateTimeRequired(map['statoDal']),
      adottabile: map['adottabile'] as bool?,
      sterilizzato: map['sterilizzato'] as bool?,
      dataSterilizzazione: dateTimeFrom(map['dataSterilizzazione']),
      slogan: map['slogan'] as String? ?? '',
      descrizione: map['descrizione'] as String? ?? '',
      carattere: (map['carattere'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      conPersone: ConPersone.parseOrNull(map['conPersone'] as String?),
      conCani: ConCani.parse(map['conCani'] as String?),
      conGatti: ConGatti.parse(map['conGatti'] as String?),
      conBambini: ConBambini.parse(map['conBambini'] as String?),
      noteCarattere: map['noteCarattere'] as String? ?? '',
      fotoCopertinaId: map['fotoCopertinaId'] as String?,
      fotoCount: intFrom(map['fotoCount']),
      referenteId: map['referenteId'] as String?,
      pubblicato: map['pubblicato'] as bool? ?? false,
      dataPubblicazione: dateTimeFrom(map['dataPubblicazione']),
      archiviato: map['archiviato'] as bool? ?? false,
      storicoStati: storico,
      patologie: map['patologie'] as String? ?? '',
      tipoPelo: TipoPelo.parseOrNull(map['tipoPelo'] as String?),
      purezza: Purezza.parseOrNull(map['purezza'] as String?),
      dataApplicazioneChip: dateTimeFrom(map['dataApplicazioneChip']),
      zonaApplicazioneChip: map['zonaApplicazioneChip'] as String? ?? '',
      veterinarioApplicatore: map['veterinarioApplicatore'] as String? ?? '',
      dataIscrizioneAnagrafe: dateTimeFrom(map['dataIscrizioneAnagrafe']),
      ultimaUbicazione: map['ultimaUbicazione'] as String? ?? '',
      dataIngressoStimata: map['dataIngressoStimata'] as bool? ?? false,
      audit: Audit.fromMap(map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'sesso': sesso?.wire,
      'dataNascita': dateTimeTo(dataNascita),
      'nascitaPresunta': nascitaPresunta,
      'razza': razza,
      'taglia': taglia.wire,
      'pesoKg': pesoKg,
      'mantello': mantello,
      'microchip': microchip,
      'iscrittoAnagrafe': iscrittoAnagrafe.wire,
      'provenienza': provenienza,
      'modalitaIngresso': modalitaIngresso?.wire,
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
      'conPersone': conPersone?.wire,
      'conCani': conCani.wire,
      'conGatti': conGatti.wire,
      'conBambini': conBambini.wire,
      'noteCarattere': noteCarattere,
      'fotoCopertinaId': fotoCopertinaId,
      'fotoCount': fotoCount,
      'referenteId': referenteId,
      'pubblicato': pubblicato,
      'dataPubblicazione': dateTimeTo(dataPubblicazione),
      'archiviato': archiviato,
      'storicoStati': storicoStati.map((item) => item.toMap()).toList(),
      'patologie': patologie,
      'tipoPelo': tipoPelo?.wire,
      'purezza': purezza?.wire,
      'dataApplicazioneChip': dateTimeTo(dataApplicazioneChip),
      'zonaApplicazioneChip': zonaApplicazioneChip,
      'veterinarioApplicatore': veterinarioApplicatore,
      'dataIscrizioneAnagrafe': dateTimeTo(dataIscrizioneAnagrafe),
      'ultimaUbicazione': ultimaUbicazione,
      'dataIngressoStimata': dataIngressoStimata,
      ...audit.toMap(),
    };
  }

  Dog withFotoCopertinaId(String? id) {
    return copyWith(
      fotoCopertinaId: id,
      clearFotoCopertinaId: id == null,
    );
  }

  Dog withPesoKg(double? kg, {Audit? audit}) {
    return copyWith(
      pesoKg: kg,
      clearPesoKg: kg == null,
      audit: audit,
    );
  }

  Dog withStato({
    required DogStato stato,
    required DateTime statoDal,
    required List<StatoVoce> storicoStati,
    Audit? audit,
  }) {
    return copyWith(
      stato: stato,
      statoDal: statoDal,
      storicoStati: storicoStati,
      audit: audit,
    );
  }

  Dog copyWith({
    String? id,
    String? nome,
    DogSex? sesso,
    bool clearSesso = false,
    DateTime? dataNascita,
    bool clearDataNascita = false,
    bool? nascitaPresunta,
    String? razza,
    Taglia? taglia,
    double? pesoKg,
    bool clearPesoKg = false,
    String? mantello,
    String? microchip,
    IscrittoAnagrafe? iscrittoAnagrafe,
    String? provenienza,
    ModalitaIngresso? modalitaIngresso,
    bool clearModalitaIngresso = false,
    DateTime? dataIngresso,
    String? settore,
    String? box,
    DogStato? stato,
    DateTime? statoDal,
    bool? adottabile,
    bool clearAdottabile = false,
    bool? sterilizzato,
    bool clearSterilizzato = false,
    DateTime? dataSterilizzazione,
    bool clearDataSterilizzazione = false,
    String? slogan,
    String? descrizione,
    List<String>? carattere,
    ConPersone? conPersone,
    bool clearConPersone = false,
    ConCani? conCani,
    ConGatti? conGatti,
    ConBambini? conBambini,
    String? noteCarattere,
    String? fotoCopertinaId,
    bool clearFotoCopertinaId = false,
    int? fotoCount,
    String? referenteId,
    bool clearReferenteId = false,
    bool? pubblicato,
    DateTime? dataPubblicazione,
    bool clearDataPubblicazione = false,
    bool? archiviato,
    List<StatoVoce>? storicoStati,
    String? patologie,
    TipoPelo? tipoPelo,
    bool clearTipoPelo = false,
    Purezza? purezza,
    bool clearPurezza = false,
    DateTime? dataApplicazioneChip,
    bool clearDataApplicazioneChip = false,
    String? zonaApplicazioneChip,
    String? veterinarioApplicatore,
    DateTime? dataIscrizioneAnagrafe,
    bool clearDataIscrizioneAnagrafe = false,
    String? ultimaUbicazione,
    bool? dataIngressoStimata,
    Audit? audit,
  }) {
    return Dog(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      sesso: clearSesso ? null : (sesso ?? this.sesso),
      dataNascita: clearDataNascita
          ? null
          : (dataNascita ?? this.dataNascita),
      nascitaPresunta: nascitaPresunta ?? this.nascitaPresunta,
      razza: razza ?? this.razza,
      taglia: taglia ?? this.taglia,
      pesoKg: clearPesoKg ? null : (pesoKg ?? this.pesoKg),
      mantello: mantello ?? this.mantello,
      microchip: microchip ?? this.microchip,
      iscrittoAnagrafe: iscrittoAnagrafe ?? this.iscrittoAnagrafe,
      provenienza: provenienza ?? this.provenienza,
      modalitaIngresso: clearModalitaIngresso
          ? null
          : (modalitaIngresso ?? this.modalitaIngresso),
      dataIngresso: dataIngresso ?? this.dataIngresso,
      settore: settore ?? this.settore,
      box: box ?? this.box,
      stato: stato ?? this.stato,
      statoDal: statoDal ?? this.statoDal,
      adottabile: clearAdottabile ? null : (adottabile ?? this.adottabile),
      sterilizzato: clearSterilizzato
          ? null
          : (sterilizzato ?? this.sterilizzato),
      dataSterilizzazione: clearDataSterilizzazione
          ? null
          : (dataSterilizzazione ?? this.dataSterilizzazione),
      slogan: slogan ?? this.slogan,
      descrizione: descrizione ?? this.descrizione,
      carattere: carattere ?? this.carattere,
      conPersone: clearConPersone ? null : (conPersone ?? this.conPersone),
      conCani: conCani ?? this.conCani,
      conGatti: conGatti ?? this.conGatti,
      conBambini: conBambini ?? this.conBambini,
      noteCarattere: noteCarattere ?? this.noteCarattere,
      fotoCopertinaId: clearFotoCopertinaId
          ? null
          : (fotoCopertinaId ?? this.fotoCopertinaId),
      fotoCount: fotoCount ?? this.fotoCount,
      referenteId: clearReferenteId
          ? null
          : (referenteId ?? this.referenteId),
      pubblicato: pubblicato ?? this.pubblicato,
      dataPubblicazione: clearDataPubblicazione
          ? null
          : (dataPubblicazione ?? this.dataPubblicazione),
      archiviato: archiviato ?? this.archiviato,
      storicoStati: storicoStati ?? this.storicoStati,
      patologie: patologie ?? this.patologie,
      tipoPelo: clearTipoPelo ? null : (tipoPelo ?? this.tipoPelo),
      purezza: clearPurezza ? null : (purezza ?? this.purezza),
      dataApplicazioneChip: clearDataApplicazioneChip
          ? null
          : (dataApplicazioneChip ?? this.dataApplicazioneChip),
      zonaApplicazioneChip:
          zonaApplicazioneChip ?? this.zonaApplicazioneChip,
      veterinarioApplicatore:
          veterinarioApplicatore ?? this.veterinarioApplicatore,
      dataIscrizioneAnagrafe: clearDataIscrizioneAnagrafe
          ? null
          : (dataIscrizioneAnagrafe ?? this.dataIscrizioneAnagrafe),
      ultimaUbicazione: ultimaUbicazione ?? this.ultimaUbicazione,
      dataIngressoStimata: dataIngressoStimata ?? this.dataIngressoStimata,
      audit: audit ?? this.audit,
    );
  }

  Dog withAdottabile(bool adottabile, {Audit? audit}) {
    return copyWith(adottabile: adottabile, audit: audit);
  }
}

DogSex? _sessoFromMap(dynamic raw) {
  if (raw == null) {
    return null;
  }
  if (raw is! String) {
    return null;
  }
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return DogSex.parse(trimmed);
}
