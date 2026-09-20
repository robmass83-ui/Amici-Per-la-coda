import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
import '../../data/dog_archive.dart';
import '../../data/models/dog.dart';
import '../../data/models/shelter_box.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../auth/auth_providers.dart';
import '../dashboard/home_providers.dart';
import '../dogs/dog_labels.dart';
import '../dogs/dogs_providers.dart';
import 'box_logic.dart';

// ── CONTRATTO DI LAYOUT · Sposta cane ──────────────────────────────────────
// maniglia · titolo · OptionRow cane · OptionRow box · errore · Salva h=40
// ───────────────────────────────────────────────────────────────────────────

class MoveDogSheet extends ConsumerStatefulWidget {
  const MoveDogSheet({super.key, this.initialDogId});

  static const caneKey = Key('move-dog-cane');
  static const boxKey = Key('move-dog-box');
  static const saveKey = Key('move-dog-save');
  static const errorKey = Key('move-dog-error');

  static Key destBoxKey(String id) => Key('move-dest-$id');

  final String? initialDogId;

  static Future<void> open(BuildContext context, {String? initialDogId}) {
    return AppSheet.present<void>(
      context: context,
      builder: (context) => MoveDogSheet(initialDogId: initialDogId),
    );
  }

  @override
  ConsumerState<MoveDogSheet> createState() => _MoveDogSheetState();
}

class _MoveDogSheetState extends ConsumerState<MoveDogSheet> {
  String? _dogId;
  String? _boxId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _dogId = widget.initialDogId;
  }

  List<Dog> _spostabili(List<Dog> dogs) {
    return [
      for (final dog in dogs)
        if (!dogEsclusoDaConteggiRifugio(dog)) dog,
    ];
  }

  Future<void> _pickDog(List<Dog> dogs) async {
    final chosen = await AppSheet.present<String>(
      context: context,
      builder: (context) {
        return AppSheet(
          title: 'Cane',
          children: [
            for (final dog in _spostabili(dogs))
              OptionRow(
                key: Key('move-pick-dog-${dog.id}'),
                icon: const IconBadge(AppIcons.carattere, size: IconBadge.inMenu),
                title: dogDisplayName(dog.nome),
                subtitle: boxAssegnatoLabel(dog.settore, dog.box),
                onTap: () => Navigator.of(context).pop(dog.id),
              ),
          ],
        );
      },
    );
    if (chosen == null || !mounted) {
      return;
    }
    setState(() {
      _dogId = chosen;
      _error = null;
    });
  }

  Future<void> _pickBox(List<ShelterBox> boxes, List<Dog> dogs) async {
    final chosen = await AppSheet.present<String>(
      context: context,
      builder: (context) {
        return AppSheet(
          title: 'Box di destinazione',
          children: [
            for (final box in boxes)
              OptionRow(
                key: MoveDogSheet.destBoxKey(box.id),
                icon: IconBadge(boxIcona(box), size: IconBadge.inMenu),
                title: boxCodice(box),
                subtitle: '${boxOccupantiLabel(box, dogs)} · ${boxFillLabel(box, dogs)}',
                onTap: () => Navigator.of(context).pop(box.id),
              ),
          ],
        );
      },
    );
    if (chosen == null || !mounted) {
      return;
    }
    setState(() {
      _boxId = chosen;
      _error = null;
    });
  }

  Future<void> _save(List<Dog> dogs, List<ShelterBox> boxes) async {
    final dogId = _dogId;
    final boxId = _boxId;
    if (dogId == null) {
      setState(() => _error = 'Scegli un cane.');
      return;
    }
    if (boxId == null) {
      setState(() => _error = 'Scegli il box di destinazione.');
      return;
    }
    Dog? dog;
    for (final item in dogs) {
      if (item.id == dogId) {
        dog = item;
        break;
      }
    }
    ShelterBox? box;
    for (final item in boxes) {
      if (item.id == boxId) {
        box = item;
        break;
      }
    }
    final foundDog = dog;
    final foundBox = box;
    if (foundDog == null || foundBox == null) {
      setState(() => _error = 'Cane o box non trovato.');
      return;
    }
    if (foundBox.inManutenzione) {
      setState(() => _error = 'Il box ${boxCodice(foundBox)} è in manutenzione.');
      return;
    }
    if (!boxPuoOspitare(foundBox, dogs, ignoreDogId: foundDog.id)) {
      setState(() => _error = messaggioBoxPieno(foundBox, dogs));
      return;
    }
    final repo = ref.read(dogRepositoryProvider);
    if (repo == null) {
      setState(() => _error = 'Archivio non disponibile.');
      return;
    }
    final userId = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    await repo.save(
      foundDog.copyWith(
        settore: foundBox.settore,
        box: foundBox.numero,
        audit: foundDog.audit.touched(userId, DateTime.now()),
      ),
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  String _dogLabel(List<Dog> dogs) {
    final id = _dogId;
    if (id == null) {
      return 'Nessuno';
    }
    for (final dog in dogs) {
      if (dog.id == id) {
        return dogDisplayName(dog.nome);
      }
    }
    return 'Cane non trovato';
  }

  String _boxLabel(List<ShelterBox> boxes, List<Dog> dogs) {
    final id = _boxId;
    if (id == null) {
      return 'Nessuno';
    }
    for (final box in boxes) {
      if (box.id == id) {
        return '${boxCodice(box)} · ${boxFillLabel(box, dogs)}';
      }
    }
    return 'Box non trovato';
  }

  @override
  Widget build(BuildContext context) {
    final dogs = ref
        .watch(dogsStreamProvider)
        .maybeWhen(data: (items) => items, orElse: () => const <Dog>[]);
    final boxes = ref
        .watch(boxesStreamProvider)
        .maybeWhen(
          data: (items) => items,
          orElse: () => const <ShelterBox>[],
        );
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
            'Sposta un cane',
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
          OptionRow(
            key: MoveDogSheet.caneKey,
            icon: const IconBadge(AppIcons.carattere, size: IconBadge.inMenu),
            title: 'Cane',
            subtitle: _dogLabel(dogs),
            onTap: () => _pickDog(dogs),
          ),
          const SizedBox(height: AppDim.gapS),
          OptionRow(
            key: MoveDogSheet.boxKey,
            icon: const IconBadge(AppIcons.box, size: IconBadge.inMenu),
            title: 'Box',
            subtitle: _boxLabel(boxes, dogs),
            onTap: () => _pickBox(boxes, dogs),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppDim.gapS),
            Text(
              key: MoveDogSheet.errorKey,
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
          const SizedBox(height: AppDim.gapM),
          AppButton(
            key: MoveDogSheet.saveKey,
            label: 'Salva',
            onPressed: () => _save(dogs, boxes),
          ),
        ],
      ),
    );
  }
}
