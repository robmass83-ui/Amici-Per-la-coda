import 'package:flutter/material.dart';

import '../tokens.dart';

/// Quadratino colorato con icona Material, usato da InfoRow / StatTile / OptionRow.
class AppIconBox extends StatelessWidget {
  const AppIconBox({
    super.key,
    required this.icon,
    required this.background,
    this.foreground = AppColor.ink2,
  });

  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDim.iconBox,
      height: AppDim.iconBox,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppDim.radIconBox),
      ),
      child: Icon(icon, size: AppDim.iconInline, color: foreground),
    );
  }
}
