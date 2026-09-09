import '../../core/firestore_codec.dart';
import '../../data/models/adopter.dart';
import '../../data/models/adoption.dart';
import '../../data/models/dog.dart';
import '../../data/models/enums.dart';
import '../dogs/dog_stato.dart';

const preaffidoDurataGg = 30;

const iterTappe = <AdoptionStato>[
  AdoptionStato.ricevuta,
  AdoptionStato.colloquio,
  AdoptionStato.visita,
  AdoptionStato.preaffido,
  AdoptionStato.adottato,
];

AdoptionStato? nextAdoptionStato(AdoptionStato stato) {
  final index = iterTappe.indexOf(stato);
  if (index < 0 || index >= iterTappe.length - 1) {
    return null;
  }
  return iterTappe[index + 1];
}

bool canAdvanceAdoption(AdoptionStato stato) => nextAdoptionStato(stato) != null;

bool canRejectAdoption(AdoptionStato stato) {
  return stato != AdoptionStato.adottato &&
      stato != AdoptionStato.respinta &&
      stato != AdoptionStato.ritirata;
}

bool adoptionAdvanceNeedsConfirm(AdoptionStato next) {
  return next == AdoptionStato.adottato;
}

List<AdoptionStatoVoce> appendAdoptionStorico(
  List<AdoptionStatoVoce> storico,
  AdoptionStatoVoce voce,
) {
  return [...storico, voce];
}

({Adoption adoption, Dog dog}) advanceAdoption({
  required Adoption adoption,
  required Dog dog,
  required DateTime now,
  required String autoreId,
  String note = '',
}) {
  final next = nextAdoptionStato(adoption.stato);
  if (next == null) {
    throw ArgumentError('La richiesta non può avanzare.');
  }
  var preDal = adoption.preaffidoDal;
  var preAl = adoption.preaffidoAl;
  if (next == AdoptionStato.preaffido) {
    preDal ??= now;
    preAl ??= now.add(const Duration(days: preaffidoDurataGg));
  }
  final updated = adoption.withWorkflow(
    stato: next,
    storicoStati: appendAdoptionStorico(
      adoption.storicoStati,
      AdoptionStatoVoce(
        stato: next,
        data: now,
        note: note.trim(),
        autoreId: autoreId,
      ),
    ),
    preaffidoDal: preDal,
    preaffidoAl: preAl,
    audit: Audit(
      createdAt: adoption.audit.createdAt,
      createdBy: adoption.audit.createdBy,
      updatedAt: now,
      updatedBy: autoreId,
    ),
  );
  return (
    adoption: updated,
    dog: syncDogWithAdoption(
      dog: dog,
      adoptionStato: next,
      rejected: false,
      now: now,
      autoreId: autoreId,
    ),
  );
}

({Adoption adoption, Dog dog}) rejectAdoption({
  required Adoption adoption,
  required Dog dog,
  required DateTime now,
  required String autoreId,
  String note = '',
}) {
  if (!canRejectAdoption(adoption.stato)) {
    throw ArgumentError('La richiesta non può essere respinta.');
  }
  final updated = adoption.withWorkflow(
    stato: AdoptionStato.respinta,
    storicoStati: appendAdoptionStorico(
      adoption.storicoStati,
      AdoptionStatoVoce(
        stato: AdoptionStato.respinta,
        data: now,
        note: note.trim(),
        autoreId: autoreId,
      ),
    ),
    audit: Audit(
      createdAt: adoption.audit.createdAt,
      createdBy: adoption.audit.createdBy,
      updatedAt: now,
      updatedBy: autoreId,
    ),
  );
  return (
    adoption: updated,
    dog: syncDogWithAdoption(
      dog: dog,
      adoptionStato: AdoptionStato.respinta,
      rejected: true,
      wasPreaffido: adoption.stato == AdoptionStato.preaffido,
      now: now,
      autoreId: autoreId,
    ),
  );
}

Dog syncDogWithAdoption({
  required Dog dog,
  required AdoptionStato adoptionStato,
  required bool rejected,
  required DateTime now,
  required String autoreId,
  bool wasPreaffido = false,
}) {
  if (rejected) {
    var next = dog;
    if (wasPreaffido &&
        dog.stato == DogStato.preaffido &&
        statoTransitionAllowed(dog.stato, DogStato.inRifugio)) {
      next = applyDogStato(
        dog: next,
        stato: DogStato.inRifugio,
        dal: now,
        note: 'Richiesta di adozione respinta',
        autoreId: autoreId,
        now: now,
      );
    }
    return next.withAdottabile(
      true,
      audit: Audit(
        createdAt: next.audit.createdAt,
        createdBy: next.audit.createdBy,
        updatedAt: now,
        updatedBy: autoreId,
      ),
    );
  }

  if (adoptionStato == AdoptionStato.preaffido) {
    var next = dog;
    if (statoTransitionAllowed(dog.stato, DogStato.preaffido)) {
      next = applyDogStato(
        dog: next,
        stato: DogStato.preaffido,
        dal: now,
        note: 'Avanzamento richiesta a preaffido',
        autoreId: autoreId,
        now: now,
      );
    }
    return next.withAdottabile(
      false,
      audit: Audit(
        createdAt: next.audit.createdAt,
        createdBy: next.audit.createdBy,
        updatedAt: now,
        updatedBy: autoreId,
      ),
    );
  }

  if (adoptionStato == AdoptionStato.adottato) {
    var next = dog;
    if (statoTransitionAllowed(dog.stato, DogStato.adottato)) {
      next = applyDogStato(
        dog: next,
        stato: DogStato.adottato,
        dal: now,
        note: 'Adozione definitiva',
        autoreId: autoreId,
        now: now,
      );
    }
    return next.withAdottabile(
      false,
      audit: Audit(
        createdAt: next.audit.createdAt,
        createdBy: next.audit.createdBy,
        updatedAt: now,
        updatedBy: autoreId,
      ),
    );
  }

  return dog;
}

String normalizeAdopterEmail(String value) => value.trim().toLowerCase();

String normalizeAdopterPhone(String value) =>
    value.replaceAll(RegExp(r'\D'), '');

Adopter? findMatchingAdopter(
  List<Adopter> adopters, {
  required String telefono,
  required String email,
}) {
  final phone = normalizeAdopterPhone(telefono);
  final mail = normalizeAdopterEmail(email);
  for (final adopter in adopters) {
    if (phone.isNotEmpty &&
        normalizeAdopterPhone(adopter.telefono) == phone) {
      return adopter;
    }
    if (mail.isNotEmpty && normalizeAdopterEmail(adopter.email) == mail) {
      return adopter;
    }
  }
  return null;
}

Adopter adopterFromRichiedente({
  required String id,
  required Richiedente richiedente,
  required String adoptionId,
  required Audit audit,
  DateTime? dataNascita,
}) {
  return Adopter(
    id: id,
    nome: richiedente.nome.trim(),
    cognome: richiedente.cognome.trim(),
    telefono: richiedente.telefono.trim(),
    email: richiedente.email.trim(),
    citta: richiedente.citta.trim(),
    indirizzo: richiedente.indirizzo.trim(),
    docTipo: richiedente.docTipo.trim(),
    docNumero: richiedente.docNumero.trim(),
    dataNascita: dataNascita,
    note: '',
    adozioniIds: [adoptionId],
    affidabilita: Affidabilita.daVerificare,
    audit: audit,
  );
}
