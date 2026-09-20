import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firestore_codec.dart';
import '../../core/format_it.dart';
import '../../data/data_providers.dart';
import '../../data/models/enums.dart';
import '../../data/models/expense.dart';
import '../../data/models/health_record.dart';
import '../../ui/components.dart';
import '../../ui/form_pickers.dart';
import '../../ui/tokens.dart';
import '../auth/auth_providers.dart';
import '../vendors/vendor_logic.dart';
import 'dogs_providers.dart';
import 'health_labels.dart';
import 'record_actions.dart';

// ── CONTRATTO DI LAYOUT · Trattamento (AppDialog) ─────────────────────────────
// Header  AppIcons.vaccino  «Aggiungi/Modifica trattamento»  ×
// Body  padding 12  gap 8
// ├ TIPO  Wrap AppChip h=26
// ├ DESCRIZIONE  AppFormField
// ├ FormRow2  DATA | PROSSIMA SCADENZA  date picker
// ├ FormRow2  VETERINARIO dropdown | LOTTO
// └ FormRow2  COSTO (€) | nota 9.5sp «Se inserito, crea anche la spesa»
// Footer  [🗑 se existing] Annulla | Salva (disabilitato se non valido)
// ───────────────────────────────────────────────────────────────────────────

class AddTreatmentSheet extends ConsumerStatefulWidget {
  const AddTreatmentSheet({super.key, required this.dogId, this.existing});

  static const descrizioneKey = Key('dog-treatment-descrizione');
  static const scadenzaKey = Key('dog-treatment-scadenza');
  static const saveKey = Key('dog-treatment-save');
  static const dataKey = Key('dog-treatment-data');

  final String dogId;
  final HealthRecord? existing;

  static Future<void> open(
    BuildContext context, {
    required String dogId,
    HealthRecord? existing,
  }) {
    return AppDialog.show<void>(
      context: context,
      form: AddTreatmentSheet(dogId: dogId, existing: existing),
    );
  }

  @override
  ConsumerState<AddTreatmentSheet> createState() => _AddTreatmentSheetState();
}

class _AddTreatmentSheetState extends ConsumerState<AddTreatmentSheet> {
  final _descrizione = TextEditingController();
  final _veterinario = TextEditingController();
  final _lotto = TextEditingController();
  final _data = TextEditingController();
  final _scadenza = TextEditingController();
  final _costo = TextEditingController();

  HealthTipo _tipo = HealthTipo.vaccino;
  String? _descrizioneError;
  String? _dataError;
  String? _scadenzaError;
  String? _costoError;
  String? _formError;
  var _saving = false;
  late final String _initial;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final now = ref.read(dogListNowProvider);
    if (existing != null) {
      _tipo = existing.tipo;
      _descrizione.text = existing.descrizione;
      _veterinario.text = existing.veterinario;
      _lotto.text = existing.lotto;
      _data.text = formatItalianDate(existing.data);
      _scadenza.text = existing.prossimaScadenza == null
          ? ''
          : formatItalianDate(existing.prossimaScadenza!);
      _costo.text = existing.costo == null
          ? ''
          : formatItalianNumber(existing.costo!);
    } else {
      _data.text = formatItalianDate(now);
    }
    _initial = _snapshot();
    for (final controller in [
      _descrizione,
      _veterinario,
      _lotto,
      _data,
      _scadenza,
      _costo,
    ]) {
      controller.addListener(_mark);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _descrizione,
      _veterinario,
      _lotto,
      _data,
      _scadenza,
      _costo,
    ]) {
      controller.removeListener(_mark);
      controller.dispose();
    }
    super.dispose();
  }

  void _mark() => setState(() {});

  String _snapshot() {
    return [
      _tipo.wire,
      _descrizione.text,
      _veterinario.text,
      _lotto.text,
      _data.text,
      _scadenza.text,
      _costo.text,
    ].join('|');
  }

  bool get _canSave {
    if (_descrizione.text.trim().isEmpty) {
      return false;
    }
    if (parseItalianDate(_data.text) == null) {
      return false;
    }
    final scadenzaRaw = _scadenza.text.trim();
    if (scadenzaRaw.isNotEmpty && parseItalianDate(scadenzaRaw) == null) {
      return false;
    }
    final costoRaw = _costo.text.trim();
    if (costoRaw.isNotEmpty && parseItalianDecimal(costoRaw) == null) {
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    final data = parseItalianDate(_data.text);
    if (data == null) {
      setState(() => _dataError = 'Data non valida (gg/mm/aaaa).');
      return;
    }
    final scadenzaRaw = _scadenza.text.trim();
    DateTime? scadenza;
    if (scadenzaRaw.isNotEmpty) {
      scadenza = parseItalianDate(scadenzaRaw);
      if (scadenza == null) {
        setState(() => _scadenzaError = 'Scadenza non valida (gg/mm/aaaa).');
        return;
      }
    }
    final costoRaw = _costo.text.trim();
    double? costo;
    if (costoRaw.isNotEmpty) {
      costo = parseItalianDecimal(costoRaw);
      if (costo == null) {
        setState(() => _costoError = 'Costo non valido.');
        return;
      }
    }
    final descrizione = _descrizione.text.trim();
    if (descrizione.isEmpty) {
      setState(() => _descrizioneError = 'Inserisci una descrizione.');
      return;
    }
    final healthRepo = ref.read(healthRepositoryProvider);
    if (healthRepo == null) {
      setState(() => _formError = 'Archivio sanitario non disponibile.');
      return;
    }
    final navigator = Navigator.of(context, rootNavigator: true);
    final userId = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    final now = DateTime.now();
    setState(() {
      _saving = true;
      _formError = null;
      _descrizioneError = null;
      _dataError = null;
      _scadenzaError = null;
      _costoError = null;
    });
    try {
      final existing = widget.existing;
      if (existing != null) {
        await healthRepo.save(
          existing.copyWith(
            tipo: _tipo,
            data: data,
            descrizione: descrizione,
            veterinario: _veterinario.text.trim(),
            lotto: _lotto.text.trim(),
            prossimaScadenza: scadenza,
            clearProssimaScadenza: scadenza == null,
            costo: costo,
            clearCosto: costo == null,
            audit: existing.audit.touched(userId, now),
          ),
        );
      } else {
        final id = 'h_${now.microsecondsSinceEpoch}';
        final record = HealthRecord(
          id: id,
          dogId: widget.dogId,
          tipo: _tipo,
          data: data,
          descrizione: descrizione,
          veterinario: _veterinario.text.trim(),
          lotto: _lotto.text.trim(),
          prossimaScadenza: scadenza,
          costo: costo,
          audit: Audit(
            createdAt: now,
            createdBy: userId,
            updatedAt: now,
            updatedBy: userId,
          ),
        );
        await healthRepo.save(record);
        if (costo != null) {
          final expenseRepo = ref.read(expenseRepositoryProvider);
          if (expenseRepo != null) {
            await expenseRepo.save(
              Expense(
                id: 'e_${now.microsecondsSinceEpoch}',
                dogId: widget.dogId,
                categoria: expenseCategoriaFromHealth(_tipo),
                importo: costo,
                data: data,
                descrizione: descrizione,
                fornitore: _veterinario.text.trim(),
                audit: Audit(
                  createdAt: now,
                  createdBy: userId,
                  updatedAt: now,
                  updatedBy: userId,
                ),
              ),
            );
          }
        }
      }
      if (!mounted) {
        return;
      }
      navigator.pop();
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
    final tipo = healthTipoLabel(existing.tipo).toLowerCase();
    final health = ref.read(healthRepositoryProvider);
    final dogs = ref.read(dogRepositoryProvider);
    final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    final ok = await confirmDeleteNamed(
      context,
      'la $tipo del ${formatItalianDate(existing.data)}',
    );
    if (!ok) {
      return;
    }
    await health?.delete(existing.id);
    await touchDogAudit(dogs: dogs, dogId: existing.dogId, uid: uid);
    if (!mounted) {
      return;
    }
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    final health = ref
        .watch(healthByDogProvider(widget.dogId))
        .maybeWhen(data: (items) => items, orElse: () => const <HealthRecord>[]);
    final expenses = ref
        .watch(expensesByDogProvider(widget.dogId))
        .maybeWhen(data: (items) => items, orElse: () => const <Expense>[]);
    final vendors = vendorsFrom(health: health, expenses: expenses);
    return AppDialog(
      icon: AppIcons.vaccino,
      title: widget.existing == null
          ? 'Aggiungi trattamento'
          : 'Modifica trattamento',
      canSave: _canSave,
      isDirty: _snapshot() != _initial,
      saving: _saving,
      saveKey: AddTreatmentSheet.saveKey,
      onSave: _save,
      onDelete: widget.existing == null ? null : _delete,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppFormField(
            label: 'Tipo',
            child: Wrap(
              spacing: AppDim.gapS,
              runSpacing: AppDim.gapS,
              children: [
                for (final tipo in HealthTipo.values)
                  AppChip(
                    label: healthTipoLabel(tipo),
                    selected: _tipo == tipo,
                    height: AppDim.formChipH,
                    padding: AppDim.formChipPad,
                    onSelected: () => setState(() => _tipo = tipo),
                  ),
              ],
            ),
          ),
          const DialogBodyGap(),
          AppFormField(
            key: AddTreatmentSheet.descrizioneKey,
            label: 'Descrizione',
            hint: 'Es. richiamo polivalente',
            controller: _descrizione,
            errorText: _descrizioneError,
          ),
          const DialogBodyGap(),
          FormRow2(
            left: AppFormField(
              key: AddTreatmentSheet.dataKey,
              label: 'Data',
              hint: 'gg/mm/aaaa',
              controller: _data,
              readOnly: false,
              errorText: _dataError,
              suffix: dateFieldSuffix(
                onTap: () => pickAppDate(context, _data),
              ),
              onTap: () => pickAppDate(context, _data),
            ),
            right: AppFormField(
              key: AddTreatmentSheet.scadenzaKey,
              label: 'Prossima scadenza',
              hint: 'gg/mm/aaaa',
              controller: _scadenza,
              readOnly: false,
              errorText: _scadenzaError,
              suffix: dateFieldSuffix(
                onTap: () => pickAppDate(context, _scadenza),
              ),
              onTap: () => pickAppDate(context, _scadenza),
            ),
          ),
          const DialogBodyGap(),
          FormRow2(
            left: AppFormField(
              label: 'Veterinario',
              hint: 'Opzionale',
              controller: _veterinario,
              suffix: GestureDetector(
                onTap: () => pickVendorName(
                  context: context,
                  controller: _veterinario,
                  vendors: vendors,
                  title: 'Veterinario',
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
            right: AppFormField(
              label: 'Lotto',
              hint: 'Opzionale',
              controller: _lotto,
            ),
          ),
          const DialogBodyGap(),
          FormRow2(
            left: AppFormField(
              label: 'Costo (€)',
              hint: '0,00',
              controller: _costo,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              errorText: _costoError,
            ),
            right: const Padding(
              padding: EdgeInsets.only(
                top: AppText.caption + AppDim.formLabelGap + AppDim.gapS,
              ),
              child: Text(
                'Se inserito, crea anche la spesa',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: AppText.statNote,
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
