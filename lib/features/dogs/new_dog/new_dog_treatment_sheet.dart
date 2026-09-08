import 'package:flutter/material.dart';

import '../../../core/format_it.dart';
import '../../../data/models/enums.dart';
import '../../../ui/components.dart';
import '../../../ui/tokens.dart';
import '../health_labels.dart';
import 'new_dog_draft.dart';

class NewDogTreatmentSheet extends StatefulWidget {
  const NewDogTreatmentSheet({super.key, required this.now});

  final DateTime now;

  static Future<PendingTreatment?> open(
    BuildContext context, {
    required DateTime now,
  }) {
    return AppSheet.present<PendingTreatment>(
      context: context,
      builder: (context) => NewDogTreatmentSheet(now: now),
    );
  }

  @override
  State<NewDogTreatmentSheet> createState() => _NewDogTreatmentSheetState();
}

class _NewDogTreatmentSheetState extends State<NewDogTreatmentSheet> {
  final _descrizione = TextEditingController();
  final _data = TextEditingController();
  HealthTipo _tipo = HealthTipo.vaccino;
  String? _error;

  @override
  void initState() {
    super.initState();
    _data.text = formatItalianDate(widget.now);
  }

  @override
  void dispose() {
    _descrizione.dispose();
    _data.dispose();
    super.dispose();
  }

  void _save() {
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
    Navigator.of(context).pop(
      PendingTreatment(tipo: _tipo, data: data, descrizione: descrizione),
    );
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
            label: 'Descrizione',
            hint: 'Es. polivalente + antirabbica',
            controller: _descrizione,
          ),
          const SizedBox(height: AppDim.gapM),
          AppTextField(
            label: 'Data',
            hint: 'gg/mm/aaaa',
            controller: _data,
            keyboardType: TextInputType.datetime,
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
          AppButton(label: 'Aggiungi', onPressed: _save),
        ],
      ),
    );
  }
}
