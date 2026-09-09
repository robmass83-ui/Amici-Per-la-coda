import 'dart:io' show Platform;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';

const photoMaxPerDog = 20;
const photoFullMaxSide = 900;
const photoThumbMaxSide = 160;
const photoFullQuality = 72;
const photoThumbQuality = 60;
const photoFullMaxBytes = 700 * 1024;
const photoThumbMaxBytes = 15 * 1024;
const photoQualityStep = 5;
const photoMaxQualityAttempts = 6;
const documentImageMaxSide = 1600;
const documentImageQuality = 70;
const documentImageMaxBytes = 300 * 1024;

class CompressedPhoto {
  const CompressedPhoto({
    required this.full,
    required this.thumb,
    required this.width,
    required this.height,
    required this.mime,
  });

  final Uint8List full;
  final Uint8List thumb;
  final int width;
  final int height;
  final String mime;
}

/// Pipeline §6: full 900 px q72 (max 700 KB) e thumb 160 px q60 (max 15 KB).
Future<CompressedPhoto> compressDogPhoto(Uint8List source) async {
  var quality = photoFullQuality;
  Uint8List? full;
  for (var i = 0; i < photoMaxQualityAttempts; i++) {
    full = await _compress(
      source,
      maxSide: photoFullMaxSide,
      quality: quality,
      maxBytes: photoFullMaxBytes,
    );
    if (full.lengthInBytes <= photoFullMaxBytes) {
      break;
    }
    quality -= photoQualityStep;
  }
  full ??= await _compress(
    source,
    maxSide: photoFullMaxSide,
    quality: photoQualityStep,
    maxBytes: photoFullMaxBytes,
  );
  if (full.lengthInBytes > photoFullMaxBytes) {
    full = await _compress(
      source,
      maxSide: photoFullMaxSide ~/ 2,
      quality: photoQualityStep,
      maxBytes: photoFullMaxBytes,
    );
  }

  var thumb = await _compress(
    source,
    maxSide: photoThumbMaxSide,
    quality: photoThumbQuality,
    maxBytes: photoThumbMaxBytes,
  );
  var thumbSide = photoThumbMaxSide;
  var attempts = 0;
  while (thumb.lengthInBytes > photoThumbMaxBytes &&
      attempts < photoMaxQualityAttempts &&
      thumbSide > 40) {
    thumbSide = (thumbSide * 0.85).round();
    thumb = await _compress(
      source,
      maxSide: thumbSide,
      quality: photoQualityStep,
      maxBytes: photoThumbMaxBytes,
    );
    attempts++;
  }

  final size = await _decodeSize(full);
  return CompressedPhoto(
    full: full,
    thumb: thumb,
    width: size.$1,
    height: size.$2,
    mime: 'image/jpeg',
  );
}

bool get _useNativeJpeg {
  try {
    return Platform.isAndroid || Platform.isIOS;
  } catch (_) {
    return false;
  }
}

Future<Uint8List> _compress(
  Uint8List source, {
  required int maxSide,
  required int quality,
  int? maxBytes,
}) async {
  if (_useNativeJpeg) {
    try {
      final out = await FlutterImageCompress.compressWithList(
        source,
        minWidth: maxSide,
        minHeight: maxSide,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      if (out.isNotEmpty) {
        return Uint8List.fromList(out);
      }
    } catch (_) {}
  }
  return _compressWithUi(source, maxSide: maxSide, maxBytes: maxBytes);
}

Future<Uint8List> _compressWithUi(
  Uint8List source, {
  required int maxSide,
  int? maxBytes,
}) async {
  var side = maxSide;
  Uint8List? last;
  for (var i = 0; i < photoMaxQualityAttempts + 4; i++) {
    last = await _scaleToPng(source, maxSide: side);
    if (maxBytes == null || last.lengthInBytes <= maxBytes) {
      return last;
    }
    side = (side * 0.7).round().clamp(8, maxSide);
  }
  return last ?? source;
}

Future<Uint8List> _scaleToPng(Uint8List source, {required int maxSide}) async {
  final codec = await ui.instantiateImageCodec(source);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  try {
    final longSide = image.width > image.height ? image.width : image.height;
    final scale = longSide <= maxSide ? 1.0 : maxSide / longSide;
    final w = (image.width * scale).round().clamp(1, maxSide);
    final h = (image.height * scale).round().clamp(1, maxSide);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawImageRect(
      image,
      ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );
    final picture = recorder.endRecording();
    final scaled = await picture.toImage(w, h);
    picture.dispose();
    try {
      final data = await scaled.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) {
        return source;
      }
      return data.buffer.asUint8List();
    } finally {
      scaled.dispose();
    }
  } finally {
    image.dispose();
  }
}

Future<(int, int)> _decodeSize(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final w = frame.image.width;
  final h = frame.image.height;
  frame.image.dispose();
  return (w, h);
}

/// Pipeline moduli firmati: 1600 px lato lungo, qualità 70, sotto i 300 KB.
Future<Uint8List> compressDocumentImage(Uint8List source) async {
  var side = documentImageMaxSide;
  var quality = documentImageQuality;
  Uint8List? last;
  for (var i = 0; i < photoMaxQualityAttempts + 6; i++) {
    last = await _compress(
      source,
      maxSide: side,
      quality: quality,
      maxBytes: documentImageMaxBytes,
    );
    if (last.lengthInBytes <= documentImageMaxBytes) {
      return last;
    }
    quality = (quality - 10).clamp(photoQualityStep, documentImageQuality);
    side = (side * 0.75).round().clamp(80, documentImageMaxSide);
  }
  return last ?? source;
}
