import 'package:flutter/material.dart';

import '../../data/models/enums.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import 'modulo_labels.dart';

// ── CONTRATTO DI LAYOUT · Visibilità modulo ───────────────────────────────
// etichetta 10sp w600 maiuscoletto muted
// SizedBox 3
// AppSegmented 4  h=32  Home | Scheda | Entrambi | Nessuna
// ───────────────────────────────────────────────────────────────────────────

class TemplateVisibilitaPicker extends StatelessWidget {
  const TemplateVisibilitaPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const segmentedKey = Key('modulo-visibilita');

  final TemplateVisibilita value;
  final ValueChanged<TemplateVisibilita> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'MOSTRA IN',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: AppText.caption,
            fontWeight: FontWeight.w600,
            color: AppColor.muted,
            height: AppDim.formLabelLineH,
          ),
        ),
        const SizedBox(height: AppDim.formLabelGap),
        AppSegmented(
          key: segmentedKey,
          values: templateVisibilitaLabels,
          selectedIndex: value.index,
          onChanged: (index) => onChanged(TemplateVisibilita.values[index]),
        ),
      ],
    );
  }
}
