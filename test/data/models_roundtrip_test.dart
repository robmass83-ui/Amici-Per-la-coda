import 'dart:typed_data';

import 'package:amici_per_la_coda/core/firestore_codec.dart';
import 'package:amici_per_la_coda/data/models/adopter.dart';
import 'package:amici_per_la_coda/data/models/adoption.dart';
import 'package:amici_per_la_coda/data/models/app_document.dart';
import 'package:amici_per_la_coda/data/models/appointment.dart';
import 'package:amici_per_la_coda/data/models/association_settings.dart';
import 'package:amici_per_la_coda/data/models/document_template.dart';
import 'package:amici_per_la_coda/data/models/dog.dart';
import 'package:amici_per_la_coda/data/models/enums.dart';
import 'package:amici_per_la_coda/data/models/expense.dart';
import 'package:amici_per_la_coda/data/models/health_record.dart';
import 'package:amici_per_la_coda/data/models/note.dart';
import 'package:amici_per_la_coda/data/models/photo.dart';
import 'package:amici_per_la_coda/data/models/shelter_box.dart';
import 'package:amici_per_la_coda/data/models/sponsorship.dart';
import 'package:amici_per_la_coda/data/models/vendor.dart';
import 'package:amici_per_la_coda/data/models/volunteer.dart';
import 'package:amici_per_la_coda/data/models/weight.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final at = DateTime.utc(2024, 6, 25, 10, 30);
  final audit = Audit.seed(at, by: 'test');

  test('Dog round-trip con date valorizzate e null', () {
    final dog = Dog(
      id: 'fenice',
      nome: 'Fenice',
      sesso: DogSex.F,
      dataNascita: null,
      nascitaPresunta: true,
      razza: 'Meticcia',
      taglia: Taglia.media,
      pesoKg: null,
      mantello: 'Fulvo',
      microchip: '380260043210987',
      iscrittoAnagrafe: IscrittoAnagrafe.daVerificare,
      provenienza: 'Corleto Perticara (PZ)',
      modalitaIngresso: ModalitaIngresso.natoInRifugio,
      dataIngresso: at,
      settore: 'B',
      box: '7',
      stato: DogStato.inRifugio,
      statoDal: at,
      adottabile: true,
      sterilizzato: false,
      dataSterilizzazione: null,
      slogan: 'Due righe',
      descrizione: 'Testo',
      carattere: const ['Dolce'],
      conPersone: ConPersone.moltoSocievole,
      conCani: ConCani.daTestare,
      conGatti: ConGatti.no,
      conBambini: ConBambini.soloGrandi,
      noteCarattere: '',
      fotoCopertinaId: null,
      referenteId: null,
      pubblicato: false,
      dataPubblicazione: null,
      archiviato: false,
      storicoStati: [
        StatoVoce(
          stato: DogStato.inRifugio,
          dal: at,
          note: 'Ingresso',
          autoreId: 'u1',
        ),
      ],
      audit: audit,
    );

    final again = Dog.fromMap(dog.id, dog.toMap());
    expect(again.nome, 'Fenice');
    expect(again.dataNascita, isNull);
    expect(again.pesoKg, isNull);
    expect(again.dataSterilizzazione, isNull);
    expect(again.fotoCopertinaId, isNull);
    expect(again.referenteId, isNull);
    expect(again.dataPubblicazione, isNull);
    expect(again.dataIngresso.toUtc(), at);
    expect(again.modalitaIngresso, ModalitaIngresso.natoInRifugio);
    expect(again.iscrittoAnagrafe, IscrittoAnagrafe.daVerificare);
    expect(again.storicoStati.single.stato, DogStato.inRifugio);
    expect(again.storicoStati.single.strutturaDestinazione, isNull);
    expect(again.patologie, '');
    expect(again.fotoCount, 0);
    expect(again.tipoPelo, isNull);
    expect(again.purezza, isNull);
    expect(again.dataIngressoStimata, isFalse);
    expect(again.toMap()['dataNascita'], isNull);
    expect(again.toMap()['fotoCount'], 0);
    expect(
      Dog.fromMap(dog.id, {...dog.toMap(), 'fotoCount': 4}).fotoCount,
      4,
    );
    expect(
      Dog.fromMap(dog.id, {...dog.toMap()..remove('fotoCount')}).fotoCount,
      0,
    );
  });

  test('Dog tiene vuoti come null: sterilizzato, extra anagrafe, ingresso stimato', () {
    final dog = Dog(
      id: 'orso',
      nome: 'Orso',
      sesso: DogSex.M,
      dataNascita: DateTime.utc(2021, 3, 17, 12),
      nascitaPresunta: false,
      razza: 'Meticcio',
      taglia: Taglia.media,
      pesoKg: null,
      mantello: 'Bianco',
      microchip: '380260160527395',
      iscrittoAnagrafe: IscrittoAnagrafe.si,
      provenienza: 'Corleto Perticara (PZ)',
      modalitaIngresso: ModalitaIngresso.rinuncia,
      dataIngresso: DateTime.utc(2024, 7, 11, 12),
      settore: '',
      box: '',
      stato: DogStato.inRifugio,
      statoDal: DateTime.utc(2024, 7, 11, 12),
      adottabile: null,
      sterilizzato: null,
      dataSterilizzazione: null,
      slogan: '',
      descrizione: '',
      carattere: const [],
      conPersone: null,
      conCani: ConCani.daTestare,
      conGatti: ConGatti.daTestare,
      conBambini: ConBambini.daTestare,
      noteCarattere: '',
      fotoCopertinaId: null,
      referenteId: null,
      pubblicato: false,
      dataPubblicazione: null,
      archiviato: false,
      storicoStati: const [],
      tipoPelo: TipoPelo.medio,
      purezza: Purezza.meticcio,
      dataApplicazioneChip: DateTime.utc(2023, 6, 17, 12),
      zonaApplicazioneChip: 'collo sx',
      veterinarioApplicatore: 'Tisci Tommaso',
      dataIscrizioneAnagrafe: null,
      ultimaUbicazione: 'C/DA PANTALOIANO',
      dataIngressoStimata: true,
      audit: audit,
    );
    final map = dog.toMap();
    expect(map['sterilizzato'], isNull);
    expect(map['adottabile'], isNull);
    expect(map['conPersone'], isNull);
    expect(map['tipoPelo'], 'medio');
    expect(map['purezza'], 'meticcio');
    expect(map['dataIngressoStimata'], isTrue);
    final again = Dog.fromMap(dog.id, map);
    expect(again.sterilizzato, isNull);
    expect(again.adottabile, isNull);
    expect(again.conPersone, isNull);
    expect(again.tipoPelo, TipoPelo.medio);
    expect(again.purezza, Purezza.meticcio);
    expect(again.dataIngressoStimata, isTrue);
    expect(again.zonaApplicazioneChip, 'collo sx');
    expect(again.veterinarioApplicatore, 'Tisci Tommaso');
    expect(
      Dog.fromMap(dog.id, {...map..remove('sterilizzato')}).sterilizzato,
      isNull,
    );
  });

  test('Dog.fromMap accetta sesso nullo e lo serializza come null', () {
    final dog = Dog(
      id: 'duca',
      nome: 'Duca',
      sesso: null,
      dataNascita: null,
      nascitaPresunta: true,
      razza: '',
      taglia: Taglia.media,
      pesoKg: null,
      mantello: '',
      microchip: '',
      iscrittoAnagrafe: IscrittoAnagrafe.daVerificare,
      provenienza: 'Stigliano (MT)',
      modalitaIngresso: ModalitaIngresso.trasferimento,
      dataIngresso: at,
      settore: '',
      box: '',
      stato: DogStato.inRifugio,
      statoDal: at,
      adottabile: false,
      sterilizzato: false,
      dataSterilizzazione: null,
      slogan: '',
      descrizione: '',
      carattere: const [],
      conPersone: ConPersone.selettivo,
      conCani: ConCani.daTestare,
      conGatti: ConGatti.daTestare,
      conBambini: ConBambini.daTestare,
      noteCarattere: '',
      fotoCopertinaId: null,
      referenteId: null,
      pubblicato: false,
      dataPubblicazione: null,
      archiviato: false,
      storicoStati: const [],
      audit: audit,
    );
    expect(dog.toMap()['sesso'], isNull);
    final fromNull = Dog.fromMap('duca', {
      ...dog.toMap(),
      'sesso': null,
    });
    expect(fromNull.sesso, isNull);
    expect(fromNull.toMap()['sesso'], isNull);
    final fromMissing = Dog.fromMap('duca', {
      ...dog.toMap()..remove('sesso'),
    });
    expect(fromMissing.sesso, isNull);
    final fromEmpty = Dog.fromMap('duca', {
      ...dog.toMap(),
      'sesso': '',
    });
    expect(fromEmpty.sesso, isNull);
  });

  test('StatoVoce round-trip con strutturaDestinazione', () {
    final voce = StatoVoce(
      stato: DogStato.trasferito,
      dal: at,
      note: 'Trasferimento',
      autoreId: 'u1',
      strutturaDestinazione: 'Canile di Potenza',
    );
    final again = StatoVoce.fromMap(voce.toMap());
    expect(again.stato, DogStato.trasferito);
    expect(again.strutturaDestinazione, 'Canile di Potenza');
  });

  test('Photo e PhotoFull round-trip', () {
    final thumb = Uint8List.fromList([1, 2, 3]);
    final photo = Photo(
      id: 'p1',
      dogId: 'fenice',
      isCover: true,
      w: 160,
      h: 120,
      mime: 'image/jpeg',
      thumb: thumb,
      bytesFull: 12000,
      createdAt: at,
      createdBy: 'u1',
    );
    final map = photo.toMap();
    expect(map['thumb'], isA<Blob>());
    expect(map.containsKey('thumbB64'), isFalse);
    final again = Photo.fromMap(photo.id, map);
    expect(again.dogId, 'fenice');
    expect(again.createdAt.toUtc(), at);
    expect(again.thumb, thumb);
    final full = PhotoFull(dati: Uint8List.fromList([9, 8, 7]));
    expect(full.toMap()['dati'], isA<Blob>());
    expect(full.toMap().containsKey('b64'), isFalse);
    expect(PhotoFull.fromMap(full.toMap()).dati, [9, 8, 7]);
  });

  test('HealthRecord round-trip con scadenza e costo null', () {
    final record = HealthRecord(
      id: 'h1',
      dogId: 'fenice',
      tipo: HealthTipo.vaccino,
      data: at,
      descrizione: 'Cimurro',
      veterinario: 'Dr. Greco',
      lotto: 'L1',
      prossimaScadenza: null,
      costo: null,
      audit: audit,
    );
    final again = HealthRecord.fromMap(record.id, record.toMap());
    expect(again.prossimaScadenza, isNull);
    expect(again.costo, isNull);
    expect(again.data.toUtc(), at);
    expect(again.tipo, HealthTipo.vaccino);
  });

  test('Expense round-trip con dogId null (spesa generale)', () {
    final expense = Expense(
      id: 'e1',
      dogId: null,
      categoria: ExpenseCategoria.cibo,
      importo: 45.5,
      data: at,
      descrizione: 'Crocchette',
      fornitore: 'Agraria',
      audit: audit,
    );
    final again = Expense.fromMap(expense.id, expense.toMap());
    expect(again.dogId, isNull);
    expect(again.importo, 45.5);
    expect(again.toMap()['dogId'], isNull);
  });

  test('Adoption round-trip con preaffido null e valorizzato', () {
    final empty = Adoption(
      id: 'a1',
      dogId: 'luna',
      richiedente: const Richiedente(
        nome: 'Marta',
        cognome: 'Rossi',
        telefono: '320',
        email: 'm@a.it',
        citta: 'Sassari',
        indirizzo: 'Via 1',
        docTipo: 'CI',
        docNumero: 'X',
        eta: 34,
      ),
      questionario: const Questionario(
        abitazione: 'Casa',
        giardinoRecintato: true,
        altezzaRecinzione: '180',
        altriAnimali: 'No',
        bambini: 'No',
        oreDaSolo: '2',
        esperienzaCani: 'Sì',
        doveDormira: 'Casa',
        note: '',
      ),
      stato: AdoptionStato.ricevuta,
      storicoStati: [
        AdoptionStatoVoce(
          stato: AdoptionStato.ricevuta,
          data: at,
          note: '',
          autoreId: 'u1',
        ),
      ],
      preaffidoDal: null,
      preaffidoAl: null,
      referenteId: 'seed_giovanna',
      dataRichiesta: at,
      audit: audit,
    );
    final again = Adoption.fromMap(empty.id, empty.toMap());
    expect(again.preaffidoDal, isNull);
    expect(again.richiedente.nome, 'Marta');
    expect(again.adopterId, '');
    expect(again.questionario.giardinoRecintato, isTrue);

    final withDates = Adoption.fromMap(empty.id, {
      ...empty.toMap(),
      'preaffidoDal': dateTimeTo(at),
      'preaffidoAl': dateTimeTo(at.add(const Duration(days: 30))),
    });
    expect(withDates.preaffidoDal!.toUtc(), at);
  });

  test('Adopter round-trip con dataNascita null e valorizzata', () {
    final empty = Adopter(
      id: 'adp1',
      nome: 'Marta',
      cognome: 'Rossi',
      telefono: '320',
      email: 'm@a.it',
      citta: 'Sassari',
      indirizzo: 'Via 1',
      docTipo: 'CI',
      docNumero: 'X',
      dataNascita: null,
      note: '',
      adozioniIds: const ['a1'],
      affidabilita: Affidabilita.ok,
      audit: audit,
    );
    final again = Adopter.fromMap(empty.id, empty.toMap());
    expect(again.dataNascita, isNull);
    expect(again.nomeCompleto, 'Marta Rossi');
    expect(again.adozioniIds, ['a1']);

    final withDate = Adopter.fromMap(empty.id, {
      ...empty.toMap(),
      'dataNascita': dateTimeTo(at),
      'affidabilita': 'non_idoneo',
    });
    expect(withDate.dataNascita!.toUtc(), at);
    expect(withDate.affidabilita, Affidabilita.nonIdoneo);
  });

  test('Vendor round-trip', () {
    final item = Vendor(
      id: 'v1',
      nome: 'Datena Anna Maria',
      tipo: VendorTipo.veterinario,
      telefono: '333',
      email: 'a@b.it',
      indirizzo: 'Via 1',
      convenzionato: true,
      note: 'note',
      audit: audit,
    );
    final again = Vendor.fromMap(item.id, item.toMap());
    expect(again.nome, 'Datena Anna Maria');
    expect(again.tipo, VendorTipo.veterinario);
    expect(again.convenzionato, isTrue);
  });

  test('AppDocument, Note, Appointment, Volunteer, Box, Settings', () {
    final doc = AppDocument(
      id: 'd1',
      dogId: 'fenice',
      adoptionId: null,
      adopterId: '',
      tipo: DocumentTipo.verbale,
      nome: 'Verbale',
      mime: 'application/pdf',
      chunkCount: 0,
      contenutoB64: null,
      caricatoIl: at,
      caricatoDa: 'u1',
    );
    expect(AppDocument.fromMap(doc.id, doc.toMap()).adoptionId, isNull);
    expect(AppDocument.fromMap(doc.id, doc.toMap()).contenutoB64, isNull);
    expect(AppDocument.fromMap(doc.id, doc.toMap()).chunkCount, 0);

    final inviato = AdoptionStatoVoce.moduloInviato(
      moduloId: 'preaffido',
      data: at,
      autoreId: 'u1',
    );
    final inviatoAgain = AdoptionStatoVoce.fromMap(inviato.toMap());
    expect(inviatoAgain.isModuloInviato, isTrue);
    expect(inviatoAgain.moduloId, 'preaffido');
    expect(inviatoAgain.toMap()['stato'], 'modulo_inviato');

    final template = DocumentTemplate(
      id: 'preaffido',
      nome: 'Modulo di preaffido',
      descrizione: 'In bianco',
      fileName: 'modulo-preaffido.pdf',
      mime: 'application/pdf',
      pdfB64: 'abc',
      versione: 1,
      aggiornatoIl: at,
      aggiornatoDa: 'u1',
    );
    expect(DocumentTemplate.fromMap(template.id, template.toMap()).versione, 1);
    expect(
      DocumentTemplate.fromMap(template.id, template.toMap()).visibilita,
      TemplateVisibilita.entrambi,
    );
    expect(
      DocumentTemplate.fromMap('x', {
        ...template.toMap(),
        'visibilita': 'home',
      }).visibilita,
      TemplateVisibilita.home,
    );

    final note = Note(
      id: 'n1',
      dogId: 'fenice',
      tipo: NoteTipo.attenzione,
      testo: 'Timida',
      autoreId: 'u1',
      createdAt: at,
    );
    expect(Note.fromMap(note.id, note.toMap()).tipo, NoteTipo.attenzione);

    final appointment = Appointment(
      id: 'ap1',
      tipo: AppointmentTipo.verificaPreaffido,
      titolo: 'Verifica',
      dogId: 'otto',
      adoptionId: null,
      inizio: at,
      fine: null,
      tuttoIlGiorno: true,
      luogo: 'Rifugio',
      stato: AppointmentStato.previsto,
      audit: audit,
    );
    final againAp = Appointment.fromMap(appointment.id, appointment.toMap());
    expect(againAp.fine, isNull);
    expect(againAp.tipo, AppointmentTipo.verificaPreaffido);

    final volunteer = Volunteer(
      id: 'v1',
      nome: 'Giovanna',
      cognome: 'Rossi',
      email: 'g@a.it',
      ruolo: VolunteerRuolo.presidente,
      attivo: true,
      coloreAvatar: '#157A3C',
      mustChangePassword: true,
      ultimoAccesso: DateTime.utc(2026, 9, 1),
      audit: audit,
    );
    final againVol = Volunteer.fromMap(volunteer.id, volunteer.toMap());
    expect(againVol.attivo, isTrue);
    expect(againVol.cognome, 'Rossi');
    expect(againVol.mustChangePassword, isTrue);
    expect(againVol.ultimoAccesso?.toUtc(), DateTime.utc(2026, 9, 1));
    expect(
      Volunteer(
        id: 'v2',
        nome: 'Anna',
        email: 'a@a.it',
        ruolo: VolunteerRuolo.volontario,
        attivo: true,
        coloreAvatar: '#2E7FD6',
        audit: audit,
      ).toMap().containsKey('ultimoAccesso'),
      isFalse,
    );

    final box = ShelterBox(
      id: 'b7',
      settore: 'B',
      numero: '7',
      capienza: 2,
      tipo: BoxTipo.normale,
      note: '',
      inManutenzione: false,
      audit: audit,
    );
    expect(ShelterBox.fromMap(box.id, box.toMap()).tipo, BoxTipo.normale);

    final settings = AssociationSettings(
      denominazione: 'Amici per la Coda ODV',
      codiceFiscale: '93081210721',
      sede: 'Corleto Perticara (PZ)',
      capienzaAutorizzata: 54,
      logoB64: null,
      audit: audit,
    );
    expect(
      AssociationSettings.fromMap(settings.toMap()).logoB64,
      isNull,
    );
    expect(
      AssociationSettings.fromMap(settings.toMap()).notificheScadenzeSanitarie,
      isTrue,
    );
    expect(
      AssociationSettings.fromMap(settings.toMap()).notificheRiepilogoSettimanale,
      isFalse,
    );
    final withPrefs = settings.copyWith(
      notificheRiepilogoSettimanale: true,
      ultimoExportAt: at,
    );
    final round = AssociationSettings.fromMap(withPrefs.toMap());
    expect(round.notificheRiepilogoSettimanale, isTrue);
    expect(round.ultimoExportAt, isNotNull);
  });

  test('Weight round-trip', () {
    final weight = Weight(
      id: 'w1',
      dogId: 'fenice',
      data: at,
      kg: 22.5,
      autoreId: 'u1',
      note: 'pesato in ambulatorio',
      audit: audit,
    );
    final again = Weight.fromMap(weight.id, weight.toMap());
    expect(again.dogId, 'fenice');
    expect(again.kg, 22.5);
    expect(again.autoreId, 'u1');
    expect(again.note, 'pesato in ambulatorio');
    expect(again.data.toUtc(), at);
  });

  test('Sponsorship round-trip con al null e valorizzato', () {
    final empty = Sponsorship(
      id: 's1',
      dogId: 'fenice',
      sostenitore: const Sostenitore(
        nome: 'Anna',
        cognome: 'Bianchi',
        email: 'a@b.it',
        telefono: '333',
      ),
      importoMensile: 15,
      attiva: true,
      dal: at,
      al: null,
      note: 'mensile',
      audit: audit,
    );
    final again = Sponsorship.fromMap(empty.id, empty.toMap());
    expect(again.al, isNull);
    expect(again.sostenitore.nome, 'Anna');
    expect(again.importoMensile, 15);
    expect(again.attiva, isTrue);
    expect(again.toMap()['al'], isNull);

    final closed = Sponsorship.fromMap(empty.id, {
      ...empty.toMap(),
      'al': dateTimeTo(at.add(const Duration(days: 30))),
      'attiva': false,
    });
    expect(closed.al!.toUtc(), at.add(const Duration(days: 30)));
    expect(closed.attiva, isFalse);
  });
}
