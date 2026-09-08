import 'package:flutter/material.dart';

import '../tokens.dart';

/// Chiave a sinistra (muted) / valore a destra. Va a capo, non scorre.
class KeyValueRow extends StatelessWidget {
  const KeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.maxLines = 3,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: AppText.label,
              color: AppColor.muted,
              height: AppDim.lineH,
            ),
          ),
        ),
        const SizedBox(width: AppDim.gapS),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: AppText.value,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColor.ink,
              height: AppDim.lineH,
            ),
          ),
        ),
      ],
    );
  }
}
