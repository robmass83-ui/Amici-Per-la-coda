import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/dog.dart';
import '../../data/models/photo.dart';
import '../../data/photos/cover_photo.dart';
import '../../data/repositories/data_repositories.dart';
import 'dog_labels.dart';

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
  await Clipboard.setData(ClipboardData(text: text));
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return;
  }
  final cover = coverPhotoOf(photos, dog.fotoCopertinaId);
  Uint8List? bytes;
  if (cover != null) {
    bytes = await photosRepo?.loadFull(cover.id);
    if (bytes == null && cover.thumbB64.isNotEmpty) {
      bytes = Uint8List.fromList(base64Decode(cover.thumbB64));
    }
  }
  try {
    if (bytes != null && bytes.isNotEmpty) {
      final file = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}scheda_${dog.id}.jpg',
      );
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles([XFile(file.path)], text: text);
    } else {
      await Share.share(text);
    }
  } catch (_) {
    // Plugin assente nei test: resta il testo negli appunti.
  }
}
