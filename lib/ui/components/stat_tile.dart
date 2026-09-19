import 'package:flutter/material.dart';

import '../tokens.dart';

// ── CONTRATTO DI LAYOUT · StatTile ─────────────────────────────────────────
// Material + InkWell (onTap opzionale)  radius=12  minHeight=40
// └ Padding card 10
//    └ Row
//       ├ icon  30×30
//       ├ SizedBox w=6
//       └ Expanded Column
//          ├ Text label  10sp muted  maxLines=2 ellipsis
//          └ Text value  15sp w700  maxLines=1 ellipsis
// ───────────────────────────────────────────────────────────────────────────

/// Card statistica compatta: icona quadrata + due righe di testo.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final Widget icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.card,
      borderRadius: BorderRadius.circular(AppDim.radCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDim.radCard),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppDim.minTouch),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDim.radCard),
              border: Border.all(color: AppColor.line),
            ),
            child: Padding(
              padding: AppDim.cardPad,
              child: Row(
                children: [
                  icon,
                  const SizedBox(width: AppDim.gapS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: AppText.caption,
                            color: AppColor.muted,
                            height: AppDim.lineH,
                          ),
                        ),
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: AppText.title,
                            fontWeight: FontWeight.w700,
                            color: AppColor.ink,
                            height: AppDim.lineH,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
