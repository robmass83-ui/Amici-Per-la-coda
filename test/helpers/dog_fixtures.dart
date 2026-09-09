import 'package:amici_per_la_coda/core/firestore_codec.dart';
import 'package:amici_per_la_coda/data/models/adopter.dart';
import 'package:amici_per_la_coda/data/models/adoption.dart';
import 'package:amici_per_la_coda/data/models/appointment.dart';
import 'package:amici_per_la_coda/data/models/dog.dart';
import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/data/models/expense.dart';
import 'package:amici_per_la_coda/data/models/health_record.dart';
import 'package:amici_per_la_coda/data/models/shelter_box.dart';
import 'package:amici_per_la_coda/data/models/sponsorship.dart';
import 'package:amici_per_la_coda/data/models/volunteer.dart';
import 'package:amici_per_la_coda/data/models/weight.dart';

Dog testDog({
  String id = 'fido',
  String nome = 'Fido',
  DogSex sesso = DogSex.M,
  DateTime? dataNascita,
  bool nascitaPresunta = true,
  String razza = 'Meticcia',
  String microchip = '',
  String settore = 'B',
  String box = '1',
  DogStato stato = DogStato.inRifugio,
  bool adottabile = false,
  bool sterilizzato = false,
  String provenienza = 'Corleto Perticara (PZ)',
  String slogan = '',
  String descrizione = '',
  double? pesoKg = 12,
  bool archiviato = false,
  DateTime? dataIngresso,
  List<String> carattere = const [],
  ConPersone conPersone = ConPersone.selettivo,
  ConCani conCani = ConCani.daTestare,
  ConGatti conGatti = ConGatti.daTestare,
  ConBambini conBambini = ConBambini.daTestare,
  String noteCarattere = '',
  bool pubblicato = false,
  DateTime? dataPubblicazione,
}) {
  final at = DateTime.utc(2024, 6, 25);
  final birth = dataNascita ?? DateTime.utc(2022, 1, 1);
  final ingresso = dataIngresso ?? at;
  return Dog(
    id: id,
    nome: nome,
    sesso: sesso,
    dataNascita: dataNascita ?? birth,
    nascitaPresunta: nascitaPresunta,
    razza: razza,
    taglia: Taglia.media,
    pesoKg: pesoKg,
    mantello: 'Misto',
    microchip: microchip,
    iscrittoAnagrafe: IscrittoAnagrafe.daVerificare,
    provenienza: provenienza,
    modalitaIngresso: ModalitaIngresso.vagante,
    dataIngresso: ingresso,
    settore: settore,
    box: box,
    stato: stato,
    statoDal: at,
    adottabile: adottabile,
    sterilizzato: sterilizzato,
    dataSterilizzazione: null,
    slogan: slogan,
    descrizione: descrizione,
    carattere: carattere,
    conPersone: conPersone,
    conCani: conCani,
    conGatti: conGatti,
    conBambini: conBambini,
    noteCarattere: noteCarattere,
    fotoCopertinaId: null,
    referenteId: null,
    pubblicato: pubblicato,
    dataPubblicazione: dataPubblicazione,
    archiviato: archiviato,
    storicoStati: [
      StatoVoce(stato: stato, dal: at, note: '', autoreId: 'test'),
    ],
    audit: Audit.seed(at, by: 'test'),
  );
}

List<Dog> testListDogs() {
  return [
    testDog(
      id: 'fenice',
      nome: '[PROVA] Fenice',
      sesso: DogSex.F,
      dataNascita: DateTime.utc(2023, 1, 10),
      microchip: '380260043210987',
      settore: 'B',
      box: '7',
      stato: DogStato.inRifugio,
      adottabile: true,
      sterilizzato: true,
      slogan: 'Dolce, forte, speciale.',
      descrizione:
          'Fenice è una cagnolina meravigliosa, dolce, socievole e piena di vita.',
      pesoKg: 22,
      carattere: const ['Dolce', 'Socievole', 'Equilibrata'],
      conPersone: ConPersone.moltoSocievole,
      conCani: ConCani.si,
      conGatti: ConGatti.si,
      conBambini: ConBambini.si,
      noteCarattere:
          'Adatta a famiglia, ama le coccole e il contatto umano.',
    ),
    testDog(
      id: 'brando',
      nome: '[PROVA] Brando',
      microchip: '380260043210988',
      settore: 'B',
      box: '6',
      stato: DogStato.inRifugio,
      adottabile: true,
    ),
    testDog(
      id: 'nina',
      nome: '[PROVA] Nina',
      sesso: DogSex.F,
      dataNascita: DateTime.utc(2019, 5, 15),
      microchip: '380260043210989',
      settore: 'B',
      box: '7',
      stato: DogStato.inStallo,
      adottabile: true,
      sterilizzato: true,
    ),
    testDog(
      id: 'zeus',
      nome: '[PROVA] Zeus',
      microchip: '380260043210990',
      stato: DogStato.inRifugio,
    ),
  ];
}

Volunteer testVolunteer({
  String id = 'uid-1',
  String nome = 'Giovanna',
  String email = 'giovanna@amiciperlacoda.it',
}) {
  return Volunteer(
    id: id,
    nome: nome,
    email: email,
    ruolo: VolunteerRuolo.presidente,
    attivo: true,
    coloreAvatar: '#157A3C',
    audit: Audit.seed(DateTime.utc(2024, 6, 25), by: 'test'),
  );
}

Expense testExpense({
  String id = 'e1',
  String? dogId = 'fenice',
  ExpenseCategoria categoria = ExpenseCategoria.visita,
  double importo = 45,
  DateTime? data,
  String descrizione = 'Controllo veterinario',
  String fornitore = '',
}) {
  final at = data ?? DateTime.utc(2025, 3, 15);
  return Expense(
    id: id,
    dogId: dogId,
    categoria: categoria,
    importo: importo,
    data: at,
    descrizione: descrizione,
    fornitore: fornitore,
    audit: Audit.seed(at, by: 'test'),
  );
}

Weight testWeight({
  String id = 'w1',
  String dogId = 'fenice',
  DateTime? data,
  double kg = 22,
  String autoreId = 'uid-1',
  String note = '',
}) {
  final at = data ?? DateTime.utc(2026, 3, 10);
  return Weight(
    id: id,
    dogId: dogId,
    data: at,
    kg: kg,
    autoreId: autoreId,
    note: note,
    audit: Audit.seed(at, by: autoreId),
  );
}

Sponsorship testSponsorship({
  String id = 's1',
  String dogId = 'fenice',
  String nome = 'Anna',
  String cognome = 'Bianchi',
  double importoMensile = 15,
  bool attiva = true,
  DateTime? dal,
  DateTime? al,
  String note = '',
}) {
  final start = dal ?? DateTime.utc(2026, 1, 1);
  return Sponsorship(
    id: id,
    dogId: dogId,
    sostenitore: Sostenitore(
      nome: nome,
      cognome: cognome,
      email: 'anna@example.it',
      telefono: '3331234567',
    ),
    importoMensile: importoMensile,
    attiva: attiva,
    dal: start,
    al: al,
    note: note,
    audit: Audit.seed(start, by: 'test'),
  );
}

Richiedente testRichiedente({
  String nome = 'Luca',
  String cognome = 'Verdi',
}) {
  return Richiedente(
    nome: nome,
    cognome: cognome,
    telefono: '3331234567',
    email: 'luca@example.it',
    citta: 'Potenza',
    indirizzo: 'Via Roma 1',
    docTipo: 'CI',
    docNumero: 'AB123',
    eta: 34,
  );
}

Questionario testQuestionario() {
  return const Questionario(
    abitazione: 'casa',
    giardinoRecintato: true,
    altezzaRecinzione: '150',
    altriAnimali: '',
    bambini: '',
    oreDaSolo: '2',
    esperienzaCani: 'si',
    doveDormira: 'interno',
    note: '',
  );
}

Adoption testAdoption({
  String id = 'ad1',
  String dogId = 'fido',
  String adopterId = '',
  AdoptionStato stato = AdoptionStato.ricevuta,
  DateTime? dataRichiesta,
  DateTime? preaffidoDal,
  DateTime? preaffidoAl,
  String referenteId = 'uid-1',
  Richiedente? richiedente,
  Questionario? questionario,
  List<AdoptionStatoVoce>? storicoStati,
}) {
  final at = dataRichiesta ?? DateTime.utc(2026, 8, 1);
  return Adoption(
    id: id,
    dogId: dogId,
    adopterId: adopterId,
    richiedente: richiedente ?? testRichiedente(),
    questionario: questionario ?? testQuestionario(),
    stato: stato,
    storicoStati:
        storicoStati ??
        [
          AdoptionStatoVoce(
            stato: stato,
            data: at,
            note: '',
            autoreId: 'test',
          ),
        ],
    preaffidoDal: preaffidoDal,
    preaffidoAl: preaffidoAl,
    referenteId: referenteId,
    dataRichiesta: at,
    audit: Audit.seed(at, by: 'test'),
  );
}

Adopter testAdopter({
  String id = 'adp1',
  String nome = 'Luca',
  String cognome = 'Verdi',
  String telefono = '3331234567',
  String email = 'luca@example.it',
  List<String> adozioniIds = const [],
}) {
  return Adopter(
    id: id,
    nome: nome,
    cognome: cognome,
    telefono: telefono,
    email: email,
    citta: 'Potenza',
    indirizzo: 'Via Roma 1',
    docTipo: 'CI',
    docNumero: 'AB123',
    dataNascita: null,
    note: '',
    adozioniIds: adozioniIds,
    affidabilita: Affidabilita.ok,
    audit: Audit.seed(DateTime.utc(2026, 8, 1), by: 'test'),
  );
}

HealthRecord testHealth({
  String id = 'h1',
  String dogId = 'fido',
  HealthTipo tipo = HealthTipo.vaccino,
  DateTime? data,
  DateTime? prossimaScadenza,
  String descrizione = 'Richiamo',
}) {
  final at = data ?? DateTime.utc(2025, 9, 1);
  return HealthRecord(
    id: id,
    dogId: dogId,
    tipo: tipo,
    data: at,
    descrizione: descrizione,
    veterinario: 'Dr. Test',
    lotto: '',
    prossimaScadenza: prossimaScadenza,
    costo: null,
    audit: Audit.seed(at, by: 'test'),
  );
}

Appointment testAppointment({
  String id = 'ap1',
  AppointmentTipo tipo = AppointmentTipo.visita,
  String titolo = 'Controllo',
  String? dogId = 'fido',
  DateTime? inizio,
  AppointmentStato stato = AppointmentStato.previsto,
}) {
  final at = inizio ?? DateTime(2026, 9, 8, 10, 30);
  return Appointment(
    id: id,
    tipo: tipo,
    titolo: titolo,
    dogId: dogId,
    adoptionId: null,
    inizio: at,
    fine: null,
    tuttoIlGiorno: false,
    luogo: '',
    volontariIds: const [],
    stato: stato,
    audit: Audit.seed(at, by: 'test'),
  );
}

ShelterBox testBox({
  String id = 'box1',
  String settore = 'A',
  String numero = '1',
  int capienza = 4,
  bool inManutenzione = false,
}) {
  return ShelterBox(
    id: id,
    settore: settore,
    numero: numero,
    capienza: capienza,
    note: '',
    inManutenzione: inManutenzione,
    audit: Audit.seed(DateTime.utc(2024, 6, 25), by: 'test'),
  );
}

