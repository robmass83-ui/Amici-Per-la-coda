import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format_it.dart';
import '../../data/data_providers.dart';
import '../../data/models/enums.dart';
import '../../data/models/note.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../auth/auth_providers.dart';
import 'dogs_providers.dart';
import 'record_actions.dart';
import 'tab_labels.dart';

// ── CONTRATTO DI LAYOUT · Nota (AppDialog) ───────────────────────────────
// Header  AppIcons.note  «Aggiungi nota» / «Modifica nota»
// Body  gap 8
// ├ TIPO  AppSegmented 4  Generale · Comportam. · Aliment. · Attenzione
// ├ TESTO  multilinea  3→8 righe
// └ riga 9.5sp  «<autore> · <data>»  solo in modifica
// Footer  [🗑 se existing] Annulla | Salva
// ───────────────────────────────────────────────────────────────────────────

class AddNoteSheet extends ConsumerStatefulWidget {
  const AddNoteSheet({super.key, required this.dogId, this.existing});

  static const testoKey = Key('dog-note-testo');
  static const saveKey = Key('dog-note-save');
  static const tipoKey = Key('dog-note-tipo');

  final String dogId;
  final Note? existing;

  static Future<void> open(
    BuildContext context, {
    required String dogId,
    Note? existing,
  }) {
    return AppDialog.show<void>(
      context: context,
      form: AddNoteSheet(dogId: dogId, existing: existing),
    );
  }

  @override
  ConsumerState<AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends ConsumerState<AddNoteSheet> {
  final _testo = TextEditingController();
  NoteTipo _tipo = NoteTipo.generale;
  String? _testoError;
  String? _formError;
  var _saving = false;
  late final String _initial;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _tipo = existing.tipo;
      _testo.text = existing.testo;
    }
    _initial = _snapshot();
    _testo.addListener(_mark);
  }

  @override
  void dispose() {
    _testo.removeListener(_mark);
    _testo.dispose();
    super.dispose();
  }

  void _mark() => setState(() {});

  String _snapshot() => '${_tipo.wire}|${_testo.text}';

  bool get _canSave => _testo.text.trim().isNotEmpty;

  Future<void> _save() async {
    final testo = _testo.text.trim();
    if (testo.isEmpty) {
      setState(() => _testoError = 'Inserisci il testo della nota.');
      return;
    }
    final repo = ref.read(noteRepositoryProvider);
    if (repo == null) {
      setState(() => _formError = 'Archivio note non disponibile.');
      return;
    }
    final userId = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    final now = ref.read(dogListNowProvider);
    setState(() {
      _saving = true;
      _formError = null;
      _testoError = null;
    });
    try {
      final existing = widget.existing;
      if (existing != null) {
        await repo.save(existing.copyWith(tipo: _tipo, testo: testo));
      } else {
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
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _formError = 'Salvataggio non riuscito. Riprova.');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) {
      return;
    }
    final snippet = existing.testo.length <= 24
        ? existing.testo
        : '${existing.testo.substring(0, 24)}…';
    final repo = ref.read(noteRepositoryProvider);
    final dogs = ref.read(dogRepositoryProvider);
    final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    final ok = await confirmDeleteNamed(context, 'la nota «$snippet»');
    if (!ok) {
      return;
    }
    await repo?.delete(existing.id);
    await touchDogAudit(dogs: dogs, dogId: existing.dogId, uid: uid);
    if (!mounted) {
      return;
    }
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    final author = existing == null
        ? ''
        : autoreEtichetta(
            ref.watch(volunteersStreamProvider).maybeWhen(
              data: (items) => items,
              orElse: () => const [],
            ),
            existing.autoreId,
          );
    return AppDialog(
      icon: AppIcons.note,
      title: existing == null ? 'Aggiungi nota' : 'Modifica nota',
      canSave: _canSave,
      isDirty: _snapshot() != _initial,
      saving: _saving,
      saveKey: AddNoteSheet.saveKey,
      onSave: _save,
      onDelete: existing == null ? null : _delete,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppFormField(
            label: 'Tipo',
            child: AppSegmented(
              key: AddNoteSheet.tipoKey,
              values: [
                for (final tipo in NoteTipo.values) noteTipoShortLabel(tipo),
              ],
              tooltips: [
                for (final tipo in NoteTipo.values) noteTipoLabel(tipo),
              ],
              selectedIndex: _tipo.index,
              onChanged: (index) =>
                  setState(() => _tipo = NoteTipo.values[index]),
            ),
          ),
          const DialogBodyGap(),
          AppFormField(
            key: AddNoteSheet.testoKey,
            label: 'Testo',
            hint: 'Cosa è successo oggi…',
            controller: _testo,
            maxLines: 8,
            minLines: 3,
            errorText: _testoError,
          ),
          if (existing != null) ...[
            const SizedBox(height: AppDim.gapS),
            Text(
              '$author · ${formatItalianDate(existing.createdAt)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: AppText.statNote,
                color: AppColor.muted,
                height: AppDim.lineH,
              ),
            ),
          ],
          if (_formError != null) ...[
            const DialogBodyGap(),
            Text(
              _formError!,
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
        ],
      ),
    );
  }
}
