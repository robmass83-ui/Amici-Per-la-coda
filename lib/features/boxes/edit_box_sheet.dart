import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firestore_codec.dart';
import '../../data/data_providers.dart';
import '../../data/models/enums.dart';
import '../../data/models/shelter_box.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../auth/auth_providers.dart';
import 'box_logic.dart';

// ── CONTRATTO DI LAYOUT · Foglio box ───────────────────────────────────────
// maniglia · titolo 13sp · campi h=34 · Wrap chip tipo · chip manutenzione
// errore 10sp rosso · Salva h=40
// ───────────────────────────────────────────────────────────────────────────

class EditBoxSheet extends ConsumerStatefulWidget {
  const EditBoxSheet({super.key, this.existing, this.initialSettore});

  static const settoreKey = Key('box-settore');
  static const numeroKey = Key('box-numero');
  static const capienzaKey = Key('box-capienza');
  static const saveKey = Key('box-save');

  final ShelterBox? existing;
  final String? initialSettore;

  static Future<void> open(
    BuildContext context, {
    ShelterBox? existing,
    String? initialSettore,
  }) {
    return AppSheet.present<void>(
      context: context,
      builder: (context) => EditBoxSheet(
        existing: existing,
        initialSettore: initialSettore,
      ),
    );
  }

  @override
  ConsumerState<EditBoxSheet> createState() => _EditBoxSheetState();
}

class _EditBoxSheetState extends ConsumerState<EditBoxSheet> {
  late final TextEditingController _settore;
  late final TextEditingController _numero;
  late final TextEditingController _capienza;
  late final TextEditingController _note;
  BoxTipo _tipo = BoxTipo.normale;
  bool _manutenzione = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _settore = TextEditingController(
      text: existing?.settore ?? widget.initialSettore ?? '',
    );
    _numero = TextEditingController(text: existing?.numero ?? '');
    _capienza = TextEditingController(
      text: existing == null ? '2' : '${existing.capienza}',
    );
    _note = TextEditingController(text: existing?.note ?? '');
    _tipo = existing?.tipo ?? BoxTipo.normale;
    _manutenzione = existing?.inManutenzione ?? false;
  }

  @override
  void dispose() {
    _settore.dispose();
    _numero.dispose();
    _capienza.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final settore = _settore.text.trim();
    final numero = _numero.text.trim();
    final capienza = int.tryParse(_capienza.text.trim()) ?? 0;
    if (settore.isEmpty) {
      setState(() => _error = 'Inserisci il settore.');
      return;
    }
    if (numero.isEmpty) {
      setState(() => _error = 'Inserisci il numero del box.');
      return;
    }
    if (capienza <= 0) {
      setState(() => _error = 'La capienza deve essere almeno 1.');
      return;
    }
    final repo = ref.read(boxRepositoryProvider);
    if (repo == null) {
      setState(() => _error = 'Archivio non disponibile.');
      return;
    }
    final userId = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    final now = DateTime.now();
    final existing = widget.existing;
    if (existing != null) {
      final next = existing.copyWith(
        settore: settore,
        numero: numero,
        capienza: capienza,
        tipo: _tipo,
        note: _note.text.trim(),
        inManutenzione: _manutenzione,
        audit: existing.audit.touched(userId, now),
      );
      await repo.save(next);
      await _spostaCaniSeCambiaCollocazione(existing, next, userId, now);
    } else {
      await repo.save(
        ShelterBox(
          id: nuovoBoxId(settore, numero),
          settore: settore,
          numero: numero,
          capienza: capienza,
          tipo: _tipo,
          note: _note.text.trim(),
          inManutenzione: _manutenzione,
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
    Navigator.of(context).pop();
  }

  Future<void> _spostaCaniSeCambiaCollocazione(
    ShelterBox before,
    ShelterBox after,
    String userId,
    DateTime now,
  ) async {
    if (before.settore == after.settore && before.numero == after.numero) {
      return;
    }
    final dogs = ref.read(dogRepositoryProvider);
    if (dogs == null) {
      return;
    }
    final all = await dogs.watchAll().first;
    for (final dog in all) {
      if (dog.settore != before.settore || dog.box != before.numero) {
        continue;
      }
      await dogs.save(
        dog.copyWith(
          settore: after.settore,
          box: after.numero,
          audit: dog.audit.touched(userId, now),
        ),
      );
    }
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
          Text(
            widget.existing == null ? 'Nuovo box' : 'Modifica box',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: AppText.h2,
              fontWeight: FontWeight.w700,
              color: AppColor.ink,
              height: AppDim.lineH,
            ),
          ),
          const SizedBox(height: AppDim.gapM),
          AppFormField(
            key: EditBoxSheet.settoreKey,
            label: 'Settore',
            controller: _settore,
            hint: 'A',
          ),
          const SizedBox(height: AppDim.gapM),
          FormRow2(
            left: AppFormField(
              key: EditBoxSheet.numeroKey,
              label: 'Numero',
              controller: _numero,
              hint: '1',
            ),
            right: AppFormField(
              key: EditBoxSheet.capienzaKey,
              label: 'Capienza',
              controller: _capienza,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
          const SizedBox(height: AppDim.gapM),
          Wrap(
            spacing: AppDim.gapS,
            runSpacing: AppDim.gapS,
            children: [
              for (final tipo in BoxTipo.values)
                AppChip(
                  label: boxTipoLabel(tipo),
                  selected: _tipo == tipo,
                  onSelected: () => setState(() => _tipo = tipo),
                ),
            ],
          ),
          const SizedBox(height: AppDim.gapS),
          Wrap(
            spacing: AppDim.gapS,
            children: [
              AppChip(
                label: 'In manutenzione',
                selected: _manutenzione,
                onSelected: () =>
                    setState(() => _manutenzione = !_manutenzione),
              ),
            ],
          ),
          const SizedBox(height: AppDim.gapM),
          AppFormField(label: 'Note', controller: _note, maxLines: 2),
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
            key: EditBoxSheet.saveKey,
            label: 'Salva',
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
