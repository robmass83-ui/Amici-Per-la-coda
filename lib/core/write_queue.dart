/// Coda di scritture dello Step 19.
///
/// Firestore con persistenza è il buffer: `set`/`delete` restano in locale
/// senza rete e si inviano al ritorno del segnale (`waitForPendingWrites`).
/// Questa coda in memoria ritenta solo le azioni che hanno lanciato:
/// se la persistenza non è ancora pronta, il lavoro non si perde.
class WriteQueue {
  final _pending = <Future<void> Function()>[];

  int get pendingCount => _pending.length;

  Future<void> enqueue(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      _pending.add(action);
    }
  }

  Future<void> flush() async {
    final jobs = List<Future<void> Function()>.of(_pending);
    _pending.clear();
    for (final job in jobs) {
      await enqueue(job);
    }
  }
}
