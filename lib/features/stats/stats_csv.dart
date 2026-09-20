import '../../core/format_it.dart';
import '../../data/models/dog.dart';
import '../../data/models/volunteer.dart';
import '../dogs/dog_labels.dart';
import '../dogs/tab_labels.dart';

const anagrafeCsvHeaders = [
  'Nome',
  'Sesso',
  'Data nascita',
  'Razza',
  'Taglia',
  'Microchip',
  'Stato',
  'Settore',
  'Box',
  'Data ingresso',
  'Adottabile',
  'Archiviato',
  'Referente',
];

String csvEscape(String value) {
  if (value.contains(',') ||
      value.contains('"') ||
      value.contains('\n') ||
      value.contains('\r')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

String anagrafeCsvDi(
  List<Dog> dogs, {
  List<Volunteer> volunteers = const [],
}) {
  final rows = List<Dog>.of(dogs)
    ..sort((a, b) => dogDisplayName(a.nome).compareTo(dogDisplayName(b.nome)));
  final lines = <String>[
    anagrafeCsvHeaders.map(csvEscape).join(','),
    for (final dog in rows)
      [
        dogDisplayName(dog.nome),
        dogSexLabel(dog.sesso),
        dog.dataNascita == null ? '' : formatItalianDate(dog.dataNascita!),
        dog.razza,
        tagliaLabel(dog.taglia),
        dog.microchip,
        dogStatoLabel(dog.stato),
        dog.settore,
        dog.box,
        formatItalianDate(dog.dataIngresso),
        dog.adottabile == true
            ? 'Sì'
            : dog.adottabile == false
            ? 'No'
            : '',
        dog.archiviato ? 'Sì' : 'No',
        volunteerNomeDi(volunteers, dog.referenteId ?? ''),
      ].map(csvEscape).join(','),
  ];
  return '${lines.join('\n')}\n';
}
