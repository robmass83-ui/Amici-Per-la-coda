import 'package:flutter/material.dart';

import '../tokens.dart';
import 'app_segmented.dart';

// ── CONTRATTO DI LAYOUT · CompatRow ────────────────────────────────────────
// Row h=30
// 2 valori (Sì/No):
// ├ Expanded  etichetta 11sp w600  maxLines=2 ellipsis
// ├ SizedBox formRowGap
// └ AppSegmented w=compatYesNoW h=28
// 3+ valori:
// ├ etichetta w=92  11sp w600  maxLines=1 ellipsis
// └ Expanded  AppSegmented h=28
// ───────────────────────────────────────────────────────────────────────────

class CompatRow extends StatelessWidget {
  const CompatRow({
    super.key,
    required this.label,
    required this.values,
    required this.selectedIndex,
    required this.onChanged,
    this.tooltips,
  });

  final String label;
  final List<String> values;
  final List<String>? tooltips;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final compactYesNo = values.length == 2;
    final labelText = Text(
      label,
      maxLines: compactYesNo ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: AppText.segmented,
        fontWeight: FontWeight.w600,
        color: AppColor.ink2,
        height: AppDim.lineH,
      ),
    );
    final segmented = AppSegmented(
      values: values,
      tooltips: tooltips,
      selectedIndex: selectedIndex,
      onChanged: onChanged,
      height: AppDim.segmentedCompactH,
    );
    return SizedBox(
      height: AppDim.compatRowH,
      child: Row(
        children: compactYesNo
            ? [
                Expanded(child: labelText),
                const SizedBox(width: AppDim.formRowGap),
                SizedBox(width: AppDim.compatYesNoW, child: segmented),
              ]
            : [
                SizedBox(width: AppDim.compatLabelW, child: labelText),
                Expanded(child: segmented),
              ],
      ),
    );
  }
}
