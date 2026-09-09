import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firestore_codec.dart';
import '../firestore/firestore_repositories.dart';
import '../models/adopter.dart';
import '../models/adoption.dart';
import '../models/association_settings.dart';
import '../models/dog.dart';
import '../models/enums.dart';
import '../models/shelter_box.dart';
import '../models/volunteer.dart';
import 'cani_csv_parser.dart';
import 'seed_ids.dart';

class SeedReport {
  const SeedReport({
    required this.dogs,
    required this.realDogs,
    required this.demoDogs,
    required this.volunteers,
    required this.boxes,
    required this.adoptions,
  });

  final int dogs;
  final int realDogs;
  final int demoDogs;
  final int volunteers;
  final int boxes;
  final int adoptions;
}

class SeedCleanupReport {
  const SeedCleanupReport({
    required this.dogs,
    required this.adoptions,
    required this.volunteers,
  });

  final int dogs;
  final int adoptions;
  final int volunteers;
}

/// Anagrafe vera da `cani.csv` + 6 cani / 3 volontari / 5 richieste di prova.
Future<SeedReport> runSeed(FirebaseFirestore db) async {
  await _deleteLegacyDemoDocs(db);

  final at = DateTime.utc(2024, 6, 25, 10);
  final audit = Audit.seed(at);
  final dogs = FirestoreDogRepository(db);
  final volunteers = FirestoreVolunteerRepository(db);
  final boxes = FirestoreBoxRepository(db);
  final adoptions = FirestoreAdoptionRepository(db);
  final adopters = FirestoreAdopterRepository(db);
  final settings = FirestoreSettingsRepository(db);

  final volunteerList = _seedVolunteers(audit);
  final realDogs = dogsFromCaniCsv(audit);
  final demoDogs = _seedDogs(audit);
  final dogList = [...realDogs, ...demoDogs];
  final boxList = _seedBoxes(audit);
  final adoptionList = _seedAdoptions(audit);
  final adopterList = _seedAdopters(adoptionList, audit);

  for (final item in volunteerList) {
    await volunteers.save(item);
  }
  for (final item in dogList) {
    await dogs.save(item);
  }
  for (final item in boxList) {
    await boxes.save(item);
  }
  for (final item in adoptionList) {
    await adoptions.save(item);
  }
  for (final item in adopterList) {
    await adopters.save(item);
  }
  await settings.saveAssociation(
    AssociationSettings(
      denominazione: 'Amici per la Coda ODV',
      codiceFiscale: '93081210721',
      sede: 'Corleto Perticara (PZ)',
      capienzaAutorizzata: 54,
      logoB64: null,
      audit: audit,
    ),
  );

  return SeedReport(
    dogs: dogList.length,
    realDogs: realDogs.length,
    demoDogs: demoDogs.length,
    volunteers: volunteerList.length,
    boxes: boxList.length,
    adoptions: adoptionList.length,
  );
}

/// Cancella solo i documenti con id `seed_*` (cani finti, adozioni e volontari seed).
Future<SeedCleanupReport> deleteSeedData(FirebaseFirestore db) async {
  final dogs = await _deletePrefixed(db.collection('dogs'), seedIdPrefix);
  final adoptions = await _deletePrefixed(
    db.collection('adoptions'),
    seedIdPrefix,
  );
  await _deletePrefixed(db.collection('adopters'), seedIdPrefix);
  final volunteers = await _deletePrefixed(
    db.collection('volunteers'),
    seedIdPrefix,
  );
  return SeedCleanupReport(
    dogs: dogs,
    adoptions: adoptions,
    volunteers: volunteers,
  );
}

Future<void> _deleteLegacyDemoDocs(FirebaseFirestore db) async {
  for (final id in legacyDemoDogIds) {
    await db.collection('dogs').doc(id).delete();
  }
  for (final id in legacyDemoAdoptionIds) {
    await db.collection('adoptions').doc(id).delete();
  }
}

Future<int> _deletePrefixed(
  CollectionReference<Map<String, dynamic>> col,
  String prefix,
) async {
  final snap = await col.get();
  var count = 0;
  for (final doc in snap.docs) {
    if (doc.id.startsWith(prefix)) {
      await doc.reference.delete();
      count++;
    }
  }
  return count;
}

List<Volunteer> _seedVolunteers(Audit audit) {
  return [
    Volunteer(
      id: 'seed_giovanna',
      nome: 'Giovanna',
      email: 'giovanna@amiciperlacoda.it',
      ruolo: VolunteerRuolo.presidente,
      attivo: true,
      coloreAvatar: '#157A3C',
      audit: audit,
    ),
    Volunteer(
      id: 'seed_roberto',
      nome: 'Roberto',
      email: 'roberto@amiciperlacoda.it',
      ruolo: VolunteerRuolo.presidente,
      attivo: true,
      coloreAvatar: '#2E7FD6',
      audit: audit,
    ),
    Volunteer(
      id: 'seed_marco',
      nome: 'Marco P.',
      email: 'marco@amiciperlacoda.it',
      ruolo: VolunteerRuolo.referente,
      attivo: true,
      coloreAvatar: '#7B4CC0',
      audit: audit,
    ),
  ];
}

List<ShelterBox> _seedBoxes(Audit audit) {
  return [
    ShelterBox(
      id: 'a1',
      settore: 'A',
      numero: '1',
      capienza: 3,
      note: 'Cuccioli',
      inManutenzione: false,
      audit: audit,
    ),
    ShelterBox(
      id: 'a2',
      settore: 'A',
      numero: '2',
      capienza: 3,
      note: '',
      inManutenzione: false,
      audit: audit,
    ),
    ShelterBox(
      id: 'a3',
      settore: 'A',
      numero: '3',
      capienza: 3,
      note: '',
      inManutenzione: false,
      audit: audit,
    ),
    ShelterBox(
      id: 'a4',
      settore: 'A',
      numero: '4',
      capienza: 3,
      note: 'In manutenzione',
      inManutenzione: true,
      audit: audit,
    ),
    ShelterBox(
      id: 'b5',
      settore: 'B',
      numero: '5',
      capienza: 2,
      note: '',
      inManutenzione: false,
      audit: audit,
    ),
    ShelterBox(
      id: 'b6',
      settore: 'B',
      numero: '6',
      capienza: 2,
      note: '',
      inManutenzione: false,
      audit: audit,
    ),
    ShelterBox(
      id: 'b7',
      settore: 'B',
      numero: '7',
      capienza: 2,
      note: 'Fenice e Nina',
      inManutenzione: false,
      audit: audit,
    ),
    ShelterBox(
      id: 'b8',
      settore: 'B',
      numero: '8',
      capienza: 2,
      note: 'Libero',
      inManutenzione: false,
      audit: audit,
    ),
  ];
}

List<Dog> _seedDogs(Audit audit) {
  Dog build({
    required String id,
    required String nome,
    required DogSex sesso,
    required DateTime? dataNascita,
    required bool nascitaPresunta,
    required String razza,
    required Taglia taglia,
    required double? pesoKg,
    required String microchip,
    required DogStato stato,
    required DateTime dataIngresso,
    required String settore,
    required String box,
    required bool adottabile,
    required bool sterilizzato,
    required DateTime? dataSterilizzazione,
    required List<String> carattere,
    required ConBambini conBambini,
    String provenienza = 'Corleto Perticara (PZ)',
    String? referenteId = 'seed_marco',
  }) {
    return Dog(
      id: '$seedIdPrefix$id',
      nome: '$seedNamePrefix$nome',
      sesso: sesso,
      dataNascita: dataNascita,
      nascitaPresunta: nascitaPresunta,
      razza: razza,
      taglia: taglia,
      pesoKg: pesoKg,
      mantello: 'Misto',
      microchip: microchip,
      iscrittoAnagrafe: IscrittoAnagrafe.si,
      provenienza: provenienza,
      modalitaIngresso: ModalitaIngresso.vagante,
      dataIngresso: dataIngresso,
      settore: settore,
      box: box,
      stato: stato,
      statoDal: dataIngresso,
      adottabile: adottabile,
      sterilizzato: sterilizzato,
      dataSterilizzazione: dataSterilizzazione,
      slogan: 'DATI DI PROVA — da rimuovere.',
      descrizione:
          '$seedNamePrefix$nome è un profilo inventato per i test. '
          'Id $seedIdPrefix$id, da rimuovere a fine collaudo.',
      carattere: carattere,
      conPersone: ConPersone.moltoSocievole,
      conCani: ConCani.si,
      conGatti: ConGatti.daTestare,
      conBambini: conBambini,
      noteCarattere: 'DATI DI PROVA — id $seedIdPrefix$id.',
      fotoCopertinaId: null,
      referenteId: referenteId,
      pubblicato: adottabile,
      dataPubblicazione: adottabile ? dataIngresso : null,
      archiviato: stato == DogStato.adottato,
      storicoStati: [
        StatoVoce(
          stato: stato,
          dal: dataIngresso,
          note: 'Ingresso',
          autoreId: 'seed_giovanna',
        ),
      ],
      audit: audit,
    );
  }

  return [
    build(
      id: 'fenice',
      nome: 'Fenice',
      sesso: DogSex.F,
      dataNascita: DateTime.utc(2023, 1, 10),
      nascitaPresunta: true,
      razza: 'Meticcia',
      taglia: Taglia.media,
      pesoKg: 18.5,
      microchip: '380260043210987',
      stato: DogStato.inRifugio,
      dataIngresso: DateTime.utc(2024, 6, 25),
      settore: 'B',
      box: '7',
      adottabile: true,
      sterilizzato: true,
      dataSterilizzazione: DateTime.utc(2024, 8, 12),
      carattere: const ['Dolce', 'Socievole', 'Equilibrata'],
      conBambini: ConBambini.si,
    ),
    build(
      id: 'brando',
      nome: 'Brando',
      sesso: DogSex.M,
      dataNascita: DateTime.utc(2022, 3, 1),
      nascitaPresunta: true,
      razza: 'Pastore mix',
      taglia: Taglia.grande,
      pesoKg: 32,
      microchip: '380260043210988',
      stato: DogStato.inRifugio,
      dataIngresso: DateTime.utc(2024, 4, 2),
      settore: 'B',
      box: '6',
      adottabile: true,
      sterilizzato: true,
      dataSterilizzazione: DateTime.utc(2024, 5, 20),
      carattere: const ['Vigile', 'Equilibrato'],
      conBambini: ConBambini.soloGrandi,
    ),
    build(
      id: 'nina',
      nome: 'Nina',
      sesso: DogSex.F,
      dataNascita: DateTime.utc(2019, 5, 15),
      nascitaPresunta: true,
      razza: 'Meticcia',
      taglia: Taglia.media,
      pesoKg: 16,
      microchip: '380260043210989',
      stato: DogStato.inStallo,
      dataIngresso: DateTime.utc(2023, 11, 8),
      settore: 'B',
      box: '7',
      adottabile: true,
      sterilizzato: true,
      dataSterilizzazione: DateTime.utc(2023, 12, 1),
      carattere: const ['Calma', 'Dolce'],
      conBambini: ConBambini.si,
    ),
    build(
      id: 'zeus',
      nome: 'Zeus',
      sesso: DogSex.M,
      dataNascita: DateTime.utc(2024, 2, 1),
      nascitaPresunta: true,
      razza: 'Maremmano mix',
      taglia: Taglia.grande,
      pesoKg: 34,
      microchip: '380260043210990',
      stato: DogStato.inRifugio,
      dataIngresso: DateTime.utc(2025, 1, 18),
      settore: 'B',
      box: '5',
      adottabile: false,
      sterilizzato: false,
      dataSterilizzazione: null,
      carattere: const ['Vivace'],
      conBambini: ConBambini.daTestare,
    ),
    build(
      id: 'luna',
      nome: 'Luna',
      sesso: DogSex.F,
      dataNascita: DateTime.utc(2026, 4, 1),
      nascitaPresunta: true,
      razza: 'Meticcia',
      taglia: Taglia.piccola,
      pesoKg: 7.2,
      microchip: '380260043210991',
      stato: DogStato.inRifugio,
      dataIngresso: DateTime.utc(2026, 7, 20),
      settore: 'A',
      box: '1',
      adottabile: true,
      sterilizzato: false,
      dataSterilizzazione: null,
      carattere: const ['Giocherellona'],
      conBambini: ConBambini.si,
    ),
    build(
      id: 'otto',
      nome: 'Otto',
      sesso: DogSex.M,
      dataNascita: DateTime.utc(2018, 6, 1),
      nascitaPresunta: true,
      razza: 'Segugio mix',
      taglia: Taglia.media,
      pesoKg: 22,
      microchip: '380260043210992',
      stato: DogStato.adottato,
      dataIngresso: DateTime.utc(2024, 2, 10),
      settore: 'B',
      box: '8',
      adottabile: false,
      sterilizzato: true,
      dataSterilizzazione: DateTime.utc(2024, 3, 4),
      carattere: const ['Fedele'],
      conBambini: ConBambini.si,
    ),
  ];
}

List<Adoption> _seedAdoptions(Audit audit) {
  Adoption item({
    required String id,
    required String dogId,
    required String adopterId,
    required String nome,
    required String cognome,
    required String citta,
    required int eta,
    required AdoptionStato stato,
    required DateTime dataRichiesta,
    DateTime? preaffidoDal,
    DateTime? preaffidoAl,
    bool giardino = true,
  }) {
    return Adoption(
      id: '$seedIdPrefix$id',
      dogId: '$seedIdPrefix$dogId',
      adopterId: '$seedIdPrefix$adopterId',
      richiedente: Richiedente(
        nome: nome,
        cognome: cognome,
        telefono: '3200000000',
        email: '${nome.toLowerCase()}.${cognome.toLowerCase()}@mail.it',
        citta: citta,
        indirizzo: 'Via Roma 1',
        docTipo: 'CI',
        docNumero: 'CA00000$id',
        eta: eta,
      ),
      questionario: Questionario(
        abitazione: 'Casa con giardino',
        giardinoRecintato: giardino,
        altezzaRecinzione: giardino ? '180' : '',
        altriAnimali: 'No',
        bambini: 'No',
        oreDaSolo: '3',
        esperienzaCani: 'Sì',
        doveDormira: 'In casa',
        note: '',
      ),
      stato: stato,
      storicoStati: [
        AdoptionStatoVoce(
          stato: stato,
          data: dataRichiesta,
          note: '',
          autoreId: 'seed_giovanna',
        ),
      ],
      preaffidoDal: preaffidoDal,
      preaffidoAl: preaffidoAl,
      referenteId: 'seed_giovanna',
      dataRichiesta: dataRichiesta,
      audit: audit,
    );
  }

  return [
    item(
      id: 'ad_marta_luna',
      dogId: 'luna',
      adopterId: 'adp_marta',
      nome: 'Marta',
      cognome: 'Rossi',
      citta: 'Sassari (SS)',
      eta: 34,
      stato: AdoptionStato.ricevuta,
      dataRichiesta: DateTime.utc(2026, 9, 6),
    ),
    item(
      id: 'ad_ferrari_otto',
      dogId: 'otto',
      adopterId: 'adp_ferrari',
      nome: 'Giulia',
      cognome: 'Ferrari',
      citta: 'Potenza (PZ)',
      eta: 41,
      stato: AdoptionStato.preaffido,
      dataRichiesta: DateTime.utc(2026, 8, 10),
      preaffidoDal: DateTime.utc(2026, 8, 20),
      preaffidoAl: DateTime.utc(2026, 9, 20),
    ),
    item(
      id: 'ad_luca_brando',
      dogId: 'brando',
      adopterId: 'adp_luca',
      nome: 'Luca',
      cognome: 'Cossu',
      citta: 'Cagliari (CA)',
      eta: 38,
      stato: AdoptionStato.colloquio,
      dataRichiesta: DateTime.utc(2026, 8, 28),
    ),
    item(
      id: 'ad_anna_nina',
      dogId: 'nina',
      adopterId: 'adp_anna',
      nome: 'Anna',
      cognome: 'Pili',
      citta: 'Oristano (OR)',
      eta: 45,
      stato: AdoptionStato.visita,
      dataRichiesta: DateTime.utc(2026, 8, 15),
    ),
    item(
      id: 'ad_sara_zeus',
      dogId: 'zeus',
      adopterId: 'adp_sara',
      nome: 'Sara',
      cognome: 'Deiana',
      citta: 'Nuoro (NU)',
      eta: 29,
      stato: AdoptionStato.respinta,
      dataRichiesta: DateTime.utc(2026, 7, 30),
      giardino: false,
    ),
  ];
}

List<Adopter> _seedAdopters(List<Adoption> adoptions, Audit audit) {
  return [
    for (final adoption in adoptions)
      Adopter(
        id: adoption.adopterId,
        nome: adoption.richiedente.nome,
        cognome: adoption.richiedente.cognome,
        telefono: adoption.richiedente.telefono,
        email: adoption.richiedente.email,
        citta: adoption.richiedente.citta,
        indirizzo: adoption.richiedente.indirizzo,
        docTipo: adoption.richiedente.docTipo,
        docNumero: adoption.richiedente.docNumero,
        dataNascita: null,
        note: '',
        adozioniIds: [adoption.id],
        affidabilita: adoption.stato == AdoptionStato.respinta
            ? Affidabilita.nonIdoneo
            : Affidabilita.ok,
        audit: audit,
      ),
  ];
}
