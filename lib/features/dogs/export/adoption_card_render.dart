import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';

import '../../../ui/tokens.dart';
import 'adoption_card_widget.dart';
import 'adoption_profile.dart';
import 'photo_prepare.dart';

Future<Uint8List> captureAdoptionCardJpeg(
  BuildContext context,
  AdoptionProfile profile,
) async {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) {
    throw StateError('Overlay assente: impossibile rendere la card.');
  }
  final key = GlobalKey();
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) {
      return Positioned(
        left: -AppDim.exportCardW - AppDim.exportCardPad,
        top: 0,
        child: Material(
          color: AppColor.card,
          child: RepaintBoundary(
            key: key,
            child: SizedBox(
              width: AppDim.exportCardW,
              height: AppDim.exportCardH,
              child: MediaQuery(
                data: const MediaQueryData(
                  size: Size(AppDim.exportCardW, AppDim.exportCardH),
                  devicePixelRatio: 1,
                ),
                child: AdoptionCardWidget(profile: profile),
              ),
            ),
          ),
        ),
      );
    },
  );
  overlay.insert(entry);
  await WidgetsBinding.instance.endOfFrame;
  await Future<void>.delayed(const Duration(milliseconds: 40));
  try {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('RepaintBoundary della card non pronto.');
    }
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) {
        throw StateError('Conversione card non riuscita.');
      }
      return await compute(encodeJpegIsolate, (
        data.buffer.asUint8List(),
        image.width,
        image.height,
        cardJpegQuality,
      ));
    } finally {
      image.dispose();
    }
  } finally {
    entry.remove();
  }
}

Future<Uint8List> jpegFromRgba({
  required Uint8List rgba,
  required int width,
  required int height,
  int quality = cardJpegQuality,
}) {
  return compute(encodeJpegIsolate, (rgba, width, height, quality));
}
