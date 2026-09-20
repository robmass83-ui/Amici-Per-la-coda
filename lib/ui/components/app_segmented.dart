import 'package:flutter/material.dart';

import '../tokens.dart';

/// Selettore a segmenti a larghezza piena.
///
/// Una riga: altezza [height] (32 di default, 28 in CompatRow), testo 11 sp.
/// Con [counts]: etichetta sopra e conteggio sotto, altezza 40.
class AppSegmented extends StatelessWidget {
  const AppSegmented({
    super.key,
    required this.values,
    required this.selectedIndex,
    required this.onChanged,
    this.counts,
    this.tooltips,
    this.height,
  }) : assert(counts == null || counts.length == values.length);

  final List<String> values;
  final List<String>? tooltips;
  final List<int>? counts;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final twoLine = counts != null;
    final h = twoLine ? AppDim.minTouch : (height ?? AppDim.segmentedH);
    return SizedBox(
      height: h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: twoLine ? AppColor.neutralSoft : AppColor.barTrack,
          borderRadius: BorderRadius.circular(
            twoLine ? AppDim.radInput : AppDim.formRad,
          ),
        ),
        child: twoLine
            ? Row(
                children: [
                  for (var i = 0; i < values.length; i++)
                    Expanded(
                      child: _Segment(
                        label: values[i],
                        tooltip: tooltips == null || i >= tooltips!.length
                            ? values[i]
                            : tooltips![i],
                        count: counts?[i],
                        selected: i == selectedIndex,
                        compact: false,
                        onTap: () => onChanged(i),
                      ),
                    ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(AppDim.segmentedPad),
                child: Row(
                  children: [
                    for (var i = 0; i < values.length; i++)
                      Expanded(
                        child: _Segment(
                          label: values[i],
                          tooltip: tooltips == null || i >= tooltips!.length
                              ? values[i]
                              : tooltips![i],
                          count: counts?[i],
                          selected: i == selectedIndex,
                          compact: true,
                          onTap: () => onChanged(i),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.tooltip,
    required this.selected,
    required this.onTap,
    required this.compact,
    this.count,
  });

  final String label;
  final String tooltip;
  final int? count;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final labelColor = selected ? AppColor.greenDark : AppColor.muted;
    final countColor = selected ? AppColor.greenDark : AppColor.ink;
    final fill = selected
        ? AppColor.card
        : (compact ? AppColor.barTrack : AppColor.neutralSoft);
    final tile = Material(
      color: fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDim.radIconBox),
        side: compact
            ? BorderSide.none
            : BorderSide(
                color: selected ? AppColor.line : AppColor.neutralSoft,
              ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDim.radIconBox),
        child: Center(
          child: count == null
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDim.gapHair,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: compact ? AppText.segmented : AppText.caption,
                        fontWeight: selected
                            ? FontWeight.w700
                            : (compact ? FontWeight.w600 : FontWeight.w500),
                        color: labelColor,
                        height: AppDim.lineH,
                      ),
                    ),
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
    );
    final padded = compact
        ? tile
        : Padding(padding: const EdgeInsets.all(AppDim.gapXs), child: tile);
    return Tooltip(message: tooltip, child: padded);
  }
}
