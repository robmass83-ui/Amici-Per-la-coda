import 'package:flutter/material.dart';

import '../../core/web_surface.dart';
import '../tokens.dart';

// ── CONTRATTO DI LAYOUT · WebContentColumn ────────────────────────────────
// Se non web o width ≤ 430: child a tutta larghezza (identico all'APK)
// Se web e width > 430:
//   ColoredBox bg
//     Align topCenter
//       SizedBox width=430  child
// Nessuno scroll orizzontale.
// ──────────────────────────────────────────────────────────────────────────

class WebContentColumn extends StatelessWidget {
  const WebContentColumn({
    super.key,
    required this.child,
    this.isWebOverride,
  });

  final Widget child;
  final bool? isWebOverride;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (!showWideWebColumn(isWeb: isWebOverride, width: width)) {
      return child;
    }
    return ColoredBox(
      color: AppColor.bg,
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: AppDim.webMaxContentWidth,
          child: child,
        ),
      ),
    );
  }
}
