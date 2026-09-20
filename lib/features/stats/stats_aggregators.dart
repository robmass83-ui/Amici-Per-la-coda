import '../../core/format_it.dart';
import '../../data/dog_archive.dart';
import '../../data/models/adoption.dart';
import '../../data/models/dog.dart';
import '../../data/models/enums.dart';
import '../../data/models/expense.dart';
import '../../data/models/sponsorship.dart';
import '../dashboard/home_aggregators.dart';

class CompositionSlice {
  const CompositionSlice({
    required this.label,
    required this.count,
    required this.percentuale,
  });

  final String label;
  final int count;
  final int percentuale;
}

class YearStats {
  const YearStats({
    required this.year,
    required this.adozioniConcluse,
    required this.nuoviIngressi,
    required this.giorniMediInRifugio,
    required this.rientriDopoAffido,
    required this.adozioniPerMese,
    required this.composizione,
    required this.speseTotali,
    required this.donazioniRicevute,
    required this.adozioniADistanza,
  });

  final int year;
  final int adozioniConcluse;
  final int nuoviIngressi;
  final int giorniMediInRifugio;
  final int rientriDopoAffido;
  final List<int> adozioniPerMese;
  final List<CompositionSlice> composizione;
  final double speseTotali;
  final double donazioniRicevute;
  final double adozioniADistanza;

  double get saldo => donazioniRicevute + adozioniADistanza - speseTotali;
}

bool dogIsCucciolo(Dog dog, DateTime now) {
  final birth = dog.dataNascita;
  if (birth == null) {
    return false;
  }
  return now.difference(birth).inDays < 365;
}

int nuoviIngressiDellAnno(List<Dog> dogs, int year) {
  var n = 0;
  for (final dog in dogs) {
    if (dog.dataIngresso.year == year) {
      n++;
    }
  }
  return n;
}

int giorniMediInRifugioDi(List<Dog> dogs, DateTime now) {
  var sum = 0;
  var n = 0;
  for (final dog in dogs) {
    if (dogEsclusoDaConteggiRifugio(dog)) {
      continue;
    }
    final days = now.difference(dog.dataIngresso).inDays;
    sum += days < 0 ? 0 : days;
    n++;
  }
  if (n == 0) {
    return 0;
  }
  return (sum / n).round();
}

int rientriDopoAffidoDellAnno(List<Dog> dogs, int year) {
  final ids = <String>{};
  for (final dog in dogs) {
    for (final voce in dog.storicoStati) {
      if (voce.stato == DogStato.restituito && voce.dal.year == year) {
        ids.add(dog.id);
        break;
      }
    }
  }
  return ids.length;
}

List<int> adozioniPerMeseDi(List<Adoption> adoptions, int year) {
  final months = List<int>.filled(12, 0);
  for (final adoption in adoptions) {
    if (adoption.stato != AdoptionStato.adottato) {
      continue;
    }
    if (adoption.storicoStati.isEmpty) {
      continue;
    }
    final at = adoption.storicoStati.last.data;
    if (at.year != year) {
      continue;
    }
    months[at.month - 1]++;
  }
  return months;
}

List<CompositionSlice> composizioneRifugioDi(List<Dog> dogs, DateTime now) {
  var media = 0;
  var grande = 0;
  var piccola = 0;
  var cuccioli = 0;
  for (final dog in dogs) {
    if (dogEsclusoDaConteggiRifugio(dog)) {
      continue;
    }
    if (dogIsCucciolo(dog, now)) {
      cuccioli++;
      continue;
    }
    switch (dog.taglia) {
      case Taglia.media:
        media++;
      case Taglia.grande:
        grande++;
      case Taglia.piccola:
        piccola++;
    }
  }
  final counts = [media, grande, piccola, cuccioli];
  final total = counts.fold<int>(0, (sum, n) => sum + n);
  final perc = _percentualiIntere(counts, total);
  const labels = [
    'Taglia media',
    'Taglia grande',
    'Taglia piccola',
    'Cuccioli',
  ];
  return [
    for (var i = 0; i < labels.length; i++)
      CompositionSlice(
        label: labels[i],
        count: counts[i],
        percentuale: perc[i],
      ),
  ];
}

List<int> _percentualiIntere(List<int> counts, int total) {
  if (total <= 0) {
    return List<int>.filled(counts.length, 0);
  }
  final raw = [for (final n in counts) (n / total) * 100];
  final floors = [for (final value in raw) value.floor()];
  var rest = 100 - floors.fold<int>(0, (sum, value) => sum + value);
  final order = List<int>.generate(raw.length, (i) => i)
    ..sort((a, b) {
      final ra = raw[a] - floors[a];
      final rb = raw[b] - floors[b];
      return rb.compareTo(ra);
    });
  final perc = List<int>.of(floors);
  for (var i = 0; i < rest && i < order.length; i++) {
    perc[order[i]]++;
  }
  return perc;
}

double speseDellAnno(List<Expense> expenses, int year) {
  var total = 0.0;
  for (final item in expenses) {
    if (item.data.year == year) {
      total += item.importo;
    }
  }
  return total;
}

int mesiSovrappostiAnno({
  required DateTime dal,
  required DateTime? al,
  required int year,
  required DateTime now,
}) {
  final yearStart = DateTime(year, 1, 1);
  final yearEnd = DateTime(year, 12, 31);
  final cap = now.year == year && now.isBefore(yearEnd) ? now : yearEnd;
  var start = dal.isAfter(yearStart) ? dal : yearStart;
  var end = al ?? cap;
  if (end.isAfter(cap)) {
    end = cap;
  }
  if (end.isBefore(start)) {
    return 0;
  }
  final months =
      (end.year - start.year) * 12 + (end.month - start.month) + 1;
  return months < 0 ? 0 : months;
}

double adozioniADistanzaDellAnno(
  List<Sponsorship> sponsorships, {
  required int year,
  required DateTime now,
}) {
  var total = 0.0;
  for (final item in sponsorships) {
    final months = mesiSovrappostiAnno(
      dal: item.dal,
      al: item.al,
      year: year,
      now: now,
    );
    total += item.importoMensile * months;
  }
  return total;
}

String formatSaldo(double value) {
  if (value > 0) {
    return '+ ${formatEuro(value)}';
  }
  return formatEuro(value);
}

List<String> mesiBreviAnno() => List<String>.from(_mesiStats);

const _mesiStats = [
  'G',
  'F',
  'M',
  'A',
  'M',
  'G',
  'L',
  'A',
  'S',
  'O',
  'N',
  'D',
];

YearStats buildYearStats({
  required List<Dog> dogs,
  required List<Adoption> adoptions,
  required List<Expense> expenses,
  required List<Sponsorship> sponsorships,
  required int year,
  required DateTime now,
}) {
  return YearStats(
    year: year,
    adozioniConcluse: adozioniDellAnno(adoptions, year),
    nuoviIngressi: nuoviIngressiDellAnno(dogs, year),
    giorniMediInRifugio: giorniMediInRifugioDi(dogs, now),
    rientriDopoAffido: rientriDopoAffidoDellAnno(dogs, year),
    adozioniPerMese: adozioniPerMeseDi(adoptions, year),
    composizione: composizioneRifugioDi(dogs, now),
    speseTotali: speseDellAnno(expenses, year),
    donazioniRicevute: 0,
    adozioniADistanza: adozioniADistanzaDellAnno(
      sponsorships,
      year: year,
      now: now,
    ),
  );
}

int primoAnnoDisponibile(List<Dog> dogs, DateTime now) {
  var year = now.year;
  for (final dog in dogs) {
    if (dog.dataIngresso.year < year) {
      year = dog.dataIngresso.year;
    }
  }
  return year;
}
