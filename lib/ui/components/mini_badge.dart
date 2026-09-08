import 'package:flutter/material.dart';

import '../tokens.dart';

enum MiniBadgeVariant { green, blue, red, orange, purple, neutral }

/// Pillola 9 sp per stati e categorie.
class MiniBadge extends StatelessWidget {
  const MiniBadge({
    super.key,
    required this.label,
    this.variant = MiniBadgeVariant.neutral,
  });

  final String label;
  final MiniBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsOf(variant);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDim.gapS,
        vertical: AppDim.gapXs,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppDim.radChip),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: AppText.micro,
          fontWeight: FontWeight.w700,
          color: colors.foreground,
          height: AppDim.lineH,
        ),
      ),
    );
  }

  static ({Color background, Color foreground}) _colorsOf(
    MiniBadgeVariant variant,
  ) {
    return switch (variant) {
      MiniBadgeVariant.green => (
        background: AppColor.greenSoft,
        foreground: AppColor.greenDark,
      ),
      MiniBadgeVariant.blue => (
        background: AppColor.blueSoft,
        foreground: AppColor.blue,
      ),
      MiniBadgeVariant.red => (
        background: AppColor.redSoft,
        foreground: AppColor.red,
      ),
      MiniBadgeVariant.orange => (
        background: AppColor.orangeSoft,
        foreground: AppColor.orange,
      ),
      MiniBadgeVariant.purple => (
        background: AppColor.purpleSoft,
        foreground: AppColor.purple,
      ),
      MiniBadgeVariant.neutral => (
        background: AppColor.neutralSoft,
        foreground: AppColor.ink2,
      ),
    };
  }
}
