import '../../core/firestore_codec.dart';
import '../models/dog.dart';
import '../models/enums.dart';
import 'cani_csv.dart';

/// Legge [caniCsvSource] e costruisce i cani veri dell'anagrafe.
List<Dog> dogsFromCaniCsv(Audit audit) {
  final rows = parseCsv(caniCsvSource);
  if (rows.isEmpty) {
    return const [];
  }
  final header = rows.first;
  final dogs = <Dog>[];
  for (var i = 1; i < rows.length; i++) {
    final row = rows[i];
    if (row.every((cell) => cell.trim().isEmpty)) {
      continue;
    }
    dogs.add(_dogFromRow(header, row, audit));
  }
  return dogs;
}

List<List<String>> parseCsv(String raw) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;

  void endField() {
    row.add(field.toString());
    field.clear();
  }

  void endRow() {
    endField();
    if (row.any((cell) => cell.trim().isNotEmpty)) {
      rows.add(row);
    }
    row = <String>[];
  }

  for (var i = 0; i < raw.length; i++) {
    final char = raw[i];
    if (inQuotes) {
      if (char == '"') {
        if (i + 1 < raw.length && raw[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(char);
      }
    } else if (char == '"') {
      inQuotes = true;
    } else if (char == ',') {
      endField();
    } else if (char == '\n') {
      endRow();
    } else if (char != '\r') {
      field.write(char);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    endRow();
  }
  return rows;
}

Dog _dogFromRow(List<String> header, List<String> row, Audit audit) {
  String cell(String name) {
    final index = header.indexOf(name);
    if (index < 0 || index >= row.length) {
      return '';
    }
    return row[index].trim();
  }

  final nome = cell('nome');
  final sessoRaw = cell('sesso');
  final dataNascita = _parseDate(cell('dataNascita'));
  final nascitaPresuntaRaw = cell('nascitaPresunta');
  final sterilizzato = _parseSiNo(cell('sterilizzato')) ?? false;
  final provenienza = cell('provenienza');
  final noteCsv = cell('note');
  final noteCarattereCsv = cell('noteCarattere');
  final fromStigliano = provenienza.toLowerCase().contains('stigliano');
  final nascitaPresunta = dataNascita == null
      ? true
      : nascitaPresuntaRaw.toUpperCase() == 'SI';
  final dataIngresso =
      _parseDate(cell('dataIngresso')) ??
      dataNascita ??
      DateTime.utc(2020, 1, 1);
  final stato = DogStato.parse(cell('stato'));
  final noteParts = <String>[
    if (noteCarattereCsv.isNotEmpty) noteCarattereCsv,
    if (noteCsv.isNotEmpty) noteCsv,
    if (sessoRaw.isEmpty) 'Sesso da rilevare.',
    if (dataNascita == null) 'Data di nascita da rilevare.',
    if (cell('dataIngresso').isEmpty) 'Data di ingresso da rilevare.',
  ];
  final pubblicato = _parseSiNo(cell('pubblicato')) ?? false;

  return Dog(
    id: slugDogId(nome),
    nome: nome,
    sesso: sessoRaw.isEmpty ? DogSex.M : DogSex.parse(sessoRaw),
    dataNascita: dataNascita,
    nascitaPresunta: nascitaPresunta,
    razza: cell('razza').isEmpty ? 'Meticcia' : cell('razza'),
    taglia: Taglia.parse(cell('taglia').isEmpty ? null : cell('taglia')),
    pesoKg: _parseDouble(cell('pesoKg')),
    mantello: cell('mantello'),
    microchip: cell('microchip'),
    iscrittoAnagrafe: IscrittoAnagrafe.parse(
      cell('iscrittoAnagrafe').isEmpty ? null : cell('iscrittoAnagrafe'),
    ),
    provenienza: provenienza,
    modalitaIngresso: ModalitaIngresso.parse(
      cell('modalitaIngresso').isEmpty
          ? (fromStigliano ? 'trasferimento' : null)
          : cell('modalitaIngresso'),
    ),
    dataIngresso: dataIngresso,
    settore: cell('settore'),
    box: cell('box'),
    stato: stato,
    statoDal: _parseDate(cell('statoDal')) ?? dataIngresso,
    adottabile: _parseSiNo(cell('adottabile')) ?? false,
    sterilizzato: sterilizzato,
    dataSterilizzazione: _parseDate(cell('dataSterilizzazione')),
    slogan: cell('slogan'),
    descrizione: cell('descrizione'),
    carattere: cell('carattere')
        .split(RegExp(r'[;|]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(),
    conPersone: ConPersone.parse(
      cell('conPersone').isEmpty ? null : cell('conPersone'),
    ),
    conCani: ConCani.parse(cell('conCani').isEmpty ? null : cell('conCani')),
    conGatti: ConGatti.parse(cell('conGatti').isEmpty ? null : cell('conGatti')),
    conBambini: ConBambini.parse(
      cell('conBambini').isEmpty ? null : cell('conBambini'),
    ),
    noteCarattere: noteParts.join(' '),
    fotoCopertinaId: null,
    referenteId: null,
    pubblicato: pubblicato,
    dataPubblicazione: pubblicato ? dataIngresso : null,
    archiviato: stato == DogStato.adottato || stato == DogStato.deceduto,
    storicoStati: [
      StatoVoce(
        stato: stato,
        dal: dataIngresso,
        note: 'Anagrafe CSV',
        autoreId: 'seed_import',
      ),
    ],
    audit: audit,
  );
}

String slugDogId(String nome) {
  const map = {
    'à': 'a',
    'á': 'a',
    'è': 'e',
    'é': 'e',
    'ì': 'i',
    'í': 'i',
    'ò': 'o',
    'ó': 'o',
    'ù': 'u',
    'ú': 'u',
    'ä': 'a',
    'ö': 'o',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
  };
  final buffer = StringBuffer();
  for (final rune in nome.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    buffer.write(map[char] ?? char);
  }
  return buffer
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}

DateTime? _parseDate(String raw) {
  if (raw.isEmpty) {
    return null;
  }
  final parts = raw.split('/');
  if (parts.length != 3) {
    return null;
  }
  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) {
    return null;
  }
  return DateTime.utc(year, month, day);
}

bool? _parseSiNo(String raw) {
  switch (raw.toUpperCase()) {
    case 'SI':
    case 'SÌ':
    case 'YES':
    case 'TRUE':
      return true;
    case 'NO':
    case 'FALSE':
      return false;
    default:
      return null;
  }
}

double? _parseDouble(String raw) {
  if (raw.isEmpty) {
    return null;
  }
  return double.tryParse(raw.replaceAll(',', '.'));
}
