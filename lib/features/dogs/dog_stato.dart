import '../../core/firestore_codec.dart';
import '../../data/dog_archive.dart';
import '../../data/models/dog.dart';
import '../../data/models/enums.dart';

export '../../data/dog_archive.dart';

/// Transizione ammessa: qualsiasi stato diverso da quello attuale.
bool statoTransitionAllowed(DogStato from, DogStato to) {
  return from != to;
}

bool statoRequiresConfirmation(DogStato to) {
  return to == DogStato.adottato || to == DogStato.deceduto;
}

Dog applyDogStato({
  required Dog dog,
  required DogStato stato,
  required DateTime dal,
  required String note,
  required String autoreId,
  required DateTime now,
  String? strutturaDestinazione,
}) {
  if (!statoTransitionAllowed(dog.stato, stato)) {
    throw ArgumentError('Transizione non ammessa');
  }
  String? dest;
  if (stato == DogStato.trasferito) {
    dest = strutturaDestinazione?.trim();
    if (dest == null || dest.isEmpty) {
      throw ArgumentError('Indica la struttura di destinazione.');
    }
  }
  final voce = StatoVoce(
    stato: stato,
    dal: dal,
    note: note.trim(),
    autoreId: autoreId,
    strutturaDestinazione: dest,
  );
  return dog
      .withStato(
        stato: stato,
        statoDal: dal,
        storicoStati: appendStoricoStato(dog.storicoStati, voce),
        audit: Audit(
          createdAt: dog.audit.createdAt,
          createdBy: dog.audit.createdBy,
          updatedAt: now,
          updatedBy: autoreId,
        ),
      )
      .copyWith(archiviato: statoArchiviaScheda(stato));
}
