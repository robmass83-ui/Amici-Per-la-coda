import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/adoption.dart';
import '../../data/models/dog.dart';
import '../../router.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../dashboard/home_aggregators.dart';
import '../dogs/dogs_providers.dart';
import 'adoption_filters.dart';
import 'adoption_labels.dart';

// ── CONTRATTO DI LAYOUT · Elenco richieste ──────────────────────────────────
// Column  stretch
// ├ SizedBox 12
// ├ Padding H12  AppSegmented h=40  5 segmenti Expanded
// │    Tutte / Da val. / Colloq. / Preaff. / Chiuse
// ├ SizedBox 9
// ├ Padding H12  Text conteggio  10sp muted  maxLines=1
// ├ SizedBox 6
// └ Expanded ListView  padding 12
//    ├ AppCard padding 10  tap → /richieste/:id
//    │  Row
//    │   ├ Avatar 44 circolare  iniziali 12sp w800
//    │   ├ SizedBox 9
//    │   ├ Expanded Column
//    │   │    Text nome  12sp w700  maxLines=1 ellipsis
//    │   │    Text cane  11.5sp  maxLines=1 ellipsis
//    │   │    Text meta   10sp muted  maxLines=1 ellipsis
//    │   └ MiniBadge
//    ├ SizedBox 9 fra le card
//    └ AppButton ghost  «Registra richiesta»  → /richieste/nuova
// Search+filtri+riepilogo ≤ 120
// ───────────────────────────────────────────────────────────────────────────

class AdoptionsPage extends ConsumerStatefulWidget {
  const AdoptionsPage({super.key});

  static const filtersKey = Key('richieste-filtri');
  static const listKey = Key('richieste-scroll');
  static const nuovaKey = Key('richieste-nuova');

  static Key cardKey(String id) => Key('richiesta-card-$id');

  @override
  ConsumerState<AdoptionsPage> createState() => _AdoptionsPageState();
}

class _AdoptionsPageState extends ConsumerState<AdoptionsPage> {
  var _filter = AdoptionQuickFilter.tutte;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adoptionsStreamProvider);
    return AppScaffold(
      title: 'Richieste di adozione',
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.home);
        }
      },
      body: async.when(
        loading: () => const Center(
          child: SizedBox(
            width: AppDim.fabSize,
            height: AppDim.fabSize,
            child: CircularProgressIndicator(strokeWidth: AppDim.gapXs),
          ),
        ),
        error: (_, _) => const Center(
          child: EmptyState(
            icon: IconBadge(AppIcons.richieste),
            message: 'Impossibile caricare le richieste.',
          ),
        ),
        data: _buildList,
      ),
    );
  }

  Widget _buildList(List<Adoption> adoptions) {
    final now = ref.watch(dogListNowProvider);
    final dogs = ref
        .watch(dogsStreamProvider)
        .maybeWhen(data: (items) => items, orElse: () => const <Dog>[]);
    final filtered = filterAdoptions(adoptions, _filter);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppDim.gapL),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDim.gapL),
          child: AppSegmented(
            key: AdoptionsPage.filtersKey,
            values: adoptionFilterLabels,
            counts: [
              for (final filter in AdoptionQuickFilter.values)
                countAdoptionsForFilter(adoptions, filter),
            ],
            selectedIndex: _filter.index,
            onChanged: (index) => setState(() {
              _filter = AdoptionQuickFilter.values[index];
            }),
          ),
        ),
        const SizedBox(height: AppDim.gapM),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDim.gapL),
          child: Text(
            adoptionResultCountLabel(filtered.length),
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
        const SizedBox(height: AppDim.gapS),
        Expanded(
          child: filtered.isEmpty
              ? Column(
                  children: [
                    const Expanded(
                      child: Center(
                        child: EmptyState(
                          icon: IconBadge(AppIcons.richieste),
                          message: 'Nessuna richiesta in questo filtro.',
                        ),
                      ),
                    ),
                    Padding(
                      padding: AppDim.pagePad,
                      child: AppButton(
                        key: AdoptionsPage.nuovaKey,
                        label: 'Registra richiesta',
                        variant: AppButtonVariant.ghost,
                        onPressed: () =>
                            context.push(AppRoutes.nuovaRichiesta),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  key: AdoptionsPage.listKey,
                  padding: AppDim.pagePad,
                  itemCount: filtered.length + 1,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppDim.gapM),
                  itemBuilder: (context, index) {
                    if (index == filtered.length) {
                      return AppButton(
                        key: AdoptionsPage.nuovaKey,
                        label: 'Registra richiesta',
                        variant: AppButtonVariant.ghost,
                        onPressed: () =>
                            context.push(AppRoutes.nuovaRichiesta),
                      );
                    }
                    final adoption = filtered[index];
                    Dog? dog;
                    for (final item in dogs) {
                      if (item.id == adoption.dogId) {
                        dog = item;
                        break;
                      }
                    }
                    return _RequestCard(
                      adoption: adoption,
                      dog: dog,
                      now: now,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.adoption,
    required this.dog,
    required this.now,
  });

  final Adoption adoption;
  final Dog? dog;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final who = richiedenteNome(adoption);
    return AppCard(
      key: AdoptionsPage.cardKey(adoption.id),
      onTap: () => context.push(AppRoutes.richiesta(adoption.id)),
      child: Row(
        children: [
          RequestInitialsAvatar(nome: who),
          const SizedBox(width: AppDim.gapM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  who.isEmpty ? '—' : who,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: AppText.body,
                    fontWeight: FontWeight.w700,
                    color: AppColor.ink,
                    height: AppDim.lineH,
                  ),
                ),
                Text(
                  adoptionDogLine(dog, now),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: AppText.value,
                    color: AppColor.ink2,
                    height: AppDim.lineH,
                  ),
                ),
                Text(
                  adoptionMetaLine(adoption, now),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: AppText.caption,
                    color: AppColor.muted,
                    height: AppDim.lineH,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDim.gapS),
          MiniBadge(
            label: adoptionListBadgeLabel(adoption.stato),
            variant: adoptionStatoBadge(adoption.stato),
          ),
        ],
      ),
    );
  }
}

class RequestInitialsAvatar extends StatelessWidget {
  const RequestInitialsAvatar({
    super.key,
    required this.nome,
    this.size = AppDim.listAvatar,
  });

  final String nome;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = requestAvatarColors(nome);
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(color: colors.bg, shape: BoxShape.circle),
        child: Center(
          child: Text(
            inizialiDi(nome),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: size > AppDim.homeAvatar ? AppText.body : AppText.caption,
              fontWeight: FontWeight.w800,
              color: colors.fg,
              height: AppDim.lineH,
            ),
          ),
        ),
      ),
    );
  }
}

({Color bg, Color fg}) requestAvatarColors(String nome) {
  const palette = <(Color, Color)>[
    (AppColor.orangeSoft, AppColor.orange),
    (AppColor.greenSoft, AppColor.greenDark),
    (AppColor.blueSoft, AppColor.blue),
    (AppColor.purpleSoft, AppColor.purple),
    (AppColor.neutralSoft, AppColor.ink2),
  ];
  final index = nome.hashCode.abs() % palette.length;
  final pair = palette[index];
  return (bg: pair.$1, fg: pair.$2);
}
