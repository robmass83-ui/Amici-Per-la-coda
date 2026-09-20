import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firestore_codec.dart';
import '../../core/format_it.dart';
import '../../data/data_providers.dart';
import '../../data/models/weight.dart';
import '../../ui/components.dart';
import '../../ui/form_pickers.dart';
import '../../ui/tokens.dart';
import '../auth/auth_providers.dart';
import 'dogs_providers.dart';
import 'record_actions.dart';

// ── CONTRATTO DI LAYOUT · Pesata (AppDialog) ───────────────────────────────
// Header  AppIcons.peso  «Registra peso» / «Modifica pesata»
// Body  gap 8
// ├ FormRow2  PESO (KG) | DATA
// └ NOTE  AppFormField
// Footer  [🗑 se existing] Annulla | Salva
// ───────────────────────────────────────────────────────────────────────────

class AddWeightSheet extends ConsumerStatefulWidget {
  const AddWeightSheet({super.key, required this.dogId, this.existing});

  static const kgKey = Key('dog-weight-kg');
  static const dataKey = Key('dog-weight-data');
  static const noteKey = Key('dog-weight-note');
  static const saveKey = Key('dog-weight-save');

  final String dogId;
  final Weight? existing;

  static Future<void> open(
    BuildContext context, {
    required String dogId,
    Weight? existing,
  }) {
    return AppDialog.show<void>(
      context: context,
      form: AddWeightSheet(dogId: dogId, existing: existing),
    );
  }

  @override
  ConsumerState<AddWeightSheet> createState() => _AddWeightSheetState();
}

class _AddWeightSheetState extends ConsumerState<AddWeightSheet> {
  final _kg = TextEditingController();
  final _data = TextEditingController();
  final _note = TextEditingController();
  String? _kgError;
  String? _dataError;
  String? _formError;
  var _saving = false;
  late final String _initial;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _kg.text = formatItalianNumber(existing.kg);
      _data.text = formatItalianDate(existing.data);
      _note.text = existing.note;
    } else {
      _data.text = formatItalianDate(ref.read(dogListNowProvider));
    }
    _initial = _snapshot();
    for (final controller in [_kg, _data, _note]) {
      controller.addListener(_mark);
    }
  }

  @override
  void dispose() {
    for (final controller in [_kg, _data, _note]) {
      controller.removeListener(_mark);
      controller.dispose();
    }
    super.dispose();
  }

  void _mark() => setState(() {});

  String _snapshot() => '${_kg.text}|${_data.text}|${_note.text}';

  bool get _canSave {
    final kg = parseItalianDecimal(_kg.text);
    return kg != null && kg > 0 && parseItalianDate(_data.text) != null;
  }

  Future<void> _save() async {
    final kg = parseItalianDecimal(_kg.text);
    if (kg == null || kg <= 0) {
      setState(() => _kgError = 'Inserisci un peso valido in kg.');
      return;
    }
    final data = parseItalianDate(_data.text);
    if (data == null) {
      setState(() => _dataError = 'Data non valida (gg/mm/aaaa).');
      return;
    }
    final weightRepo = ref.read(weightRepositoryProvider);
    if (weightRepo == null) {
      setState(() => _formError = 'Archivio pesi non disponibile.');
      return;
    }
    final userId = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    final now = DateTime.now();
    setState(() {
      _saving = true;
      _formError = null;
      _kgError = null;
      _dataError = null;
    });
    try {
      final existing = widget.existing;
      if (existing != null) {
        await weightRepo.save(
          existing.copyWith(
            data: data,
            kg: kg,
            note: _note.text.trim(),
            audit: existing.audit.touched(userId, now),
          ),
        );
      } else {
        await weightRepo.save(
          Weight(
            id: 'w_${now.microsecondsSinceEpoch}',
            dogId: widget.dogId,
            data: data,
            kg: kg,
            autoreId: userId,
            note: _note.text.trim(),
            audit: Audit(
              createdAt: now,
              createdBy: userId,
              updatedAt: now,
              updatedBy: userId,
            ),
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
    final weights = ref.read(weightRepositoryProvider);
    final dogs = ref.read(dogRepositoryProvider);
    final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    final ok = await confirmDeleteNamed(
      context,
      'la pesata del ${formatItalianDate(existing.data)}',
    );
    if (!ok) {
      return;
    }
    await weights?.delete(existing.id);
    await touchDogAudit(dogs: dogs, dogId: existing.dogId, uid: uid);
    if (!mounted) {
      return;
    }
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      icon: AppIcons.peso,
      title: widget.existing == null ? 'Registra peso' : 'Modifica pesata',
      canSave: _canSave,
      isDirty: _snapshot() != _initial,
      saving: _saving,
      saveKey: AddWeightSheet.saveKey,
      onSave: _save,
      onDelete: widget.existing == null ? null : _delete,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormRow2(
            left: AppFormField(
              key: AddWeightSheet.kgKey,
              label: 'Peso (kg)',
              hint: 'Es. 22,0',
              controller: _kg,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              errorText: _kgError,
            ),
            right: AppFormField(
              key: AddWeightSheet.dataKey,
              label: 'Data',
              hint: 'gg/mm/aaaa',
              controller: _data,
              readOnly: true,
              errorText: _dataError,
              suffix: dateFieldSuffix(
                onTap: () => pickAppDate(context, _data),
              ),
              onTap: () => pickAppDate(context, _data),
            ),
          ),
          const DialogBodyGap(),
          AppFormField(
            key: AddWeightSheet.noteKey,
            label: 'Note',
            hint: 'Opzionale, es. pesato in ambulatorio',
            controller: _note,
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
