import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format_it.dart';
import '../../data/data_providers.dart';
import '../../data/models/photo.dart';
import '../../data/models/volunteer.dart';
import '../../data/photos/cover_photo.dart';
import '../../data/photos/photo_codec.dart';
import '../../data/photos/photo_limit.dart';
import '../auth/auth_providers.dart';
import '../../router.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import 'dogs_providers.dart';
import 'photo_thumb.dart';
import 'tab_labels.dart';

// ── CONTRATTO DI LAYOUT · Galleria foto ────────────────────────────────────
// Column
// ├ SafeArea  bottom=false
// │  └ AppHeader  h=44  back 34×34  titolo «Foto di {nome}»
// └ Expanded ListView
//    ├ hero  h=AppDim.galleryHeroH(300)  larghezza piena
//    │    Image full (o thumb)  BoxFit.cover
//    │    overlay basso  padding 10/12  testo bianco su AppColor.ink
//    │       titolo 12sp w700 maxLines=1  sottotitolo 10.5sp maxLines=1
//    │    counter  in alto a destra  MiniBadge
//    ├ Padding  12
//    │  ├ Wrap  spacing=6 runSpacing=6  3 colonne quadrate
//    │  │    thumb + COPERTINA + elimina 40×40  + tessera aggiungi
//    │  ├ SizedBox 9
//    │  ├ SectionTitle  Carica nuove foto
//    │  ├ SizedBox 9
//    │  ├ area upload  padding=10  radius=12
//    │  │    IconBadge galleria 32  + testi 12sp / 10sp  maxLines=2
//    │  ├ (limite) Text 12sp rosso
//    │  ├ SizedBox 9
//    │  └ Row  gap=9
//    │       AppButton ghost  Imposta copertina  h=40
//    │       AppButton grey   Usa per annuncio   h=40
// ───────────────────────────────────────────────────────────────────────────

class DogGalleryPage extends ConsumerStatefulWidget {
  const DogGalleryPage({super.key, required this.dogId});

  final String dogId;

  static const heroKey = Key('gallery-hero');
  static const addKey = Key('gallery-add');
  static const uploadKey = Key('gallery-upload');
  static const setCoverKey = Key('gallery-set-cover');
  static const limitKey = Key('gallery-limit');
  static const cameraKey = Key('gallery-camera');
  static const galleryPickKey = Key('gallery-pick');

  @override
  ConsumerState<DogGalleryPage> createState() => _DogGalleryPageState();
}

class _DogGalleryPageState extends ConsumerState<DogGalleryPage> {
  String? _userSelectedId;
  String? _loadedId;
  Uint8List? _full;
  String? _limitMessage;
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final dog = ref.watch(dogByIdProvider(widget.dogId)).asData?.value;
    final photos =
        ref
            .watch(photosByDogProvider(widget.dogId))
            .maybeWhen(data: (items) => items, orElse: () => const <Photo>[]);
    final volunteers = ref
        .watch(volunteersStreamProvider)
        .maybeWhen(
          data: (items) => items,
          orElse: () => const <Volunteer>[],
        );

    final selected = _selectedOf(photos, dog?.fotoCopertinaId);
    if (selected != null && selected.id != _loadedId) {
      final id = selected.id;
      _loadedId = id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_loadFull(id));
        }
      });
    } else if (selected == null && (_loadedId != null || _full != null)) {
      _loadedId = null;
      _full = null;
    }
    final nome = dog?.nome ?? '';
    final selectedIndex = selected == null ? 0 : photos.indexOf(selected);
    final isCover =
        selected != null &&
        coverPhotoOf(photos, dog?.fotoCopertinaId)?.id == selected.id;

    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: AppHeader(
            title: nome.isEmpty ? 'Foto' : 'Foto di $nome',
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.dog(widget.dogId));
              }
            },
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              _Hero(
                nome: nome,
                photo: selected,
                full: _full,
                isCover: isCover,
                index: selectedIndex < 0 ? 0 : selectedIndex + 1,
                total: photos.length,
                author: selected == null
                    ? ''
                    : autoreEtichetta(volunteers, selected.createdBy),
              ),
              Padding(
                padding: AppDim.pagePad,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ThumbGrid(
                      nome: nome,
                      photos: photos,
                      selectedId: selected?.id,
                      coverId: coverPhotoOf(
                        photos,
                        dog?.fotoCopertinaId,
                      )?.id,
                      onSelect: (id) => setState(() => _userSelectedId = id),
                      onDelete: _delete,
                      onAdd: _openSource,
                    ),
                    const SizedBox(height: AppDim.gapM),
                    const SectionTitle(
                      title: 'Carica nuove foto',
                      icon: IconBadge(
                        AppIcons.galleria,
                        size: IconBadge.inTitle,
                      ),
                    ),
                    const SizedBox(height: AppDim.gapM),
                    _UploadArea(onTap: _openSource),
                    if (_limitMessage != null) ...[
                      const SizedBox(height: AppDim.gapS),
                      Text(
                        _limitMessage!,
                        key: DogGalleryPage.limitKey,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: AppText.body,
                          color: AppColor.red,
                          height: AppDim.lineH,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppDim.gapM),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            key: DogGalleryPage.setCoverKey,
                            label: 'Imposta copertina',
                            variant: AppButtonVariant.ghost,
                            onPressed: selected == null
                                ? null
                                : () => _setCover(selected.id),
                          ),
                        ),
                        const SizedBox(width: AppDim.gapM),
                        Expanded(
                          child: AppButton(
                            label: 'Usa per annuncio',
                            variant: AppButtonVariant.grey,
                            onPressed: selected == null
                                ? null
                                : () => AppToast.show(
                                    context,
                                    'Foto usata nell\'annuncio',
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Photo? _selectedOf(List<Photo> photos, String? coverId) {
    if (photos.isEmpty) {
      return null;
    }
    if (_userSelectedId != null) {
      for (final photo in photos) {
        if (photo.id == _userSelectedId) {
          return photo;
        }
      }
    }
    return coverPhotoOf(photos, coverId) ?? photos.first;
  }

  Future<void> _loadFull(String photoId) async {
    final repo = ref.read(photoRepositoryProvider);
    if (repo == null) {
      return;
    }
    final bytes = await repo.loadFull(photoId);
    if (!mounted || _loadedId != photoId) {
      return;
    }
    setState(() => _full = bytes);
  }

  Future<void> _openSource() async {
    if (_busy) {
      return;
    }
    await AppSheet.show<void>(
      context: context,
      title: 'Aggiungi foto',
      children: [
        OptionRow(
          key: DogGalleryPage.cameraKey,
          icon: const IconBadge(AppIcons.fotocamera, size: IconBadge.inMenu),
          title: 'Fotocamera',
          subtitle: 'Scatta una foto',
          onTap: () {
            Navigator.of(context, rootNavigator: true).pop();
            unawaited(_pickCamera());
          },
        ),
        OptionRow(
          key: DogGalleryPage.galleryPickKey,
          icon: const IconBadge(AppIcons.galleria, size: IconBadge.inMenu),
          title: 'Scegli dalla galleria',
          subtitle: 'Selezione multipla',
          onTap: () {
            Navigator.of(context, rootNavigator: true).pop();
            unawaited(_pickGallery());
          },
        ),
      ],
    );
  }

  Future<void> _pickCamera() async {
    final bytes = await ref.read(photoPickerProvider).pickFromCamera();
    if (bytes == null) {
      return;
    }
    await _uploadAll([bytes]);
  }

  Future<void> _pickGallery() async {
    final files = await ref.read(photoPickerProvider).pickFromGallery();
    if (files.isEmpty) {
      return;
    }
    await _uploadAll(files);
  }

  Future<void> _uploadAll(List<Uint8List> files) async {
    final repo = ref.read(photoRepositoryProvider);
    if (repo == null || _busy) {
      return;
    }
    setState(() {
      _busy = true;
      _limitMessage = null;
    });
    final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    try {
      for (final bytes in files) {
        try {
          final photo = await repo.upload(
            widget.dogId,
            bytes,
            createdBy: uid,
          );
          _userSelectedId = photo.id;
          _loadedId = photo.id;
          _full = null;
          unawaited(_loadFull(photo.id));
        } on PhotoLimitReached {
          if (!mounted) {
            return;
          }
          setState(() => _limitMessage = PhotoLimitReached.message);
          AppToast.show(context, PhotoLimitReached.message);
          return;
        }
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _setCover(String photoId) async {
    final repo = ref.read(photoRepositoryProvider);
    if (repo == null) {
      return;
    }
    await repo.setCover(widget.dogId, photoId);
    if (mounted) {
      AppToast.show(context, 'Impostata come copertina');
    }
  }

  Future<void> _delete(String photoId) async {
    final repo = ref.read(photoRepositoryProvider);
    if (repo == null) {
      return;
    }
    await repo.delete(photoId);
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.nome,
    required this.photo,
    required this.full,
    required this.isCover,
    required this.index,
    required this.total,
    required this.author,
  });

  final String nome;
  final Photo? photo;
  final Uint8List? full;
  final bool isCover;
  final int index;
  final int total;
  final String author;

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (full != null) {
      image = Image.memory(
        full!,
        key: DogGalleryPage.heroKey,
        fit: BoxFit.cover,
        width: double.infinity,
        height: AppDim.galleryHeroH,
        gaplessPlayback: true,
      );
    } else if (photo != null) {
      image = PhotoThumb(
        key: DogGalleryPage.heroKey,
        nome: nome,
        photo: photo,
        width: double.infinity,
        height: AppDim.galleryHeroH,
        radius: 0,
      );
    } else {
      image = PhotoThumb(
        key: DogGalleryPage.heroKey,
        nome: nome,
        width: double.infinity,
        height: AppDim.galleryHeroH,
        radius: 0,
      );
    }

    final title = isCover ? 'Foto principale' : 'Foto';
    final date = photo == null ? '' : formatItalianDate(photo!.createdAt);
    final headline = date.isEmpty ? title : '$title · $date';
    final subtitle = author.isEmpty ? '' : 'Scattata da $author';

    return SizedBox(
      height: AppDim.galleryHeroH,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: AppColor.ink, child: image),
          if (total > 0)
            Positioned(
              top: AppDim.gapL,
              right: AppDim.gapL,
              child: MiniBadge(
                label: '$index / $total',
                variant: MiniBadgeVariant.neutral,
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ColoredBox(
              color: AppColor.ink,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDim.gapL,
                  vertical: AppDim.gapL,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      headline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: AppText.body,
                        fontWeight: FontWeight.w700,
                        color: AppColor.card,
                        height: AppDim.lineH,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: AppDim.gapHair),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: AppText.label,
                          color: AppColor.card,
                          height: AppDim.lineH,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThumbGrid extends StatelessWidget {
  const _ThumbGrid({
    required this.nome,
    required this.photos,
    required this.selectedId,
    required this.coverId,
    required this.onSelect,
    required this.onDelete,
    required this.onAdd,
  });

  final String nome;
  final List<Photo> photos;
  final String? selectedId;
  final String? coverId;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onDelete;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tile =
            (constraints.maxWidth - AppDim.gapS * 2) / 3;
        return Wrap(
          spacing: AppDim.gapS,
          runSpacing: AppDim.gapS,
          children: [
            for (final photo in photos)
              SizedBox(
                width: tile,
                height: tile,
                child: _ThumbCell(
                  nome: nome,
                  photo: photo,
                  selected: photo.id == selectedId,
                  isCover: photo.id == coverId,
                  onSelect: () => onSelect(photo.id),
                  onDelete: () => onDelete(photo.id),
                ),
              ),
            if (photos.length < photoMaxPerDog)
              SizedBox(
                width: tile,
                height: tile,
                child: _AddTile(onTap: onAdd),
              ),
          ],
        );
      },
    );
  }
}

class _ThumbCell extends StatelessWidget {
  const _ThumbCell({
    required this.nome,
    required this.photo,
    required this.selected,
    required this.isCover,
    required this.onSelect,
    required this.onDelete,
  });

  final String nome;
  final Photo photo;
  final bool selected;
  final bool isCover;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDim.radIconBox),
        border: Border.all(
          color: selected ? AppColor.green : AppColor.line,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDim.radIconBox),
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: onSelect,
              child: PhotoThumb(
                nome: nome,
                photo: photo,
                width: double.infinity,
                height: double.infinity,
                radius: 0,
              ),
            ),
            if (isCover)
              const Positioned(
                left: AppDim.gapXs,
                bottom: AppDim.gapXs,
                child: MiniBadge(
                  label: 'COPERTINA',
                  variant: MiniBadgeVariant.green,
                ),
              ),
            Positioned(
              top: 0,
              right: 0,
              child: SizedBox(
                width: AppDim.minTouch,
                height: AppDim.minTouch,
                child: GestureDetector(
                  onTap: onDelete,
                  behavior: HitTestBehavior.opaque,
                  child: const Center(
                    child: IconBadge(
                      AppIcons.elimina,
                      size: IconBadge.inTitle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: DogGalleryPage.addKey,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColor.greenTint,
          borderRadius: BorderRadius.circular(AppDim.radIconBox),
          border: Border.all(color: AppColor.line),
        ),
        child: const Center(
          child: IconBadge(AppIcons.foto, size: IconBadge.inMenu),
        ),
      ),
    );
  }
}

class _UploadArea extends StatelessWidget {
  const _UploadArea({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: DogGalleryPage.uploadKey,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColor.greenTint,
          borderRadius: BorderRadius.circular(AppDim.radCard),
          border: Border.all(color: AppColor.line),
        ),
        child: const Padding(
          padding: AppDim.cardPad,
          child: Column(
            children: [
              IconBadge(AppIcons.galleria, size: IconBadge.inMenu),
              SizedBox(height: AppDim.gapS),
              Text(
                'Tocca per scattare o scegliere dalla galleria',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: AppText.body,
                  fontWeight: FontWeight.w600,
                  color: AppColor.ink,
                  height: AppDim.lineH,
                ),
              ),
              SizedBox(height: AppDim.gapXs),
              Text(
                'JPG o PNG · max 10 MB · fino a 20 foto per cane',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: AppText.caption,
                  color: AppColor.faint,
                  height: AppDim.lineH,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
