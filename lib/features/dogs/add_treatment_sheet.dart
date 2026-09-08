import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firestore_codec.dart';
import '../../core/format_it.dart';
import '../../data/data_providers.dart';
import '../../data/models/enums.dart';
import '../../data/models/expense.dart';
import '../../data/models/health_record.dart';
import '../auth/auth_providers.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import 'dogs_providers.dart';
import 'health_labels.dart';

// ── CONTRATTO DI LAYOUT · Aggiungi trattamento ─────────────────────────────
// Padding 12 + tastiera o barra di sistema
// Column  mainAxisSize=min
// ├ maniglia  32×4  (AppDim.gapXl×2 × gapXs)
// ├ SizedBox h=9
// ├ titolo 13sp w700  maxLines=1
// ├ SizedBox h=9
// ├ Wrap chip tipo  h=28  spacing=6 runSpacing=6
// ├ SizedBox h=9
// ├ AppTextField × n  (label 10.5 + campo h=40)  gap=9
// └ AppButton Salva  h=40
// ───────────────────────────────────────────────────────────────────────────

class AddTreatmentSheet extends ConsumerStatefulWidget {
  const AddTreatmentSheet({super.key, required this.dogId});

  static const descrizioneKey = Key('dog-treatment-descrizione');
  static const scadenzaKey = Key('dog-treatment-scadenza');
  static const saveKey = Key('dog-treatment-save');

  final String dogId;

  static Future<void> open(BuildContext context, {required String dogId}) {
    return AppSheet.present<void>(
      context: context,
      builder: (context) => AddTreatmentSheet(dogId: dogId),
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
  String? _error;

  @override
  void initState() {
    super.initState();
    _data.text = formatItalianDate(ref.read(dogListNowProvider));
  }

  @override
  void dispose() {
    _descrizione.dispose();
    _veterinario.dispose();
    _lotto.dispose();
    _data.dispose();
    _scadenza.dispose();
    _costo.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final data = parseItalianDate(_data.text);
    if (data == null) {
      setState(() => _error = 'Data non valida (gg/mm/aaaa).');
      return;
    }
    final scadenzaRaw = _scadenza.text.trim();
    DateTime? scadenza;
    if (scadenzaRaw.isNotEmpty) {
      scadenza = parseItalianDate(scadenzaRaw);
      if (scadenza == null) {
        setState(() => _error = 'Scadenza non valida (gg/mm/aaaa).');
        return;
      }
    }
    final costoRaw = _costo.text.trim();
    double? costo;
    if (costoRaw.isNotEmpty) {
      costo = parseItalianDecimal(costoRaw);
      if (costo == null) {
        setState(() => _error = 'Costo non valido.');
        return;
      }
    }
    final descrizione = _descrizione.text.trim();
    if (descrizione.isEmpty) {
      setState(() => _error = 'Inserisci una descrizione.');
      return;
    }
    final healthRepo = ref.read(healthRepositoryProvider);
    if (healthRepo == null) {
      setState(() => _error = 'Archivio sanitario non disponibile.');
      return;
    }
    final userId = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    final now = DateTime.now();
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
            'Aggiungi trattamento',
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
          Wrap(
            spacing: AppDim.gapS,
            runSpacing: AppDim.gapS,
            children: [
              for (final tipo in HealthTipo.values)
                AppChip(
                  label: healthTipoLabel(tipo),
                  selected: _tipo == tipo,
                  onSelected: () => setState(() => _tipo = tipo),
                ),
            ],
          ),
          const SizedBox(height: AppDim.gapM),
          AppTextField(
            key: AddTreatmentSheet.descrizioneKey,
            label: 'Descrizione',
            hint: 'Es. richiamo polivalente',
            controller: _descrizione,
          ),
          const SizedBox(height: AppDim.gapM),
          AppTextField(
            label: 'Data',
            hint: 'gg/mm/aaaa',
            controller: _data,
            keyboardType: TextInputType.datetime,
          ),
          const SizedBox(height: AppDim.gapM),
          AppTextField(
            label: 'Veterinario',
            hint: 'Opzionale',
            controller: _veterinario,
          ),
          const SizedBox(height: AppDim.gapM),
          AppTextField(
            label: 'Lotto',
            hint: 'Opzionale',
            controller: _lotto,
          ),
          const SizedBox(height: AppDim.gapM),
          AppTextField(
            key: AddTreatmentSheet.scadenzaKey,
            label: 'Prossima scadenza',
            hint: 'gg/mm/aaaa',
            controller: _scadenza,
            keyboardType: TextInputType.datetime,
          ),
          const SizedBox(height: AppDim.gapM),
          AppTextField(
            label: 'Costo (€)',
            hint: 'Opzionale',
            controller: _costo,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
            key: AddTreatmentSheet.saveKey,
            label: 'Salva',
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
