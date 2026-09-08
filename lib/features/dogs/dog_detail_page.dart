import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format_it.dart';
import '../../data/models/dog.dart';
import '../../data/models/enums.dart';
import '../../data/models/photo.dart';
import '../../data/photos/cover_photo.dart';
import '../../router.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import 'dog_adozione_tab.dart';
import 'dog_altro_tab.dart';
import 'dog_documenti_tab.dart';
import 'dog_labels.dart';
import 'dog_note_tab.dart';
import 'dog_salute_tab.dart';
import 'dog_scheda_tab.dart';
import 'dog_spese_tab.dart';
import 'dog_tabs.dart';
import 'dogs_providers.dart';
import 'photo_thumb.dart';

// ── CONTRATTO DI LAYOUT · Scheda cane ──────────────────────────────────────
// Column
// ├ SafeArea  bottom=false
// │  └ AppHeader  h=AppDim.appBarH(44)
// │     back 34×34  (flex: none)  edit  share  more  34×34  (flex: none)
// └ Expanded NestedScrollView
//    header:
//    ├ Padding  L/T/R=AppDim.gapL(12)  B=AppDim.gapM(9)
//    │  └ Column  crossAxisAlignment=stretch
//    │     ├ Row  crossAxisAlignment=start
//    │     │  ├ foto  120×168  radius=12  (flex: none)
//    │     │  ├ SizedBox w=12
//    │     │  └ Expanded
//    │     │     └ Column  crossAxisAlignment=start  mainAxisSize=min
//    │     │        ├ Row  crossAxisAlignment=center
//    │     │        │  ├ Expanded Text nome  26sp w700  AppColor.ink
//    │     │        │  │    maxLines=1 ellipsis
//    │     │        │  ├ SizedBox w=6
//    │     │        │  └ MiniBadge stato  9sp  (flex: none)
//    │     │        ├ SizedBox h=4
//    │     │        ├ Text slogan  10.5sp italic  AppColor.muted
//    │     │        │    maxLines=2 ellipsis
//    │     │        ├ SizedBox h=6
//    │     │        └ InfoRow ×7  gap h=6 fra le righe
//    │     │           ├ IconBadge  27×27  (flex: none)
//    │     │           ├ SizedBox w=6
//    │     │           └ Expanded Column
//    │     │              ├ Text label  10.5sp  AppColor.muted  maxLines=1 ellipsis
//    │     │              └ Text value  11.5sp w600  AppColor.ink  maxLines=2 ellipsis
//    │     ├ SizedBox h=12
//    │     ├ quote  padding=10  radius=10  fondo AppColor.greenTint
//    │     │    Text  11.5sp italic  AppColor.ink2
//    │     ├ SizedBox h=9
//    │     └ Wrap  spacing=9 runSpacing=9
//    │        └ StatTile ×4  width=(max-9)/2
//    │           ├ IconBadge  30×30  (flex: none)
//    │           ├ SizedBox w=6
//    │           └ Expanded Column
//    │              ├ Text label  10sp  AppColor.muted  maxLines=2 ellipsis
//    │              └ Text value  15sp w700  AppColor.ink  maxLines=1 ellipsis
//    ├ TabBar  h=46  isScrollable=false  7 tab
//    │    Text  9sp  maxLines=2 ellipsis  textAlign=center
//    body:
//    └ ListView  padding L/R=12 T/B=9
//       tab Scheda: Wrap 2×2  (vedi dog_scheda_tab.dart)
//       tab Salute: scadenze + libretto + peso + pulsante
//       tab Adozione / Spese / Documenti / Note / Altro: dati dai repository

// ───────────────────────────────────────────────────────────────────────────

/// Scheda cane: intestazione, 7 righe info, 4 stat e TabBar a 7 voci.
class DogDetailPage extends ConsumerStatefulWidget {
  const DogDetailPage({super.key, required this.dogId});

  final String dogId;

  static const microchipKey = Key('dog-microchip');
  static const tabBarKey = Key('dog-tab-bar');
  static const coverKey = Key('dog-cover');
  static const coverImageKey = Key('dog-cover-image');

  static Key tabBodyKey(DogSheetTab tab) => Key('dog-tab-${tab.name}');

  @override
  ConsumerState<DogDetailPage> createState() => _DogDetailPageState();
}

class _DogDetailPageState extends ConsumerState<DogDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: DogSheetTab.values.length, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncDog = ref.watch(dogByIdProvider(widget.dogId));
    final now = ref.watch(dogListNowProvider);
    final requestCount = ref.watch(dogAdoptionCountProvider(widget.dogId));

    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: AppHeader(
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.animali);
              }
            },
            onEdit: () => AppToast.show(
              context,
              'Modifica scheda: disponibile negli step successivi.',
            ),
            onShare: () => AppToast.show(
              context,
              'Condividi scheda: disponibile negli step successivi.',
            ),
            onMore: () => AppToast.show(
              context,
              'Altre azioni: disponibili negli step successivi.',
            ),
          ),
        ),
        Expanded(
          child: asyncDog.when(
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
                message: 'Impossibile caricare la scheda.',
              ),
            ),
            data: (dog) {
              if (dog == null) {
                return const Center(
                  child: EmptyState(
                    icon: IconBadge(AppIcons.carattere),
                    message: 'Cane non trovato.',
                  ),
                );
              }
              return _DogDetailBody(
                dog: dog,
                now: now,
                requestCount: requestCount,
                tabs: _tabs,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DogDetailBody extends StatelessWidget {
  const _DogDetailBody({
    required this.dog,
    required this.now,
    required this.requestCount,
    required this.tabs,
  });

  final Dog dog;
  final DateTime now;
  final int requestCount;
  final TabController tabs;

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDim.gapL,
                AppDim.gapL,
                AppDim.gapL,
                AppDim.gapM,
              ),
              child: _DogHero(
                dog: dog,
                now: now,
                requestCount: requestCount,
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _DogTabBarDelegate(controller: tabs),
          ),
        ];
      },
      body: ColoredBox(
        color: AppColor.bg,
        child: AnimatedBuilder(
          animation: tabs,
          builder: (context, _) {
            final tab = DogSheetTab.values[tabs.index];
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppDim.gapL,
                AppDim.gapM,
                AppDim.gapL,
                AppDim.gapL,
              ),
              children: [
                KeyedSubtree(
                  key: DogDetailPage.tabBodyKey(tab),
                  child: _tabBody(tab),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _tabBody(DogSheetTab tab) {
    return switch (tab) {
      DogSheetTab.scheda => DogSchedaTab(dog: dog),
      DogSheetTab.salute => DogSaluteTab(dog: dog),
      DogSheetTab.adozione => DogAdozioneTab(dog: dog),
      DogSheetTab.spese => DogSpeseTab(dog: dog),
      DogSheetTab.documenti => DogDocumentiTab(dog: dog),
      DogSheetTab.note => DogNoteTab(dog: dog),
      DogSheetTab.altro => DogAltroTab(dog: dog),
    };
  }
}

class _DogHero extends StatelessWidget {
  const _DogHero({
    required this.dog,
    required this.now,
    required this.requestCount,
  });

  final Dog dog;
  final DateTime now;
  final int requestCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CoverPhoto(dog: dog),
            const SizedBox(width: AppDim.gapL),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NameLine(dog: dog),
                  if (dog.slogan.isNotEmpty) ...[
                    const SizedBox(height: AppDim.gapXs),
                    Text(
                      dog.slogan,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: AppText.label,
                        fontStyle: FontStyle.italic,
                        color: AppColor.muted,
                        height: AppDim.lineH,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppDim.gapS),
                  ..._infoRows(dog, now),
                ],
              ),
            ),
          ],
        ),
        if (dog.descrizione.isNotEmpty) ...[
          const SizedBox(height: AppDim.gapL),
          _Quote(text: dog.descrizione),
        ],
        const SizedBox(height: AppDim.gapM),
        _StatGrid(dog: dog, requestCount: requestCount),
      ],
    );
  }

  List<Widget> _infoRows(Dog dog, DateTime now) {
    final rows = <(AppIconSpec, String, String, Key?)>[
      (
        dog.sesso == DogSex.F ? AppIcons.sessoF : AppIcons.sessoM,
        'Sesso',
        dogSexLabel(dog.sesso),
        null,
      ),
      (
        AppIcons.data,
        'Età',
        dogAgeDetailLabel(dog, now),
        null,
      ),
      (
        AppIcons.razza,
        'Razza e taglia',
        dogRazzaTagliaLabel(dog),
        null,
      ),
      (
        AppIcons.peso,
        'Peso',
        dogPesoLabel(dog.pesoKg),
        null,
      ),
      (
        AppIcons.microchip,
        'Microchip',
        dog.microchip.isEmpty ? '—' : dog.microchip,
        DogDetailPage.microchipKey,
      ),
      (
        AppIcons.provenienza,
        'Provenienza',
        dog.provenienza.isEmpty ? '—' : dog.provenienza,
        null,
      ),
      (
        AppIcons.data,
        'Data di ingresso',
        formatItalianDate(dog.dataIngresso),
        null,
      ),
    ];

    return [
      for (var i = 0; i < rows.length; i++) ...[
        if (i > 0) const SizedBox(height: AppDim.gapS),
        InfoRow(
          icon: IconBadge(rows[i].$1),
          label: rows[i].$2,
          value: rows[i].$3,
          valueKey: rows[i].$4,
        ),
      ],
    ];
  }
}

class _NameLine extends StatelessWidget {
  const _NameLine({required this.dog});

  final Dog dog;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            dog.nome,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: AppText.display,
              fontWeight: FontWeight.w700,
              color: AppColor.ink,
              height: AppDim.lineH,
            ),
          ),
        ),
        const SizedBox(width: AppDim.gapS),
        MiniBadge(
          label: dogStatoLabel(dog.stato),
          variant: dogStatoBadge(dog.stato),
        ),
      ],
    );
  }
}

class _CoverPhoto extends ConsumerWidget {
  const _CoverPhoto({required this.dog});

  final Dog dog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref
        .watch(photosByDogProvider(dog.id))
        .maybeWhen(data: (items) => items, orElse: () => const <Photo>[]);
    final cover = coverPhotoOf(photos, dog.fotoCopertinaId);
    return GestureDetector(
      key: DogDetailPage.coverKey,
      onTap: () => context.push(AppRoutes.dogFoto(dog.id)),
      child: PhotoThumb(
        nome: dog.nome,
        photo: cover,
        width: AppDim.photoW,
        height: AppDim.photoH,
        radius: AppDim.radCard,
        imageKey: cover == null ? null : DogDetailPage.coverImageKey,
      ),
    );
  }
}

class _Quote extends StatelessWidget {
  const _Quote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColor.greenTint,
        borderRadius: BorderRadius.circular(AppDim.radInput),
        border: Border.all(color: AppColor.line),
      ),
      child: Padding(
        padding: AppDim.cardPad,
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: AppText.value,
            fontStyle: FontStyle.italic,
            color: AppColor.ink2,
            height: AppDim.lineH,
          ),
        ),
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.dog, required this.requestCount});

  final Dog dog;
  final int requestCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileW = (constraints.maxWidth - AppDim.gapM) / 2;
        return Wrap(
          spacing: AppDim.gapM,
          runSpacing: AppDim.gapM,
          children: [
            SizedBox(
              width: tileW,
              child: StatTile(
                icon: IconBadge(
                  AppIcons.perStato(dog.stato.wire),
                  size: IconBadge.inStat,
                ),
                label: 'Stato attuale',
                value: dogStatoLabel(dog.stato),
              ),
            ),
            SizedBox(
              width: tileW,
              child: StatTile(
                icon: const IconBadge(
                  AppIcons.sterilizzato,
                  size: IconBadge.inStat,
                ),
                label: dogSterilizedLabel(dog),
                value: yesNo(dog.sterilizzato),
              ),
            ),
            SizedBox(
              width: tileW,
              child: StatTile(
                icon: const IconBadge(
                  AppIcons.adottabile,
                  size: IconBadge.inStat,
                ),
                label: 'Adottabile',
                value: yesNo(dog.adottabile),
              ),
            ),
            SizedBox(
              width: tileW,
              child: StatTile(
                icon: const IconBadge(
                  AppIcons.richieste,
                  size: IconBadge.inStat,
                ),
                label: 'Richieste',
                value: '$requestCount',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DogTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _DogTabBarDelegate({required this.controller});

  final TabController controller;

  @override
  double get minExtent => AppDim.tabBarH;

  @override
  double get maxExtent => AppDim.tabBarH;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: AppColor.card,
      child: Material(
        color: AppColor.card,
        child: TabBar(
          key: DogDetailPage.tabBarKey,
          controller: controller,
          isScrollable: false,
          tabs: [
            for (final tab in DogSheetTab.values) _DogTab(label: tab.label),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _DogTabBarDelegate oldDelegate) {
    return oldDelegate.controller != controller;
  }
}

class _DogTab extends StatelessWidget implements PreferredSizeWidget {
  const _DogTab({required this.label});

  final String label;

  @override
  Size get preferredSize => const Size.fromHeight(AppDim.tabBarH);

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: AppDim.tabBarH,
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: AppText.micro,
          height: AppDim.lineH,
        ),
      ),
    );
  }
}
