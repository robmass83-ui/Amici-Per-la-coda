import '../../../data/models/enums.dart';
import 'adoption_profile.dart';

String testoPostAdozione(AdoptionProfile profile) {
  final nome = profile.nome;
  final eta = profile.etaTesto == '—' ? '' : profile.etaTesto;
  final taglia = _taglia(profile.taglia);
  final lineaEta = [
    if (eta.isNotEmpty) eta,
    if (taglia.isNotEmpty) 'Taglia ${taglia.toLowerCase()}',
  ].join(' · ');
  final carattere = profile.carattere.take(2).join(', ');
  final sterile = profile.isFemmina ? 'Sterilizzata' : 'Castrato';
  final vaccino = profile.isFemmina ? 'vaccinata' : 'vaccinato';
  final sanitario = profile.vaccinatoInRegola && profile.sterilizzato
      ? '$sterile e $vaccino'
      : (profile.sterilizzato ? sterile : '');
  final telefono = profile.associazione.telefono.trim();
  final citta = profile.associazione.citta.trim();
  final slugCitta = citta
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9àèéìòù]+'), '')
      .replaceAll(RegExp(r'[àá]'), 'a')
      .replaceAll(RegExp(r'[èé]'), 'e')
      .replaceAll(RegExp(r'[ìí]'), 'i')
      .replaceAll(RegExp(r'[òó]'), 'o')
      .replaceAll(RegExp(r'[ùú]'), 'u');
  final hashCitta = slugCitta.isEmpty ? '' : '#$slugCitta';
  return [
    nome,
    if (lineaEta.isNotEmpty) lineaEta,
    if (carattere.isNotEmpty) carattere,
    if (sanitario.isNotEmpty) sanitario,
    if (telefono.isNotEmpty) 'Per informazioni: $telefono',
    ['#adozione', if (hashCitta.isNotEmpty) hashCitta, '#amiciperlacoda']
        .join(' '),
  ].join('\n');
}

String truncateStory(String text, {int maxChars = 220}) {
  final t = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (t.length <= maxChars) {
    return t;
  }
  final cut = t.substring(0, maxChars);
  final lastDot = cut.lastIndexOf('.');
  if (lastDot >= 80) {
    return cut.substring(0, lastDot + 1);
  }
  return '$cut…';
}

String _taglia(Taglia taglia) {
  return switch (taglia) {
    Taglia.piccola => 'Piccola',
    Taglia.media => 'Media',
    Taglia.grande => 'Grande',
  };
}

String fileNameSchedaPdf(String nome) {
  return 'Scheda-${_filePart(nome)}-AmiciPerLaCoda.pdf';
}

String fileNameCardJpeg(String nome) {
  return '${_filePart(nome)}-AmiciPerLaCoda.jpg';
}

String _filePart(String nome) {
  final cleaned = nome.replaceAll(RegExp(r'[^\wàèéìòùÀÈÉÌÒÙ \-]+'), '').trim();
  if (cleaned.isEmpty) {
    return 'Cane';
  }
  return cleaned.replaceAll(RegExp(r'\s+'), '-');
}
