import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../core/firestore_codec.dart';
import 'photo_limit.dart';

// Limiti foto — coincidono con backend/firestore.rules (thumb < 25 KB,
// dati < 600 KB). Firestore accetta 1 MiB a documento; il codec sta sotto
// (thumb 12 KB, full 450 KB) così resta margine per metadati e per il
// fallback JPEG. Se si alzano questi tetti oltre le soglie delle regole,
// il client comprime e Firestore rifiuta il write. Non spingere verso 1 MiB:
// un Blob grosso saturerebbe la quota e farebbe fallire il batch.
const photoMaxPerDog = 20;
const photoFullMaxSide = 1400;
const photoFullReducedSide = 1100;
const photoThumbMaxSide = 200;
const photoFullQuality = 80;
const photoFullMinQuality = 45;
const photoThumbQuality = 70;
const photoFullMaxBytes = 450 * 1024;
const photoThumbMaxBytes = 12 * 1024;

/// Tetto regole `thumb.size() < 25000`. Il codec resta a [photoThumbMaxBytes].
const photoThumbRulesMaxBytes = 25000;

/// Tetto regole `dati.size() < 600000`. Il codec resta a [photoFullMaxBytes].
const photoFullRulesMaxBytes = 600000;
const photoDocumentMaxBytes = 900 * 1024;
const photoQualityStep = 5;
const photoMaxQualityAttempts = 8;
const documentImageMaxSide = 1600;
const documentImageQuality = 70;
const documentImageMaxBytes = 300 * 1024;

const photoMimeWebp = 'image/webp';
const photoMimeJpeg = 'image/jpeg';
const photoMimePng = 'image/png';

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

class _PhotoProfile {
  const _PhotoProfile({
    required this.fullMaxSide,
    required this.fullReducedSide,
    required this.fullQuality,
    required this.fullMinQuality,
    required this.thumbMaxSide,
    required this.thumbQuality,
    required this.thumbMaxBytes,
    required this.preferWebp,
  });

  final int fullMaxSide;
  final int fullReducedSide;
  final int fullQuality;
  final int fullMinQuality;
  final int thumbMaxSide;
  final int thumbQuality;
  final int thumbMaxBytes;
  final bool preferWebp;
}

const _webpProfile = _PhotoProfile(
  fullMaxSide: photoFullMaxSide,
  fullReducedSide: photoFullReducedSide,
  fullQuality: photoFullQuality,
  fullMinQuality: photoFullMinQuality,
  thumbMaxSide: photoThumbMaxSide,
  thumbQuality: photoThumbQuality,
  thumbMaxBytes: photoThumbMaxBytes,
  preferWebp: true,
);

/// JPEG 900 px q72 / thumb 160 px q60: solo per il confronto nei test STEP 4.
const _jpegLegacyProfile = _PhotoProfile(
  fullMaxSide: 900,
  fullReducedSide: 700,
  fullQuality: 72,
  fullMinQuality: 45,
  thumbMaxSide: 160,
  thumbQuality: 60,
  thumbMaxBytes: 15 * 1024,
  preferWebp: false,
);

/// Pipeline STEP 4: full WebP 1400 px q80 (max 450 KB; q min 45, poi 1100 px)
/// e thumb WebP 200 px q70 (max 12 KB). Se WebP non è disponibile: JPEG.
/// Il plugin gira sul thread nativo; il fallback Dart usa [compute].
Future<CompressedPhoto> compressDogPhoto(Uint8List source) {
  return _compressDogPhoto(source, _webpProfile);
}

/// Confronta il risparmio STEP 4 rispetto al JPEG in uso fino allo STEP 3.
@visibleForTesting
Future<CompressedPhoto> compressDogPhotoJpegBaseline(Uint8List source) {
  return _compressDogPhoto(source, _jpegLegacyProfile);
}

String photoFileExtension(String mime) {
  if (mime == photoMimeWebp) {
    return 'webp';
  }
  if (mime == photoMimePng) {
    return 'png';
  }
  return 'jpg';
}

Future<CompressedPhoto> _compressDogPhoto(
  Uint8List source,
  _PhotoProfile profile,
) async {
  if (_useNativePlugin) {
    if (profile.preferWebp) {
      final webp = await _nativePipeline(
        source,
        profile,
        CompressFormat.webp,
        photoMimeWebp,
      );
      if (webp != null) {
        return webp;
      }
    }
    final jpeg = await _nativePipeline(
      source,
      profile,
      CompressFormat.jpeg,
      photoMimeJpeg,
    );
    if (jpeg != null) {
      return jpeg;
    }
  }
  if (_inFlutterTest) {
    return _uiPipeline(source, profile);
  }
  try {
    final map = profile.preferWebp
        ? await compute(_softwareCompressWebp, source)
        : await compute(_softwareCompressJpeg, source);
    return _photoFromIsolate(map);
  } catch (_) {
    return _uiPipeline(source, profile);
  }
}

Map<String, Object> _photoToIsolate(CompressedPhoto photo) {
  return {
    'full': photo.full,
    'thumb': photo.thumb,
    'width': photo.width,
    'height': photo.height,
    'mime': photo.mime,
  };
}

CompressedPhoto _photoFromIsolate(Map<String, Object> map) {
  return CompressedPhoto(
    full: map['full']! as Uint8List,
    thumb: map['thumb']! as Uint8List,
    width: map['width']! as int,
    height: map['height']! as int,
    mime: map['mime']! as String,
  );
}

Future<Map<String, Object>> _softwareCompressWebp(Uint8List source) async {
  return _photoToIsolate(await _uiPipeline(source, _webpProfile));
}

Future<Map<String, Object>> _softwareCompressJpeg(Uint8List source) async {
  return _photoToIsolate(await _uiPipeline(source, _jpegLegacyProfile));
}

bool get _inFlutterTest {
  try {
    return Platform.environment.containsKey('FLUTTER_TEST');
  } catch (_) {
    return false;
  }
}

bool get _useNativePlugin {
  if (kIsWeb) {
    return false;
  }
  try {
    return Platform.isAndroid || Platform.isIOS;
  } catch (_) {
    return false;
  }
}

Future<CompressedPhoto?> _nativePipeline(
  Uint8List source,
  _PhotoProfile profile,
  CompressFormat format,
  String mime,
) async {
  try {
    final full = await _nativeFull(source, profile, format);
    if (full == null || full.isEmpty) {
      return null;
    }
    final thumb = await _nativeThumb(source, profile, format);
    if (thumb == null || thumb.isEmpty) {
      return null;
    }
    final size = await _decodeSize(full);
    return CompressedPhoto(
      full: full,
      thumb: thumb,
      width: size.$1,
      height: size.$2,
      mime: mime,
    );
  } catch (_) {
    return null;
  }
}

Future<Uint8List?> _nativeFull(
  Uint8List source,
  _PhotoProfile profile,
  CompressFormat format,
) async {
  var quality = profile.fullQuality;
  var side = profile.fullMaxSide;
  Uint8List? last;
  while (true) {
    last = await _nativeOnce(
      source,
      maxSide: side,
      quality: quality,
      format: format,
    );
    if (last == null) {
      return null;
    }
    if (last.lengthInBytes <= photoFullMaxBytes) {
      return last;
    }
    if (quality > profile.fullMinQuality) {
      quality -= photoQualityStep;
      continue;
    }
    if (side > profile.fullReducedSide) {
      side = profile.fullReducedSide;
      continue;
    }
    return last;
  }
}

Future<Uint8List?> _nativeThumb(
  Uint8List source,
  _PhotoProfile profile,
  CompressFormat format,
) async {
  var quality = profile.thumbQuality;
  var side = profile.thumbMaxSide;
  Uint8List? last;
  var attempts = 0;
  while (true) {
    last = await _nativeOnce(
      source,
      maxSide: side,
      quality: quality,
      format: format,
    );
    if (last == null) {
      return null;
    }
    if (last.lengthInBytes <= profile.thumbMaxBytes) {
      return last;
    }
    attempts++;
    if (quality > profile.fullMinQuality) {
      quality -= photoQualityStep;
      continue;
    }
    if (attempts < photoMaxQualityAttempts && side > 40) {
      side = (side * 0.85).round().clamp(40, profile.thumbMaxSide);
      continue;
    }
    return last;
  }
}

Future<Uint8List?> _nativeOnce(
  Uint8List source, {
  required int maxSide,
  required int quality,
  required CompressFormat format,
}) async {
  try {
    final out = await FlutterImageCompress.compressWithList(
      source,
      minWidth: maxSide,
      minHeight: maxSide,
      quality: quality,
      format: format,
    );
    if (out.isEmpty) {
      return null;
    }
    return Uint8List.fromList(out);
  } catch (_) {
    return null;
  }
}

Future<CompressedPhoto> _uiPipeline(
  Uint8List source,
  _PhotoProfile profile,
) async {
  var quality = profile.fullQuality;
  var side = profile.fullMaxSide;
  Uint8List? full;
  while (true) {
    full = await _compressWithUi(
      source,
      maxSide: side,
      maxBytes: photoFullMaxBytes,
    );
    if (full.lengthInBytes <= photoFullMaxBytes) {
      break;
    }
    if (quality > profile.fullMinQuality) {
      quality -= photoQualityStep;
      side = (side * 0.92).round().clamp(profile.fullReducedSide, side);
      continue;
    }
    if (side > profile.fullReducedSide) {
      side = profile.fullReducedSide;
      continue;
    }
    break;
  }

  var thumb = await _compressWithUi(
    source,
    maxSide: profile.thumbMaxSide,
    maxBytes: profile.thumbMaxBytes,
  );
  var thumbSide = profile.thumbMaxSide;
  var attempts = 0;
  while (thumb.lengthInBytes > profile.thumbMaxBytes &&
      attempts < photoMaxQualityAttempts &&
      thumbSide > 40) {
    thumbSide = (thumbSide * 0.85).round();
    thumb = await _compressWithUi(
      source,
      maxSide: thumbSide,
      maxBytes: profile.thumbMaxBytes,
    );
    attempts++;
  }

  final size = await _decodeSize(full);
  return CompressedPhoto(
    full: full,
    thumb: thumb,
    width: size.$1,
    height: size.$2,
    mime: photoMimePng,
  );
}

Future<Uint8List> _compress(
  Uint8List source, {
  required int maxSide,
  required int quality,
  int? maxBytes,
}) async {
  if (_useNativePlugin) {
    final out = await _nativeOnce(
      source,
      maxSide: maxSide,
      quality: quality,
      format: CompressFormat.jpeg,
    );
    if (out != null && out.isNotEmpty) {
      return out;
    }
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

void ensurePhotoDocumentFits(Map<String, dynamic> data) {
  if (firestoreMapBytes(data) > photoDocumentMaxBytes) {
    throw const PhotoTooLarge();
  }
}
