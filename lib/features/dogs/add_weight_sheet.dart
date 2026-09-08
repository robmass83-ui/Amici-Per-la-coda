import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firestore_codec.dart';
import '../../core/format_it.dart';
import '../../data/data_providers.dart';
import '../../data/models/weight.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../auth/auth_providers.dart';
import 'dogs_providers.dart';

// ── CONTRATTO DI LAYOUT · Registra peso ────────────────────────────────────
// Padding 12 + tastiera o barra di sistema
// Column  mainAxisSize=min
// ├ maniglia  32×4
// ├ SizedBox h=9
// ├ titolo 13sp w700  maxLines=1
// ├ SizedBox h=9
// ├ AppTextField kg  (label 10.5 + campo h=40)
// ├ SizedBox h=9
// ├ AppTextField data
// ├ SizedBox h=9
// ├ AppTextField note
// └ AppButton Salva  h=40
// ───────────────────────────────────────────────────────────────────────────

class AddWeightSheet extends ConsumerStatefulWidget {
  const AddWeightSheet({super.key, required this.dogId});

  static const kgKey = Key('dog-weight-kg');
  static const dataKey = Key('dog-weight-data');
  static const noteKey = Key('dog-weight-note');
  static const saveKey = Key('dog-weight-save');

  final String dogId;

  static Future<void> open(BuildContext context, {required String dogId}) {
    return AppSheet.present<void>(
      context: context,
      builder: (context) => AddWeightSheet(dogId: dogId),
    );
  }

  @override
  ConsumerState<AddWeightSheet> createState() => _AddWeightSheetState();
}

class _AddWeightSheetState extends ConsumerState<AddWeightSheet> {
  final _kg = TextEditingController();
  final _data = TextEditingController();
  final _note = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _data.text = formatItalianDate(ref.read(dogListNowProvider));
  }

  @override
  void dispose() {
    _kg.dispose();
    _data.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final kg = parseItalianDecimal(_kg.text);
    if (kg == null || kg <= 0) {
      setState(() => _error = 'Inserisci un peso valido in kg.');
      return;
    }
    final data = parseItalianDate(_data.text);
    if (data == null) {
      setState(() => _error = 'Data non valida (gg/mm/aaaa).');
      return;
    }
    final weightRepo = ref.read(weightRepositoryProvider);
    if (weightRepo == null) {
      setState(() => _error = 'Archivio pesi non disponibile.');
      return;
    }
    final userId = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    final now = DateTime.now();
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
            'Registra peso',
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
          AppTextField(
            key: AddWeightSheet.kgKey,
            label: 'Peso (kg)',
            hint: 'Es. 22,0',
            controller: _kg,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: AppDim.gapM),
          AppTextField(
            key: AddWeightSheet.dataKey,
            label: 'Data',
            hint: 'gg/mm/aaaa',
            controller: _data,
            keyboardType: TextInputType.datetime,
          ),
          const SizedBox(height: AppDim.gapM),
          AppTextField(
            key: AddWeightSheet.noteKey,
            label: 'Note',
            hint: 'Opzionale, es. pesato in ambulatorio',
            controller: _note,
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
            key: AddWeightSheet.saveKey,
            label: 'Salva',
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
