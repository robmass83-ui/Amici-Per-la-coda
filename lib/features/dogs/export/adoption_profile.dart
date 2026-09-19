import 'dart:convert';
import 'dart:typed_data';

import '../../../core/format_it.dart';
import '../../../data/models/association_settings.dart';
import '../../../data/models/dog.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/health_record.dart';
import '../../../data/models/weight.dart';
import '../dog_labels.dart';

const logoAssetPath = 'assets/logo.png';
const maxFotoSchedaAdozione = 20;

const _mesiIt = [
  'Gennaio',
  'Febbraio',
  'Marzo',
  'Aprile',
  'Maggio',
  'Giugno',
  'Luglio',
  'Agosto',
  'Settembre',
  'Ottobre',
  'Novembre',
  'Dicembre',
];

/// Sorgente unica dei dati pubblici per PDF e card social.
///
/// Allowlist: nome, slogan, descrizione, sesso, eta, razza, taglia, peso,
/// provenienza (comune), in rifugio da, stato pubblico, sanitario sintetico,
/// carattere, compatibilità, foto, associazione, data generazione.
/// Vietati: microchip, box, settore, spese, richieste, note interne,
/// referente, id, documenti, audit.
class AdoptionAssociation {
  const AdoptionAssociation({
    required this.nome,
    required this.citta,
    required this.telefono,
    required this.email,
    this.logo,
    this.logoFromAsset = false,
  });

  final String nome;
  final String citta;
  final String telefono;
  final String email;
  final Uint8List? logo;
  final bool logoFromAsset;

  factory AdoptionAssociation.fromSettings(
    AssociationSettings? settings, {
    Uint8List? assetLogo,
  }) {
    Uint8List? logo;
    var fromAsset = false;
    final b64 = settings?.logoB64?.trim() ?? '';
    if (b64.isNotEmpty) {
      try {
        logo = Uint8List.fromList(base64Decode(b64));
      } catch (_) {
        logo = null;
      }
    }
    if (logo == null || logo.isEmpty) {
      logo = assetLogo;
      fromAsset = assetLogo != null && assetLogo.isNotEmpty;
    }
    final sede = settings?.sede.trim() ?? '';
    return AdoptionAssociation(
      nome: (settings?.denominazione.trim().isNotEmpty ?? false)
          ? settings!.denominazione.trim()
          : 'Amici per la Coda',
      citta: comuneDi(sede),
      telefono: settings?.telefono.trim() ?? '',
      email: settings?.email.trim() ?? '',
      logo: logo,
      logoFromAsset: fromAsset,
    );
  }

  Map<String, Object?> toJson() => {
    'nome': nome,
    'citta': citta,
    'telefono': telefono,
    'email': email,
    'logoBytes': logo?.length ?? 0,
  };
}

class AdoptionProfile {
  const AdoptionProfile({
    required this.nome,
    required this.slogan,
    required this.descrizione,
    required this.sesso,
    required this.etaTesto,
    required this.razza,
    required this.taglia,
    required this.pesoTesto,
    required this.provenienza,
    required this.inRifugioDa,
    required this.statoPubblico,
    required this.sterilizzato,
    required this.dataSterilizzazione,
    required this.vaccinatoInRegola,
    required this.dataVaccino,
    required this.antiparassitarioInRegola,
    required this.haVacciniRegistrati,
    required this.haAntiparassitarioRegistrato,
    required this.testLeishmania,
    required this.carattere,
    required this.conPersone,
    required this.conCani,
    required this.conGatti,
    required this.conBambini,
    required this.noteCarattere,
    required this.fotoCopertina,
    required this.altreFoto,
    required this.associazione,
    required this.dataGenerazione,
  });

  final String nome;
  final String slogan;
  final String descrizione;
  final DogSex? sesso;
  final String etaTesto;
  final String razza;
  final Taglia taglia;
  final String pesoTesto;
  final String provenienza;
  final String inRifugioDa;
  final String statoPubblico;
  final bool sterilizzato;
  final DateTime? dataSterilizzazione;
  final bool vaccinatoInRegola;
  final DateTime? dataVaccino;
  final bool antiparassitarioInRegola;
  final bool haVacciniRegistrati;
  final bool haAntiparassitarioRegistrato;
  final String? testLeishmania;
  final List<String> carattere;
  final ConPersone conPersone;
  final ConCani conCani;
  final ConGatti conGatti;
  final ConBambini conBambini;
  final String noteCarattere;
  final Uint8List? fotoCopertina;
  final List<Uint8List> altreFoto;
  final AdoptionAssociation associazione;
  final DateTime dataGenerazione;

  bool get isFemmina => sesso == DogSex.F;

  bool get etaSconosciuta =>
      etaTesto.trim().isEmpty || etaTesto.trim() == '—';

  bool get pesoSconosciuto =>
      pesoTesto.trim().isEmpty || pesoTesto.trim() == '—';

  bool get haDatoSanitario =>
      sterilizzato ||
      haVacciniRegistrati ||
      haAntiparassitarioRegistrato ||
      testLeishmania != null;

  String get statoPillola => switch (statoPubblico) {
    'in_preaffido' => 'IN PREAFFIDO',
    'adottato' => 'ADOTTATO',
    _ => 'CERCA FAMIGLIA',
  };

  /// Serializzazione allowlist: niente chiavi interne, niente bytes grezzi.
  Map<String, Object?> toJson() {
    return {
      'nome': nome,
      'slogan': slogan,
      'descrizione': descrizione,
      'sesso': sesso?.wire,
      'etaTesto': etaTesto,
      'razza': razza,
      'taglia': taglia.wire,
      'pesoTesto': pesoTesto,
      'provenienza': provenienza,
      'inRifugioDa': inRifugioDa,
      'statoPubblico': statoPubblico,
      'sterilizzato': sterilizzato,
      'dataSterilizzazione': dataSterilizzazione?.toIso8601String(),
      'vaccinatoInRegola': vaccinatoInRegola,
      'dataVaccino': dataVaccino?.toIso8601String(),
      'antiparassitarioInRegola': antiparassitarioInRegola,
      'haVacciniRegistrati': haVacciniRegistrati,
      'haAntiparassitarioRegistrato': haAntiparassitarioRegistrato,
      'testLeishmania': testLeishmania,
      'carattere': carattere,
      'conPersone': conPersone.wire,
      'conCani': conCani.wire,
      'conGatti': conGatti.wire,
      'conBambini': conBambini.wire,
      'noteCarattere': noteCarattere,
      'fotoCopertinaBytes': fotoCopertina?.length ?? 0,
      'altreFotoCount': altreFoto.length,
      'associazione': associazione.toJson(),
      'dataGenerazione': dataGenerazione.toIso8601String(),
    };
  }

  /// Unica fabbrica: copia i campi pubblici e calcola vaccino/antiparassitario.
  factory AdoptionProfile.fromDog(
    Dog dog,
    List<HealthRecord> health,
    List<Weight> weights,
    List<Uint8List> photos,
    AdoptionAssociation association, {
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    final cover = photos.isEmpty ? null : photos.first;
    final extra = photos.length <= 1
        ? const <Uint8List>[]
        : photos.sublist(
            1,
            photos.length > maxFotoSchedaAdozione
                ? maxFotoSchedaAdozione
                : photos.length,
          );
    final latestKg = _latestKg(weights) ?? dog.pesoKg;
    final vaccines = health.where((item) => item.tipo == HealthTipo.vaccino);
    final lastVaccine = _latestByDate(vaccines);
    final parasites = health.where(
      (item) => item.tipo == HealthTipo.antiparassitario,
    );
    final lastParasite = _latestByDate(parasites);
    return AdoptionProfile(
      nome: dogDisplayName(dog.nome),
      slogan: dog.slogan.trim(),
      descrizione: dog.descrizione.trim(),
      sesso: dog.sesso,
      etaTesto: dogAgeShortLabel(dog, at, compact: false) ?? '—',
      razza: dog.razza.trim(),
      taglia: dog.taglia,
      pesoTesto: latestKg == null
          ? '—'
          : 'Circa ${formatItalianNumber(latestKg)} kg',
      provenienza: comuneDi(dog.provenienza),
      inRifugioDa: meseAnnoDi(dog.dataIngresso),
      statoPubblico: statoPubblicoDi(dog.stato),
      sterilizzato: dog.sterilizzato == true,
      dataSterilizzazione: dog.dataSterilizzazione,
      vaccinatoInRegola: vaccinatoInRegolaDi(health, at),
      dataVaccino: lastVaccine == null
          ? null
          : (lastVaccine.prossimaScadenza ?? lastVaccine.data),
      antiparassitarioInRegola: antiparassitarioInRegolaDi(health, at),
      haVacciniRegistrati: lastVaccine != null,
      haAntiparassitarioRegistrato: lastParasite != null,
      testLeishmania: testLeishmaniaDi(health),
      carattere: List<String>.from(dog.carattere),
      conPersone: dog.conPersone ?? ConPersone.selettivo,
      conCani: dog.conCani,
      conGatti: dog.conGatti,
      conBambini: dog.conBambini,
      noteCarattere: dog.noteCarattere.trim(),
      fotoCopertina: cover,
      altreFoto: extra,
      associazione: association,
      dataGenerazione: at,
    );
  }
}

String statoPubblicoDi(DogStato stato) {
  return switch (stato) {
    DogStato.preaffido => 'in_preaffido',
    DogStato.adottato => 'adottato',
    _ => 'cerca_famiglia',
  };
}

String comuneDi(String provenienza) {
  final raw = provenienza.trim();
  if (raw.isEmpty) {
    return '';
  }
  final cut = raw.indexOf('(');
  if (cut <= 0) {
    return raw;
  }
  return raw.substring(0, cut).trim();
}

String meseAnnoDi(DateTime date) {
  final local = date.toLocal();
  return '${_mesiIt[local.month - 1]} ${local.year}';
}

bool vaccinatoInRegolaDi(List<HealthRecord> health, DateTime now) {
  final from = now.subtract(const Duration(days: 365));
  for (final item in health) {
    if (item.tipo != HealthTipo.vaccino) {
      continue;
    }
    if (item.data.isBefore(from)) {
      continue;
    }
    final next = item.prossimaScadenza;
    if (next == null || !next.isBefore(now)) {
      return true;
    }
  }
  return false;
}

bool antiparassitarioInRegolaDi(List<HealthRecord> health, DateTime now) {
  final from = now.subtract(const Duration(days: 45));
  DateTime? last;
  for (final item in health) {
    if (item.tipo != HealthTipo.antiparassitario) {
      continue;
    }
    if (last == null || item.data.isAfter(last)) {
      last = item.data;
    }
  }
  if (last == null) {
    return false;
  }
  return !last.isBefore(from);
}

String? testLeishmaniaDi(List<HealthRecord> health) {
  String? found;
  DateTime? at;
  for (final item in health) {
    final text = item.descrizione.toLowerCase();
    if (!text.contains('leish')) {
      continue;
    }
    if (at != null && item.data.isBefore(at)) {
      continue;
    }
    at = item.data;
    if (text.contains('positiv')) {
      found = 'positivo';
    } else if (text.contains('negativ')) {
      found = 'negativo';
    }
  }
  return found;
}

double? _latestKg(List<Weight> weights) {
  Weight? latest;
  for (final item in weights) {
    if (latest == null || item.data.isAfter(latest.data)) {
      latest = item;
    }
  }
  return latest?.kg;
}

HealthRecord? _latestByDate(Iterable<HealthRecord> items) {
  HealthRecord? latest;
  for (final item in items) {
    if (latest == null || item.data.isAfter(latest.data)) {
      latest = item;
    }
  }
  return latest;
}

/// Testo della sezione «La sua storia»: descrizione del cane, oppure due-tre
/// frasi costruite solo con i dati pubblici disponibili.
String storiaSchedaAdozione(AdoptionProfile profile) {
  final own = profile.descrizione.trim();
  if (own.isNotEmpty) {
    return own;
  }
  return storiaGenerata(profile);
}

String storiaGenerata(AdoptionProfile profile) {
  final femmina = profile.isFemmina;
  final articolo = femmina ? 'una' : 'un';
  final razza = profile.razza.trim().isNotEmpty
      ? profile.razza.trim()
      : (femmina ? 'cagna' : 'cane');
  final taglia = tagliaLabel(profile.taglia).toLowerCase();
  final sesso = dogSexLabel(profile.sesso).toLowerCase();
  final arrivato = femmina ? 'arrivata' : 'arrivato';
  final buf = StringBuffer(
    '${profile.nome} è $articolo $razza di taglia $taglia, $sesso',
  );
  if (profile.provenienza.isNotEmpty) {
    buf.write(', $arrivato a ${profile.provenienza}');
  }
  if (profile.inRifugioDa.isNotEmpty) {
    buf.write(' nel ${profile.inRifugioDa}');
  }
  buf.write('.');
  buf.write(' Con le persone: ${conPersoneLabel(profile.conPersone).toLowerCase()}.');
  final bits = <String>[];
  if (profile.sterilizzato) {
    bits.add(femmina ? 'Sterilizzata' : 'Castrato');
  }
  if (profile.haVacciniRegistrati) {
    bits.add(femmina ? 'vaccinata' : 'vaccinato');
  }
  if (bits.isNotEmpty) {
    buf.write(' ${bits.join(' e ')}.');
  }
  return buf.toString();
}
