import 'package:flutter/material.dart';

import '../tokens.dart';

/// Riga scheda: quadratino icona + etichetta piccola + valore.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueKey,
  });

  final Widget icon;
  final String label;
  final String value;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        icon,
        const SizedBox(width: AppDim.gapS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: AppText.label,
                  color: AppColor.muted,
                  height: AppDim.lineH,
                ),
              ),
              Text(
                value,
                key: valueKey,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: AppText.value,
                  fontWeight: FontWeight.w600,
                  color: AppColor.ink,
                  height: AppDim.lineH,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
