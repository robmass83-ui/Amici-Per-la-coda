import '../../core/format_it.dart';

enum ScadenzaFascia { scaduto, entro7, entro30, lontano }

DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

/// Giorni interi dalla mezzanotte di [now] alla mezzanotte di [scadenza].
int giorniAllaScadenza(DateTime scadenza, DateTime now) {
  return _dateOnly(scadenza).difference(_dateOnly(now)).inDays;
}

ScadenzaFascia fasciaScadenza(DateTime scadenza, DateTime now) {
  final days = giorniAllaScadenza(scadenza, now);
  if (days < 0) {
    return ScadenzaFascia.scaduto;
  }
  if (days <= 7) {
    return ScadenzaFascia.entro7;
  }
  if (days <= 30) {
    return ScadenzaFascia.entro30;
  }
  return ScadenzaFascia.lontano;
}

String etichettaScadenza(DateTime scadenza, DateTime now) {
  final days = giorniAllaScadenza(scadenza, now);
  if (days < 0) {
    final n = -days;
    return n == 1 ? 'scaduto da 1 g' : 'scaduto da $n gg';
  }
  if (days == 0) {
    return 'oggi';
  }
  if (days == 1) {
    return 'tra 1 g';
  }
  if (days <= 30) {
    return 'tra $days gg';
  }
  return formatItalianDate(scadenza);
}
