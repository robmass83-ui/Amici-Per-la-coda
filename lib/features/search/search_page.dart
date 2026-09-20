import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format_it.dart';
import '../../data/models/adopter.dart';
import '../../data/models/app_document.dart';
import '../../data/models/dog.dart';
import '../../data/models/volunteer.dart';
import '../../data/search_recents_store.dart';
import '../../router.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../dogs/dog_list_tile.dart';
import '../dogs/dogs_providers.dart';
import '../dogs/tab_labels.dart';
import 'global_search.dart';
import 'search_providers.dart';

// ── CONTRATTO DI LAYOUT · Ricerca globale (Step 17-bis, schermata 23) ─────
// Column stretch
// ├ Padding 12
// │  Row
// │    Expanded AppTextField h=38  NO label  hint
// │    SizedBox 6
// │    Annulla  min 40×40  11.5sp green w600
// ├ Expanded ListView padding 12
// │    se query < 2: chip recenti (Wrap) + OptionRow «Cerca anche per»
// │    se query ≥ 2 (dopo 300ms): sezioni Cani (n) / Documenti (n) / Adottanti (n)
// ───────────────────────────────────────────────────────────────────────────

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  static const fieldKey = Key('search-field');
  static const cancelKey = Key('search-annulla');
  static const recentsKey = Key('search-recenti');
  static const dogsKey = Key('search-cani');
  static const docsKey = Key('search-documenti');
  static const adoptersKey = Key('search-adottanti');

  static Key recentChipKey(String query) => Key('search-recent-$query');
  static Key dogHitKey(String id) => Key('search-dog-$id');

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  SearchScope _scope = SearchScope.tutto;
  List<String> _recents = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_loadRecents());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadRecents() async {
    final items = await ref.read(searchRecentsStoreProvider).load();
    if (!mounted) {
      return;
    }
    setState(() => _recents = items);
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() => _query = '');
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: AppDim.searchDebounceMs),
      () {
        if (!mounted) {
          return;
        }
        setState(() => _query = value.trim());
        unawaited(_remember(value));
      },
    );
  }

  Future<void> _remember(String value) async {
    final store = ref.read(searchRecentsStoreProvider);
    final next = pushSearchRecent(_recents, value);
    await store.save(next);
    if (!mounted) {
      return;
    }
    setState(() => _recents = next);
  }

  void _applyRecent(String value) {
    _debounce?.cancel();
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
    setState(() {
      _query = value.trim();
      _scope = SearchScope.tutto;
    });
    unawaited(_remember(value));
  }

  void _setScope(SearchScope scope) {
    setState(() => _scope = scope);
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(dogListNowProvider);
    final dogs = ref.watch(dogsStreamProvider).maybeWhen(
          data: (items) => items,
          orElse: () => const <Dog>[],
        );
    final documents = ref.watch(documentsAllProvider).maybeWhen(
          data: (items) => items,
          orElse: () => const <AppDocument>[],
        );
    final adopters = ref.watch(adoptersStreamProvider).maybeWhen(
          data: (items) => items,
          orElse: () => const <Adopter>[],
        );
    final volunteers = ref.watch(volunteersStreamProvider).maybeWhen(
          data: (items) => items,
          orElse: () => const <Volunteer>[],
        );
    final ready = searchQueryReady(_query);
    final result = ready
        ? searchGlobal(
            query: _query,
            scope: _scope,
            dogs: dogs,
            documents: documents,
            adopters: adopters,
            volunteers: volunteers,
          )
        : const GlobalSearchResult.empty();

    return AppScaffold(
      title: 'Cerca',
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.animali);
        }
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: AppDim.pagePad,
            child: Row(
              children: [
                Expanded(
                  child: AppTextField(
                    key: SearchPage.fieldKey,
                    hint: searchScopeHint(_scope),
                    controller: _controller,
                    fieldHeight: AppDim.searchH,
                    textInputAction: TextInputAction.search,
                    suffix: const Icon(
                      Icons.search_rounded,
                      size: AppDim.iconNav,
                      color: AppColor.faint,
                    ),
                    onChanged: _onChanged,
                  ),
                ),
                const SizedBox(width: AppDim.gapS),
                GestureDetector(
                  key: SearchPage.cancelKey,
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRoutes.animali);
                    }
                  },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: AppDim.minTouch,
                      minHeight: AppDim.minTouch,
                    ),
                    child: const Center(
                      child: Text(
                        'Annulla',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: AppText.value,
                          fontWeight: FontWeight.w600,
                          color: AppColor.green,
                          height: AppDim.lineH,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppDim.gapL,
                0,
                AppDim.gapL,
                AppDim.gapL,
              ),
              children: [
                if (!ready) ...[
                  const SectionTitle(title: 'Ricerche recenti'),
                  const SizedBox(height: AppDim.gapS),
                  if (_recents.isEmpty)
                    const Text(
                      'Nessuna ricerca recente.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: AppText.caption,
                        color: AppColor.muted,
                        height: AppDim.lineH,
                      ),
                    )
                  else
                    Wrap(
                      key: SearchPage.recentsKey,
                      spacing: AppDim.gapS,
                      runSpacing: AppDim.gapS,
                      children: [
                        for (final item in _recents)
                          AppChip(
                            key: SearchPage.recentChipKey(item),
                            label: item,
                            selected: false,
                            onSelected: () => _applyRecent(item),
                          ),
                      ],
                    ),
                  const SizedBox(height: AppDim.gapL),
                  const SectionTitle(title: 'Cerca anche per'),
                  const SizedBox(height: AppDim.gapS),
                  AppCard(
                    child: Column(
                      children: [
                        OptionRow(
                          icon: const IconBadge(
                            AppIcons.microchip,
                            size: IconBadge.inMenu,
                          ),
                          title: 'Numero microchip',
                          minHeight: AppDim.menuRowH,
                          titleSize: AppText.formCard,
                          onTap: () => _setScope(SearchScope.microchip),
                        ),
                        OptionRow(
                          icon: const IconBadge(
                            AppIcons.box,
                            size: IconBadge.inMenu,
                          ),
                          title: 'Box o settore',
                          minHeight: AppDim.menuRowH,
                          titleSize: AppText.formCard,
                          onTap: () => _setScope(SearchScope.box),
                        ),
                        OptionRow(
                          icon: const IconBadge(
                            AppIcons.volontari,
                            size: IconBadge.inMenu,
                          ),
                          title: 'Adottante o volontario',
                          minHeight: AppDim.menuRowH,
                          titleSize: AppText.formCard,
                          onTap: () => _setScope(SearchScope.persone),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  SectionTitle(
                    title: 'Cani (${result.dogs.length})',
                  ),
                  const SizedBox(height: AppDim.gapS),
                  if (result.dogs.isEmpty)
                    const Text(
                      'Nessun cane.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: AppText.caption,
                        color: AppColor.muted,
                        height: AppDim.lineH,
                      ),
                    )
                  else
                    Column(
                      key: SearchPage.dogsKey,
                      children: [
                        for (var i = 0; i < result.dogs.length; i++) ...[
                          if (i > 0) const SizedBox(height: AppDim.gapM),
                          DogListTile(
                            key: SearchPage.dogHitKey(result.dogs[i].id),
                            dog: result.dogs[i],
                            now: now,
                            onTap: () =>
                                AppRoutes.openDog(
                                  context,
                                  result.dogs[i].id,
                                  from: AppRoutes.cerca,
                                ),
                          ),
                        ],
                      ],
                    ),
                  const SizedBox(height: AppDim.gapL),
                  SectionTitle(
                    title: 'Documenti (${result.documents.length})',
                  ),
                  const SizedBox(height: AppDim.gapS),
                  if (result.documents.isEmpty)
                    const Text(
                      'Nessun documento.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: AppText.caption,
                        color: AppColor.muted,
                        height: AppDim.lineH,
                      ),
                    )
                  else
                    AppCard(
                      key: SearchPage.docsKey,
                      child: Column(
                        children: [
                          for (final doc in result.documents)
                            OptionRow(
                              icon: IconBadge(
                                AppIcons.perDocumento(doc.tipo.wire),
                                size: IconBadge.inMenu,
                              ),
                              title: doc.nome,
                              subtitle:
                                  '${documentTipoLabel(doc.tipo)} · ${formatItalianDate(doc.caricatoIl)}',
                              onTap: () {
                                if (doc.dogId != null &&
                                    doc.dogId!.isNotEmpty) {
                                  AppRoutes.openDog(
                                    context,
                                    doc.dogId!,
                                    from: AppRoutes.cerca,
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppDim.gapL),
                  SectionTitle(
                    title: 'Adottanti (${result.adopters.length})',
                  ),
                  const SizedBox(height: AppDim.gapS),
                  if (result.adopters.isEmpty)
                    const Text(
                      'Nessun adottante.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: AppText.caption,
                        color: AppColor.muted,
                        height: AppDim.lineH,
                      ),
                    )
                  else
                    AppCard(
                      key: SearchPage.adoptersKey,
                      child: Column(
                        children: [
                          for (final item in result.adopters)
                            OptionRow(
                              icon: const IconBadge(
                                AppIcons.famiglie,
                                size: IconBadge.inMenu,
                              ),
                              title: item.nomeCompleto,
                              subtitle: [
                                if (item.citta.isNotEmpty) item.citta,
                                if (item.telefono.isNotEmpty) item.telefono,
                              ].join(' · '),
                              onTap: () =>
                                  context.push(AppRoutes.adottanti),
                            ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
