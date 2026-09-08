import 'package:flutter/material.dart';

import '../tokens.dart';

/// Chip filtro selezionabile, altezza 28.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDim.chipH,
      child: Material(
        color: selected ? AppColor.green : AppColor.card,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? AppColor.green : AppColor.line),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onSelected,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDim.gapM),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: AppText.caption,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColor.card : AppColor.ink2,
                  height: AppDim.lineH,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
