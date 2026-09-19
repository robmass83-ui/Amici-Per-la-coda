import '../../core/firestore_codec.dart';
import '../../core/new_id.dart';
import '../../data/models/adopter.dart';
import '../../data/models/adoption.dart';
import '../../data/models/dog.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/data_repositories.dart';
import '../dogs/dog_stato.dart';

const emptyQuestionario = Questionario(
  abitazione: '',
  giardinoRecintato: false,
  altezzaRecinzione: '',
  altriAnimali: '',
  bambini: '',
  oreDaSolo: '',
  esperienzaCani: '',
  doveDormira: '',
  note: '',
);

Adoption? familyLinkOf(List<Adoption> items, String dogId) {
  final matches = [for (final item in items) if (item.dogId == dogId) item];
  if (matches.isEmpty) {
    return null;
  }
  matches.sort((a, b) => b.dataRichiesta.compareTo(a.dataRichiesta));
  return matches.first;
}

Adoption familyLinkAdoption({
  required String id,
  required String dogId,
  required Adopter adopter,
  required Audit audit,
  required DateTime now,
}) {
  return Adoption(
    id: id,
    dogId: dogId,
    adopterId: adopter.id,
    richiedente: Richiedente(
      nome: adopter.nome,
      cognome: adopter.cognome,
      telefono: adopter.telefono,
      email: adopter.email,
      citta: adopter.citta,
      indirizzo: adopter.indirizzo,
      docTipo: adopter.docTipo,
      docNumero: adopter.docNumero,
      eta: 0,
    ),
    questionario: emptyQuestionario,
    stato: AdoptionStato.adottato,
    storicoStati: const [],
    preaffidoDal: null,
    preaffidoAl: null,
    referenteId: '',
    dataRichiesta: now,
    audit: audit,
  );
}

({Dog dog, bool wroteStorico}) markDogAdottatoIfNeeded({
  required Dog dog,
  required DateTime now,
  required String autoreId,
}) {
  if (dog.stato == DogStato.adottato) {
    return (dog: dog.copyWith(adottabile: false), wroteStorico: false);
  }
  final updated = applyDogStato(
    dog: dog,
    stato: DogStato.adottato,
    dal: now,
    note: '',
    autoreId: autoreId,
    now: now,
  ).copyWith(adottabile: false);
  return (dog: updated, wroteStorico: true);
}

Future<void> replaceDogFamily({
  required AdoptionRepository adoptions,
  required AdopterRepository adopters,
  required List<Adoption> existing,
  required Adopter adopter,
  required String dogId,
  required String uid,
  required DateTime now,
}) async {
  for (final old in existing.where((item) => item.dogId == dogId)) {
    await adoptions.delete(old.id);
    final previous = await adopters.getById(old.adopterId);
    if (previous != null) {
      await adopters.save(previous.withoutAdozioneId(old.id));
    }
  }
  final link = familyLinkAdoption(
    id: newEntityId('ado', now),
    dogId: dogId,
    adopter: adopter,
    audit: Audit(
      createdAt: now,
      createdBy: uid,
      updatedAt: now,
      updatedBy: uid,
    ),
    now: now,
  );
  await adoptions.save(link);
  await adopters.save(adopter.withAdozioneId(link.id, audit: link.audit));
}
