import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/dog.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import 'dog_list_query.dart';
import 'dog_list_tile.dart';
import 'dogs_providers.dart';

// ── CONTRATTO DI LAYOUT · Scegli cane ──────────────────────────────────────
// AppSheet  titolo «Scegli un cane»
// ├ AppTextField  h=38  hint «Nome…»  NO label
// ├ (se spesa) OptionRow  «Spesa generale del rifugio»  icona spese
// └ ListView  maxHeight = schermo − appBar×4
//    └ DogListTile  thumb 44  nome 12sp  tap → pop DogPick
// ───────────────────────────────────────────────────────────────────────────

class DogPick {
  const DogPick({this.dogId});

  /// `null` = spesa generale del rifugio.
  final String? dogId;
}

class PickDogSheet extends ConsumerStatefulWidget {
  const PickDogSheet({
    super.key,
    this.showGeneralExpense = false,
    this.noneLabel,
  });

  final bool showGeneralExpense;
  final String? noneLabel;

  static const searchKey = Key('pick-dog-search');
  static const generalExpenseKey = Key('pick-dog-generale');
  static const noneKey = Key('pick-dog-none');

  static Key dogKey(String id) => Key('pick-dog-$id');

  static Future<DogPick?> show(
    BuildContext context, {
    bool showGeneralExpense = false,
    String? noneLabel,
  }) {
    return AppSheet.present<DogPick>(
      context: context,
      builder: (context) => PickDogSheet(
        showGeneralExpense: showGeneralExpense,
        noneLabel: noneLabel,
      ),
    );
  }

  @override
  ConsumerState<PickDogSheet> createState() => _PickDogSheetState();
}

class _PickDogSheetState extends ConsumerState<PickDogSheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(dogListNowProvider);
    final dogs = ref
        .watch(dogsStreamProvider)
        .maybeWhen(data: (items) => items, orElse: () => const <Dog>[]);
    final filtered = filterDogs(
      dogs,
      query: _search.text,
      now: now,
    );
    final maxH =
        MediaQuery.sizeOf(context).height - AppDim.appBarH * 4;

    return AppSheet(
      title: 'Scegli un cane',
      children: [
        AppTextField(
          key: PickDogSheet.searchKey,
          hint: 'Nome…',
          controller: _search,
          fieldHeight: AppDim.searchH,
          textInputAction: TextInputAction.search,
          suffix: const Icon(
            Icons.search_rounded,
            size: AppDim.iconNav,
            color: AppColor.faint,
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (widget.noneLabel != null) ...[
          const SizedBox(height: AppDim.gapM),
          OptionRow(
            key: PickDogSheet.noneKey,
            icon: const IconBadge(AppIcons.carattere, size: IconBadge.inMenu),
            title: widget.noneLabel!,
            subtitle: 'Campo lasciato vuoto',
            onTap: () => Navigator.of(context).pop(const DogPick()),
          ),
        ],
        if (widget.showGeneralExpense) ...[
          const SizedBox(height: AppDim.gapM),
          OptionRow(
            key: PickDogSheet.generalExpenseKey,
            icon: const IconBadge(AppIcons.spese, size: IconBadge.inMenu),
            title: 'Spesa generale del rifugio',
            subtitle: 'Non associata a un cane',
            onTap: () => Navigator.of(context).pop(const DogPick()),
          ),
        ],
        const SizedBox(height: AppDim.gapM),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: filtered.isEmpty
              ? const EmptyState(
                  icon: IconBadge(AppIcons.carattere),
                  message: 'Nessun cane in elenco.',
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final dog = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppDim.gapM),
                      child: DogListTile(
                        key: PickDogSheet.dogKey(dog.id),
                        dog: dog,
                        now: now,
                        onTap: () =>
                            Navigator.of(context).pop(DogPick(dogId: dog.id)),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
