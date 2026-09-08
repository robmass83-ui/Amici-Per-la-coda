import 'dart:typed_data';

import '../../../core/firestore_codec.dart';
import '../../../core/format_it.dart';
import '../../../core/new_id.dart';
import '../../../data/models/dog.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/health_record.dart';
import '../../../data/models/weight.dart';
import '../../../data/repositories/data_repositories.dart';
import 'new_dog_draft.dart';
import 'new_dog_draft_store.dart';

class NewDogSubmitResult {
  const NewDogSubmitResult({required this.dogId});

  final String dogId;
}

Future<NewDogSubmitResult> submitNewDog({
  required NewDogDraft draft,
  required List<Uint8List> photos,
  required DogRepository dogs,
  required String uid,
  required DateTime now,
  HealthRepository? health,
  WeightRepository? weights,
  PhotoRepository? photoRepo,
  DogDraftStore? drafts,
}) async {
  final ingresso = draft.dataIngresso ?? now;
  final peso = parseItalianDecimal(draft.pesoText);
  final id = newEntityId('dog', now);
  final audit = Audit(
    createdAt: now,
    createdBy: uid,
    updatedAt: now,
    updatedBy: uid,
  );
  final dog = Dog(
    id: id,
    nome: draft.nome.trim(),
    sesso: draft.sesso,
    dataNascita: draft.dataNascita,
    nascitaPresunta: draft.nascitaPresunta,
    razza: draft.razza.trim(),
    taglia: draft.taglia,
    pesoKg: peso,
    mantello: draft.mantello.trim(),
    microchip: draft.microchip.trim(),
    iscrittoAnagrafe: draft.iscrittoAnagrafe,
    provenienza: draft.provenienza.trim(),
    modalitaIngresso: draft.modalitaIngresso,
    dataIngresso: ingresso,
    settore: draft.settore.trim(),
    box: draft.box.trim(),
    stato: DogStato.inRifugio,
    statoDal: ingresso,
    adottabile: draft.adottabileFlag,
    sterilizzato: draft.sterilizzato,
    dataSterilizzazione: draft.dataSterilizzazione,
    slogan: draft.slogan.trim(),
    descrizione: draft.descrizione.trim(),
    carattere: List<String>.of(draft.carattere),
    conPersone: draft.conPersone,
    conCani: draft.conCani,
    conGatti: draft.conGatti,
    conBambini: draft.conBambini,
    noteCarattere: draft.noteCarattere.trim(),
    fotoCopertinaId: null,
    referenteId: draft.referenteId,
    pubblicato: draft.pubblicato,
    dataPubblicazione: draft.pubblicato ? now : null,
    archiviato: false,
    storicoStati: [
      StatoVoce(
        stato: DogStato.inRifugio,
        dal: ingresso,
        note: 'Ingresso in rifugio',
        autoreId: uid,
      ),
    ],
    audit: audit,
  );
  await dogs.save(dog);

  if (peso != null && weights != null) {
    await weights.save(
      Weight(
        id: newEntityId('w', now),
        dogId: id,
        data: ingresso,
        kg: peso,
        autoreId: uid,
        note: 'Peso all\'ingresso',
        audit: audit,
      ),
    );
  }

  if (health != null) {
    var healthIndex = 0;
    Future<void> saveHealth({
      required HealthTipo tipo,
      required DateTime data,
      required String descrizione,
      DateTime? scadenza,
      String veterinario = '',
      String lotto = '',
      double? costo,
    }) {
      return health.save(
        HealthRecord(
          id: newEntityId('h', now, index: healthIndex++),
          dogId: id,
          tipo: tipo,
          data: data,
          descrizione: descrizione,
          veterinario: veterinario,
          lotto: lotto,
          prossimaScadenza: scadenza,
          costo: costo,
          audit: audit,
        ),
      );
    }

    if (draft.sterilizzazione != WizardSterilizzazione.no &&
        draft.dataSterilizzazione != null) {
      await saveHealth(
        tipo: HealthTipo.sterilizzazione,
        data: draft.dataSterilizzazione!,
        descrizione: draft.sterilizzato
            ? 'Sterilizzazione'
            : 'Sterilizzazione programmata',
      );
    }
    for (final item in draft.trattamenti) {
      await saveHealth(
        tipo: item.tipo,
        data: item.data,
        descrizione: item.descrizione,
        scadenza: item.prossimaScadenza,
        veterinario: item.veterinario,
        lotto: item.lotto,
        costo: item.costo,
      );
    }
    for (final test in draft.testEffettuati) {
      await saveHealth(
        tipo: HealthTipo.esame,
        data: ingresso,
        descrizione: 'Test $test',
      );
    }
    final terapie = draft.terapieInCorso.trim();
    if (terapie.isNotEmpty) {
      await saveHealth(
        tipo: HealthTipo.terapia,
        data: ingresso,
        descrizione: terapie,
      );
    }
  }

  if (photoRepo != null && photos.isNotEmpty) {
    final cover = draft.coverIndex.clamp(0, photos.length - 1);
    for (var i = 0; i < photos.length; i++) {
      await photoRepo.upload(
        id,
        photos[i],
        asCover: i == cover,
        createdBy: uid,
      );
    }
  }

  await drafts?.clear(uid);
  return NewDogSubmitResult(dogId: id);
}
