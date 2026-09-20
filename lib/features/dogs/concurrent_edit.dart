import '../../core/format_it.dart';

/// True se sul server c'è una `updatedAt` più recente di quella letta
/// all'apertura del form.
bool hasConcurrentDogEdit({
  required DateTime openedUpdatedAt,
  required DateTime serverUpdatedAt,
}) {
  return serverUpdatedAt.isAfter(openedUpdatedAt);
}

String concurrentEditMessage(String editorNome) {
  final chi = editorNome.trim().isEmpty ? 'Qualcuno' : editorNome.trim();
  return '$chi ha modificato questa scheda mentre la stavi aprendo';
}

String ultimaModificaLabel({
  required String editorNome,
  required DateTime updatedAt,
}) {
  final chi = editorNome.trim().isEmpty ? '—' : editorNome.trim();
  return 'Ultima modifica: $chi, ${formatItalianDate(updatedAt)}';
}
