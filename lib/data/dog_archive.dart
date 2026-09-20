import 'models/dog.dart';
import 'models/enums.dart';

const storicoStatiMax = 30;

/// Stati di uscita: la scheda resta consultabile solo in archivio.
bool statoArchiviaScheda(DogStato stato) {
  return switch (stato) {
    DogStato.adottato ||
    DogStato.deceduto ||
    DogStato.trasferito ||
    DogStato.restituito =>
      true,
    _ => false,
  };
}

/// Archivio = flag esplicito oppure stato di uscita (deceduto, adottato, …).
bool dogInArchivio(Dog dog) {
  return dog.archiviato || statoArchiviaScheda(dog.stato);
}

/// Archiviati, adottati, deceduti e trasferiti non occupano posti né conteggi rifugio.
bool dogEsclusoDaConteggiRifugio(Dog dog) {
  return dogInArchivio(dog);
}

List<StatoVoce> appendStoricoStato(List<StatoVoce> storico, StatoVoce voce) {
  final next = [...storico, voce]..sort((a, b) => b.dal.compareTo(a.dal));
  if (next.length <= storicoStatiMax) {
    return next;
  }
  return next.take(storicoStatiMax).toList();
}

Dog applyArchivia({
  required Dog dog,
  required String autoreId,
  required DateTime now,
}) {
  if (dog.archiviato) {
    return dog;
  }
  final voce = StatoVoce(
    stato: dog.stato,
    dal: now,
    note: 'Scheda archiviata',
    autoreId: autoreId,
  );
  return dog.copyWith(
    archiviato: true,
    storicoStati: appendStoricoStato(dog.storicoStati, voce),
    audit: dog.audit.touched(autoreId, now),
  );
}

Dog applyRipristina({
  required Dog dog,
  required String autoreId,
  required DateTime now,
}) {
  if (!dogInArchivio(dog)) {
    return dog;
  }
  final voce = StatoVoce(
    stato: DogStato.inRifugio,
    dal: now,
    note: 'Scheda ripristinata',
    autoreId: autoreId,
  );
  return dog.copyWith(
    archiviato: false,
    stato: DogStato.inRifugio,
    statoDal: now,
    storicoStati: appendStoricoStato(dog.storicoStati, voce),
    audit: dog.audit.touched(autoreId, now),
  );
}
