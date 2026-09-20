import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
import '../../data/models/adoption.dart';
import '../../data/models/document_template.dart';
import '../../data/models/dog.dart';
import '../../ui/components.dart';
import '../adoptions/adoption_flow.dart';
import '../affido/affido_copy.dart';
import '../auth/auth_providers.dart';
import '../dashboard/home_aggregators.dart';
import '../dogs/dog_labels.dart';
import '../dogs/dogs_providers.dart';

List<DocumentTemplate> templatesSorted(List<DocumentTemplate> items) {
  return List<DocumentTemplate>.of(items)
    ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
}

List<DocumentTemplate> templatesInHome(List<DocumentTemplate> items) {
  return templatesSorted(items.where((item) => item.visibilita.inHome).toList());
}

List<DocumentTemplate> templatesInScheda(List<DocumentTemplate> items) {
  return templatesSorted(
    items.where((item) => item.visibilita.inScheda).toList(),
  );
}

Future<void> shareDocumentTemplate({
  required BuildContext context,
  required WidgetRef ref,
  required DocumentTemplate template,
  Adoption? adoption,
  Dog? dog,
}) async {
  if (template.pdfB64.isEmpty) {
    AppToast.show(context, 'Questo modulo non ha un file PDF.');
    return;
  }
  final bytes = base64Decode(template.pdfB64);
  final share = ref.read(fileShareProvider);
  final text = moduloShareText(
    templateId: template.id,
    templateNome: template.nome,
    adopterNome: adoption == null ? '' : richiedenteNome(adoption),
    dogNome: dog == null ? '' : dogDisplayName(dog.nome),
  );
  await share.shareFile(
    bytes: Uint8List.fromList(bytes),
    fileName: template.fileName,
    mime: template.mime,
    text: text,
  );
  if (adoption != null) {
    final repo = ref.read(adoptionRepositoryProvider);
    final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    final now = ref.read(dogListNowProvider);
    if (repo != null) {
      await repo.save(
        recordModuloInviato(
          adoption: adoption,
          moduloId: template.id,
          now: now,
          autoreId: uid,
        ),
      );
    }
  }
  if (context.mounted) {
    AppToast.show(context, 'Modulo pronto da condividere.');
  }
}

Adoption? adoptionForDog(List<Adoption> adoptions, String? dogId) {
  if (dogId == null || dogId.isEmpty) {
    return null;
  }
  final ofDog = adoptions.where((item) => item.dogId == dogId).toList()
    ..sort((a, b) => b.dataRichiesta.compareTo(a.dataRichiesta));
  if (ofDog.isEmpty) {
    return null;
  }
  return ofDog.first;
}
