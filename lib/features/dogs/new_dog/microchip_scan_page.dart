import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../ui/components.dart';
import '../../../ui/tokens.dart';
import 'new_dog_validation.dart';

// ── CONTRATTO DI LAYOUT · Scanner microchip ────────────────────────────────
// Column
// ├ SafeArea bottom=false → AppHeader h=44  back  titolo «Scanner microchip»
// └ Expanded
//    ├ MobileScanner  fill
//    └ fascia bassa  padding=12  h auto
//         Text  12sp  maxLines=2  «Inquadra il codice a 15 cifre»
// ───────────────────────────────────────────────────────────────────────────

class MicrochipScanPage extends StatefulWidget {
  const MicrochipScanPage({super.key});

  @override
  State<MicrochipScanPage> createState() => _MicrochipScanPageState();
}

class _MicrochipScanPageState extends State<MicrochipScanPage> {
  final _controller = MobileScannerController();
  var _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) {
      return;
    }
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) {
        continue;
      }
      final chip = extractMicrochipDigits(raw);
      if (chip == null) {
        continue;
      }
      _handled = true;
      Navigator.of(context).pop(chip);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColor.ink,
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: AppHeader(
              title: 'Scanner microchip',
              onBack: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
            ),
          ),
          const ColoredBox(
            color: AppColor.card,
            child: Padding(
              padding: AppDim.pagePad,
              child: Text(
                'Inquadra il codice a barre o QR del microchip (15 cifre).',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: AppText.body,
                  color: AppColor.muted,
                  height: AppDim.lineH,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
