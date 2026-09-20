class PhotoLimitReached implements Exception {
  const PhotoLimitReached();

  static const message = 'Puoi caricare al massimo 20 foto per cane.';

  @override
  String toString() => message;
}

class PhotoTooLarge implements Exception {
  const PhotoTooLarge();

  static const message =
      'La foto è troppo grande per essere salvata. Prova con un\'altra immagine.';

  @override
  String toString() => message;
}
