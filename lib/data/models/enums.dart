T enumByWire<T extends Enum>(
  List<T> values,
  String Function(T value) wireOf,
  String? raw,
  T fallback,
) {
  return enumByWireOrNull(values, wireOf, raw) ?? fallback;
}

T? enumByWireOrNull<T extends Enum>(
  List<T> values,
  String Function(T value) wireOf,
  String? raw,
) {
  if (raw == null) {
    return null;
  }
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  for (final value in values) {
    if (wireOf(value) == trimmed) {
      return value;
    }
  }
  return null;
}

enum DogSex {
  F,
  M;

  String get wire => name;
  static DogSex parse(String? raw) =>
      enumByWire(values, (v) => v.wire, raw, DogSex.M);
}

enum Taglia {
  piccola,
  media,
  grande;

  String get wire => name;
  static Taglia parse(String? raw) =>
      enumByWire(values, (v) => v.wire, raw, Taglia.media);
}

enum TipoPelo {
  corto,
  medio,
  lungo,
  nonIndicato;

  String get wire => switch (this) {
    corto => 'corto',
    medio => 'medio',
    lungo => 'lungo',
    nonIndicato => 'non_indicato',
  };

  static TipoPelo? parseOrNull(String? raw) =>
      enumByWireOrNull(values, (v) => v.wire, raw);
}

enum Purezza {
  meticcio,
  inPurezza;

  String get wire => switch (this) {
    meticcio => 'meticcio',
    inPurezza => 'in_purezza',
  };

  static Purezza? parseOrNull(String? raw) =>
      enumByWireOrNull(values, (v) => v.wire, raw);
}

enum IscrittoAnagrafe {
  si,
  no,
  daVerificare;

  String get wire => switch (this) {
    si => 'si',
    no => 'no',
    daVerificare => 'da_verificare',
  };

  static IscrittoAnagrafe parse(String? raw) =>
      enumByWire(values, (v) => v.wire, raw, IscrittoAnagrafe.daVerificare);
}

enum ModalitaIngresso {
  vagante,
  sequestro,
  rinuncia,
  natoInRifugio,
  trasferimento;

  String get wire => switch (this) {
    vagante => 'vagante',
    sequestro => 'sequestro',
    rinuncia => 'rinuncia',
    natoInRifugio => 'nato_in_rifugio',
    trasferimento => 'trasferimento',
  };

  static ModalitaIngresso parse(String? raw) =>
      enumByWire(values, (v) => v.wire, raw, ModalitaIngresso.vagante);

  static ModalitaIngresso? parseOrNull(String? raw) =>
      enumByWireOrNull(values, (v) => v.wire, raw);
}

enum DogStato {
  inRifugio,
  inStallo,
  preaffido,
  adottato,
  inCura,
  restituito,
  deceduto,
  trasferito;

  String get wire => switch (this) {
    inRifugio => 'in_rifugio',
    inStallo => 'in_stallo',
    preaffido => 'preaffido',
    adottato => 'adottato',
    inCura => 'in_cura',
    restituito => 'restituito',
    deceduto => 'deceduto',
    trasferito => 'trasferito',
  };

  static DogStato parse(String? raw) =>
      enumByWire(values, (v) => v.wire, raw, DogStato.inRifugio);
}

enum ConPersone {
  moltoSocievole,
  selettivo,
  diffidente;

  String get wire => switch (this) {
    moltoSocievole => 'molto_socievole',
    selettivo => 'selettivo',
    diffidente => 'diffidente',
  };

  static ConPersone parse(String? raw) =>
      enumByWire(values, (v) => v.wire, raw, ConPersone.selettivo);

  static ConPersone? parseOrNull(String? raw) =>
      enumByWireOrNull(values, (v) => v.wire, raw);
}

enum ConCani {
  si,
  selettivo,
  no,
  daTestare;

  String get wire => switch (this) {
    si => 'si',
    selettivo => 'selettivo',
    no => 'no',
    daTestare => 'da_testare',
  };

  static ConCani parse(String? raw) =>
      enumByWire(values, (v) => v.wire, raw, ConCani.daTestare);
}

enum ConGatti {
  si,
  no,
  daTestare;

  String get wire => switch (this) {
    si => 'si',
    no => 'no',
    daTestare => 'da_testare',
  };

  static ConGatti parse(String? raw) =>
      enumByWire(values, (v) => v.wire, raw, ConGatti.daTestare);
}

enum ConBambini {
  si,
  soloGrandi,
  no,
  daTestare;

  String get wire => switch (this) {
    si => 'si',
    soloGrandi => 'solo_grandi',
    no => 'no',
    daTestare => 'da_testare',
  };

  static ConBambini parse(String? raw) =>
      enumByWire(values, (v) => v.wire, raw, ConBambini.daTestare);
}

enum HealthTipo {
  vaccino,
  sterilizzazione,
  sverminazione,
  antiparassitario,
  visita,
  esame,
  terapia,
  altro;

  String get wire => name;
  static HealthTipo parse(String? raw) =>
      enumByWire(values, (v) => v.wire, raw, HealthTipo.altro);
}

enum ExpenseCategoria {
  visita,
  sterilizzazione,
  farmaci,
  esami,
  cibo,
  altro;

  String get wire => name;
  static ExpenseCategoria parse(String? raw) =>
      enumByWire(values, (v) => v.wire, raw, ExpenseCategoria.altro);
}

enum AdoptionStato {
  ricevuta,
  colloquio,
  visita,
  preaffido,
  adottato,
  respinta,
  ritirata;

  String get wire => name;
  static AdoptionStato parse(String? raw) =>
      enumByWire(values, (v) => v.wire, raw, AdoptionStato.ricevuta);
}

enum DocumentTipo {
  libretto,
  anagrafe,
  verbale,
  preaffido,
  adozione,
  microchip,
  preaffidoFirmato,
  adozioneFirmato,
  documentoIdentita,
  altro;

  String get wire => switch (this) {
    libretto => 'libretto',
    anagrafe => 'anagrafe',
    verbale => 'verbale',
    preaffido => 'preaffido',
    adozione => 'adozione',
    microchip => 'microchip',
    preaffidoFirmato => 'preaffido_firmato',
    adozioneFirmato => 'adozione_firmato',
    documentoIdentita => 'documento_identita',
    altro => 'altro',
  };

  static DocumentTipo parse(String? raw) =>
      enumByWire(values, (v) => v.wire, raw, DocumentTipo.altro);
}

enum NoteTipo {
  generale,
  comportamento,
  alimentazione,
  attenzione;

  String get wire => name;
  static NoteTipo parse(String? raw) =>
      enumByWire(values, (v) => v.wire, raw, NoteTipo.generale);
}

enum AppointmentTipo {
  visita,
  colloquio,
  verificaPreaffido,
  scadenza,
  altro;

  String get wire => switch (this) {
    visita => 'visita',
    colloquio => 'colloquio',
    verificaPreaffido => 'verifica_preaffido',
    scadenza => 'scadenza',
    altro => 'altro',
  };

  static AppointmentTipo parse(String? raw) =>
      enumByWire(values, (v) => v.wire, raw, AppointmentTipo.altro);
}

enum AppointmentStato {
  previsto,
  fatto,
  annullato;

  String get wire => name;
  static AppointmentStato parse(String? raw) =>
      enumByWire(values, (v) => v.wire, raw, AppointmentStato.previsto);
}

enum BoxTipo {
  normale,
  degenza,
  isolamento,
  quarantena;

  String get wire => name;
  static BoxTipo parse(String? raw) =>
      enumByWire(values, (v) => v.wire, raw, BoxTipo.normale);
}

enum VolunteerRuolo {
  presidente,
  referente,
  volontario;

  String get wire => name;
  static VolunteerRuolo parse(String? raw) =>
      enumByWire(values, (v) => v.wire, raw, VolunteerRuolo.volontario);
}

enum Affidabilita {
  ok,
  daVerificare,
  nonIdoneo;

  String get wire => switch (this) {
    ok => 'ok',
    daVerificare => 'da_verificare',
    nonIdoneo => 'non_idoneo',
  };

  static Affidabilita parse(String? raw) =>
      enumByWire(values, (v) => v.wire, raw, Affidabilita.daVerificare);
}

enum VendorTipo {
  veterinario,
  clinica,
  farmacia,
  negozio,
  toelettatura,
  altro;

  String get wire => name;
  static VendorTipo parse(String? raw) =>
      enumByWire(values, (v) => v.wire, raw, VendorTipo.altro);
}

enum TemplateVisibilita {
  home,
  scheda,
  entrambi,
  nessuna;

  String get wire => name;

  static TemplateVisibilita parse(String? raw) =>
      enumByWire(values, (v) => v.wire, raw, TemplateVisibilita.entrambi);

  bool get inHome => this == home || this == entrambi;

  bool get inScheda => this == scheda || this == entrambi;
}
