const patologiePreset = [
  'Leishmania',
  'Filaria',
  'Parvovirosi',
  'Giardia',
  'Epilessia',
  'Cimurro',
  'Ehrlichia',
  'Babesia',
  'Dermatite',
];

final _patologieSep = RegExp(r'\s*[,;]\s*|\n+');

List<String> splitPatologie(String testo) {
  return testo
      .split(_patologieSep)
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

String joinPatologie(Iterable<String> parts) => parts.join(', ');

bool haPatologie(String testo) => testo.trim().isNotEmpty;

String patologieRiepilogo(String testo) {
  final trimmed = testo.trim();
  return trimmed.isEmpty ? 'Nessuna' : trimmed;
}

bool patologiaSelezionata(String testo, String tag) {
  final needle = tag.trim().toLowerCase();
  if (needle.isEmpty) {
    return false;
  }
  return splitPatologie(testo).any((item) => item.toLowerCase() == needle);
}

String togglePatologiaNelTesto(String testo, String tag) {
  final label = tag.trim();
  if (label.isEmpty) {
    return testo.trim();
  }
  final parts = splitPatologie(testo);
  final idx = parts.indexWhere(
    (item) => item.toLowerCase() == label.toLowerCase(),
  );
  if (idx >= 0) {
    parts.removeAt(idx);
  } else {
    parts.add(label);
  }
  return joinPatologie(parts);
}

List<String> patologiePresetSelezionate(String testo) {
  return [
    for (final tag in patologiePreset)
      if (patologiaSelezionata(testo, tag)) tag,
  ];
}

String patologieNotaLibera(String testo) {
  final preset = {
    for (final tag in patologiePreset) tag.toLowerCase(),
  };
  return joinPatologie(
    splitPatologie(testo).where((item) => !preset.contains(item.toLowerCase())),
  );
}
