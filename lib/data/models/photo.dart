import '../../core/firestore_codec.dart';

class Photo {
  const Photo({
    required this.id,
    required this.dogId,
    required this.isCover,
    required this.w,
    required this.h,
    required this.mime,
    required this.thumbB64,
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
  final String thumbB64;
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
      thumbB64: map['thumbB64'] as String? ?? '',
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
      'thumbB64': thumbB64,
      'bytesFull': bytesFull,
      'createdAt': dateTimeTo(createdAt),
      'createdBy': createdBy,
    };
  }
}

class PhotoFull {
  const PhotoFull({required this.b64});

  final String b64;

  factory PhotoFull.fromMap(Map<String, dynamic> map) {
    return PhotoFull(b64: map['b64'] as String? ?? '');
  }

  Map<String, dynamic> toMap() => {'b64': b64};
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
      thumbB64: thumbB64,
      bytesFull: bytesFull,
      createdAt: createdAt,
      createdBy: createdBy,
    );
  }
}
