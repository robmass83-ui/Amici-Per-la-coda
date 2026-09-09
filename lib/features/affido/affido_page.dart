import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format_it.dart';
import '../../core/new_id.dart';
import '../../data/data_providers.dart';
import '../../data/documents/document_codec.dart';
import '../../data/documents/document_file_picker.dart';
import '../../data/documents/template_assets.dart';
import '../../data/models/adoption.dart';
import '../../data/models/app_document.dart';
import '../../data/models/document_template.dart';
import '../../data/models/dog.dart';
import '../../data/models/enums.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../adoptions/adoption_flow.dart';
import '../auth/auth_providers.dart';
import '../dashboard/home_aggregators.dart';
import '../dogs/dog_labels.dart';
import '../dogs/dogs_providers.dart';
import '../dogs/tab_labels.dart';
import 'affido_copy.dart';
import 'affido_providers.dart';
import 'affido_upload.dart';

// ── CONTRATTO DI LAYOUT · Documenti di affido ────────────────────────────
// AppScaffold  titolo «Documenti di affido»  back
// ListView  padding=12
// ├ AppCard banner inviato (se c'è)  testo 10.5sp  maxLines=2
// ├ SectionTitle  Moduli da inviare  icona AppIcons.modulo
// ├ AppCard  OptionRow ×2  titolo 12sp  subtitle Versione n · Invia
// ├ SectionTitle  Documenti ricevuti  icona AppIcons.documenti
// ├ AppCard  empty EmptyState  oppure OptionRow per file
// ├ SizedBox 12
// └ AppButton  Carica documento compilato
// ───────────────────────────────────────────────────────────────────────────

class AffidoPage extends ConsumerWidget {
  const AffidoPage({super.key, this.adoptionId, this.dogId});

  final String? adoptionId;
  final String? dogId;

  static const inviaPreaffidoKey = Key('affido-invia-preaffido');
  static const inviaAdozioneKey = Key('affido-invia-adozione');
  static const caricaKey = Key('affido-carica');
  static const bannerKey = Key('affido-banner-inviato');
  static const ricevutiKey = Key('affido-ricevuti');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref
        .watch(templatesStreamProvider)
        .maybeWhen(
          data: (items) => items,
          orElse: () => const <DocumentTemplate>[],
        );
    final adoptions = ref
        .watch(adoptionsStreamProvider)
        .maybeWhen(
          data: (items) => items,
          orElse: () => const <Adoption>[],
        );
    final dogs = ref
        .watch(dogsStreamProvider)
        .maybeWhen(data: (items) => items, orElse: () => const <Dog>[]);
    final adoption = _adoptionOf(adoptions, adoptionId, dogId);
    final dog = _dogOf(dogs, adoption?.dogId ?? dogId);
    final docs = _docsOf(ref, adoption, dog);
    final sortedTemplates = List<DocumentTemplate>.of(templates)
      ..sort((a, b) => a.id.compareTo(b.id));
    final received = List<AppDocument>.of(docs)
      ..sort((a, b) => b.caricatoIl.compareTo(a.caricatoIl));
    final volunteer = ref.watch(currentVolunteerProvider);
    final banner = adoption == null
        ? null
        : _bannerText(adoption, volunteer?.nome ?? '');

    return AppScaffold(
      title: 'Documenti di affido',
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      },
      body: ListView(
        padding: AppDim.pagePad,
        children: [
          if (banner != null) ...[
            AppCard(
              key: bannerKey,
              color: AppColor.greenTint,
              child: Text(
                banner,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: AppText.label,
                  color: AppColor.ink,
                  height: AppDim.lineH,
                ),
              ),
            ),
            const SizedBox(height: AppDim.gapM),
          ],
          const SectionTitle(
            title: 'Moduli da inviare',
            icon: IconBadge(AppIcons.modulo, size: IconBadge.inTitle),
          ),
          const SizedBox(height: AppDim.gapM),
          AppCard(
            child: Column(
              children: [
                for (var i = 0; i < sortedTemplates.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppDim.gapXs),
                  OptionRow(
                    key: sortedTemplates[i].id == templatePreaffidoId
                        ? inviaPreaffidoKey
                        : inviaAdozioneKey,
                    icon: const IconBadge(
                      AppIcons.modulo,
                      size: IconBadge.inMenu,
                    ),
                    title: sortedTemplates[i].nome,
                    subtitle:
                        'Versione ${sortedTemplates[i].versione} · Invia',
                    onTap: () => unawaited(
                      inviaModulo(
                        context: context,
                        ref: ref,
                        template: sortedTemplates[i],
                        adoption: adoption,
                        dog: dog,
                      ),
                    ),
                  ),
                ],
                if (sortedTemplates.isEmpty)
                  const EmptyState(
                    icon: IconBadge(AppIcons.modulo),
                    message: 'Moduli non ancora disponibili.',
                    compact: true,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppDim.gapL),
          const SectionTitle(
            title: 'Documenti ricevuti',
            icon: IconBadge(AppIcons.documenti, size: IconBadge.inTitle),
          ),
          const SizedBox(height: AppDim.gapM),
          AppCard(
            key: ricevutiKey,
            child: received.isEmpty
                ? const EmptyState(
                    icon: IconBadge(AppIcons.allegato),
                    message: 'Nessun documento ricevuto.',
                    compact: true,
                  )
                : Column(
                    children: [
                      for (var i = 0; i < received.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppDim.gapXs),
                        OptionRow(
                          icon: IconBadge(
                            AppIcons.perDocumento(received[i].tipo.wire),
                            size: IconBadge.inMenu,
                          ),
                          title: received[i].nome.isEmpty
                              ? documentTipoLabel(received[i].tipo)
                              : received[i].nome,
                          subtitle:
                              '${documentTipoLabel(received[i].tipo)} · ${formatItalianDate(received[i].caricatoIl)}',
                          onTap: () => unawaited(
                            _openDocActions(context, ref, received[i]),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: AppDim.gapL),
          AppButton(
            key: caricaKey,
            label: 'Carica documento compilato',
            onPressed: () => unawaited(
              UploadSignedSheet.open(
                context,
                adoption: adoption,
                dog: dog,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Adoption? _adoptionOf(
  List<Adoption> adoptions,
  String? adoptionId,
  String? dogId,
) {
  if (adoptionId != null) {
    for (final item in adoptions) {
      if (item.id == adoptionId) {
        return item;
      }
    }
  }
  if (dogId != null) {
    final ofDog = adoptions.where((item) => item.dogId == dogId).toList()
      ..sort((a, b) => b.dataRichiesta.compareTo(a.dataRichiesta));
    if (ofDog.isNotEmpty) {
      return ofDog.first;
    }
  }
  return null;
}

Dog? _dogOf(List<Dog> dogs, String? id) {
  if (id == null) {
    return null;
  }
  for (final dog in dogs) {
    if (dog.id == id) {
      return dog;
    }
  }
  return null;
}

List<AppDocument> _docsOf(WidgetRef ref, Adoption? adoption, Dog? dog) {
  if (adoption != null && adoption.adopterId.isNotEmpty) {
    return ref
        .watch(documentsByAdopterProvider(adoption.adopterId))
        .maybeWhen(
          data: (items) => items
              .where(
                (item) =>
                    item.dogId == adoption.dogId ||
                    item.adoptionId == adoption.id,
              )
              .toList(),
          orElse: () => const <AppDocument>[],
        );
  }
  if (dog != null) {
    return ref
        .watch(documentsByDogProvider(dog.id))
        .maybeWhen(
          data: (items) => items,
          orElse: () => const <AppDocument>[],
        );
  }
  if (adoption != null) {
    return ref
        .watch(documentsByAdoptionProvider(adoption.id))
        .maybeWhen(
          data: (items) => items,
          orElse: () => const <AppDocument>[],
        );
  }
  return const [];
}

String? _bannerText(Adoption adoption, String volunteerNome) {
  final voce = latestModuloInviato(adoption);
  if (voce == null) {
    return null;
  }
  return moduloInviatoEtichetta(
    moduloId: voce.moduloId ?? templatePreaffidoId,
    data: voce.data,
    volontarioNome: volunteerNome,
  );
}

Future<void> inviaModulo({
  required BuildContext context,
  required WidgetRef ref,
  required DocumentTemplate template,
  required Adoption? adoption,
  required Dog? dog,
}) async {
  if (adoption == null || dog == null) {
    AppToast.show(
      context,
      'Apri una richiesta di adozione per inviare il modulo.',
    );
    return;
  }
  final bytes = base64Decode(template.pdfB64);
  final share = ref.read(fileShareProvider);
  final text = moduloShareText(
    templateId: template.id,
    adopterNome: richiedenteNome(adoption),
    dogNome: dogDisplayName(dog.nome),
  );
  await share.shareFile(
    bytes: Uint8List.fromList(bytes),
    fileName: template.fileName,
    mime: template.mime,
    text: text,
  );
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
  if (context.mounted) {
    AppToast.show(context, 'Modulo pronto da condividere.');
  }
}

Future<void> _openDocActions(
  BuildContext context,
  WidgetRef ref,
  AppDocument document,
) {
  return AppSheet.show<void>(
    context: context,
    title: document.nome.isEmpty
        ? documentTipoLabel(document.tipo)
        : document.nome,
    children: [
      OptionRow(
        icon: const IconBadge(AppIcons.apri, size: IconBadge.inMenu),
        title: 'Apri',
        onTap: () async {
          Navigator.of(context).pop();
          await _openDocument(context, ref, document);
        },
      ),
      OptionRow(
        icon: const IconBadge(AppIcons.condividi, size: IconBadge.inMenu),
        title: 'Condividi',
        onTap: () async {
          Navigator.of(context).pop();
          await _shareDocument(context, ref, document);
        },
      ),
      OptionRow(
        icon: const IconBadge(AppIcons.elimina, size: IconBadge.inMenu),
        title: 'Elimina',
        titleColor: AppColor.red,
        onTap: () async {
          Navigator.of(context).pop();
          await _deleteDocument(context, ref, document);
        },
      ),
    ],
  );
}

Future<void> _openDocument(
  BuildContext context,
  WidgetRef ref,
  AppDocument document,
) async {
  try {
    final bytes = await _loadOrEmpty(ref, document);
    await ref.read(fileOpenerProvider).openFile(
      bytes: bytes,
      fileName: document.nome.isEmpty ? 'documento' : document.nome,
      mime: document.mime.isEmpty ? 'application/pdf' : document.mime,
    );
  } catch (_) {
    if (context.mounted) {
      AppToast.show(context, 'Impossibile aprire il documento.');
    }
  }
}

Future<void> _shareDocument(
  BuildContext context,
  WidgetRef ref,
  AppDocument document,
) async {
  try {
    final bytes = await _loadOrEmpty(ref, document);
    await ref.read(fileShareProvider).shareFile(
      bytes: bytes,
      fileName: document.nome.isEmpty ? 'documento' : document.nome,
      mime: document.mime.isEmpty ? 'application/octet-stream' : document.mime,
      text: document.nome,
    );
  } catch (_) {
    if (context.mounted) {
      AppToast.show(context, 'Impossibile condividere il documento.');
    }
  }
}

Future<void> _deleteDocument(
  BuildContext context,
  WidgetRef ref,
  AppDocument document,
) async {
  final ok = await AppSheet.present<bool>(
    context: context,
    builder: (context) => AppSheet(
      title: 'Elimina documento',
      children: [
        const Text(
          'Vuoi eliminare questo file? L\'azione non si può annullare.',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: AppText.body,
            color: AppColor.ink,
            height: AppDim.lineH,
          ),
        ),
        const SizedBox(height: AppDim.gapL),
        AppButton(
          label: 'Elimina',
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
  if (ok != true) {
    return;
  }
  await ref.read(documentRepositoryProvider)?.delete(document.id);
}

Future<Uint8List> _loadOrEmpty(WidgetRef ref, AppDocument document) async {
  final repo = ref.read(documentRepositoryProvider);
  if (repo == null) {
    return Uint8List(0);
  }
  return repo.loadBytes(document.id);
}

class UploadSignedSheet extends ConsumerStatefulWidget {
  const UploadSignedSheet({super.key, this.adoption, this.dog});

  final Adoption? adoption;
  final Dog? dog;

  static const pdfKey = Key('affido-upload-pdf');
  static const fotoKey = Key('affido-upload-foto');
  static const saveKey = Key('affido-upload-salva');
  static const avanzaKey = Key('affido-upload-avanza');
  static const restaKey = Key('affido-upload-resta');

  static Future<void> open(
    BuildContext context, {
    Adoption? adoption,
    Dog? dog,
  }) {
    return AppSheet.present<void>(
      context: context,
      builder: (context) => UploadSignedSheet(adoption: adoption, dog: dog),
    );
  }

  @override
  ConsumerState<UploadSignedSheet> createState() => _UploadSignedSheetState();
}

class _UploadSignedSheetState extends ConsumerState<UploadSignedSheet> {
  DocumentTipo _tipo = DocumentTipo.preaffidoFirmato;
  String? _error;
  var _busy = false;

  Future<void> _pick({required bool pdf}) async {
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      final picker = ref.read(documentFilePickerProvider);
      final files = pdf
          ? [
              ?await picker.pickPdf(),
            ]
          : await picker.pickImages();
      if (files.isEmpty) {
        return;
      }
      await _save(files);
    } on DocumentTooLarge catch (error) {
      setState(() => _error = error.toString());
    } catch (_) {
      setState(() => _error = 'Caricamento non riuscito. Riprova.');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _save(List<PickedDocumentFile> files) async {
    final adoption = widget.adoption;
    final dog = widget.dog;
    if (adoption == null || dog == null) {
      setState(
        () => _error = 'Apri una richiesta di adozione per allegare il file.',
      );
      return;
    }
    final prepared = await prepareSignedUpload(files);
    ensureDocumentSizeAllowed(prepared.bytes.lengthInBytes);
    final repo = ref.read(documentRepositoryProvider);
    if (repo == null) {
      setState(() => _error = 'Archivio documenti non disponibile.');
      return;
    }
    final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    final now = ref.read(dogListNowProvider);
    final saved = await repo.saveBytes(
      AppDocument(
        id: newEntityId('doc', now),
        dogId: dog.id,
        adoptionId: adoption.id,
        adopterId: adoption.adopterId,
        tipo: _tipo,
        nome: prepared.name,
        mime: prepared.mime,
        chunkCount: 0,
        contenutoB64: null,
        caricatoIl: now,
        caricatoDa: uid,
      ),
      prepared.bytes,
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    if (_tipo == DocumentTipo.preaffidoFirmato &&
        nextAdoptionStato(adoption.stato) == AdoptionStato.preaffido) {
      await _proposeAdvance(adoption, dog);
    } else if (context.mounted) {
      AppToast.show(context, 'Documento caricato: ${saved.nome}');
    }
  }

  Future<void> _proposeAdvance(Adoption adoption, Dog dog) async {
    final go = await AppSheet.present<bool>(
      context: context,
      builder: (context) => AppSheet(
        title: 'Avanzare a preaffido?',
        children: [
          const Text(
            'Il modulo firmato è stato caricato. Vuoi far avanzare la richiesta a preaffido?',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: AppText.body,
              color: AppColor.ink,
              height: AppDim.lineH,
            ),
          ),
          const SizedBox(height: AppDim.gapL),
          AppButton(
            key: UploadSignedSheet.avanzaKey,
            label: 'Avanza a preaffido',
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: AppDim.gapM),
          AppButton(
            key: UploadSignedSheet.restaKey,
            label: 'Non ora',
            variant: AppButtonVariant.grey,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
    if (go != true) {
      return;
    }
    final adoptionRepo = ref.read(adoptionRepositoryProvider);
    final dogRepo = ref.read(dogRepositoryProvider);
    if (adoptionRepo == null || dogRepo == null) {
      return;
    }
    final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    final now = ref.read(dogListNowProvider);
    final result = advanceAdoption(
      adoption: adoption,
      dog: dog,
      now: now,
      autoreId: uid,
    );
    await adoptionRepo.save(result.adoption);
    await dogRepo.save(result.dog);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppDim.pagePad,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: AppDim.gapXl * 2,
              height: AppDim.gapXs,
              decoration: BoxDecoration(
                color: AppColor.line,
                borderRadius: BorderRadius.circular(AppDim.radChip),
              ),
            ),
          ),
          const SizedBox(height: AppDim.gapM),
          const Text(
            'Carica documento compilato',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: AppText.h2,
              fontWeight: FontWeight.w700,
              color: AppColor.ink,
              height: AppDim.lineH,
            ),
          ),
          const SizedBox(height: AppDim.gapM),
          Wrap(
            spacing: AppDim.gapS,
            runSpacing: AppDim.gapS,
            children: [
              for (final tipo in const [
                DocumentTipo.preaffidoFirmato,
                DocumentTipo.adozioneFirmato,
                DocumentTipo.documentoIdentita,
                DocumentTipo.altro,
              ])
                AppChip(
                  label: documentTipoLabel(tipo),
                  selected: _tipo == tipo,
                  onSelected: () => setState(() => _tipo = tipo),
                ),
            ],
          ),
          const SizedBox(height: AppDim.gapM),
          AppButton(
            key: UploadSignedSheet.pdfKey,
            label: _busy ? 'Attendere…' : 'Scegli PDF',
            onPressed: _busy ? null : () => _pick(pdf: true),
          ),
          const SizedBox(height: AppDim.gapM),
          AppButton(
            key: UploadSignedSheet.fotoKey,
            label: 'Scegli foto',
            variant: AppButtonVariant.ghost,
            onPressed: _busy ? null : () => _pick(pdf: false),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppDim.gapS),
            Text(
              _error!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: AppText.caption,
                color: AppColor.red,
                height: AppDim.lineH,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
