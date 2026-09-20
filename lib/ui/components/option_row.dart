import 'package:flutter/material.dart';

import '../tokens.dart';

/// Riga di menu: icona + titolo + sottotitolo + chevron.
class OptionRow extends StatelessWidget {
  const OptionRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle = '',
    required this.onTap,
    this.titleColor,
    this.minHeight = AppDim.minTouch,
    this.titleSize = AppText.body,
    this.trailing,
  });

  final Widget icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? titleColor;
  final double minHeight;
  final double titleSize;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDim.gapS),
          child: Row(
            children: [
              icon,
              const SizedBox(width: AppDim.gapS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: titleSize,
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? AppColor.ink,
                        height: AppDim.lineH,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: AppText.caption,
                          color: AppColor.muted,
                          height: AppDim.lineH,
                        ),
                      ),
                  ],
                ),
              ),
              trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: AppDim.iconNav,
                    color: AppColor.faint,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
