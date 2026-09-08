import 'package:intl/intl.dart';

/// Date italiane `dd/MM/yyyy` e importi con virgola.
String formatItalianDate(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month/${local.year}';
}

String formatItalianNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toString().replaceAll('.', ',');
}

String formatEuro(double value) {
  final negative = value < 0;
  final abs = negative ? -value : value;
  final cents = (abs * 100).round();
  final whole = cents ~/ 100;
  final frac = (cents % 100).toString().padLeft(2, '0');
  final sign = negative ? '-' : '';
  return '$sign€ $whole,$frac';
}

String formatItalianLongDate(DateTime date) {
  return DateFormat('EEEE d MMMM', 'it_IT').format(
    DateTime(date.year, date.month, date.day),
  );
}

String formatItalianTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

DateTime? parseItalianDate(String raw) {
  final parts = raw.trim().split(RegExp(r'[/\-.]'));
  if (parts.length != 3) {
    return null;
  }
  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null || year < 100) {
    return null;
  }
  final parsed = DateTime(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    return null;
  }
  return parsed;
}

double? parseItalianDecimal(String raw) {
  final cleaned = raw
      .trim()
      .replaceAll('€', '')
      .replaceAll(' ', '')
      .replaceAll(',', '.');
  if (cleaned.isEmpty) {
    return null;
  }
  return double.tryParse(cleaned);
}
