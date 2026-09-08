import '../../core/format_it.dart';
import '../../data/models/enums.dart';
import '../../data/models/expense.dart';
import '../../data/models/health_record.dart';
import '../../data/models/sponsorship.dart';
import '../../data/models/weight.dart';

String healthTipoLabel(HealthTipo tipo) {
  return switch (tipo) {
    HealthTipo.vaccino => 'Vaccino',
    HealthTipo.sterilizzazione => 'Sterilizzazione',
    HealthTipo.sverminazione => 'Sverminazione',
    HealthTipo.antiparassitario => 'Antiparassitario',
    HealthTipo.visita => 'Visita',
    HealthTipo.esame => 'Esame',
    HealthTipo.terapia => 'Terapia',
    HealthTipo.altro => 'Altro',
  };
}

String expenseCategoriaLabel(ExpenseCategoria categoria) {
  return switch (categoria) {
    ExpenseCategoria.visita => 'Visite veterinarie',
    ExpenseCategoria.sterilizzazione => 'Sterilizzazione',
    ExpenseCategoria.farmaci => 'Farmaci',
    ExpenseCategoria.esami => 'Esami',
    ExpenseCategoria.cibo => 'Cibo',
    ExpenseCategoria.altro => 'Altro',
  };
}

ExpenseCategoria expenseCategoriaFromHealth(HealthTipo tipo) {
  return switch (tipo) {
    HealthTipo.vaccino || HealthTipo.visita => ExpenseCategoria.visita,
    HealthTipo.sterilizzazione => ExpenseCategoria.sterilizzazione,
    HealthTipo.esame => ExpenseCategoria.esami,
    HealthTipo.sverminazione ||
    HealthTipo.antiparassitario ||
    HealthTipo.terapia => ExpenseCategoria.farmaci,
    HealthTipo.altro => ExpenseCategoria.altro,
  };
}

List<HealthRecord> healthSortedByDataDesc(List<HealthRecord> records) {
  final copy = List<HealthRecord>.of(records);
  copy.sort((a, b) => b.data.compareTo(a.data));
  return copy;
}

List<HealthRecord> prossimeScadenzeDi(List<HealthRecord> records) {
  final withDate = records
      .where((item) => item.prossimaScadenza != null)
      .toList();
  withDate.sort(
    (a, b) => a.prossimaScadenza!.compareTo(b.prossimaScadenza!),
  );
  return withDate;
}

Map<ExpenseCategoria, double> spesePerCategoria(List<Expense> items) {
  final totals = <ExpenseCategoria, double>{};
  for (final item in items) {
    totals[item.categoria] = (totals[item.categoria] ?? 0) + item.importo;
  }
  return totals;
}

double totaleSpese(List<Expense> items) {
  return items.fold<double>(0, (sum, item) => sum + item.importo);
}

class RipartoVoce {
  const RipartoVoce({
    required this.categoria,
    required this.importo,
    required this.percentuale,
  });

  final ExpenseCategoria categoria;
  final double importo;
  final int percentuale;
}

/// Quote intere 0–100 che sommano sempre 100 (resto più grande).
List<RipartoVoce> ripartizioneSpese(List<Expense> items) {
  final byCat = spesePerCategoria(items);
  final total = totaleSpese(items);
  if (total <= 0) {
    return const [];
  }
  final entries = byCat.entries.where((e) => e.value > 0).toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final raw = [for (final e in entries) (e.value / total) * 100];
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
  return [
    for (var i = 0; i < entries.length; i++)
      RipartoVoce(
        categoria: entries[i].key,
        importo: entries[i].value,
        percentuale: perc[i],
      ),
  ];
}

int mesiTra(DateTime from, DateTime now) {
  var months = (now.year - from.year) * 12 + (now.month - from.month);
  if (now.day < from.day) {
    months--;
  }
  return months < 1 ? 1 : months;
}

double mediaMensileSpese(
  List<Expense> items, {
  required DateTime from,
  required DateTime now,
}) {
  return totaleSpese(items) / mesiTra(from, now);
}

class PesoPunto {
  const PesoPunto({required this.data, required this.kg});

  final DateTime data;
  final double kg;
}

List<PesoPunto> pesoPuntiDa(List<Weight> weights) {
  final points = [
    for (final weight in weights) PesoPunto(data: weight.data, kg: weight.kg),
  ];
  points.sort((a, b) => a.data.compareTo(b.data));
  return points;
}

class AdozioneADistanzaRiepilogo {
  const AdozioneADistanzaRiepilogo({
    required this.sostenitoriAttivi,
    required this.contributoMensile,
    required this.coperturaPercentuale,
  });

  final int sostenitoriAttivi;
  final double contributoMensile;
  final int coperturaPercentuale;
}

int coperturaAdozioneADistanza({
  required double contributoMensile,
  required double speseTotali,
  required int mesiPermanenza,
}) {
  if (speseTotali <= 0) {
    return 0;
  }
  final raw = contributoMensile * mesiPermanenza / speseTotali * 100;
  if (raw.isNaN || raw.isInfinite) {
    return 0;
  }
  return raw.clamp(0, 100).round();
}

AdozioneADistanzaRiepilogo? riepilogoAdozioneADistanza({
  required List<Sponsorship> sponsorships,
  required List<Expense> expenses,
  required DateTime from,
  required DateTime now,
}) {
  final attive = sponsorships.where((item) => item.attiva).toList();
  if (attive.isEmpty) {
    return null;
  }
  final contributo = attive.fold<double>(
    0,
    (sum, item) => sum + item.importoMensile,
  );
  return AdozioneADistanzaRiepilogo(
    sostenitoriAttivi: attive.length,
    contributoMensile: contributo,
    coperturaPercentuale: coperturaAdozioneADistanza(
      contributoMensile: contributo,
      speseTotali: totaleSpese(expenses),
      mesiPermanenza: mesiTra(from, now),
    ),
  );
}

String pesoAndamentoCaption(List<PesoPunto> points) {
  if (points.isEmpty) {
    return 'Nessuna misura di peso.';
  }
  if (points.length == 1) {
    return 'Peso attuale ${formatItalianNumber(points.first.kg)} kg';
  }
  return 'Da ${formatItalianNumber(points.first.kg)} kg a '
      '${formatItalianNumber(points.last.kg)} kg';
}

const _mesiBrevi = [
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

String meseBreve(DateTime date) => _mesiBrevi[date.month - 1];
