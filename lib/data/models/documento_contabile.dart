import '../../core/firestore_codec.dart';

enum TipologiaContabile {
  fattura,
  scontrino,
  ricevuta,
  preventivo,
  altro;

  String get wire => name;

  String get etichetta {
    return switch (this) {
      TipologiaContabile.fattura => 'Fattura',
      TipologiaContabile.scontrino => 'Scontrino',
      TipologiaContabile.ricevuta => 'Ricevuta',
      TipologiaContabile.preventivo => 'Preventivo',
      TipologiaContabile.altro => 'Altro',
    };
  }

  static TipologiaContabile parse(String? raw) {
    return TipologiaContabile.values
            .where((value) => value.wire == raw)
            .firstOrNull ??
        TipologiaContabile.altro;
  }
}

class AnnoContabile {
  const AnnoContabile({
    required this.id,
    required this.anno,
    required this.audit,
  });

  final String id;
  final int anno;
  final Audit audit;

  factory AnnoContabile.fromMap(String id, Map<String, dynamic> map) {
    return AnnoContabile(
      id: id,
      anno: (numberFrom(map['anno']) ?? 0).toInt(),
      audit: Audit.fromMap(map),
    );
  }

  Map<String, dynamic> toMap() {
    return {'anno': anno, ...audit.toMap()};
  }

  AnnoContabile copyWith({String? id, int? anno, Audit? audit}) {
    return AnnoContabile(
      id: id ?? this.id,
      anno: anno ?? this.anno,
      audit: audit ?? this.audit,
    );
  }
}

class DocumentoContabile {
  const DocumentoContabile({
    required this.id,
    required this.anno,
    required this.nome,
    required this.data,
    required this.tipologia,
    required this.descrizione,
    required this.importo,
    required this.mime,
    required this.nomeFile,
    required this.dimensione,
    required this.chunkCount,
    required this.generation,
    required this.audit,
  });

  final String id;
  final int anno;
  final String nome;
  final DateTime data;
  final TipologiaContabile tipologia;
  final String descrizione;
  final double? importo;
  final String mime;
  final String nomeFile;
  final int dimensione;
  final int chunkCount;
  final int generation;
  final Audit audit;

  factory DocumentoContabile.fromMap(String id, Map<String, dynamic> map) {
    return DocumentoContabile(
      id: id,
      anno: (numberFrom(map['anno']) ?? 0).toInt(),
      nome: map['nome'] as String? ?? '',
      data: dateTimeRequired(map['data']),
      tipologia: TipologiaContabile.parse(map['tipologia'] as String?),
      descrizione: map['descrizione'] as String? ?? '',
      importo: numberFrom(map['importo']),
      mime: map['mime'] as String? ?? '',
      nomeFile: map['nomeFile'] as String? ?? '',
      dimensione: (numberFrom(map['dimensione']) ?? 0).toInt(),
      chunkCount: (numberFrom(map['chunkCount']) ?? 0).toInt(),
      generation: (numberFrom(map['generation']) ?? 0).toInt(),
      audit: Audit.fromMap(map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'anno': anno,
      'nome': nome,
      'data': dateTimeTo(data),
      'tipologia': tipologia.wire,
      'descrizione': descrizione,
      if (importo != null) 'importo': importo,
      'mime': mime,
      'nomeFile': nomeFile,
      'dimensione': dimensione,
      'chunkCount': chunkCount,
      'generation': generation,
      ...audit.toMap(),
    };
  }

  DocumentoContabile copyWith({
    String? id,
    int? anno,
    String? nome,
    DateTime? data,
    TipologiaContabile? tipologia,
    String? descrizione,
    double? importo,
    bool clearImporto = false,
    String? mime,
    String? nomeFile,
    int? dimensione,
    int? chunkCount,
    int? generation,
    Audit? audit,
  }) {
    return DocumentoContabile(
      id: id ?? this.id,
      anno: anno ?? this.anno,
      nome: nome ?? this.nome,
      data: data ?? this.data,
      tipologia: tipologia ?? this.tipologia,
      descrizione: descrizione ?? this.descrizione,
      importo: clearImporto ? null : importo ?? this.importo,
      mime: mime ?? this.mime,
      nomeFile: nomeFile ?? this.nomeFile,
      dimensione: dimensione ?? this.dimensione,
      chunkCount: chunkCount ?? this.chunkCount,
      generation: generation ?? this.generation,
      audit: audit ?? this.audit,
    );
  }
}
