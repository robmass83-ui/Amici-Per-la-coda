import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/adopter.dart';
import 'models/adoption.dart';
import 'models/app_document.dart';
import 'models/appointment.dart';
import 'models/association_settings.dart';
import 'models/document_template.dart';
import 'models/dog.dart';
import 'models/expense.dart';
import 'models/health_record.dart';
import 'models/shelter_box.dart';
import 'models/sponsorship.dart';
import 'models/volunteer.dart';

Object? jsonSafe(Object? value) {
  if (value == null || value is num || value is bool || value is String) {
    return value;
  }
  if (value is DateTime) {
    return value.toUtc().toIso8601String();
  }
  if (value is Timestamp) {
    return value.toDate().toUtc().toIso8601String();
  }
  if (value is Map) {
    return {
      for (final entry in value.entries)
        entry.key.toString(): jsonSafe(entry.value),
    };
  }
  if (value is Iterable) {
    return [for (final item in value) jsonSafe(item)];
  }
  return value.toString();
}

Map<String, dynamic> _withId(String id, Map<String, dynamic> map) {
  return {'id': id, ...map};
}

Map<String, dynamic> buildBackupMap({
  required DateTime exportedAt,
  required List<Dog> dogs,
  required List<Volunteer> volunteers,
  required List<ShelterBox> boxes,
  required List<Adoption> adoptions,
  required List<Adopter> adopters,
  required List<Appointment> appointments,
  required List<HealthRecord> health,
  required List<Expense> expenses,
  required List<Sponsorship> sponsorships,
  required List<AppDocument> documents,
  required List<DocumentTemplate> templates,
  AssociationSettings? association,
}) {
  return {
    'esportatoIl': exportedAt.toUtc().toIso8601String(),
    'associazione': association == null ? null : jsonSafe(association.toMap()),
    'dogs': [
      for (final item in dogs) jsonSafe(_withId(item.id, item.toMap())),
    ],
    'volunteers': [
      for (final item in volunteers)
        jsonSafe(_withId(item.id, item.toMap())),
    ],
    'boxes': [
      for (final item in boxes) jsonSafe(_withId(item.id, item.toMap())),
    ],
    'adoptions': [
      for (final item in adoptions)
        jsonSafe(_withId(item.id, item.toMap())),
    ],
    'adopters': [
      for (final item in adopters)
        jsonSafe(_withId(item.id, item.toMap())),
    ],
    'appointments': [
      for (final item in appointments)
        jsonSafe(_withId(item.id, item.toMap())),
    ],
    'health': [
      for (final item in health) jsonSafe(_withId(item.id, item.toMap())),
    ],
    'expenses': [
      for (final item in expenses)
        jsonSafe(_withId(item.id, item.toMap())),
    ],
    'sponsorships': [
      for (final item in sponsorships)
        jsonSafe(_withId(item.id, item.toMap())),
    ],
    'documents': [
      for (final item in documents)
        jsonSafe(_withId(item.id, item.toMap())..['contenutoB64'] = null),
    ],
    'templates': [
      for (final item in templates)
        jsonSafe(_withId(item.id, item.toMap())..['pdfB64'] = null),
    ],
    'notaFoto':
        'Le foto intere restano in Firestore (photos/{id}/full). '
        'Note e pesi per cane restano nelle rispettive collezioni.',
  };
}

String backupJsonOf(Map<String, dynamic> backup) {
  return const JsonEncoder.withIndent('  ').convert(jsonSafe(backup));
}

String backupFileName(DateTime exportedAt) {
  final d = exportedAt.toUtc();
  final month = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return 'amici-per-la-coda-export-${d.year}$month$day.json';
}
