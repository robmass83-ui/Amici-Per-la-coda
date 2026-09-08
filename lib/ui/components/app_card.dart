import 'package:flutter/material.dart';

import '../tokens.dart';

/// Card bianca con bordo, raggio 12, ombra tenue e padding 10.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color = AppColor.card,
    this.borderColor = AppColor.line,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding ?? AppDim.cardPad, child: child);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppDim.radCard),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(color: AppColor.shadow, blurRadius: AppDim.gapS),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(AppDim.radCard),
        child: onTap == null
            ? content
            : InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppDim.radCard),
                child: content,
              ),
      ),
    );
  }
}
