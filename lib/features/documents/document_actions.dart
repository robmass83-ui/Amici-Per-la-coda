import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
import '../../data/models/app_document.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../auth/auth_providers.dart';
import '../dogs/add_document_sheet.dart';
import '../dogs/record_actions.dart';
import '../dogs/tab_labels.dart';

class DocumentActionKeys {
  static const open = Key('document-action-open');
  static const share = Key('document-action-share');
  static const rename = Key('document-action-rename');
  static const delete = Key('document-action-delete');
}

enum _DocumentMenuChoice { open, share, rename, delete }

String documentDisplayName(AppDocument document) {
  if (document.nome.trim().isNotEmpty) {
    return document.nome.trim();
  }
  return documentTipoLabel(document.tipo);
}

String documentFileName(AppDocument document) {
  final base = documentDisplayName(document);
  final ext = _extensionForMime(document.mime);
  if (ext.isEmpty || base.toLowerCase().endsWith(ext)) {
    return base;
  }
  return '$base$ext';
}

String documentMime(AppDocument document) {
  return document.mime.isEmpty ? 'application/pdf' : document.mime;
}

String _extensionForMime(String mime) {
  final lower = mime.toLowerCase();
  if (lower.contains('pdf') || lower.isEmpty) {
    return '.pdf';
  }
  if (lower.contains('jpeg') || lower.contains('jpg')) {
    return '.jpg';
  }
  if (lower.contains('png')) {
    return '.png';
  }
  if (lower.contains('webp')) {
    return '.webp';
  }
  return '';
}

void _closeDocumentMenu(BuildContext context, _DocumentMenuChoice choice) {
  Navigator.of(context, rootNavigator: true).pop(choice);
}

Future<void> showDocumentActions(
  BuildContext context,
  WidgetRef ref,
  AppDocument document, {
  required bool canWrite,
}) async {
  final choice = await AppSheet.show<_DocumentMenuChoice>(
    context: context,
    title: documentDisplayName(document),
    children: [
      OptionRow(
        key: DocumentActionKeys.open,
        icon: const IconBadge(AppIcons.apri, size: IconBadge.inMenu),
        title: 'Apri',
        onTap: () => _closeDocumentMenu(context, _DocumentMenuChoice.open),
      ),
      OptionRow(
        key: DocumentActionKeys.share,
        icon: const IconBadge(AppIcons.condividi, size: IconBadge.inMenu),
        title: 'Condividi',
        onTap: () => _closeDocumentMenu(context, _DocumentMenuChoice.share),
      ),
      if (canWrite)
        OptionRow(
          key: DocumentActionKeys.rename,
          icon: const IconBadge(AppIcons.modifica, size: IconBadge.inMenu),
          title: 'Rinomina',
          onTap: () => _closeDocumentMenu(context, _DocumentMenuChoice.rename),
        ),
      if (canWrite)
        OptionRow(
          key: DocumentActionKeys.delete,
          icon: const IconBadge(AppIcons.elimina, size: IconBadge.inMenu),
          title: 'Elimina',
          titleColor: AppColor.red,
          onTap: () => _closeDocumentMenu(context, _DocumentMenuChoice.delete),
        ),
    ],
  );
  if (!context.mounted || choice == null) {
    return;
  }
  switch (choice) {
    case _DocumentMenuChoice.open:
      await openAppDocument(context, ref, document);
    case _DocumentMenuChoice.share:
      await shareAppDocument(context, ref, document);
    case _DocumentMenuChoice.rename:
      await AddDocumentSheet.open(
        context,
        dogId: document.dogId ?? '',
        existing: document,
      );
    case _DocumentMenuChoice.delete:
      await deleteAppDocument(context, ref, document);
  }
}

Future<void> openAppDocument(
  BuildContext context,
  WidgetRef ref,
  AppDocument document,
) async {
  try {
    final bytes = await _loadBytes(ref, document);
    if (!context.mounted) {
      return;
    }
    await ref.read(fileOpenerProvider).openFile(
      bytes: bytes,
      fileName: documentFileName(document),
      mime: documentMime(document),
    );
  } catch (_) {
    if (context.mounted) {
      AppToast.show(context, 'Impossibile aprire il documento.');
    }
  }
}

Future<void> shareAppDocument(
  BuildContext context,
  WidgetRef ref,
  AppDocument document,
) async {
  try {
    final bytes = await _loadBytes(ref, document);
    if (!context.mounted) {
      return;
    }
    await ref.read(fileShareProvider).shareFile(
      bytes: bytes,
      fileName: documentFileName(document),
      mime: documentMime(document),
      text: documentDisplayName(document),
    );
  } catch (_) {
    if (context.mounted) {
      AppToast.show(context, 'Impossibile condividere il documento.');
    }
  }
}

Future<void> deleteAppDocument(
  BuildContext context,
  WidgetRef ref,
  AppDocument document,
) async {
  final nome = documentDisplayName(document);
  final ok = await confirmDeleteNamed(context, 'il documento «$nome»');
  if (!ok) {
    return;
  }
  await ref.read(documentRepositoryProvider)?.delete(document.id);
  final dogId = document.dogId;
  if (dogId != null && dogId.isNotEmpty) {
    await touchDogAudit(
      dogs: ref.read(dogRepositoryProvider),
      dogId: dogId,
      uid: ref.read(authRepositoryProvider).currentUser?.uid ?? '',
    );
  }
}

Future<Uint8List> _loadBytes(WidgetRef ref, AppDocument document) async {
  final repo = ref.read(documentRepositoryProvider);
  if (repo == null) {
    throw StateError('Archivio documenti non disponibile.');
  }
  final bytes = await repo.loadBytes(document.id);
  if (bytes.isEmpty) {
    throw StateError('Documento vuoto.');
  }
  return bytes;
}
