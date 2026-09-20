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

String formatItalianDayMonth(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month';
}

String formatItalianMonthYear(DateTime date) {
  final raw = DateFormat('MMMM yyyy', 'it_IT').format(
    DateTime(date.year, date.month),
  );
  if (raw.isEmpty) {
    return raw;
  }
  return '${raw[0].toUpperCase()}${raw.substring(1)}';
}

String formatItalianWeekdayDay(DateTime date) {
  return DateFormat('EEEE d', 'it_IT').format(
    DateTime(date.year, date.month, date.day),
  );
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

String formatFileSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  final kb = bytes / 1024;
  if (kb < 1024) {
    final shown = kb >= 10 ? kb.round().toString() : formatItalianNumber(kb);
    return '$shown KB';
  }
  final mb = kb / 1024;
  return '${formatItalianNumber(mb)} MB';
}

DateTime? parseItalianTime(String raw, DateTime day) {
  final parts = raw.trim().split(':');
  if (parts.length < 2) {
    return null;
  }
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) {
    return null;
  }
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
    return null;
  }
  return DateTime(day.year, day.month, day.day, hour, minute);
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
