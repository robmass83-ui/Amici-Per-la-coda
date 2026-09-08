import 'package:flutter/material.dart';

import '../../ui/tokens.dart';
import 'health_labels.dart';

// ── CONTRATTO DI LAYOUT · Grafico peso ─────────────────────────────────────
// Column  crossAxisAlignment=stretch
// ├ SizedBox  h=AppDim.chartH(72)
// │  └ CustomPaint  barre verticali
// │     gap fra barre = AppDim.gapS(6)
// │     raggio alto = AppDim.radIconBox(8)
// │     ultima barra AppColor.green, le altre AppColor.greenSoft
// ├ SizedBox  h=AppDim.gapXs(4)
// └ Row
//    └ Expanded × n  Text mese  9sp  AppColor.muted
//       maxLines=1  ellipsis  textAlign=center
// ───────────────────────────────────────────────────────────────────────────

class PesoChart extends StatelessWidget {
  const PesoChart({super.key, required this.punti});

  final List<PesoPunto> punti;

  @override
  Widget build(BuildContext context) {
    if (punti.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: AppDim.chartH,
          child: CustomPaint(
            painter: PesoChartPainter(punti: punti),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: AppDim.gapXs),
        Row(
          children: [
            for (final punto in punti)
              Expanded(
                child: Text(
                  meseBreve(punto.data),
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

class PesoChartPainter extends CustomPainter {
  PesoChartPainter({required this.punti});

  final List<PesoPunto> punti;

  @override
  void paint(Canvas canvas, Size size) {
    if (punti.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }
    var maxKg = punti.first.kg;
    var minKg = punti.first.kg;
    for (final punto in punti) {
      if (punto.kg > maxKg) {
        maxKg = punto.kg;
      }
      if (punto.kg < minKg) {
        minKg = punto.kg;
      }
    }
    final floor = punti.length == 1 ? 0.0 : minKg * 0.85;
    final span = (maxKg - floor).clamp(1.0, double.infinity);

    final n = punti.length;
    const gap = AppDim.gapS;
    final barW = (size.width - gap * (n - 1)) / n;
    const radius = Radius.circular(AppDim.radIconBox);

    for (var i = 0; i < n; i++) {
      final ratio = ((punti[i].kg - floor) / span).clamp(0.05, 1.0);
      final h = size.height * ratio;
      final left = i * (barW + gap);
      final rect = Rect.fromLTWH(left, size.height - h, barW, h);
      final rrect = RRect.fromRectAndCorners(
        rect,
        topLeft: radius,
        topRight: radius,
      );
      final paint = Paint()
        ..color = i == n - 1 ? AppColor.green : AppColor.greenSoft
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant PesoChartPainter oldDelegate) {
    if (oldDelegate.punti.length != punti.length) {
      return true;
    }
    for (var i = 0; i < punti.length; i++) {
      if (oldDelegate.punti[i].kg != punti[i].kg ||
          oldDelegate.punti[i].data != punti[i].data) {
        return true;
      }
    }
    return false;
  }
}
