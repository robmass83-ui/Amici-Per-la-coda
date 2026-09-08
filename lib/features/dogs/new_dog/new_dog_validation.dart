const microchipCifre = 15;

String? validateNomeCane(String raw) {
  if (raw.trim().isEmpty) {
    return 'Inserisci il nome del cane.';
  }
  return null;
}

String? validateMicrochip(String raw) {
  final value = raw.trim();
  if (value.isEmpty) {
    return null;
  }
  if (!RegExp(r'^\d{15}$').hasMatch(value)) {
    return 'Il microchip deve avere 15 cifre.';
  }
  return null;
}

String? validateDataIngresso(DateTime? data) {
  if (data == null) {
    return 'Inserisci la data di ingresso.';
  }
  return null;
}

String? extractMicrochipDigits(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length == microchipCifre) {
    return digits;
  }
  if (digits.length > microchipCifre) {
    return digits.substring(0, microchipCifre);
  }
  return null;
}
