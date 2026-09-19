import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'jpeg_encode.dart';

const pdfPhotoMaxSide = 1200;
const pdfPhotoQuality = 80;
const pdfGalleryMaxSide = 700;
const pdfGalleryQuality = 75;
const cardJpegQuality = 90;

class RgbaBitmap {
  const RgbaBitmap(this.pixels, this.width, this.height);
  final Uint8List pixels;
  final int width;
  final int height;
}

Future<RgbaBitmap> decodeRgbaScaled(
  Uint8List source, {
  required int maxSide,
}) async {
  final probe = await ui.instantiateImageCodec(source);
  final frame = await probe.getNextFrame();
  final src = frame.image;
  final sw = src.width;
  final sh = src.height;
  src.dispose();
  final longSide = sw > sh ? sw : sh;
  final ui.Codec codec;
  if (longSide <= maxSide) {
    codec = await ui.instantiateImageCodec(source);
  } else if (sw >= sh) {
    codec = await ui.instantiateImageCodec(source, targetWidth: maxSide);
  } else {
    codec = await ui.instantiateImageCodec(source, targetHeight: maxSide);
  }
  final scaled = await codec.getNextFrame();
  final image = scaled.image;
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) {
      throw StateError('Decodifica foto non riuscita.');
    }
    return RgbaBitmap(
      data.buffer.asUint8List(),
      image.width,
      image.height,
    );
  } finally {
    image.dispose();
  }
}

Uint8List encodeJpegIsolate((Uint8List, int, int, int) args) {
  return encodeJpeg(
    args.$1,
    width: args.$2,
    height: args.$3,
    quality: args.$4,
  );
}

Future<Uint8List> preparePhotoJpeg(
  Uint8List source, {
  required int maxSide,
  required int quality,
}) async {
  final bitmap = await decodeRgbaScaled(source, maxSide: maxSide);
  return compute(encodeJpegIsolate, (
    bitmap.pixels,
    bitmap.width,
    bitmap.height,
    quality,
  ));
}

Future<Uint8List> preparePhotoForPdf(Uint8List source) {
  return preparePhotoJpeg(
    source,
    maxSide: pdfPhotoMaxSide,
    quality: pdfPhotoQuality,
  );
}

Future<List<Uint8List>> preparePhotosForPdf(List<Uint8List> photos) async {
  if (photos.isEmpty) {
    return const [];
  }
  final out = <Uint8List>[
    await preparePhotoJpeg(
      photos.first,
      maxSide: pdfPhotoMaxSide,
      quality: pdfPhotoQuality,
    ),
  ];
  for (final photo in photos.skip(1)) {
    out.add(
      await preparePhotoJpeg(
        photo,
        maxSide: pdfGalleryMaxSide,
        quality: pdfGalleryQuality,
      ),
    );
  }
  return out;
}
