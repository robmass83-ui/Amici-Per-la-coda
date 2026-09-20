import '../../core/format_it.dart';
import '../../data/documents/template_assets.dart';
import '../../data/models/adoption.dart';
import '../../data/models/enums.dart';

String moduloShareText({
  required String templateId,
  required String adopterNome,
  required String dogNome,
  String? templateNome,
}) {
  final quale = switch (templateId) {
    templateAdozioneId => 'di adozione',
    templatePreaffidoId => 'di preaffido',
    _ => () {
      final nome = (templateNome ?? '').trim();
      if (nome.isEmpty) {
        return '';
      }
      return '«$nome»';
    }(),
  };
  final chi = adopterNome.trim().isEmpty ? '' : adopterNome.trim();
  final cane = dogNome.trim();
  final ciao = chi.isEmpty ? 'Ciao' : 'Ciao $chi';
  final qualePart = quale.isEmpty ? '' : ' $quale';
  final perCane = cane.isEmpty ? '' : ' per $cane';
  return '$ciao, in allegato il modulo$qualePart$perCane. '
      'Compilalo, firmalo e rimandacelo quando puoi. Grazie! — Amici per la Coda';
}

String moduloInviatoEtichetta({
  required String moduloId,
  required DateTime data,
  required String volontarioNome,
  String? templateNome,
}) {
  final quale = switch (moduloId) {
    templateAdozioneId => 'adozione',
    templatePreaffidoId => 'preaffido',
    _ => (templateNome ?? '').trim().isEmpty
        ? 'modulo'
        : (templateNome ?? '').trim(),
  };
  final chi = volontarioNome.trim().isEmpty
      ? 'volontario'
      : volontarioNome.trim();
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
