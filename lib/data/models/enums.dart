T enumByWire<T extends Enum>(
  List<T> values,
  String Function(T value) wireOf,
  String? raw,
  T fallback,
) {
  if (raw == null) {
    return fallback;
  }
  for (final value in values) {
    if (wireOf(value) == raw) {
      return value;
    }
  }
  return fallback;
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
}

enum DogStato {
  inRifugio,
  inStallo,
  preaffido,
  adottato,
  inCura,
  restituito,
  deceduto;

  String get wire => switch (this) {
    inRifugio => 'in_rifugio',
    inStallo => 'in_stallo',
    preaffido => 'preaffido',
    adottato => 'adottato',
    inCura => 'in_cura',
    restituito => 'restituito',
    deceduto => 'deceduto',
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
  turno,
  verificaPreaffido,
  scadenza,
  altro;

  String get wire => switch (this) {
    visita => 'visita',
    colloquio => 'colloquio',
    turno => 'turno',
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
