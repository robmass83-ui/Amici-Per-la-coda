import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

const tinyPngB64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

Uint8List tinyPngBytes() => Uint8List.fromList(base64Decode(tinyPngB64));

Future<Uint8List> solidPng({
  Color color = const Color(0xFF157A3C),
  int width = 32,
  int height = 32,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = color,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

Future<Uint8List> noisyPng({required int width, required int height}) async {
  final pixels = Uint8List(width * height * 4);
  var state = 1103515245;
  for (var i = 0; i < pixels.length; i += 4) {
    state = 1664525 * state + 1013904223;
    pixels[i] = state & 255;
    pixels[i + 1] = (state >> 8) & 255;
    pixels[i + 2] = (state >> 16) & 255;
    pixels[i + 3] = 255;
  }
  final done = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    pixels,
    width,
    height,
    ui.PixelFormat.rgba8888,
    done.complete,
  );
  final image = await done.future;
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
