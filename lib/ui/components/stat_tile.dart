import 'package:flutter/material.dart';

import '../tokens.dart';

/// Card statistica compatta: icona quadrata + due righe di testo.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final Widget icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColor.card,
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
    );
  }
}
