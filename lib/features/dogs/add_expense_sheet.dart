import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firestore_codec.dart';
import '../../core/format_it.dart';
import '../../data/data_providers.dart';
import '../../data/models/enums.dart';
import '../../data/models/expense.dart';
import '../auth/auth_providers.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import 'dogs_providers.dart';
import 'health_labels.dart';

// ── CONTRATTO DI LAYOUT · Registra spesa ───────────────────────────────────
// Padding 12 + tastiera o barra di sistema
// maniglia · titolo · Wrap chip categoria · campi importo/data/desc/fornitore
// AppButton Salva h=40
// ───────────────────────────────────────────────────────────────────────────

class AddExpenseSheet extends ConsumerStatefulWidget {
  const AddExpenseSheet({super.key, required this.dogId});

  static const importoKey = Key('dog-expense-importo');
  static const descrizioneKey = Key('dog-expense-descrizione');
  static const saveKey = Key('dog-expense-save');

  final String dogId;

  static Future<void> open(BuildContext context, {required String dogId}) {
    return AppSheet.present<void>(
      context: context,
      builder: (context) => AddExpenseSheet(dogId: dogId),
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
  String? _error;

  @override
  void initState() {
    super.initState();
    _data.text = formatItalianDate(ref.read(dogListNowProvider));
  }

  @override
  void dispose() {
    _importo.dispose();
    _descrizione.dispose();
    _fornitore.dispose();
    _data.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final importo = parseItalianDecimal(_importo.text);
    if (importo == null || importo <= 0) {
      setState(() => _error = 'Inserisci un importo valido.');
      return;
    }
    final data = parseItalianDate(_data.text);
    if (data == null) {
      setState(() => _error = 'Data non valida (gg/mm/aaaa).');
      return;
    }
    final descrizione = _descrizione.text.trim();
    if (descrizione.isEmpty) {
      setState(() => _error = 'Inserisci una descrizione.');
      return;
    }
    final repo = ref.read(expenseRepositoryProvider);
    if (repo == null) {
      setState(() => _error = 'Archivio spese non disponibile.');
      return;
    }
    final userId = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    final now = DateTime.now();
    await repo.save(
      Expense(
        id: 'e_${now.microsecondsSinceEpoch}',
        dogId: widget.dogId,
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
            'Registra spesa',
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
              for (final cat in ExpenseCategoria.values)
                AppChip(
                  label: expenseCategoriaLabel(cat),
                  selected: _categoria == cat,
                  onSelected: () => setState(() => _categoria = cat),
                ),
            ],
          ),
          const SizedBox(height: AppDim.gapM),
          AppTextField(
            key: AddExpenseSheet.importoKey,
            label: 'Importo (€)',
            hint: '0,00',
            controller: _importo,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: AppDim.gapM),
          AppTextField(
            key: AddExpenseSheet.descrizioneKey,
            label: 'Descrizione',
            hint: 'Es. controllo veterinario',
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
            label: 'Fornitore',
            hint: 'Opzionale',
            controller: _fornitore,
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
            key: AddExpenseSheet.saveKey,
            label: 'Salva',
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
