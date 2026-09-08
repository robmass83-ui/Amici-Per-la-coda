import '../../core/format_it.dart';
import '../../data/models/adoption.dart';
import '../../data/models/dog.dart';
import '../../data/models/enums.dart';

class DogAdoptionStatusView {
  const DogAdoptionStatusView({
    required this.preaffido,
    required this.dataAdozione,
    required this.famiglia,
  });

  final String preaffido;
  final String dataAdozione;
  final String famiglia;
}

DogAdoptionStatusView dogAdoptionStatusView(Dog dog, List<Adoption> adoptions) {
  Adoption? latestWith(AdoptionStato stato) {
    final matches = adoptions.where((item) => item.stato == stato).toList();
    if (matches.isEmpty) {
      return null;
    }
    matches.sort((a, b) => b.dataRichiesta.compareTo(a.dataRichiesta));
    return matches.first;
  }

  final preaffidoRec = latestWith(AdoptionStato.preaffido);
  final adottatoRec = latestWith(AdoptionStato.adottato);

  String preaffidoText() {
    if (preaffidoRec != null) {
      final dal = preaffidoRec.preaffidoDal;
      return dal == null ? 'Sì' : formatItalianDate(dal);
    }
    if (dog.stato == DogStato.preaffido) {
      return formatItalianDate(dog.statoDal);
    }
    return '—';
  }

  String dataAdozioneText() {
    if (adottatoRec != null) {
      for (final voce in adottatoRec.storicoStati.reversed) {
        if (voce.stato == AdoptionStato.adottato) {
          return formatItalianDate(voce.data);
        }
      }
      return formatItalianDate(adottatoRec.audit.updatedAt);
    }
    if (dog.stato == DogStato.adottato) {
      return formatItalianDate(dog.statoDal);
    }
    return '—';
  }

  String famigliaText() {
    final rec = adottatoRec ?? preaffidoRec;
    if (rec == null) {
      return '—';
    }
    final name = '${rec.richiedente.nome} ${rec.richiedente.cognome}'.trim();
    return name.isEmpty ? '—' : name;
  }

  return DogAdoptionStatusView(
    preaffido: preaffidoText(),
    dataAdozione: dataAdozioneText(),
    famiglia: famigliaText(),
  );
}
