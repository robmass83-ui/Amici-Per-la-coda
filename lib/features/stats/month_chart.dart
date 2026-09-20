import 'package:flutter/material.dart';

import '../../ui/tokens.dart';
import 'stats_aggregators.dart';

// ── CONTRATTO DI LAYOUT · Adozioni per mese ────────────────────────────────
// Column stretch
// ├ SizedBox h=AppDim.statsChartH(96)
// │  └ CustomPaint  12 barre  gap=AppDim.gapS
// │     raggio alto AppDim.radIconBox
// │     ≥80% del max → AppColor.green, resto greenSoft
// │     vuoto: altezza minima AppDim.statsBarMin del chart
// └ Row  12× Expanded  lettera mese  AppText.micro  muted  ellipsis
// ───────────────────────────────────────────────────────────────────────────

class AdozioniMeseChart extends StatelessWidget {
  const AdozioniMeseChart({super.key, required this.perMese});

  final List<int> perMese;

  @override
  Widget build(BuildContext context) {
    final labels = mesiBreviAnno();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: AppDim.statsChartH,
          child: CustomPaint(
            painter: AdozioniMesePainter(perMese: perMese),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: AppDim.gapXs),
        Row(
          children: [
            for (var i = 0; i < 12; i++)
              Expanded(
                child: Text(
                  labels[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: AppText.micro,
                    color: AppColor.muted,
                    height: AppDim.lineH,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class AdozioniMesePainter extends CustomPainter {
  AdozioniMesePainter({required this.perMese});

  final List<int> perMese;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || perMese.length != 12) {
      return;
    }
    var maxN = 0;
    for (final n in perMese) {
      if (n > maxN) {
        maxN = n;
      }
    }
    const gap = AppDim.gapS;
    final barW = (size.width - gap * 11) / 12;
    const radius = Radius.circular(AppDim.radIconBox);
    for (var i = 0; i < 12; i++) {
      final n = perMese[i];
      final ratio = maxN <= 0
          ? AppDim.statsBarMin
          : (n / maxN).clamp(AppDim.statsBarMin, 1.0);
      final h = size.height * ratio;
      final left = i * (barW + gap);
      final rect = Rect.fromLTWH(left, size.height - h, barW, h);
      final rrect = RRect.fromRectAndCorners(
        rect,
        topLeft: radius,
        topRight: radius,
      );
      final strong = maxN > 0 && n / maxN >= AppDim.statsHot;
      final paint = Paint()
        ..color = strong ? AppColor.green : AppColor.greenSoft
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant AdozioniMesePainter oldDelegate) {
    if (oldDelegate.perMese.length != perMese.length) {
      return true;
    }
    for (var i = 0; i < perMese.length; i++) {
      if (oldDelegate.perMese[i] != perMese[i]) {
        return true;
      }
    }
    return false;
  }
}
