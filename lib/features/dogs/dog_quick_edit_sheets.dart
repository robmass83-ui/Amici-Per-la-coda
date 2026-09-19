import 'package:flutter/material.dart';

import '../../core/format_it.dart';
import '../../data/models/dog.dart';
import '../../data/models/enums.dart';
import '../../ui/components.dart';
import '../../ui/form_pickers.dart';
import '../../ui/tokens.dart';

// ── CONTRATTO DI LAYOUT · Fogli rapidi scheda ──────────────────────────────
// AppSheet titolo
// ├ AppSegmented 2 valori h=40 larghezza piena
// ├ se operato: SizedBox 9 + AppFormField data (digitabile + suffix)
// └ SizedBox 9 + AppButton Salva
// ───────────────────────────────────────────────────────────────────────────

Future<void> showSituazioneSheet({
  required BuildContext context,
  required Dog dog,
  required void Function(bool sterilizzato, DateTime? data) onSave,
}) {
  return AppSheet.present<void>(
    context: context,
    builder: (context) => _SituazioneSheet(dog: dog, onSave: onSave),
  );
}

Future<void> showAdottabileSheet({
  required BuildContext context,
  required Dog dog,
  required void Function(bool adottabile) onSave,
}) {
  return AppSheet.present<void>(
    context: context,
    builder: (context) => _AdottabileSheet(dog: dog, onSave: onSave),
  );
}

class _SituazioneSheet extends StatefulWidget {
  const _SituazioneSheet({required this.dog, required this.onSave});

  final Dog dog;
  final void Function(bool sterilizzato, DateTime? data) onSave;

  @override
  State<_SituazioneSheet> createState() => _SituazioneSheetState();
}

class _SituazioneSheetState extends State<_SituazioneSheet> {
  late final TextEditingController _data;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.dog.sterilizzato == true ? 1 : 0;
    _data = TextEditingController(
      text: widget.dog.dataSterilizzazione == null
          ? ''
          : formatItalianDate(widget.dog.dataSterilizzazione!),
    );
  }

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final female = widget.dog.sesso == DogSex.F;
    final labels = female
        ? const ['Intera', 'Sterilizzata']
        : const ['Intero', 'Castrato'];
    return AppSheet(
      title: 'Situazione',
      children: [
        AppSegmented(
          values: labels,
          selectedIndex: _index,
          onChanged: (i) => setState(() => _index = i),
        ),
        if (_index == 1) ...[
          const SizedBox(height: AppDim.gapM),
          AppFormField(
            label: 'Data intervento',
            hint: 'gg/mm/aaaa',
            controller: _data,
            keyboardType: TextInputType.datetime,
            suffix: dateFieldSuffix(
              onTap: () => pickDogFormDate(context, _data, () => setState(() {})),
            ),
          ),
        ],
        const SizedBox(height: AppDim.gapM),
        AppButton(
          label: 'Salva',
          onPressed: () {
            final operated = _index == 1;
            Navigator.of(context).pop();
            widget.onSave(
              operated,
              operated ? parseItalianDate(_data.text) : null,
            );
          },
        ),
      ],
    );
  }
}

class _AdottabileSheet extends StatefulWidget {
  const _AdottabileSheet({required this.dog, required this.onSave});

  final Dog dog;
  final void Function(bool adottabile) onSave;

  @override
  State<_AdottabileSheet> createState() => _AdottabileSheetState();
}

class _AdottabileSheetState extends State<_AdottabileSheet> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.dog.adottabile == true ? 0 : 1;
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: 'Adottabile',
      children: [
        AppSegmented(
          values: const ['Sì', 'No'],
          selectedIndex: _index,
          onChanged: (i) => setState(() => _index = i),
        ),
        const SizedBox(height: AppDim.gapM),
        AppButton(
          label: 'Salva',
          onPressed: () {
            Navigator.of(context).pop();
            widget.onSave(_index == 0);
          },
        ),
      ],
    );
  }
}
