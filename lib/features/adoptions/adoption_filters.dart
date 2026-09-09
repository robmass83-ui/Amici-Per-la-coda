import '../../data/models/adoption.dart';
import '../../data/models/enums.dart';

enum AdoptionQuickFilter { tutte, daValutare, colloquio, preaffido, concluse }

const adoptionFilterLabels = <String>[
  'Tutte',
  'Da val.',
  'Colloq.',
  'Preaff.',
  'Chiuse',
];

bool adoptionMatchesFilter(Adoption adoption, AdoptionQuickFilter filter) {
  return switch (filter) {
    AdoptionQuickFilter.tutte => true,
    AdoptionQuickFilter.daValutare => adoption.stato == AdoptionStato.ricevuta,
    AdoptionQuickFilter.colloquio =>
      adoption.stato == AdoptionStato.colloquio ||
          adoption.stato == AdoptionStato.visita,
    AdoptionQuickFilter.preaffido => adoption.stato == AdoptionStato.preaffido,
    AdoptionQuickFilter.concluse =>
      adoption.stato == AdoptionStato.adottato ||
          adoption.stato == AdoptionStato.respinta ||
          adoption.stato == AdoptionStato.ritirata,
  };
}

List<Adoption> filterAdoptions(
  List<Adoption> adoptions,
  AdoptionQuickFilter filter,
) {
  final filtered = adoptions
      .where((item) => adoptionMatchesFilter(item, filter))
      .toList();
  filtered.sort((a, b) => b.dataRichiesta.compareTo(a.dataRichiesta));
  return filtered;
}

int countAdoptionsForFilter(
  List<Adoption> adoptions,
  AdoptionQuickFilter filter,
) {
  return adoptions.where((item) => adoptionMatchesFilter(item, filter)).length;
}

String adoptionResultCountLabel(int count) {
  if (count == 0) {
    return 'Nessuna richiesta';
  }
  if (count == 1) {
    return '1 richiesta';
  }
  return '$count richieste';
}
