import 'package:flutter/material.dart';

import '../../core/format_it.dart';
import '../../data/models/documento_contabile.dart';
import '../../ui/components/app_button.dart';
import '../../ui/components/app_chip.dart';
import '../../ui/components/app_text_field.dart';
import '../../ui/tokens.dart';
import 'contabilita_logic.dart';

class FiltriContabilitaSheet extends StatefulWidget {
  const FiltriContabilitaSheet({super.key, required this.initial});

  final FiltriContabilita initial;

  @override
  State<FiltriContabilitaSheet> createState() => _FiltriContabilitaSheetState();
}

class _FiltriContabilitaSheetState extends State<FiltriContabilitaSheet> {
  TipologiaContabile? _tipologia;
  DateTime? _dal;
  DateTime? _al;
  late final TextEditingController _dalController;
  late final TextEditingController _alController;

  @override
  void initState() {
    super.initState();
    _tipologia = widget.initial.tipologia;
    _dal = widget.initial.dal;
    _al = widget.initial.al;
    _dalController = TextEditingController(
      text: _dal == null ? '' : formatItalianDate(_dal!),
    );
    _alController = TextEditingController(
      text: _al == null ? '' : formatItalianDate(_al!),
    );
  }

  @override
  void dispose() {
    _dalController.dispose();
    _alController.dispose();
    super.dispose();
  }

  Future<void> _scegliData({required bool dal}) async {
    final corrente = dal ? _dal : _al;
    final scelta = await showDatePicker(
      context: context,
      initialDate: corrente ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime(2100, 12, 31),
    );
    if (scelta != null && mounted) {
      setState(() {
        if (dal) {
          _dal = scelta;
          _dalController.text = formatItalianDate(scelta);
        } else {
          _al = scelta;
          _alController.text = formatItalianDate(scelta);
        }
      });
    }
  }

  void _azzera() {
    setState(() {
      _tipologia = null;
      _dal = null;
      _al = null;
      _dalController.clear();
      _alController.clear();
    });
  }

  void _applica() {
    Navigator.of(context).pop(
      FiltriContabilita(
        nome: widget.initial.nome,
        tipologia: _tipologia,
        dal: _dal,
        al: _al,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppDim.gapS,
          runSpacing: AppDim.gapS,
          children: [
            AppChip(
              label: 'Tutte',
              selected: _tipologia == null,
              onSelected: () => setState(() => _tipologia = null),
            ),
            for (final tipologia in TipologiaContabile.values)
              AppChip(
                label: tipologia.etichetta,
                selected: _tipologia == tipologia,
                onSelected: () => setState(() => _tipologia = tipologia),
              ),
          ],
        ),
        const SizedBox(height: AppDim.gapM),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Dal',
                hint: 'gg/mm/aaaa',
                readOnly: true,
                controller: _dalController,
                onTap: () => _scegliData(dal: true),
              ),
            ),
            const SizedBox(width: AppDim.gapS),
            Expanded(
              child: AppTextField(
                label: 'Al',
                hint: 'gg/mm/aaaa',
                readOnly: true,
                controller: _alController,
                onTap: () => _scegliData(dal: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDim.gapM),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Azzera',
                variant: AppButtonVariant.ghost,
                onPressed: _azzera,
              ),
            ),
            const SizedBox(width: AppDim.gapS),
            Expanded(
              child: AppButton(label: 'Applica', onPressed: _applica),
            ),
          ],
        ),
      ],
    );
  }
}
