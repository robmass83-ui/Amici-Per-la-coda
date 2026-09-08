import 'package:flutter/material.dart';

import '../tokens.dart';

enum AppButtonVariant { primary, ghost, grey }

/// Pulsante compatto, altezza 40, testo 13 sp.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final colors = _colorsOf(variant);

    final button = SizedBox(
      height: AppDim.minTouch,
      child: Material(
        color: enabled ? colors.background : AppColor.neutralSoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDim.radInput),
          side: BorderSide(color: enabled ? colors.border : AppColor.line),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppDim.radInput),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDim.gapL),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: AppText.h2,
                  fontWeight: FontWeight.w700,
                  color: enabled ? colors.foreground : AppColor.faint,
                  height: AppDim.lineH,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (expand) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  static ({Color background, Color foreground, Color border}) _colorsOf(
    AppButtonVariant variant,
  ) {
    return switch (variant) {
      AppButtonVariant.primary => (
        background: AppColor.green,
        foreground: AppColor.card,
        border: AppColor.green,
      ),
      AppButtonVariant.ghost => (
        background: AppColor.card,
        foreground: AppColor.green,
        border: AppColor.green,
      ),
      AppButtonVariant.grey => (
        background: AppColor.neutralSoft,
        foreground: AppColor.ink,
        border: AppColor.line,
      ),
    };
  }
}
