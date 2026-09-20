import 'dart:typed_data';

import '../../core/firestore_codec.dart';

/// Metadati + miniatura in `photos/{id}`. Il Blob `thumb` è ≤ 12 KB (codec)
/// e deve restare < 25 KB (regole). Alzare oltre 25 KB: Firestore rifiuta
/// create/update. La foto piena sta in `photos/{id}/full/data` (`dati`,
/// codec ≤ 450 KB, regole < 600 KB) così la lista non scarica i full.
class Photo {
  const Photo({
    required this.id,
    required this.dogId,
    required this.isCover,
    required this.w,
    required this.h,
    required this.mime,
    required this.thumb,
    required this.bytesFull,
    required this.createdAt,
    required this.createdBy,
  });

  final String id;
  final String dogId;
  final bool isCover;
  final int w;
  final int h;
  final String mime;
  final Uint8List thumb;
  final int bytesFull;
  final DateTime createdAt;
  final String createdBy;

  factory Photo.fromMap(String id, Map<String, dynamic> map) {
    return Photo(
      id: id,
      dogId: map['dogId'] as String? ?? '',
      isCover: map['isCover'] as bool? ?? false,
      w: intFrom(map['w']),
      h: intFrom(map['h']),
      mime: map['mime'] as String? ?? 'image/jpeg',
      thumb: bytesFrom(map['thumb'] ?? map['thumbB64']),
      bytesFull: intFrom(map['bytesFull']),
      createdAt: dateTimeRequired(map['createdAt']),
      createdBy: map['createdBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dogId': dogId,
      'isCover': isCover,
      'w': w,
      'h': h,
      'mime': mime,
      'thumb': blobTo(thumb),
      'bytesFull': bytesFull,
      'createdAt': dateTimeTo(createdAt),
      'createdBy': createdBy,
    };
  }
}

class PhotoFull {
  const PhotoFull({required this.dati});

  /// Bytes della foto piena. Codec ≤ 450 KB; regole Firestore `dati.size() < 600000`.
  /// Alzare il codec sopra 600 KB fa rifiutare il documento `full/data`.
  final Uint8List dati;

  factory PhotoFull.fromMap(Map<String, dynamic> map) {
    return PhotoFull(dati: bytesFrom(map['dati'] ?? map['b64']));
  }

  Map<String, dynamic> toMap() => {'dati': blobTo(dati)};
}

extension PhotoCopy on Photo {
  Photo copyWith({bool? isCover}) {
    return Photo(
      id: id,
      dogId: dogId,
      isCover: isCover ?? this.isCover,
      w: w,
      h: h,
      mime: mime,
      thumb: thumb,
      bytesFull: bytesFull,
      createdAt: createdAt,
      createdBy: createdBy,
    );
  }
}
