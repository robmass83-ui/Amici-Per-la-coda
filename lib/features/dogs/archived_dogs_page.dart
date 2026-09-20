import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/dog_archive.dart';
import '../../data/models/dog.dart';
import '../../data/models/enums.dart';
import '../../router.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import 'dog_labels.dart';
import 'dog_list_tile.dart';
import 'dogs_providers.dart';

// ── CONTRATTO DI LAYOUT · Cani archiviati (Step 17-bis, punto 10) ─────────
// Column stretch
// ├ Padding 12  AppTextField h=38  hint nome/microchip  NO label
// ├ SizedBox 6
// ├ Padding H=12  AppSegmented 5  Tutti/Adott./Deced./Trasf./Rest.
// ├ SizedBox 9
// └ Expanded ListView
//     DogListTile  tap → scheda (cambio stato dalla scheda)
// ───────────────────────────────────────────────────────────────────────────

enum _ArchiveFilter { tutti, adottato, deceduto, trasferito, restituito }

class ArchivedDogsPage extends ConsumerStatefulWidget {
  const ArchivedDogsPage({super.key});

  static const listKey = Key('archiviati-list');
  static const searchKey = Key('archiviati-search');
  static const filtersKey = Key('archiviati-filtri');

  @override
  ConsumerState<ArchivedDogsPage> createState() => _ArchivedDogsPageState();
}

class _ArchivedDogsPageState extends ConsumerState<ArchivedDogsPage> {
  final _search = TextEditingController();
  _ArchiveFilter _filter = _ArchiveFilter.tutti;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(dogListNowProvider);
    final dogs = ref.watch(dogsStreamProvider).maybeWhen(
          data: (items) => items,
          orElse: () => const <Dog>[],
        );
    final needle = _search.text.trim().toLowerCase();
    final archived = dogs.where((dog) {
      if (!dogInArchivio(dog)) {
        return false;
      }
      if (!_matchesFilter(dog, _filter)) {
        return false;
      }
      if (needle.isEmpty) {
        return true;
      }
      return dogDisplayName(dog.nome).toLowerCase().contains(needle) ||
          dog.microchip.toLowerCase().contains(needle);
    }).toList();

    return AppScaffold(
      title: 'Cani archiviati',
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.altro);
        }
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: AppDim.pagePad,
            child: AppTextField(
              key: ArchivedDogsPage.searchKey,
              hint: 'Nome o microchip',
              controller: _search,
              fieldHeight: AppDim.searchH,
              suffix: const Icon(
                Icons.search_rounded,
                size: AppDim.iconNav,
                color: AppColor.faint,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDim.gapL),
            child: AppSegmented(
              key: ArchivedDogsPage.filtersKey,
              values: const ['Tutti', 'Adott.', 'Deced.', 'Trasf.', 'Rest.'],
              selectedIndex: _filter.index,
              onChanged: (i) => setState(
                () => _filter = _ArchiveFilter.values[i],
              ),
            ),
          ),
          const SizedBox(height: AppDim.gapM),
          Expanded(
            child: archived.isEmpty
                ? const Center(
                    child: EmptyState(
                      icon: IconBadge(AppIcons.archivia),
                      message: 'Nessun cane archiviato.',
                      compact: true,
                    ),
                  )
                : ListView.separated(
                    key: ArchivedDogsPage.listKey,
                    padding: AppDim.pagePad,
                    itemCount: archived.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppDim.gapM),
                    itemBuilder: (context, index) {
                      final dog = archived[index];
                      return DogListTile(
                        dog: dog,
                        now: now,
                        onTap: () => AppRoutes.openDog(
                          context,
                          dog.id,
                          from: AppRoutes.archiviati,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

bool _matchesFilter(Dog dog, _ArchiveFilter filter) {
  return switch (filter) {
    _ArchiveFilter.tutti => true,
    _ArchiveFilter.adottato => dog.stato == DogStato.adottato,
    _ArchiveFilter.deceduto => dog.stato == DogStato.deceduto,
    _ArchiveFilter.trasferito => dog.stato == DogStato.trasferito,
    _ArchiveFilter.restituito => dog.stato == DogStato.restituito,
  };
}
