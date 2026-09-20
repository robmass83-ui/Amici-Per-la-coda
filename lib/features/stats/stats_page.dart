import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format_it.dart';
import '../../data/data_providers.dart';
import '../../data/models/dog.dart';
import '../../data/models/volunteer.dart';
import '../../router.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../dogs/dogs_providers.dart';
import 'month_chart.dart';
import 'stats_aggregators.dart';
import 'stats_csv.dart';
import 'stats_pdf.dart';
import 'stats_providers.dart';

// ── CONTRATTO DI LAYOUT · Statistiche (Step 17, schermata 22) ──────────────
// ListView padding=12
// ├ header trailing  anno ▾  11.5sp green w600  h=40
// ├ Row  2× Expanded AppCard pad=12  gap=9
// │    cifra 26sp w800  ·  etichetta 10.5sp muted maxLines=2
// ├ SizedBox 9
// ├ Row  2× Expanded  (stesso)
// ├ SizedBox 12
// ├ SectionTitle  Adozioni per mese  icona statistiche
// ├ AppCard pad=10  AdozioniMeseChart h=96
// ├ SizedBox 12
// ├ SectionTitle  Composizione del rifugio  icona carattere
// ├ AppCard pad=10
// │    per fetta: KeyValueRow  ·  SizedBox 4  ·  barra h=7
// │    SizedBox 9 fra le fette
// ├ SizedBox 12
// ├ SectionTitle  Bilancio spese sanitarie  icona spese
// ├ AppCard pad=10  KeyValueRow ×4  (saldo w700 green/red)
// ├ SizedBox 12
// ├ AppButton ghost  Esporta report annuale
// ├ SizedBox 9
// └ AppButton ghost  Esporta anagrafe (CSV)
// ───────────────────────────────────────────────────────────────────────────

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  static const listKey = Key('stats-list');
  static const yearKey = Key('stats-year');
  static const pdfKey = Key('stats-export-pdf');
  static const csvKey = Key('stats-export-csv');
  static const adozioniKey = Key('stats-adozioni');
  static const ingressiKey = Key('stats-ingressi');
  static const giorniKey = Key('stats-giorni');
  static const rientriKey = Key('stats-rientri');
  static const chartKey = Key('stats-chart');
  static const saldoKey = Key('stats-saldo');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(yearStatsProvider);
    final year = ref.watch(statsYearProvider);
    return AppScaffold(
      title: 'Statistiche',
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.home);
        }
      },
      headerActions: [
        GestureDetector(
          key: yearKey,
          behavior: HitTestBehavior.opaque,
          onTap: () => _pickYear(context, ref),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AppDim.minTouch,
              minHeight: AppDim.minTouch,
            ),
            child: Center(
              child: Text(
                '$year ▾',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
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
      body: ListView(
        key: listKey,
        padding: AppDim.pagePad,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  key: adozioniKey,
                  value: '${stats.adozioniConcluse}',
                  label: 'Adozioni concluse',
                  color: AppColor.green,
                ),
              ),
              const SizedBox(width: AppDim.gapM),
              Expanded(
                child: _StatCard(
                  key: ingressiKey,
                  value: '${stats.nuoviIngressi}',
                  label: 'Nuovi ingressi',
                  color: AppColor.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDim.gapM),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  key: giorniKey,
                  value: '${stats.giorniMediInRifugio}',
                  label: 'Giorni medi in rifugio',
                  color: AppColor.ink,
                ),
              ),
              const SizedBox(width: AppDim.gapM),
              Expanded(
                child: _StatCard(
                  key: rientriKey,
                  value: '${stats.rientriDopoAffido}',
                  label: 'Rientri dopo affido',
                  color: AppColor.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDim.gapL),
          const SectionTitle(
            title: 'Adozioni per mese',
            icon: IconBadge(AppIcons.statistiche, size: IconBadge.inTitle),
          ),
          const SizedBox(height: AppDim.gapM),
          AppCard(
            key: chartKey,
            child: AdozioniMeseChart(perMese: stats.adozioniPerMese),
          ),
          const SizedBox(height: AppDim.gapL),
          const SectionTitle(
            title: 'Composizione del rifugio',
            icon: IconBadge(AppIcons.carattere, size: IconBadge.inTitle),
          ),
          const SizedBox(height: AppDim.gapM),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < stats.composizione.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppDim.gapM),
                  _CompositionRow(slice: stats.composizione[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppDim.gapL),
          const SectionTitle(
            title: 'Bilancio spese sanitarie',
            icon: IconBadge(AppIcons.spese, size: IconBadge.inTitle),
          ),
          const SizedBox(height: AppDim.gapM),
          AppCard(
            child: Column(
              children: [
                KeyValueRow(
                  label: 'Spese totali ${stats.year}',
                  value: formatEuro(stats.speseTotali),
                ),
                const SizedBox(height: AppDim.gapS),
                KeyValueRow(
                  label: 'Donazioni ricevute',
                  value: formatEuro(stats.donazioniRicevute),
                  valueColor: AppColor.green,
                ),
                const SizedBox(height: AppDim.gapS),
                KeyValueRow(
                  label: 'Adozioni a distanza',
                  value: formatEuro(stats.adozioniADistanza),
                  valueColor: AppColor.green,
                ),
                const SizedBox(height: AppDim.gapS),
                KeyValueRow(
                  key: saldoKey,
                  label: 'Saldo',
                  value: formatSaldo(stats.saldo),
                  valueColor: stats.saldo < 0 ? AppColor.red : AppColor.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDim.gapL),
          AppButton(
            key: pdfKey,
            label: 'Esporta report annuale',
            variant: AppButtonVariant.ghost,
            onPressed: () => _exportPdf(context, ref, stats),
          ),
          const SizedBox(height: AppDim.gapM),
          AppButton(
            key: csvKey,
            label: 'Esporta anagrafe (CSV)',
            variant: AppButtonVariant.ghost,
            onPressed: () => _exportCsv(context, ref),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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
      padding: const EdgeInsets.all(AppDim.gapL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: AppText.display,
              fontWeight: FontWeight.w800,
              letterSpacing: AppDim.displayTracking,
              color: color,
              height: AppDim.lineH,
            ),
          ),
          Text(
            label,
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

class _CompositionRow extends StatelessWidget {
  const _CompositionRow({required this.slice});

  final CompositionSlice slice;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyValueRow(
          label: slice.label,
          value: '${slice.percentuale}%',
        ),
        const SizedBox(height: AppDim.gapXs),
        SizedBox(
          height: AppDim.statBarH,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColor.barTrack,
              borderRadius: BorderRadius.circular(AppDim.statBarR),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: (slice.percentuale / 100).clamp(0, 1),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColor.green,
                    borderRadius: BorderRadius.circular(AppDim.statBarR),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _pickYear(BuildContext context, WidgetRef ref) async {
  final now = ref.read(dogListNowProvider);
  final dogs = ref.read(dogsStreamProvider).maybeWhen(
        data: (items) => items,
        orElse: () => const <Dog>[],
      );
  final from = primoAnnoDisponibile(dogs, now);
  final years = [for (var y = now.year; y >= from; y--) y];
  final chosen = await AppSheet.present<int>(
    context: context,
    builder: (context) {
      return AppSheet(
        title: 'Anno',
        children: [
          for (final year in years)
            OptionRow(
              key: Key('stats-year-$year'),
              icon: const IconBadge(AppIcons.data, size: IconBadge.inMenu),
              title: '$year',
              onTap: () => Navigator.of(context).pop(year),
            ),
        ],
      );
    },
  );
  if (chosen == null) {
    return;
  }
  ref.read(statsYearProvider.notifier).setYear(chosen);
}

Future<void> _exportPdf(
  BuildContext context,
  WidgetRef ref,
  YearStats stats,
) async {
  try {
    final bytes = await reportAnnualePdf(stats);
    await ref.read(fileShareProvider).shareFile(
          bytes: bytes,
          fileName: 'report_${stats.year}.pdf',
          mime: 'application/pdf',
          text: 'Report annuale ${stats.year}',
        );
  } catch (_) {
    if (context.mounted) {
      AppToast.show(context, 'Export non riuscito.');
    }
  }
}

Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
  try {
    final dogs = ref.read(dogsStreamProvider).maybeWhen(
          data: (items) => items,
          orElse: () => const <Dog>[],
        );
    final volunteers = ref.read(volunteersStreamProvider).maybeWhen(
          data: (items) => items,
          orElse: () => const <Volunteer>[],
        );
    final csv = anagrafeCsvDi(dogs, volunteers: volunteers);
    await ref.read(fileShareProvider).shareFile(
          bytes: Uint8List.fromList(utf8.encode(csv)),
          fileName: 'anagrafe_cani.csv',
          mime: 'text/csv',
          text: 'Anagrafe cani',
        );
  } catch (_) {
    if (context.mounted) {
      AppToast.show(context, 'Export non riuscito.');
    }
  }
}
