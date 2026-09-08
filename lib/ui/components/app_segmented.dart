import 'package:flutter/material.dart';

import '../tokens.dart';

/// Selettore a segmenti a larghezza piena.
///
/// Una riga: etichetta sola (altezza 34) oppure etichetta sopra e conteggio
/// sotto (altezza 40). I segmenti hanno larghezza identica.
class AppSegmented extends StatelessWidget {
  const AppSegmented({
    super.key,
    required this.values,
    required this.selectedIndex,
    required this.onChanged,
    this.counts,
  }) : assert(counts == null || counts.length == values.length);

  final List<String> values;
  final List<int>? counts;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final twoLine = counts != null;
    return SizedBox(
      height: twoLine ? AppDim.minTouch : AppDim.segmentedH,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColor.neutralSoft,
          borderRadius: BorderRadius.circular(AppDim.radInput),
        ),
        child: Row(
          children: [
            for (var i = 0; i < values.length; i++)
              Expanded(
                child: _Segment(
                  label: values[i],
                  count: counts?[i],
                  selected: i == selectedIndex,
                  onTap: () => onChanged(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final labelColor = selected ? AppColor.greenDark : AppColor.muted;
    final countColor = selected ? AppColor.greenDark : AppColor.ink;
    return Padding(
      padding: const EdgeInsets.all(AppDim.gapXs),
      child: Material(
        color: selected ? AppColor.card : AppColor.neutralSoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDim.radIconBox),
          side: BorderSide(color: selected ? AppColor.line : AppColor.neutralSoft),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDim.radIconBox),
          child: Center(
            child: count == null
                ? Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: AppText.caption,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: labelColor,
                      height: AppDim.lineH,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: AppText.micro,
                          fontWeight: FontWeight.w500,
                          color: labelColor,
                          height: AppDim.lineH,
                        ),
                      ),
                      Text(
                        '$count',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: AppText.caption,
                          fontWeight: FontWeight.w700,
                          color: countColor,
                          height: AppDim.lineH,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
