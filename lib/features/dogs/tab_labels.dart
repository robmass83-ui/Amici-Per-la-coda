import '../../data/models/enums.dart';
import '../../data/models/volunteer.dart';

String adoptionStatoLabel(AdoptionStato stato) {
  return switch (stato) {
    AdoptionStato.ricevuta => 'Ricevuta',
    AdoptionStato.colloquio => 'Colloquio',
    AdoptionStato.visita => 'Visita',
    AdoptionStato.preaffido => 'Preaffido',
    AdoptionStato.adottato => 'Adottato',
    AdoptionStato.respinta => 'Respinta',
    AdoptionStato.ritirata => 'Ritirata',
  };
}

String documentTipoLabel(DocumentTipo tipo) {
  return switch (tipo) {
    DocumentTipo.libretto => 'Libretto sanitario',
    DocumentTipo.anagrafe => 'Iscrizione anagrafe',
    DocumentTipo.verbale => 'Verbale di recupero',
    DocumentTipo.preaffido => 'Modulo di preaffido',
    DocumentTipo.adozione => 'Contratto di adozione',
    DocumentTipo.microchip => 'Passaggio microchip',
    DocumentTipo.preaffidoFirmato => 'Preaffido firmato',
    DocumentTipo.adozioneFirmato => 'Adozione firmata',
    DocumentTipo.documentoIdentita => 'Documento d\'identità',
    DocumentTipo.altro => 'Documento',
  };
}

String noteTipoLabel(NoteTipo tipo) {
  return switch (tipo) {
    NoteTipo.generale => 'Generale',
    NoteTipo.comportamento => 'Comportamento',
    NoteTipo.alimentazione => 'Alimentazione',
    NoteTipo.attenzione => 'Attenzione',
  };
}

String volunteerNomeDi(List<Volunteer> volunteers, String id) {
  for (final volunteer in volunteers) {
    if (volunteer.id == id) {
      return volunteer.nome;
    }
  }
  return '';
}

String autoreEtichetta(List<Volunteer> volunteers, String id) {
  final nome = volunteerNomeDi(volunteers, id);
  return nome.isEmpty ? 'Volontario' : nome;
}
