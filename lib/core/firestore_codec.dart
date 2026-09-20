import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? dateTimeFrom(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  throw ArgumentError('Valore data non valido');
}

DateTime dateTimeRequired(dynamic value) {
  final parsed = dateTimeFrom(value);
  if (parsed == null) {
    throw ArgumentError('Data obbligatoria mancante');
  }
  return parsed;
}

Object? dateTimeTo(DateTime? value) {
  if (value == null) {
    return null;
  }
  return Timestamp.fromDate(value);
}

double? numberFrom(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  throw ArgumentError('Valore numerico non valido');
}

int intFrom(dynamic value, {int fallback = 0}) {
  if (value == null) {
    return fallback;
  }
  if (value is num) {
    return value.toInt();
  }
  throw ArgumentError('Valore intero non valido');
}

bool boolFrom(dynamic value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }
  return fallback;
}

/// Legge Blob, Uint8List o (legacy) stringa base64.
Uint8List bytesFrom(dynamic value) {
  if (value == null) {
    return Uint8List(0);
  }
  if (value is Blob) {
    return Uint8List.fromList(value.bytes);
  }
  if (value is Uint8List) {
    return value;
  }
  if (value is List<int>) {
    return Uint8List.fromList(value);
  }
  if (value is String && value.isNotEmpty) {
    try {
      return Uint8List.fromList(base64Decode(value));
    } catch (_) {
      return Uint8List(0);
    }
  }
  return Uint8List(0);
}

Blob blobTo(Uint8List bytes) => Blob(bytes);

int firestoreValueBytes(dynamic value) {
  if (value == null) {
    return 1;
  }
  if (value is Blob) {
    return value.bytes.length;
  }
  if (value is Uint8List) {
    return value.lengthInBytes;
  }
  if (value is String) {
    return value.length;
  }
  if (value is Timestamp) {
    return 8;
  }
  if (value is bool) {
    return 1;
  }
  if (value is num) {
    return 8;
  }
  if (value is Map) {
    return firestoreMapBytes(Map<String, dynamic>.from(value));
  }
  if (value is Iterable) {
    var total = 0;
    for (final item in value) {
      total += firestoreValueBytes(item);
    }
    return total;
  }
  return 8;
}

int firestoreMapBytes(Map<String, dynamic> map) {
  var total = 0;
  for (final entry in map.entries) {
    total += entry.key.length + firestoreValueBytes(entry.value);
  }
  return total;
}

/// Lettura cache-first con fallback server.
/// Razze (`Dog.razza`) e tipi trattamento (`HealthTipo`, `patologiePreset`)
/// non sono collezioni Firestore: restano costanti/enum locali.
Future<DocumentSnapshot<Map<String, dynamic>>> getCacheThenServer(
  DocumentReference<Map<String, dynamic>> doc,
) async {
  try {
    final cached = await doc.get(const GetOptions(source: Source.cache));
    if (cached.exists) {
      return cached;
    }
  } catch (_) {}
  return doc.get();
}

Future<QuerySnapshot<Map<String, dynamic>>> getQueryCacheThenServer(
  Query<Map<String, dynamic>> query,
) async {
  try {
    final cached = await query.get(const GetOptions(source: Source.cache));
    if (cached.docs.isNotEmpty) {
      return cached;
    }
  } catch (_) {}
  return query.get();
}

/// Una subscription Firestore, più ascoltatori Dart. L'ultimo snapshot è
/// replayato ai nuovi ascoltatori (così `metadata.isFromCache` non si perde).
class SharedQuerySnapshots {
  SharedQuerySnapshots(Query<Map<String, dynamic>> query)
    : _source = query.snapshots(includeMetadataChanges: true);

  final Stream<QuerySnapshot<Map<String, dynamic>>> _source;
  QuerySnapshot<Map<String, dynamic>>? _last;
  StreamController<QuerySnapshot<Map<String, dynamic>>>? _ctrl;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots() {
    _ctrl ??= StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );
    return Stream<QuerySnapshot<Map<String, dynamic>>>.multi((listener) {
      final last = _last;
      if (last != null) {
        listener.add(last);
      }
      final sub = _ctrl!.stream.listen(
        listener.add,
        onError: listener.addError,
        onDone: listener.close,
      );
      listener
        ..onPause = sub.pause
        ..onResume = sub.resume
        ..onCancel = sub.cancel;
    });
  }

  void _start() {
    _sub ??= _source.listen(
      (snap) {
        _last = snap;
        _ctrl?.add(snap);
      },
      onError: (Object error, StackTrace stack) {
        _ctrl?.addError(error, stack);
      },
    );
  }

  void _stop() {
    unawaited(_sub?.cancel());
    _sub = null;
    _last = null;
  }
}

class Audit {
  const Audit({
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
  });

  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;

  factory Audit.fromMap(Map<String, dynamic> map) {
    final fallback = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    return Audit(
      createdAt: dateTimeFrom(map['createdAt']) ?? fallback,
      createdBy: map['createdBy'] as String? ?? '',
      updatedAt: dateTimeFrom(map['updatedAt']) ?? fallback,
      updatedBy: map['updatedBy'] as String? ?? '',
    );
  }

  factory Audit.seed(DateTime at, {String by = 'seed'}) {
    return Audit(createdAt: at, createdBy: by, updatedAt: at, updatedBy: by);
  }

  Map<String, dynamic> toMap() {
    return {
      'createdAt': dateTimeTo(createdAt),
      'createdBy': createdBy,
      'updatedAt': dateTimeTo(updatedAt),
      'updatedBy': updatedBy,
    };
  }

  Audit copyWith({
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return Audit(
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  Audit touched(String by, DateTime at) {
    return copyWith(updatedAt: at, updatedBy: by);
  }
}
