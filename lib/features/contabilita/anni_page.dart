import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── CONTRATTO DI LAYOUT · Anni contabili ──────────────────────────────────
// Center
//   Text «Contabilità»
// ───────────────────────────────────────────────────────────────────────────

class AnniContabiliPage extends ConsumerWidget {
  const AnniContabiliPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Center(child: Text('Contabilità'));
  }
}
