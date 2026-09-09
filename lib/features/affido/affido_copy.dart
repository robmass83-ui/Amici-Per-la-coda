import '../../core/format_it.dart';
import '../../data/documents/template_assets.dart';
import '../../data/models/adoption.dart';
import '../../data/models/enums.dart';

String moduloShareText({
  required String templateId,
  required String adopterNome,
  required String dogNome,
}) {
  final quale = templateId == templateAdozioneId
      ? 'di adozione'
      : 'di preaffido';
  final chi = adopterNome.trim().isEmpty ? '' : adopterNome.trim();
  final cane = dogNome.trim().isEmpty ? 'il cane' : dogNome.trim();
  final ciao = chi.isEmpty ? 'Ciao' : 'Ciao $chi';
  return '$ciao, in allegato il modulo $quale per $cane. '
      'Compilalo, firmalo e rimandacelo quando puoi. Grazie! — Amici per la Coda';
}

String moduloInviatoEtichetta({
  required String moduloId,
  required DateTime data,
  required String volontarioNome,
}) {
  final quale = moduloId == templateAdozioneId ? 'adozione' : 'preaffido';
  final chi = volontarioNome.trim().isEmpty ? 'volontario' : volontarioNome.trim();
  return 'Modulo $quale inviato il ${formatItalianDate(data)} da $chi · in attesa di ritorno';
}

AdoptionStatoVoce? latestModuloInviato(
  Adoption adoption, {
  String? moduloId,
}) {
  for (final voce in adoption.storicoStati.reversed) {
    if (!voce.isModuloInviato) {
      continue;
    }
    if (moduloId == null || voce.moduloId == moduloId) {
      return voce;
    }
  }
  return null;
}

DocumentTipo signedTipoOf(String templateId) {
  return templateId == templateAdozioneId
      ? DocumentTipo.adozioneFirmato
      : DocumentTipo.preaffidoFirmato;
}

String signedNomeOf(String templateId) {
  return templateId == templateAdozioneId
      ? 'Modulo di adozione firmato'
      : 'Modulo di preaffido firmato';
}
