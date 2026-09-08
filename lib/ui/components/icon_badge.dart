import 'package:flutter/material.dart';
import '../tokens.dart';
import '../icons.dart';

/// Quadratino colorato con l'icona dentro — l'elemento visivo ricorrente
/// dell'app (righe informative, menu, liste, stat card).
class IconBadge extends StatelessWidget {
  const IconBadge(this.spec, {super.key, this.size = AppDim.iconBox});

  final AppIconSpec spec;
  final double size;

  /// Misure ammesse: 20 (dentro i titoli), 27 (righe informative),
  /// 30 (stat card), 32 (righe di menu), 34 (avatar dei volontari).
  static const inTitle = 20.0;
  static const inRow   = 27.0;
  static const inStat  = 30.0;
  static const inMenu  = 32.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: spec.bg,
        borderRadius: BorderRadius.circular(size * 0.30),
      ),
      child: Icon(spec.icon, size: size * 0.52, color: spec.fg),
    );
  }
}
