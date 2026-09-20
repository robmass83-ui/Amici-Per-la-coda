import 'package:flutter/material.dart';

import '../tokens.dart';

// ── CONTRATTO DI LAYOUT · AppSwitch ────────────────────────────────────────
// Hit 40×40  (AppDim.minTouch)
// └ traccia  38×22  raggio chip  fill green / barTrack
//    thumb  18  inset 2  bianco  a destra se on, a sinistra se off
// ───────────────────────────────────────────────────────────────────────────

class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return SizedBox(
      width: AppDim.minTouch,
      height: AppDim.minTouch,
      child: GestureDetector(
        onTap: enabled ? () => onChanged!(!value) : null,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: SizedBox(
            width: AppDim.switchW,
            height: AppDim.switchH,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: value ? AppColor.green : AppColor.barTrack,
                borderRadius: BorderRadius.circular(AppDim.radChip),
              ),
              child: Align(
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(AppDim.switchInset),
                  child: SizedBox(
                    width: AppDim.switchThumb,
                    height: AppDim.switchThumb,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColor.card,
                        shape: BoxShape.circle,
                        boxShadow: enabled
                            ? const [
                                BoxShadow(
                                  color: AppColor.shadow,
                                  blurRadius: AppDim.gapXs,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
