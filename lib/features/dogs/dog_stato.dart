import '../../core/firestore_codec.dart';
import '../../data/models/dog.dart';
import '../../data/models/enums.dart';

const storicoStatiMax = 30;

/// Transizione ammessa: qualsiasi stato diverso, tranne uscire da deceduto.
bool statoTransitionAllowed(DogStato from, DogStato to) {
  if (from == to) {
    return false;
  }
  if (from == DogStato.deceduto) {
    return false;
  }
  return true;
}

bool statoRequiresConfirmation(DogStato to) {
  return to == DogStato.adottato || to == DogStato.deceduto;
}

List<StatoVoce> appendStoricoStato(List<StatoVoce> storico, StatoVoce voce) {
  final next = [...storico, voce]
    ..sort((a, b) => b.dal.compareTo(a.dal));
  if (next.length <= storicoStatiMax) {
    return next;
  }
  return next.take(storicoStatiMax).toList();
}

Dog applyDogStato({
  required Dog dog,
  required DogStato stato,
  required DateTime dal,
  required String note,
  required String autoreId,
  required DateTime now,
}) {
  if (!statoTransitionAllowed(dog.stato, stato)) {
    throw ArgumentError('Transizione non ammessa');
  }
  final voce = StatoVoce(
    stato: stato,
    dal: dal,
    note: note.trim(),
    autoreId: autoreId,
  );
  return dog.withStato(
    stato: stato,
    statoDal: dal,
    storicoStati: appendStoricoStato(dog.storicoStati, voce),
    audit: Audit(
      createdAt: dog.audit.createdAt,
      createdBy: dog.audit.createdBy,
      updatedAt: now,
      updatedBy: autoreId,
    ),
  );
}
