import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
import '../../data/models/dog.dart';
import '../auth/auth_providers.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import 'dogs_providers.dart';
import 'patologie.dart';

// ── CONTRATTO DI LAYOUT · Patologie (AppDialog) ────────────────────────────
// Header  AppIcons.patologia  «Patologie»  ×
// Body  padding 12  gap 8
// ├ TESTO  AppFormField  maxLines=4  hint «Scrivi o usa le risposte rapide»
// ├ SizedBox formRowGap
// └ RISPOSTE RAPIDE  Wrap AppChip h=26
//    tap: aggiunge o toglie l'etichetta dal testo (più di una)
// Footer  Annulla | Salva
// ───────────────────────────────────────────────────────────────────────────

class PatologieSheet extends ConsumerStatefulWidget {
  const PatologieSheet({super.key, required this.dog});

  static const testoKey = Key('dog-patologie-testo');
  static const saveKey = Key('dog-patologie-save');

  static Key chipKey(String label) => Key('dog-patologie-chip-$label');

  final Dog dog;

  static Future<void> open(BuildContext context, {required Dog dog}) {
    return AppDialog.show<void>(
      context: context,
      form: PatologieSheet(dog: dog),
    );
  }

  @override
  ConsumerState<PatologieSheet> createState() => _PatologieSheetState();
}

class _PatologieSheetState extends ConsumerState<PatologieSheet> {
  late final TextEditingController _testo;
  late final String _initial;
  var _saving = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _testo = TextEditingController(text: widget.dog.patologie);
    _initial = widget.dog.patologie.trim();
    _testo.addListener(_mark);
  }

  @override
  void dispose() {
    _testo.removeListener(_mark);
    _testo.dispose();
    super.dispose();
  }

  void _mark() => setState(() {});

  bool get _isDirty => _testo.text.trim() != _initial;

  void _toggle(String tag) {
    final next = togglePatologiaNelTesto(_testo.text, tag);
    _testo.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  Future<void> _save() async {
    final repo = ref.read(dogRepositoryProvider);
    if (repo == null) {
      setState(() => _formError = 'Archivio cani non disponibile.');
      return;
    }
    final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    final now = ref.read(dogListNowProvider);
    setState(() {
      _saving = true;
      _formError = null;
    });
    try {
      await repo.save(
        widget.dog.copyWith(
          patologie: _testo.text.trim(),
          audit: widget.dog.audit.touched(uid, now),
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    final testo = _testo.text;
    return AppDialog(
      icon: AppIcons.patologia,
      title: 'Patologie',
      canSave: true,
      isDirty: _isDirty,
      saving: _saving,
      saveKey: PatologieSheet.saveKey,
      onSave: _save,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppFormField(
            key: PatologieSheet.testoKey,
            label: 'Patologie',
            hint: 'Scrivi o usa le risposte rapide',
            controller: _testo,
            maxLines: 4,
            minLines: 2,
            keyboardType: TextInputType.multiline,
          ),
          const DialogBodyGap(),
          AppFormField(
            label: 'Risposte rapide',
            child: Wrap(
              spacing: AppDim.gapS,
              runSpacing: AppDim.gapS,
              children: [
                for (final tag in patologiePreset)
                  AppChip(
                    key: PatologieSheet.chipKey(tag),
                    label: tag,
                    selected: patologiaSelezionata(testo, tag),
                    height: AppDim.formChipH,
                    padding: AppDim.formChipPad,
                    onSelected: () => _toggle(tag),
                  ),
              ],
            ),
          ),
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
