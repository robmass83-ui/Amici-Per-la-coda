class PhotoLimitReached implements Exception {
  const PhotoLimitReached();

  static const message = 'Puoi caricare al massimo 20 foto per cane.';

  @override
  String toString() => message;
}
