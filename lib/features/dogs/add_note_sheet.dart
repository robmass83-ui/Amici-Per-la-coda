import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
import '../../data/models/enums.dart';
import '../../data/models/note.dart';
import '../auth/auth_providers.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import 'dogs_providers.dart';
import 'tab_labels.dart';

// ── CONTRATTO DI LAYOUT · Aggiungi nota ────────────────────────────────────
// Padding 12 + tastiera o barra di sistema
// maniglia · titolo 13sp · AppSegmented 4 tipi h=34
// AppTextField testo h=40 · AppButton Salva h=40
// ───────────────────────────────────────────────────────────────────────────

class AddNoteSheet extends ConsumerStatefulWidget {
  const AddNoteSheet({super.key, required this.dogId});

  static const testoKey = Key('dog-note-testo');
  static const saveKey = Key('dog-note-save');

  final String dogId;

  static Future<void> open(BuildContext context, {required String dogId}) {
    return AppSheet.present<void>(
      context: context,
      builder: (context) => AddNoteSheet(dogId: dogId),
    );
  }

  @override
  ConsumerState<AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends ConsumerState<AddNoteSheet> {
  final _testo = TextEditingController();
  NoteTipo _tipo = NoteTipo.generale;
  String? _error;

  @override
  void dispose() {
    _testo.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final testo = _testo.text.trim();
    if (testo.isEmpty) {
      setState(() => _error = 'Inserisci il testo della nota.');
      return;
    }
    final repo = ref.read(noteRepositoryProvider);
    if (repo == null) {
      setState(() => _error = 'Archivio note non disponibile.');
      return;
    }
    final userId = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    final now = ref.read(dogListNowProvider);
    await repo.save(
      Note(
        id: 'n_${DateTime.now().microsecondsSinceEpoch}',
        dogId: widget.dogId,
        tipo: _tipo,
        testo: testo,
        autoreId: userId,
        createdAt: now,
      ),
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppDim.pagePad,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: AppDim.gapXl * 2,
              height: AppDim.gapXs,
              decoration: BoxDecoration(
                color: AppColor.line,
                borderRadius: BorderRadius.circular(AppDim.radChip),
              ),
            ),
          ),
          const SizedBox(height: AppDim.gapM),
          const Text(
            'Aggiungi nota',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: AppText.h2,
              fontWeight: FontWeight.w700,
              color: AppColor.ink,
              height: AppDim.lineH,
            ),
          ),
          const SizedBox(height: AppDim.gapM),
          AppSegmented(
            values: [
              for (final tipo in NoteTipo.values) noteTipoLabel(tipo),
            ],
            selectedIndex: _tipo.index,
            onChanged: (index) => setState(() => _tipo = NoteTipo.values[index]),
          ),
          const SizedBox(height: AppDim.gapM),
          AppTextField(
            key: AddNoteSheet.testoKey,
            label: 'Testo',
            hint: 'Cosa è successo oggi…',
            controller: _testo,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppDim.gapS),
            Text(
              _error!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: AppText.caption,
                color: AppColor.red,
                height: AppDim.lineH,
              ),
            ),
          ],
          const SizedBox(height: AppDim.gapM),
          AppButton(
            key: AddNoteSheet.saveKey,
            label: 'Salva',
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
