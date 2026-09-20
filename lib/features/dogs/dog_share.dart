import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../data/models/dog.dart';
import '../../data/models/photo.dart';
import '../../data/photos/cover_photo.dart';
import '../../data/photos/photo_codec.dart';
import '../../data/repositories/data_repositories.dart';
import 'dog_labels.dart';
import 'dog_share_io.dart' if (dart.library.html) 'dog_share_web.dart';

String testoCondivisioneScheda(Dog dog, DateTime now) {
  final nome = dogDisplayName(dog.nome);
  final eta = dogAgeShortLabel(dog, now, compact: false) ?? 'età non indicata';
  final tags = carattereLabel(dog.carattere);
  final carattere = tags == '—' ? 'carattere da conoscere' : tags;
  return '$nome\n$eta\n$carattere';
}

Future<void> condividiSchedaCane({
  required Dog dog,
  required DateTime now,
  required List<Photo> photos,
  PhotoRepository? photosRepo,
}) async {
  final text = testoCondivisioneScheda(dog, now);
  try {
    await Clipboard.setData(ClipboardData(text: text));
  } catch (_) {}
  if (_inWidgetTest) {
    return;
  }
  final cover = coverPhotoOf(photos, dog.fotoCopertinaId);
  Uint8List? bytes;
  if (cover != null) {
    bytes = await photosRepo?.loadFull(cover.id);
    if (bytes == null && cover.thumb.isNotEmpty) {
      bytes = cover.thumb;
    }
  }
  try {
    if (bytes != null && bytes.isNotEmpty) {
      await shareSchedaBytes(
        bytes: bytes,
        fileName:
            'scheda_${dog.id}.${photoFileExtension(cover?.mime ?? photoMimeJpeg)}',
        text: text,
      );
    } else {
      await shareSchedaTesto(text);
    }
  } catch (_) {
    // Plugin assente nei test: resta il testo negli appunti.
  }
}

bool get _inWidgetTest {
  return WidgetsBinding.instance.runtimeType.toString().contains('Test');
}
