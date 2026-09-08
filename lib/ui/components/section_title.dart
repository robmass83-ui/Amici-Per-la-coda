import 'package:flutter/material.dart';

import '../tokens.dart';

/// Titolo di sezione 13 sp + icona + link opzionale «Vedi tutti ›».
class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.icon,
    this.onSeeAll,
    this.seeAllLabel = 'Vedi tutti ›',
  });

  final String title;
  final Widget? icon;
  final VoidCallback? onSeeAll;
  final String seeAllLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          icon!,
          const SizedBox(width: AppDim.gapS),
        ],
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: AppText.h2,
              fontWeight: FontWeight.w700,
              color: AppColor.ink,
              height: AppDim.lineH,
            ),
          ),
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDim.gapXs,
                vertical: AppDim.gapXs,
              ),
              child: Text(
                seeAllLabel,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: AppText.caption,
                  fontWeight: FontWeight.w600,
                  color: AppColor.green,
                  height: AppDim.lineH,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
