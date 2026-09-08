import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/dog.dart';
import '../../router.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import 'dog_list_query.dart';
import 'dog_list_tile.dart';
import 'dogs_providers.dart';

// ── CONTRATTO DI LAYOUT · Elenco cani ──────────────────────────────────────
// Column  crossAxisAlignment=stretch
// ├ SizedBox h=AppDim.gapL(12)
// ├ Padding  H=AppDim.gapL(12)
// │  └ AppTextField  h=AppDim.searchH(38)  NO label
// │     hint «Nome, microchip, box…»
// │     suffix Icon search  size=AppDim.iconNav(18)  AppColor.faint
// ├ SizedBox h=AppDim.gapS(6)
// ├ Padding  H=AppDim.gapL(12)
// │  └ AppSegmented  h=AppDim.minTouch(40)  5 segmenti Expanded uguali
// │     etichetta AppText.micro maxLines=1  conteggio AppText.caption maxLines=1
// ├ SizedBox h=AppDim.gapM(9)
// ├ Padding  H=AppDim.gapL(12)
// │  └ Row  crossAxisAlignment=center
// │     ├ Expanded Text conteggio  AppText.caption  AppColor.muted
// │     │    maxLines=1 ellipsis
// │     └ Text «Filtri e ordina»  AppText.caption w600  AppColor.green
// │          maxLines=1 ellipsis
// ├ SizedBox h=AppDim.gapS(6)
// └ Expanded
//    ├ (vuoto) Center EmptyState  IconBadge(AppIcons.carattere)
//    └ ListView  padding H=AppDim.gapL(12)  B=AppDim.gapL(12)
//       └ DogListTile + SizedBox h=AppDim.gapM(9) fra le card
// Blocco search+filtri+riepilogo ≤ 120
// ───────────────────────────────────────────────────────────────────────────

/// Elenco cani: ricerca, filtri rapidi a segmenti, card e paginazione a 20.
class DogsPage extends ConsumerStatefulWidget {
  const DogsPage({super.key});

  static const listKey = Key('animali-scroll');
  static const filtersKey = Key('animali-filtri');

  @override
  ConsumerState<DogsPage> createState() => _DogsPageState();
}

class _DogsPageState extends ConsumerState<DogsPage> {
  final _search = TextEditingController();
  DogQuickFilter _filter = DogQuickFilter.tutti;
  int _visible = dogListPageSize;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _resetPage() {
    _visible = dogListPageSize;
  }

  @override
  Widget build(BuildContext context) {
    final asyncDogs = ref.watch(dogsStreamProvider);
    final now = ref.watch(dogListNowProvider);

    return asyncDogs.when(
      loading: () => const Center(
        child: SizedBox(
          width: AppDim.fabSize,
          height: AppDim.fabSize,
          child: CircularProgressIndicator(strokeWidth: AppDim.gapXs),
        ),
      ),
      error: (_, _) => const Center(
        child: EmptyState(
          icon: IconBadge(AppIcons.errore),
          message: 'Impossibile caricare l\'elenco.',
        ),
      ),
      data: (dogs) => _buildList(context, dogs, now),
    );
  }

  Widget _buildList(BuildContext context, List<Dog> dogs, DateTime now) {
    final filtered = filterDogs(
      dogs,
      query: _search.text,
      filter: _filter,
      now: now,
    );
    final visible = pageDogs(filtered, _visible);
    final hasMore = visible.length < filtered.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppDim.gapL),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDim.gapL),
          child: AppTextField(
            hint: 'Nome, microchip, box…',
            controller: _search,
            fieldHeight: AppDim.searchH,
            textInputAction: TextInputAction.search,
            suffix: const Icon(
              Icons.search_rounded,
              size: AppDim.iconNav,
              color: AppColor.faint,
            ),
            onChanged: (_) => setState(_resetPage),
          ),
        ),
        const SizedBox(height: AppDim.gapS),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDim.gapL),
          child: AppSegmented(
            key: DogsPage.filtersKey,
            values: const ['Tutti', 'Rifugio', 'Stallo', 'Adottab.', 'Cuccioli'],
            counts: [
              for (final filter in DogQuickFilter.values)
                countForFilter(dogs, filter, now),
            ],
            selectedIndex: _filter.index,
            onChanged: (index) => setState(() {
              _filter = DogQuickFilter.values[index];
              _resetPage();
            }),
          ),
        ),
        const SizedBox(height: AppDim.gapM),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDim.gapL),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  resultCountLabel(filtered.length),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: AppText.caption,
                    color: AppColor.muted,
                    height: AppDim.lineH,
                  ),
                ),
              ),
              InkWell(
                onTap: () => AppToast.show(
                  context,
                  'Filtri avanzati: disponibili negli step successivi.',
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppDim.gapXs),
                  child: Text(
                    'Filtri e ordina',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: AppText.caption,
                      fontWeight: FontWeight.w600,
                      color: AppColor.green,
                      height: AppDim.lineH,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDim.gapS),
        Expanded(child: _results(context, filtered, visible, hasMore, now)),
      ],
    );
  }

  Widget _results(
    BuildContext context,
    List<Dog> filtered,
    List<Dog> visible,
    bool hasMore,
    DateTime now,
  ) {
    if (filtered.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: IconBadge(AppIcons.carattere),
          message: 'Nessun cane in elenco.',
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (hasMore &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - AppDim.fabSize) {
          setState(() => _visible += dogListPageSize);
        }
        return false;
      },
      child: ListView.builder(
        key: DogsPage.listKey,
        padding: const EdgeInsets.only(
          left: AppDim.gapL,
          right: AppDim.gapL,
          bottom: AppDim.gapL,
        ),
        itemCount: visible.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == visible.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppDim.gapM),
              child: Center(
                child: Text(
                  'Scorri per caricare altri ${filtered.length - visible.length}',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: AppText.caption,
                    color: AppColor.faint,
                    height: AppDim.lineH,
                  ),
                ),
              ),
            );
          }
          final dog = visible[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDim.gapM),
            child: DogListTile(
              dog: dog,
              now: now,
              onTap: () => context.push(AppRoutes.dog(dog.id)),
            ),
          );
        },
      ),
    );
  }
}
