import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format_it.dart';
import '../../data/models/adoption.dart';
import '../../data/models/dog.dart';
import '../../data/models/enums.dart';
import '../../data/models/photo.dart';
import '../../data/models/volunteer.dart';
import '../../router.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../dogs/dog_labels.dart';
import '../dogs/dogs_providers.dart';
import '../dogs/photo_thumb.dart';
import '../dogs/tab_labels.dart';
import 'home_aggregators.dart';
import 'home_providers.dart';

// ── CONTRATTO DI LAYOUT · Home / Dashboard ─────────────────────────────────
// SCHERMATA HOME
// AppScaffold(bottomNav: home)  ← fornito da AppShell
// └ AppHeader(logo centrato, nessun pulsante indietro)
// └ ListView  padding=12  (scroll verticale)
//    │
//    ├ Text  "Ciao <nome volontario> 👋"      17sp w800  letterSpacing=-0.3
//    ├ SizedBox h=2
//    ├ Text  "<data estesa> · <n> cose da fare oggi"   11.5sp w400
//    │        formato data: "martedì 8 settembre"  (intl, locale it_IT)
//    ├ SizedBox h=12
//    │
//    ├ Row  (due card gemelle)  gap=9
//    │   ├ Expanded → AppCard padding=12
//    │   │    ├ Text "<n>"                    26sp w800  letterSpacing=-1
//    │   │    ├ Text "Cani in rifugio"        10.5sp
//    │   │    ├ SizedBox h=8
//    │   │    ├ Bar h=7 radius=6  fondo barTrack  fill clamp 0–1
//    │   │    │    green se sotto capienza, orange se oltre; assente se posti=0
//    │   │    └ Text OccupancyDisplay.caption  9.5sp muted
//    │   │         sotto: "<p>% dei <tot> posti"
//    │   │         oltre: "<n> su <tot> posti · oltre capienza"
//    │   │         posti=0: "posti non configurati"  (niente barra)
//    │   └ Expanded → AppCard padding=12
//    │        ├ Text "<n>"                    26sp w800  green
//    │        ├ Text "Adozioni nel <anno>"    10.5sp
//    │        ├ SizedBox h=12
//    │        └ Text "▲ +<n> rispetto al <anno-1>"  9.5sp w700  green
//    │             (se il delta è negativo: "▼ −<n>", colore red)
//    │
//    ├ SectionTitle  "Da fare oggi"   icona AppIcons.scadenza
//    ├ AppCard padding=10
//    │   └ per ogni voce (max 4):  Row  padding verticale 3.5
//    │        ├ IconBadge(spec, size=IconBadge.inRow)
//    │        ├ SizedBox w=7
//    │        ├ Expanded  Text.rich  10.8sp  maxLines=1  ellipsis
//    │        └ Text trailing  10.2sp
//    │      separatore 1px tratteggiato line2, non dopo l'ultima
//    │   stato vuoto: EmptyState compatto "Nessuna scadenza per oggi 🎉"  h=56
//    │
//    ├ SectionTitle  "Ultimi arrivi"  icona AppIcons.carattere
//    │      azione a destra: "Vedi tutti ›" → /animali
//    ├ Row  gap=9   TRE card di larghezza uguale, MAI lista orizzontale
//    │   └ 3 × Expanded → AppCard padding=7
//    │        ├ AspectRatio 1:1 → foto radius=9
//    │        ├ SizedBox h=6
//    │        ├ Text nome     11.5sp w700  maxLines=1 ellipsis
//    │        └ Text età      9.5sp  maxLines=1 ellipsis
//    │      se i cani sono meno di 3, le card mancanti NON si disegnano
//    │      e le rimanenti restano della loro larghezza (usa Spacer)
//    │
//    ├ SectionTitle  "Richieste di adozione"  icona AppIcons.richieste
//    │      azione a destra: "<n> nuove ›" → /richieste
//    ├ AppCard padding=10
//    │   └ max 2 Row: Avatar 34 · testo · MiniBadge
//    │      stato vuoto: EmptyState "Nessuna richiesta in sospeso"
//    │
//    ├ SectionTitle  "Scorciatoie"
//    └ GridView 2 colonne  gap=9  shrinkWrap  physics=Never  aspect≈2.05
// ───────────────────────────────────────────────────────────────────────────

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const seeAllArriviKey = Key('home-see-all-arrivi');
  static const richiesteLinkKey = Key('home-richieste-link');
  static const ultimiArriviRowKey = Key('home-ultimi-arrivi-row');
  static const offlineBannerKey = Key('home-offline-banner');
  static const shortcutNuovoKey = Key('home-shortcut-nuovo');
  static const shortcutAffidoKey = Key('home-shortcut-affido');
  static const shortcutBoxKey = Key('home-shortcut-box');
  static const shortcutStatsKey = Key('home-shortcut-stats');
  static const emptyDbKey = Key('home-empty-db');
  static const todoCardKey = Key('home-todo-card');
  static const richiesteCardKey = Key('home-richieste-card');
  static const listKey = Key('home-list');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(homeSummaryProvider);
    final offline = ref.watch(homeOfflineProvider);
    final nome = ref.watch(homeVolunteerNameProvider);
    final now = ref.watch(dogListNowProvider);

    return Column(
      children: [
        if (offline)
          const ColoredBox(
            key: offlineBannerKey,
            color: AppColor.orangeSoft,
            child: SizedBox(
              height: AppDim.offlineBannerH,
              width: double.infinity,
              child: Center(
                child: Text(
                  'Dati non aggiornati · sei offline',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: AppText.caption,
                    color: AppColor.ink,
                    height: AppDim.lineH,
                  ),
                ),
              ),
            ),
          ),
        Expanded(
          child: summaryAsync.when(
            loading: () => const _HomeSkeleton(),
            error: (error, stack) => const _HomeSkeleton(),
            data: (summary) {
              if (summary.databaseVuoto) {
                return _EmptyDatabase(
                  onAdd: () => context.push(AppRoutes.nuovo),
                );
              }
              return _HomeDashboard(
                summary: summary,
                nome: nome,
                now: now,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmptyDatabase extends StatelessWidget {
  const _EmptyDatabase({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: EmptyState(
        key: HomePage.emptyDbKey,
        icon: const IconBadge(AppIcons.carattere),
        message: 'Nessun cane ancora registrato',
        actionLabel: 'Aggiungi il primo cane',
        onAction: onAdd,
      ),
    );
  }
}

class _HomeDashboard extends ConsumerWidget {
  const _HomeDashboard({
    required this.summary,
    required this.nome,
    required this.now,
  });

  final HomeSummary summary;
  final String nome;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nTodo = summary.daFareOggi.length;
    final cose =
        nTodo == 1 ? '1 cosa da fare oggi' : '$nTodo cose da fare oggi';
    final delta = summary.deltaAdozioni;
    final deltaText = delta < 0
        ? '▼ −${delta.abs()} rispetto al ${now.year - 1}'
        : '▲ +$delta rispetto al ${now.year - 1}';
    final deltaColor = delta < 0 ? AppColor.red : AppColor.green;
    final occupancy = summary.occupancy;

    return ListView(
      key: HomePage.listKey,
      padding: AppDim.pagePad,
      children: [
        Text(
          'Ciao $nome 👋',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: AppText.hello,
            fontWeight: FontWeight.w800,
            letterSpacing: AppDim.helloTracking,
            color: AppColor.ink,
            height: AppDim.lineH,
          ),
        ),
        const SizedBox(height: AppDim.helloGap),
        Text(
          '${formatItalianLongDate(now)} · $cose',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: AppText.value,
            fontWeight: FontWeight.w400,
            color: AppColor.muted,
            height: AppDim.lineH,
          ),
        ),
        const SizedBox(height: AppDim.gapL),
        Row(
          children: [
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.all(AppDim.gapL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${summary.caniInRifugio}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: AppText.display,
                        fontWeight: FontWeight.w800,
                        letterSpacing: AppDim.displayTracking,
                        color: AppColor.ink,
                        height: AppDim.lineH,
                      ),
                    ),
                    const Text(
                      'Cani in rifugio',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: AppText.label,
                        color: AppColor.muted,
                        height: AppDim.lineH,
                      ),
                    ),
                    const SizedBox(height: AppDim.statBarGap),
                    if (occupancy.showBar) ...[
                      _OccupancyBar(
                        factor: occupancy.barFill,
                        fill: occupancy.kind == OccupancyKind.oltreCapienza
                            ? AppColor.orange
                            : AppColor.green,
                      ),
                      const SizedBox(height: AppDim.gapXs),
                    ],
                    Text(
                      occupancy.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: AppText.statNote,
                        color: AppColor.muted,
                        height: AppDim.lineH,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppDim.gapM),
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.all(AppDim.gapL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${summary.adozioniAnnoCorrente}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: AppText.display,
                        fontWeight: FontWeight.w800,
                        color: AppColor.green,
                        height: AppDim.lineH,
                      ),
                    ),
                    Text(
                      'Adozioni nel ${now.year}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: AppText.label,
                        color: AppColor.muted,
                        height: AppDim.lineH,
                      ),
                    ),
                    const SizedBox(height: AppDim.gapL),
                    Text(
                      deltaText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: AppText.statNote,
                        fontWeight: FontWeight.w700,
                        color: deltaColor,
                        height: AppDim.lineH,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDim.gapL),
        const SectionTitle(
          title: 'Da fare oggi',
          icon: IconBadge(AppIcons.scadenza, size: IconBadge.inTitle),
        ),
        const SizedBox(height: AppDim.gapM),
        AppCard(
          key: HomePage.todoCardKey,
          child: summary.daFareOggi.isEmpty
              ? const SizedBox(
                  height: AppDim.emptyTodoH,
                  child: EmptyState(
                    compact: true,
                    icon: IconBadge(
                      AppIcons.scadenza,
                      size: IconBadge.inTitle,
                    ),
                    message: 'Nessuna scadenza per oggi 🎉',
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < summary.daFareOggi.length; i++) ...[
                      if (i > 0) const _DashedSeparator(),
                      _TodoRow(item: summary.daFareOggi[i]),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: AppDim.gapL),
        SectionTitle(
          key: HomePage.seeAllArriviKey,
          title: 'Ultimi arrivi',
          icon: const IconBadge(AppIcons.carattere, size: IconBadge.inTitle),
          onSeeAll: () => context.go(AppRoutes.animali),
          seeAllLabel: 'Vedi tutti ›',
        ),
        const SizedBox(height: AppDim.gapM),
        _UltimiArriviRow(dogs: summary.ultimiArrivi, now: now),
        const SizedBox(height: AppDim.gapL),
        SectionTitle(
          key: HomePage.richiesteLinkKey,
          title: 'Richieste di adozione',
          icon: const IconBadge(AppIcons.richieste, size: IconBadge.inTitle),
          onSeeAll: () => context.push(AppRoutes.richieste),
          seeAllLabel: '${summary.richiesteNuove} nuove ›',
        ),
        const SizedBox(height: AppDim.gapM),
        AppCard(
          key: HomePage.richiesteCardKey,
          child: summary.richiesteAperte.isEmpty
              ? const EmptyState(
                  compact: true,
                  icon: IconBadge(
                    AppIcons.richieste,
                    size: IconBadge.inTitle,
                  ),
                  message: 'Nessuna richiesta in sospeso',
                )
              : _RichiesteList(
                  richieste: summary.richiesteAperte,
                  now: now,
                ),
        ),
        const SizedBox(height: AppDim.gapL),
        const SectionTitle(title: 'Scorciatoie'),
        const SizedBox(height: AppDim.gapM),
        LayoutBuilder(
          builder: (context, constraints) {
            final cellW = (constraints.maxWidth - AppDim.gapM) / 2;
            const minH = IconBadge.inStat +
                AppDim.gapS +
                AppText.value * AppDim.lineH +
                AppText.statNote * AppDim.lineH +
                AppDim.gapL * 2 +
                AppDim.gapHair * 2;
            final fitted = cellW / minH;
            final ratio = fitted < AppDim.shortcutAspect
                ? fitted
                : AppDim.shortcutAspect;
            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppDim.gapM,
              mainAxisSpacing: AppDim.gapM,
              childAspectRatio: ratio,
              children: [
                _ShortcutCard(
                  key: HomePage.shortcutNuovoKey,
                  icon: AppIcons.carattere,
                  title: 'Nuovo cane',
                  subtitle: 'Crea profilo completo',
                  onTap: () => context.push(AppRoutes.nuovo),
                ),
                _ShortcutCard(
                  key: HomePage.shortcutAffidoKey,
                  icon: AppIcons.modulo,
                  title: 'Modulo affido',
                  subtitle: 'Invia e carica',
                  onTap: () => context.push(AppRoutes.affido),
                ),
                _ShortcutCard(
                  key: HomePage.shortcutBoxKey,
                  icon: AppIcons.box,
                  title: 'Box e settori',
                  subtitle: '${summary.boxLiberi} box liberi',
                  onTap: () => context.push(AppRoutes.box),
                ),
                _ShortcutCard(
                  key: HomePage.shortcutStatsKey,
                  icon: AppIcons.statistiche,
                  title: 'Statistiche',
                  subtitle: 'Report annuale',
                  onTap: () => context.push(AppRoutes.statistiche),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _OccupancyBar extends StatelessWidget {
  const _OccupancyBar({required this.factor, required this.fill});

  final double factor;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDim.statBarH,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColor.barTrack,
          borderRadius: BorderRadius.circular(AppDim.statBarR),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: factor.clamp(0, 1),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(AppDim.statBarR),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

class _TodoRow extends StatelessWidget {
  const _TodoRow({required this.item});

  final TodoItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDim.todoPadV),
      child: Row(
        children: [
          IconBadge(item.icon, size: IconBadge.inRow),
          const SizedBox(width: AppDim.todoGap),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  if (item.nomeCane.isNotEmpty)
                    TextSpan(
                      text: item.nomeCane,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  TextSpan(
                    text: item.resto,
                    style: const TextStyle(fontWeight: FontWeight.w400),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: AppText.todo,
                color: AppColor.ink,
                height: AppDim.lineH,
              ),
            ),
          ),
          const SizedBox(width: AppDim.gapS),
          Text(
            item.trailing,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: AppText.todoTrail,
              color: AppColor.muted,
              height: AppDim.lineH,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedSeparator extends StatelessWidget {
  const _DashedSeparator();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDim.gapHair,
      width: double.infinity,
      child: CustomPaint(painter: _DashPainter()),
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColor.line2
      ..strokeWidth = AppDim.gapHair;
    var x = 0.0;
    const dash = AppDim.gapXs;
    const gap = AppDim.gapS;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _UltimiArriviRow extends ConsumerWidget {
  const _UltimiArriviRow({required this.dogs, required this.now});

  final List<Dog> dogs;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      key: HomePage.ultimiArriviRowKey,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: AppDim.gapM),
          if (i < dogs.length)
            Expanded(child: _ArrivoCard(dog: dogs[i], now: now))
          else
            const Spacer(),
        ],
      ],
    );
  }
}

class _ArrivoCard extends ConsumerWidget {
  const _ArrivoCard({required this.dog, required this.now});

  final Dog dog;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref
        .watch(photosByDogProvider(dog.id))
        .maybeWhen(data: (items) => items, orElse: () => const <Photo>[]);
    Photo? cover;
    for (final photo in photos) {
      if (photo.id == dog.fotoCopertinaId || photo.isCover) {
        cover = photo;
        break;
      }
    }
    final eta = dogAgeShortLabel(dog, now) ?? '—';
    return AppCard(
      padding: const EdgeInsets.all(AppDim.arriviPad),
      onTap: () => context.push(AppRoutes.dog(dog.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return PhotoThumb(
                  nome: dog.nome,
                  photo: cover,
                  width: constraints.maxWidth,
                  height: constraints.maxWidth,
                  radius: AppDim.arriviRadius,
                );
              },
            ),
          ),
          const SizedBox(height: AppDim.gapS),
          Text(
            dogDisplayName(dog.nome),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: AppText.value,
              fontWeight: FontWeight.w700,
              color: AppColor.ink,
              height: AppDim.lineH,
            ),
          ),
          Text(
            eta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: AppText.statNote,
              color: AppColor.muted,
              height: AppDim.lineH,
            ),
          ),
        ],
      ),
    );
  }
}

class _RichiesteList extends ConsumerWidget {
  const _RichiesteList({required this.richieste, required this.now});

  final List<Adoption> richieste;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final volunteers = ref
        .watch(volunteersStreamProvider)
        .maybeWhen(data: (items) => items, orElse: () => const <Volunteer>[]);
    final dogs = ref
        .watch(dogsStreamProvider)
        .maybeWhen(data: (items) => items, orElse: () => const <Dog>[]);
    return Column(
      children: [
        for (var i = 0; i < richieste.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(height: AppDim.gapM),
            const Divider(
              height: AppDim.gapHair,
              thickness: AppDim.gapHair,
              color: AppColor.line2,
            ),
            const SizedBox(height: AppDim.gapM),
          ],
          _RichiestaRow(
            adoption: richieste[i],
            now: now,
            dogs: dogs,
            volunteers: volunteers,
          ),
        ],
      ],
    );
  }
}

class _RichiestaRow extends StatelessWidget {
  const _RichiestaRow({
    required this.adoption,
    required this.now,
    required this.dogs,
    required this.volunteers,
  });

  final Adoption adoption;
  final DateTime now;
  final List<Dog> dogs;
  final List<Volunteer> volunteers;

  @override
  Widget build(BuildContext context) {
    final who = richiedenteNome(adoption);
    final cane = dogNameById(dogs, adoption.dogId);
    var hex = '';
    for (final volunteer in volunteers) {
      if (volunteer.id == adoption.referenteId) {
        hex = volunteer.coloreAvatar;
        break;
      }
    }
    return InkWell(
      onTap: () => context.push(AppRoutes.richiesta(adoption.id)),
      child: Row(
        children: [
          SizedBox(
            width: AppDim.homeAvatar,
            height: AppDim.homeAvatar,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(avatarColorValue(hex)),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  inizialiDi(who),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: AppText.body,
                    fontWeight: FontWeight.w800,
                    color: AppColor.card,
                    height: AppDim.lineH,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDim.gapM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cane.isEmpty ? who : '$who → $cane',
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
                  richiestaStatoDescrittivo(adoption, now),
                  maxLines: 1,
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
          ),
          MiniBadge(
            label: adoptionStatoLabel(adoption.stato),
            variant: adoption.stato == AdoptionStato.ricevuta
                ? MiniBadgeVariant.orange
                : MiniBadgeVariant.purple,
          ),
        ],
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final AppIconSpec icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppDim.gapL),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon, size: IconBadge.inStat),
          const SizedBox(height: AppDim.gapS),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: AppText.value,
              fontWeight: FontWeight.w700,
              color: AppColor.ink,
              height: AppDim.lineH,
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: AppText.statNote,
              color: AppColor.muted,
              height: AppDim.lineH,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppDim.pagePad,
      children: const [
        _Skel(width: AppDim.photoH, height: AppText.hello),
        SizedBox(height: AppDim.helloGap),
        _Skel(width: AppDim.logoLoginW, height: AppText.value),
        SizedBox(height: AppDim.gapL),
        Row(
          children: [
            Expanded(child: _SkelCard()),
            SizedBox(width: AppDim.gapM),
            Expanded(child: _SkelCard()),
          ],
        ),
        SizedBox(height: AppDim.gapL),
        _Skel(width: AppDim.photoW, height: AppText.h2),
        SizedBox(height: AppDim.gapM),
        _SkelCard(height: AppDim.emptyTodoH),
      ],
    );
  }
}

class _Skel extends StatelessWidget {
  const _Skel({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: AppColor.neutralSoft,
          borderRadius: BorderRadius.all(Radius.circular(AppDim.radIconBox)),
        ),
      ),
    );
  }
}

class _SkelCard extends StatelessWidget {
  const _SkelCard({this.height});

  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? AppDim.listAvatar * 2,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: AppColor.neutralSoft,
          borderRadius: BorderRadius.all(Radius.circular(AppDim.radCard)),
        ),
      ),
    );
  }
}
