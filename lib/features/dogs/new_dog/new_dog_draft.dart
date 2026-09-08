import '../../../data/models/enums.dart';

enum WizardSterilizzazione { si, no, programmata }

enum WizardAdottabile { si, nonAncora, nonAdottabile }

class PendingTreatment {
  const PendingTreatment({
    required this.tipo,
    required this.data,
    required this.descrizione,
    this.veterinario = '',
    this.lotto = '',
    this.prossimaScadenza,
    this.costo,
  });

  final HealthTipo tipo;
  final DateTime data;
  final String descrizione;
  final String veterinario;
  final String lotto;
  final DateTime? prossimaScadenza;
  final double? costo;

  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo.wire,
      'data': data.toIso8601String(),
      'descrizione': descrizione,
      'veterinario': veterinario,
      'lotto': lotto,
      'prossimaScadenza': prossimaScadenza?.toIso8601String(),
      'costo': costo,
    };
  }

  factory PendingTreatment.fromMap(Map<String, dynamic> map) {
    return PendingTreatment(
      tipo: HealthTipo.parse(map['tipo'] as String?),
      data: DateTime.parse(map['data'] as String),
      descrizione: map['descrizione'] as String? ?? '',
      veterinario: map['veterinario'] as String? ?? '',
      lotto: map['lotto'] as String? ?? '',
      prossimaScadenza: _dateFrom(map['prossimaScadenza']),
      costo: (map['costo'] as num?)?.toDouble(),
    );
  }
}

class NewDogDraft {
  const NewDogDraft({
    this.step = 0,
    this.nome = '',
    this.sesso = DogSex.F,
    this.dataNascita,
    this.nascitaPresunta = true,
    this.razza = '',
    this.taglia = Taglia.media,
    this.pesoText = '',
    this.mantello = '',
    this.microchip = '',
    this.iscrittoAnagrafe = IscrittoAnagrafe.daVerificare,
    this.provenienza = '',
    this.modalitaIngresso = ModalitaIngresso.vagante,
    this.dataIngresso,
    this.settore = '',
    this.box = '',
    this.slogan = '',
    this.descrizione = '',
    this.carattere = const [],
    this.conPersone = ConPersone.selettivo,
    this.conCani = ConCani.daTestare,
    this.conGatti = ConGatti.daTestare,
    this.conBambini = ConBambini.daTestare,
    this.noteCarattere = '',
    this.coverIndex = 0,
    this.sterilizzazione = WizardSterilizzazione.no,
    this.dataSterilizzazione,
    this.trattamenti = const [],
    this.testEffettuati = const [],
    this.terapieInCorso = '',
    this.adottabile = WizardAdottabile.nonAncora,
    this.pubblicato = false,
    this.referenteId,
  });

  final int step;
  final String nome;
  final DogSex sesso;
  final DateTime? dataNascita;
  final bool nascitaPresunta;
  final String razza;
  final Taglia taglia;
  final String pesoText;
  final String mantello;
  final String microchip;
  final IscrittoAnagrafe iscrittoAnagrafe;
  final String provenienza;
  final ModalitaIngresso modalitaIngresso;
  final DateTime? dataIngresso;
  final String settore;
  final String box;
  final String slogan;
  final String descrizione;
  final List<String> carattere;
  final ConPersone conPersone;
  final ConCani conCani;
  final ConGatti conGatti;
  final ConBambini conBambini;
  final String noteCarattere;
  final int coverIndex;
  final WizardSterilizzazione sterilizzazione;
  final DateTime? dataSterilizzazione;
  final List<PendingTreatment> trattamenti;
  final List<String> testEffettuati;
  final String terapieInCorso;
  final WizardAdottabile adottabile;
  final bool pubblicato;
  final String? referenteId;

  bool get sterilizzato => sterilizzazione == WizardSterilizzazione.si;

  bool get adottabileFlag => adottabile == WizardAdottabile.si;

  NewDogDraft copyWith({
    int? step,
    String? nome,
    DogSex? sesso,
    DateTime? dataNascita,
    bool clearDataNascita = false,
    bool? nascitaPresunta,
    String? razza,
    Taglia? taglia,
    String? pesoText,
    String? mantello,
    String? microchip,
    IscrittoAnagrafe? iscrittoAnagrafe,
    String? provenienza,
    ModalitaIngresso? modalitaIngresso,
    DateTime? dataIngresso,
    bool clearDataIngresso = false,
    String? settore,
    String? box,
    String? slogan,
    String? descrizione,
    List<String>? carattere,
    ConPersone? conPersone,
    ConCani? conCani,
    ConGatti? conGatti,
    ConBambini? conBambini,
    String? noteCarattere,
    int? coverIndex,
    WizardSterilizzazione? sterilizzazione,
    DateTime? dataSterilizzazione,
    bool clearDataSterilizzazione = false,
    List<PendingTreatment>? trattamenti,
    List<String>? testEffettuati,
    String? terapieInCorso,
    WizardAdottabile? adottabile,
    bool? pubblicato,
    String? referenteId,
    bool clearReferenteId = false,
  }) {
    return NewDogDraft(
      step: step ?? this.step,
      nome: nome ?? this.nome,
      sesso: sesso ?? this.sesso,
      dataNascita: clearDataNascita ? null : (dataNascita ?? this.dataNascita),
      nascitaPresunta: nascitaPresunta ?? this.nascitaPresunta,
      razza: razza ?? this.razza,
      taglia: taglia ?? this.taglia,
      pesoText: pesoText ?? this.pesoText,
      mantello: mantello ?? this.mantello,
      microchip: microchip ?? this.microchip,
      iscrittoAnagrafe: iscrittoAnagrafe ?? this.iscrittoAnagrafe,
      provenienza: provenienza ?? this.provenienza,
      modalitaIngresso: modalitaIngresso ?? this.modalitaIngresso,
      dataIngresso: clearDataIngresso
          ? null
          : (dataIngresso ?? this.dataIngresso),
      settore: settore ?? this.settore,
      box: box ?? this.box,
      slogan: slogan ?? this.slogan,
      descrizione: descrizione ?? this.descrizione,
      carattere: carattere ?? this.carattere,
      conPersone: conPersone ?? this.conPersone,
      conCani: conCani ?? this.conCani,
      conGatti: conGatti ?? this.conGatti,
      conBambini: conBambini ?? this.conBambini,
      noteCarattere: noteCarattere ?? this.noteCarattere,
      coverIndex: coverIndex ?? this.coverIndex,
      sterilizzazione: sterilizzazione ?? this.sterilizzazione,
      dataSterilizzazione: clearDataSterilizzazione
          ? null
          : (dataSterilizzazione ?? this.dataSterilizzazione),
      trattamenti: trattamenti ?? this.trattamenti,
      testEffettuati: testEffettuati ?? this.testEffettuati,
      terapieInCorso: terapieInCorso ?? this.terapieInCorso,
      adottabile: adottabile ?? this.adottabile,
      pubblicato: pubblicato ?? this.pubblicato,
      referenteId: clearReferenteId ? null : (referenteId ?? this.referenteId),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'step': step,
      'nome': nome,
      'sesso': sesso.wire,
      'dataNascita': dataNascita?.toIso8601String(),
      'nascitaPresunta': nascitaPresunta,
      'razza': razza,
      'taglia': taglia.wire,
      'pesoText': pesoText,
      'mantello': mantello,
      'microchip': microchip,
      'iscrittoAnagrafe': iscrittoAnagrafe.wire,
      'provenienza': provenienza,
      'modalitaIngresso': modalitaIngresso.wire,
      'dataIngresso': dataIngresso?.toIso8601String(),
      'settore': settore,
      'box': box,
      'slogan': slogan,
      'descrizione': descrizione,
      'carattere': carattere,
      'conPersone': conPersone.wire,
      'conCani': conCani.wire,
      'conGatti': conGatti.wire,
      'conBambini': conBambini.wire,
      'noteCarattere': noteCarattere,
      'coverIndex': coverIndex,
      'sterilizzazione': sterilizzazione.name,
      'dataSterilizzazione': dataSterilizzazione?.toIso8601String(),
      'trattamenti': trattamenti.map((item) => item.toMap()).toList(),
      'testEffettuati': testEffettuati,
      'terapieInCorso': terapieInCorso,
      'adottabile': adottabile.name,
      'pubblicato': pubblicato,
      'referenteId': referenteId,
    };
  }

  factory NewDogDraft.fromMap(Map<String, dynamic> map) {
    final trattamentiRaw = map['trattamenti'] as List<dynamic>? ?? const [];
    return NewDogDraft(
      step: (map['step'] as num?)?.toInt() ?? 0,
      nome: map['nome'] as String? ?? '',
      sesso: DogSex.parse(map['sesso'] as String?),
      dataNascita: _dateFrom(map['dataNascita']),
      nascitaPresunta: map['nascitaPresunta'] as bool? ?? true,
      razza: map['razza'] as String? ?? '',
      taglia: Taglia.parse(map['taglia'] as String?),
      pesoText: map['pesoText'] as String? ?? '',
      mantello: map['mantello'] as String? ?? '',
      microchip: map['microchip'] as String? ?? '',
      iscrittoAnagrafe: IscrittoAnagrafe.parse(
        map['iscrittoAnagrafe'] as String?,
      ),
      provenienza: map['provenienza'] as String? ?? '',
      modalitaIngresso: ModalitaIngresso.parse(
        map['modalitaIngresso'] as String?,
      ),
      dataIngresso: _dateFrom(map['dataIngresso']),
      settore: map['settore'] as String? ?? '',
      box: map['box'] as String? ?? '',
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
      coverIndex: (map['coverIndex'] as num?)?.toInt() ?? 0,
      sterilizzazione: _sterilizzazioneFrom(map['sterilizzazione'] as String?),
      dataSterilizzazione: _dateFrom(map['dataSterilizzazione']),
      trattamenti: trattamentiRaw
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (item) => PendingTreatment.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList(),
      testEffettuati: (map['testEffettuati'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      terapieInCorso: map['terapieInCorso'] as String? ?? '',
      adottabile: _adottabileFrom(map['adottabile'] as String?),
      pubblicato: map['pubblicato'] as bool? ?? false,
      referenteId: map['referenteId'] as String?,
    );
  }
}

DateTime? _dateFrom(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

WizardSterilizzazione _sterilizzazioneFrom(String? raw) {
  return switch (raw) {
    'si' => WizardSterilizzazione.si,
    'programmata' => WizardSterilizzazione.programmata,
    _ => WizardSterilizzazione.no,
  };
}

WizardAdottabile _adottabileFrom(String? raw) {
  return switch (raw) {
    'si' => WizardAdottabile.si,
    'nonAdottabile' => WizardAdottabile.nonAdottabile,
    _ => WizardAdottabile.nonAncora,
  };
}
