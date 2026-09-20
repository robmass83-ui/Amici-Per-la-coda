import '../../core/firestore_codec.dart';

class AssociationSettings {
  const AssociationSettings({
    required this.denominazione,
    required this.codiceFiscale,
    required this.sede,
    required this.capienzaAutorizzata,
    required this.logoB64,
    required this.audit,
    this.telefono = '',
    this.email = '',
    this.notificheScadenzeSanitarie = true,
    this.notificheNuoveRichieste = true,
    this.notificheScadenzaPreaffidi = true,
    this.notificheRiepilogoSettimanale = false,
    this.ultimoExportAt,
  });

  final String denominazione;
  final String codiceFiscale;
  final String sede;
  final int capienzaAutorizzata;
  final String? logoB64;
  final String telefono;
  final String email;
  final Audit audit;
  final bool notificheScadenzeSanitarie;
  final bool notificheNuoveRichieste;
  final bool notificheScadenzaPreaffidi;
  final bool notificheRiepilogoSettimanale;
  final DateTime? ultimoExportAt;

  factory AssociationSettings.fromMap(Map<String, dynamic> map) {
    final raw = map['notifiche'];
    final notifiche = raw is Map
        ? Map<String, dynamic>.from(raw)
        : const <String, dynamic>{};
    return AssociationSettings(
      denominazione: map['denominazione'] as String? ?? '',
      codiceFiscale: map['codiceFiscale'] as String? ?? '',
      sede: map['sede'] as String? ?? '',
      capienzaAutorizzata: intFrom(map['capienzaAutorizzata']),
      logoB64: map['logoB64'] as String?,
      telefono: map['telefono'] as String? ?? '',
      email: map['email'] as String? ?? '',
      audit: Audit.fromMap(map),
      notificheScadenzeSanitarie: boolFrom(
        notifiche['scadenzeSanitarie'],
        fallback: true,
      ),
      notificheNuoveRichieste: boolFrom(
        notifiche['nuoveRichieste'],
        fallback: true,
      ),
      notificheScadenzaPreaffidi: boolFrom(
        notifiche['scadenzaPreaffidi'],
        fallback: true,
      ),
      notificheRiepilogoSettimanale: boolFrom(
        notifiche['riepilogoSettimanale'],
      ),
      ultimoExportAt: dateTimeFrom(map['ultimoExportAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'denominazione': denominazione,
      'codiceFiscale': codiceFiscale,
      'sede': sede,
      'capienzaAutorizzata': capienzaAutorizzata,
      'logoB64': logoB64,
      'telefono': telefono,
      'email': email,
      'notifiche': {
        'scadenzeSanitarie': notificheScadenzeSanitarie,
        'nuoveRichieste': notificheNuoveRichieste,
        'scadenzaPreaffidi': notificheScadenzaPreaffidi,
        'riepilogoSettimanale': notificheRiepilogoSettimanale,
      },
      'ultimoExportAt': dateTimeTo(ultimoExportAt),
      ...audit.toMap(),
    };
  }

  AssociationSettings copyWith({
    String? denominazione,
    String? codiceFiscale,
    String? sede,
    int? capienzaAutorizzata,
    String? logoB64,
    bool clearLogo = false,
    String? telefono,
    String? email,
    Audit? audit,
    bool? notificheScadenzeSanitarie,
    bool? notificheNuoveRichieste,
    bool? notificheScadenzaPreaffidi,
    bool? notificheRiepilogoSettimanale,
    DateTime? ultimoExportAt,
    bool clearUltimoExport = false,
  }) {
    return AssociationSettings(
      denominazione: denominazione ?? this.denominazione,
      codiceFiscale: codiceFiscale ?? this.codiceFiscale,
      sede: sede ?? this.sede,
      capienzaAutorizzata: capienzaAutorizzata ?? this.capienzaAutorizzata,
      logoB64: clearLogo ? null : (logoB64 ?? this.logoB64),
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      audit: audit ?? this.audit,
      notificheScadenzeSanitarie:
          notificheScadenzeSanitarie ?? this.notificheScadenzeSanitarie,
      notificheNuoveRichieste:
          notificheNuoveRichieste ?? this.notificheNuoveRichieste,
      notificheScadenzaPreaffidi:
          notificheScadenzaPreaffidi ?? this.notificheScadenzaPreaffidi,
      notificheRiepilogoSettimanale:
          notificheRiepilogoSettimanale ?? this.notificheRiepilogoSettimanale,
      ultimoExportAt: clearUltimoExport
          ? null
          : (ultimoExportAt ?? this.ultimoExportAt),
    );
  }
}
