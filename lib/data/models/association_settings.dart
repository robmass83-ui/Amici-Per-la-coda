import '../../core/firestore_codec.dart';

class AssociationSettings {
  const AssociationSettings({
    required this.denominazione,
    required this.codiceFiscale,
    required this.sede,
    required this.capienzaAutorizzata,
    required this.logoB64,
    required this.audit,
  });

  final String denominazione;
  final String codiceFiscale;
  final String sede;
  final int capienzaAutorizzata;
  final String? logoB64;
  final Audit audit;

  factory AssociationSettings.fromMap(Map<String, dynamic> map) {
    return AssociationSettings(
      denominazione: map['denominazione'] as String? ?? '',
      codiceFiscale: map['codiceFiscale'] as String? ?? '',
      sede: map['sede'] as String? ?? '',
      capienzaAutorizzata: intFrom(map['capienzaAutorizzata']),
      logoB64: map['logoB64'] as String?,
      audit: Audit.fromMap(map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'denominazione': denominazione,
      'codiceFiscale': codiceFiscale,
      'sede': sede,
      'capienzaAutorizzata': capienzaAutorizzata,
      'logoB64': logoB64,
      ...audit.toMap(),
    };
  }
}
