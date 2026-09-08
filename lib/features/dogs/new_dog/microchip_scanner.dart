import 'package:flutter/material.dart';

import 'microchip_scan_page.dart';
import 'new_dog_validation.dart';

abstract interface class MicrochipScanner {
  Future<String?> scan(BuildContext context);
}

class MobileMicrochipScanner implements MicrochipScanner {
  const MobileMicrochipScanner();

  @override
  Future<String?> scan(BuildContext context) async {
    final raw = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const MicrochipScanPage()),
    );
    if (raw == null) {
      return null;
    }
    return extractMicrochipDigits(raw) ?? raw;
  }
}
