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
}
