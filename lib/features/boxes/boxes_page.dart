import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/dog.dart';
import '../../data/models/shelter_box.dart';
import '../../router.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../affido/affido_providers.dart';
import '../dashboard/home_aggregators.dart';
import '../dashboard/home_providers.dart';
import '../dogs/dogs_providers.dart';
import '../dogs/edit_permissions.dart';
import 'box_logic.dart';
import 'edit_box_sheet.dart';
import 'move_dog_sheet.dart';
import 'rename_settore_sheet.dart';

// ── CONTRATTO DI LAYOUT · Box e settori (Step 16) ──────────────────────────
// ListView padding=12
// ├ Row  3× Expanded AppCard  gap=9  pad=10  centro
// │    numero 15sp w800  ·  etichetta 9sp muted  (Posti / Occupati / Liberi)
// ├ SizedBox 12
// ├ per ogni settore normale:
// │    SectionTitle  "Settore <X>"  icona box  ·  Rinomina (solo scrittura)
// │    SizedBox 9
// │    Wrap  gap=9  due colonne: larghezza = (max − 9) / 2
// │      AppCard pad=10
// │        Row  codice 12.5sp w700 Expanded ellipsis  ·  MiniBadge occupazione
// │        SizedBox 3
// │        occupanti 10.5sp muted  maxLines=2 ellipsis
// ├ SectionTitle Infermeria  (se ci sono box non normali)
// │    stessa Wrap a 2 colonne
// ├ vuoto: EmptyState
// ├ SizedBox 12
// └ bottoni ghost (solo presidente/referente): Sposta un cane · Nuovo box
// ───────────────────────────────────────────────────────────────────────────

class BoxesPage extends ConsumerStatefulWidget {
  const BoxesPage({super.key, this.initialDogId});

  static const listKey = Key('boxes-list');
  static const postiKey = Key('boxes-posti');
  static const occupatiKey = Key('boxes-occupati');
  static const liberiKey = Key('boxes-liberi');
  static const moveKey = Key('boxes-move');
  static const addKey = Key('boxes-add');

  static Key cardKey(String id) => Key('boxes-card-$id');
  static Key settoreKey(String settore) => Key('boxes-settore-$settore');

  final String? initialDogId;

  @override
  ConsumerState<BoxesPage> createState() => _BoxesPageState();
}

class _BoxesPageState extends ConsumerState<BoxesPage> {
  var _openedInitial = false;

  @override
  Widget build(BuildContext context) {
    final canWrite = canWriteRecords(ref.watch(currentVolunteerProvider));
    final boxes = ref
        .watch(boxesStreamProvider)
        .maybeWhen(
          data: (items) => items,
          orElse: () => const <ShelterBox>[],
        );
    final dogs = ref
        .watch(dogsStreamProvider)
        .maybeWhen(data: (items) => items, orElse: () => const <Dog>[]);
    final capienzaAutorizzata = ref
        .watch(associationSettingsProvider)
        .maybeWhen(
          data: (item) => item?.capienzaAutorizzata ?? 0,
          orElse: () => 0,
        );
    final posti = postiTotaliDi(
      boxes,
      capienzaAutorizzata: capienzaAutorizzata,
    );
    final occupati = caniInRifugioDi(dogs);
    final liberi = posti - occupati < 0 ? 0 : posti - occupati;

    if (!_openedInitial &&
        canWrite &&
        widget.initialDogId != null &&
        widget.initialDogId!.isNotEmpty) {
      _openedInitial = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        MoveDogSheet.open(context, initialDogId: widget.initialDogId);
      });
    }

    return AppScaffold(
      title: 'Box e settori',
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.home);
        }
      },
      body: ListView(
        key: BoxesPage.listKey,
        padding: AppDim.pagePad,
        children: [
          Row(
            children: [
              Expanded(
                child: _CounterCard(
                  key: BoxesPage.postiKey,
                  value: '$posti',
                  label: 'Posti',
                  color: AppColor.ink,
                ),
              ),
              const SizedBox(width: AppDim.gapM),
              Expanded(
                child: _CounterCard(
                  key: BoxesPage.occupatiKey,
                  value: '$occupati',
                  label: 'Occupati',
                  color: AppColor.orange,
                ),
              ),
              const SizedBox(width: AppDim.gapM),
              Expanded(
                child: _CounterCard(
                  key: BoxesPage.liberiKey,
                  value: '$liberi',
                  label: 'Liberi',
                  color: AppColor.green,
                ),
              ),
            ],
          ),
          if (boxes.isEmpty) ...[
            const SizedBox(height: AppDim.gapL),
            const EmptyState(
              icon: IconBadge(AppIcons.box),
              message: 'Nessun box ancora. Crea il primo settore.',
            ),
          ] else ...[
            for (final settore in settoriNormaliDi(boxes)) ...[
              const SizedBox(height: AppDim.gapL),
              SectionTitle(
                key: BoxesPage.settoreKey(settore),
                title: settoreTitle(settore),
                icon: const IconBadge(AppIcons.box, size: IconBadge.inTitle),
                seeAllLabel: 'Rinomina',
                onSeeAll: canWrite
                    ? () => RenameSettoreSheet.open(context, da: settore)
                    : null,
              ),
              const SizedBox(height: AppDim.gapM),
              _BoxWrap(
                boxes: boxesDelSettore(boxes, settore),
                dogs: dogs,
                canWrite: canWrite,
              ),
            ],
            if (boxesInfermeria(boxes).isNotEmpty) ...[
              const SizedBox(height: AppDim.gapL),
              const SectionTitle(
                title: 'Infermeria',
                icon: IconBadge(AppIcons.infermeria, size: IconBadge.inTitle),
              ),
              const SizedBox(height: AppDim.gapM),
              _BoxWrap(
                boxes: boxesInfermeria(boxes),
                dogs: dogs,
                canWrite: canWrite,
              ),
            ],
          ],
          if (canWrite) ...[
            const SizedBox(height: AppDim.gapL),
            AppButton(
              key: BoxesPage.moveKey,
              label: 'Sposta un cane',
              variant: AppButtonVariant.ghost,
              onPressed: () => MoveDogSheet.open(context),
            ),
            const SizedBox(height: AppDim.gapM),
            AppButton(
              key: BoxesPage.addKey,
              label: 'Nuovo box',
              variant: AppButtonVariant.ghost,
              onPressed: () => EditBoxSheet.open(context),
            ),
          ],
        ],
      ),
    );
  }
}

class _CounterCard extends StatelessWidget {
  const _CounterCard({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: AppText.title,
              fontWeight: FontWeight.w800,
              color: color,
              height: AppDim.lineH,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: AppText.micro,
              color: AppColor.muted,
              height: AppDim.lineH,
            ),
          ),
        ],
      ),
    );
  }
}

class _BoxWrap extends StatelessWidget {
  const _BoxWrap({
    required this.boxes,
    required this.dogs,
    required this.canWrite,
  });

  final List<ShelterBox> boxes;
  final List<Dog> dogs;
  final bool canWrite;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - AppDim.gapM) / 2;
        return Wrap(
          spacing: AppDim.gapM,
          runSpacing: AppDim.gapM,
          children: [
            for (final box in boxes)
              SizedBox(
                width: width,
                child: _BoxCard(
                  box: box,
                  dogs: dogs,
                  canWrite: canWrite,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BoxCard extends StatelessWidget {
  const _BoxCard({
    required this.box,
    required this.dogs,
    required this.canWrite,
  });

  final ShelterBox box;
  final List<Dog> dogs;
  final bool canWrite;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: BoxesPage.cardKey(box.id),
      onTap: canWrite ? () => EditBoxSheet.open(context, existing: box) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  boxCodice(box),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: AppText.h2,
                    fontWeight: FontWeight.w700,
                    color: AppColor.ink,
                    height: AppDim.lineH,
                  ),
                ),
              ),
              const SizedBox(width: AppDim.gapXs),
              MiniBadge(
                label: boxFillLabel(box, dogs),
                variant: boxFillVariant(box, dogs),
              ),
            ],
          ),
          const SizedBox(height: AppDim.formLabelGap),
          Text(
            boxOccupantiLabel(box, dogs),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: AppText.label,
              color: AppColor.muted,
              height: AppDim.lineH,
            ),
          ),
        ],
      ),
    );
  }
}
