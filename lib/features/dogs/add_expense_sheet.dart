import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firestore_codec.dart';
import '../../core/format_it.dart';
import '../../data/data_providers.dart';
import '../../data/models/dog.dart';
import '../../data/models/enums.dart';
import '../../data/models/expense.dart';
import '../../data/models/health_record.dart';
import '../../ui/components.dart';
import '../../ui/form_pickers.dart';
import '../../ui/tokens.dart';
import '../auth/auth_providers.dart';
import '../vendors/vendor_logic.dart';
import 'dogs_providers.dart';
import 'dog_labels.dart';
import 'health_labels.dart';
import 'pick_dog_sheet.dart';
import 'record_actions.dart';

// ── CONTRATTO DI LAYOUT · Spesa (AppDialog) ───────────────────────────────
// Header  AppIcons.spese  «Registra spesa» / «Modifica spesa»
// Body  gap 8
// ├ CANE  (solo se aperto senza cane)  selettore + «Spesa generale»
// ├ CATEGORIA  Wrap AppChip
// ├ FormRow2  IMPORTO (€) | DATA
// ├ DESCRIZIONE
// └ FORNITORE  dropdown vendors + testo libero
// Footer  [🗑 se existing] Annulla | Salva
// ───────────────────────────────────────────────────────────────────────────

class AddExpenseSheet extends ConsumerStatefulWidget {
  const AddExpenseSheet({super.key, required this.dogId, this.existing});

  static const importoKey = Key('dog-expense-importo');
  static const descrizioneKey = Key('dog-expense-descrizione');
  static const saveKey = Key('dog-expense-save');
  static const caneKey = Key('dog-expense-cane');

  final String? dogId;
  final Expense? existing;

  static Future<void> open(
    BuildContext context, {
    String? dogId,
    Expense? existing,
  }) {
    return AppDialog.show<void>(
      context: context,
      form: AddExpenseSheet(dogId: dogId, existing: existing),
    );
  }

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  final _importo = TextEditingController();
  final _descrizione = TextEditingController();
  final _fornitore = TextEditingController();
  final _data = TextEditingController();
  ExpenseCategoria _categoria = ExpenseCategoria.visita;
  String? _dogId;
  String? _importoError;
  String? _dataError;
  String? _descrizioneError;
  String? _formError;
  var _saving = false;
  late final String _initial;

  @override
  void initState() {
    super.initState();
    _dogId = widget.existing?.dogId ?? widget.dogId;
    final existing = widget.existing;
    if (existing != null) {
      _categoria = existing.categoria;
      _importo.text = formatItalianNumber(existing.importo);
      _descrizione.text = existing.descrizione;
      _fornitore.text = existing.fornitore;
      _data.text = formatItalianDate(existing.data);
    } else {
      _data.text = formatItalianDate(ref.read(dogListNowProvider));
    }
    _initial = _snapshot();
    for (final controller in [_importo, _descrizione, _fornitore, _data]) {
      controller.addListener(_mark);
    }
  }

  @override
  void dispose() {
    for (final controller in [_importo, _descrizione, _fornitore, _data]) {
      controller.removeListener(_mark);
      controller.dispose();
    }
    super.dispose();
  }

  void _mark() => setState(() {});

  String _snapshot() {
    return [
      _dogId ?? '',
      _categoria.wire,
      _importo.text,
      _descrizione.text,
      _fornitore.text,
      _data.text,
    ].join('|');
  }

  bool get _canSave {
    final importo = parseItalianDecimal(_importo.text);
    return importo != null &&
        importo > 0 &&
        parseItalianDate(_data.text) != null &&
        _descrizione.text.trim().isNotEmpty;
  }

  Future<void> _save() async {
    final importo = parseItalianDecimal(_importo.text);
    if (importo == null || importo <= 0) {
      setState(() => _importoError = 'Inserisci un importo valido.');
      return;
    }
    final data = parseItalianDate(_data.text);
    if (data == null) {
      setState(() => _dataError = 'Data non valida (gg/mm/aaaa).');
      return;
    }
    final descrizione = _descrizione.text.trim();
    if (descrizione.isEmpty) {
      setState(() => _descrizioneError = 'Inserisci una descrizione.');
      return;
    }
    final repo = ref.read(expenseRepositoryProvider);
    if (repo == null) {
      setState(() => _formError = 'Archivio spese non disponibile.');
      return;
    }
    final userId = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    final now = DateTime.now();
    setState(() {
      _saving = true;
      _formError = null;
      _importoError = null;
      _dataError = null;
      _descrizioneError = null;
    });
    try {
      final existing = widget.existing;
      if (existing != null) {
        await repo.save(
          existing.copyWith(
            categoria: _categoria,
            importo: importo,
            data: data,
            descrizione: descrizione,
            fornitore: _fornitore.text.trim(),
            audit: existing.audit.touched(userId, now),
          ),
        );
      } else {
        await repo.save(
          Expense(
            id: 'e_${now.microsecondsSinceEpoch}',
            dogId: _dogId,
            categoria: _categoria,
            importo: importo,
            data: data,
            descrizione: descrizione,
            fornitore: _fornitore.text.trim(),
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
    final nome = existing.descrizione.isEmpty
        ? expenseCategoriaLabel(existing.categoria)
        : existing.descrizione;
    final expenses = ref.read(expenseRepositoryProvider);
    final dogs = ref.read(dogRepositoryProvider);
    final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    final ok = await confirmDeleteNamed(
      context,
      'la spesa «$nome» del ${formatItalianDate(existing.data)}',
    );
    if (!ok) {
      return;
    }
    await expenses?.delete(existing.id);
    if (existing.dogId != null) {
      await touchDogAudit(dogs: dogs, dogId: existing.dogId!, uid: uid);
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _pickDog() async {
    final pick = await PickDogSheet.show(
      context,
      showGeneralExpense: true,
    );
    if (pick == null || !mounted) {
      return;
    }
    setState(() => _dogId = pick.dogId);
  }

  String _caneHint() {
    final id = _dogId;
    if (id == null) {
      return 'Spesa generale del rifugio';
    }
    final dogs = ref
        .read(dogsStreamProvider)
        .maybeWhen(data: (items) => items, orElse: () => const <Dog>[]);
    for (final dog in dogs) {
      if (dog.id == id) {
        return dogDisplayName(dog.nome);
      }
    }
    return 'Cane';
  }

  @override
  Widget build(BuildContext context) {
    final vendorDogId = _dogId ?? widget.dogId ?? '';
    final health = vendorDogId.isEmpty
        ? const <HealthRecord>[]
        : ref
              .watch(healthByDogProvider(vendorDogId))
              .maybeWhen(
                data: (items) => items,
                orElse: () => const <HealthRecord>[],
              );
    final expenses = vendorDogId.isEmpty
        ? const <Expense>[]
        : ref
              .watch(expensesByDogProvider(vendorDogId))
              .maybeWhen(
                data: (items) => items,
                orElse: () => const <Expense>[],
              );
    final vendors = vendorsFrom(health: health, expenses: expenses);
    final showCane = widget.dogId == null && widget.existing == null;
    return AppDialog(
      icon: AppIcons.spese,
      title: widget.existing == null ? 'Registra spesa' : 'Modifica spesa',
      canSave: _canSave,
      isDirty: _snapshot() != _initial,
      saving: _saving,
      saveKey: AddExpenseSheet.saveKey,
      onSave: _save,
      onDelete: widget.existing == null ? null : _delete,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showCane) ...[
            AppFormField(
              key: AddExpenseSheet.caneKey,
              label: 'Cane',
              hint: _caneHint(),
              onTap: _pickDog,
            ),
            const DialogBodyGap(),
          ],
          AppFormField(
            label: 'Categoria',
            child: Wrap(
              spacing: AppDim.gapS,
              runSpacing: AppDim.gapS,
              children: [
                for (final cat in ExpenseCategoria.values)
                  AppChip(
                    label: expenseCategoriaLabel(cat),
                    selected: _categoria == cat,
                    height: AppDim.formChipH,
                    padding: AppDim.formChipPad,
                    onSelected: () => setState(() => _categoria = cat),
                  ),
              ],
            ),
          ),
          const DialogBodyGap(),
          FormRow2(
            left: AppFormField(
              key: AddExpenseSheet.importoKey,
              label: 'Importo (€)',
              hint: '0,00',
              controller: _importo,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              errorText: _importoError,
            ),
            right: AppFormField(
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
            key: AddExpenseSheet.descrizioneKey,
            label: 'Descrizione',
            hint: 'Es. controllo veterinario',
            controller: _descrizione,
            errorText: _descrizioneError,
          ),
          const DialogBodyGap(),
          AppFormField(
            label: 'Fornitore',
            hint: 'Opzionale',
            controller: _fornitore,
            suffix: GestureDetector(
              onTap: () => pickVendorName(
                context: context,
                controller: _fornitore,
                vendors: vendors,
                title: 'Fornitore',
              ),
              child: const Text(
                '▾',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: AppText.body,
                  color: AppColor.muted,
                  height: AppDim.lineH,
                ),
              ),
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
