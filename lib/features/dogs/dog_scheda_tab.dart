import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format_it.dart';
import '../../data/models/dog.dart';
import '../../data/models/enums.dart';
import '../../data/models/expense.dart';
import '../../data/models/health_record.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import 'dog_adoption_status.dart';
import 'dog_labels.dart';
import 'dogs_providers.dart';
import 'health_labels.dart';

// ── CONTRATTO DI LAYOUT · Tab Scheda ───────────────────────────────────────
// Padding  L/R=AppDim.gapL(12)  T/B=AppDim.gapM(9)
// └ Wrap  spacing=9  runSpacing=9
//    └ SizedBox  width=(max-9)/2  ×4
//       AppCard  pad=10
//       ├ SectionTitle  IconBadge 20×20  (flex: none)
//       │    titolo  13sp w700  maxLines=2 ellipsis
//       ├ SizedBox  h=9
//       └ righe
//          KeyValueRow  label Expanded maxLines=3 · value Expanded maxLines=3
//          gap fra righe = 6
//          attività: IconBadge 27  (flex: none) · SizedBox 6
//                    Expanded nome 11.5sp maxLines=1
//                    data 10sp  (flex: none) maxLines=1
// ───────────────────────────────────────────────────────────────────────────

class DogSchedaTab extends ConsumerWidget {
  const DogSchedaTab({super.key, required this.dog});

  static const gridKey = Key('dog-scheda-grid');

  final Dog dog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref
        .watch(healthByDogProvider(dog.id))
        .maybeWhen(data: (items) => items, orElse: () => const <HealthRecord>[]);
    final expenses = ref
        .watch(expensesByDogProvider(dog.id))
        .maybeWhen(data: (items) => items, orElse: () => const <Expense>[]);
    final adoptions = ref.watch(dogAdoptionsProvider(dog.id));
    final requestCount = ref.watch(dogAdoptionCountProvider(dog.id));
    final status = dogAdoptionStatusView(dog, adoptions);

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileW = (constraints.maxWidth - AppDim.gapM) / 2;
        return Wrap(
          key: gridKey,
          spacing: AppDim.gapM,
          runSpacing: AppDim.gapM,
          children: [
            SizedBox(
              width: tileW,
              child: _CarattereCard(dog: dog),
            ),
            SizedBox(
              width: tileW,
              child: _AdozioneCard(
                dog: dog,
                requestCount: requestCount,
                status: status,
              ),
            ),
            SizedBox(
              width: tileW,
              child: _SanitarieCard(records: health),
            ),
            SizedBox(
              width: tileW,
              child: _SpeseCard(expenses: expenses),
            ),
          ],
        );
      },
    );
  }
}

class _CarattereCard extends StatelessWidget {
  const _CarattereCard({required this.dog});

  final Dog dog;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle(
            title: 'Carattere e compatibilità',
            icon: IconBadge(AppIcons.carattere, size: IconBadge.inTitle),
          ),
          const SizedBox(height: AppDim.gapM),
          KeyValueRow(label: 'Carattere', value: carattereLabel(dog.carattere)),
          const SizedBox(height: AppDim.gapS),
          KeyValueRow(label: 'Con persone', value: conPersoneLabel(dog.conPersone)),
          const SizedBox(height: AppDim.gapS),
          KeyValueRow(label: 'Con cani', value: conCaniLabel(dog.conCani)),
          const SizedBox(height: AppDim.gapS),
          KeyValueRow(label: 'Con gatti', value: conGattiLabel(dog.conGatti)),
          const SizedBox(height: AppDim.gapS),
          KeyValueRow(label: 'Con bambini', value: conBambiniLabel(dog.conBambini)),
          const SizedBox(height: AppDim.gapS),
          KeyValueRow(label: 'Note', value: dashIfEmpty(dog.noteCarattere)),
        ],
      ),
    );
  }
}

class _AdozioneCard extends StatelessWidget {
  const _AdozioneCard({
    required this.dog,
    required this.requestCount,
    required this.status,
  });

  final Dog dog;
  final int requestCount;
  final DogAdoptionStatusView status;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle(
            title: 'Stato adozione',
            icon: IconBadge(AppIcons.adottabile, size: IconBadge.inTitle),
          ),
          const SizedBox(height: AppDim.gapM),
          KeyValueRow(
            label: 'Adottabile',
            value: yesNo(dog.adottabile),
            valueColor: dog.adottabile ? AppColor.green : null,
          ),
          const SizedBox(height: AppDim.gapS),
          KeyValueRow(label: 'Richieste ricevute', value: '$requestCount'),
          const SizedBox(height: AppDim.gapS),
          KeyValueRow(label: 'Preaffido', value: status.preaffido),
          const SizedBox(height: AppDim.gapS),
          KeyValueRow(label: 'Data adozione', value: status.dataAdozione),
          const SizedBox(height: AppDim.gapS),
          KeyValueRow(label: 'Famiglia adottante', value: status.famiglia),
        ],
      ),
    );
  }
}

class _SanitarieCard extends StatelessWidget {
  const _SanitarieCard({required this.records});

  final List<HealthRecord> records;

  @override
  Widget build(BuildContext context) {
    final latest = healthSortedByDataDesc(records).take(5).toList();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle(
            title: 'Ultime attività sanitarie',
            icon: IconBadge(AppIcons.vaccino, size: IconBadge.inTitle),
          ),
          const SizedBox(height: AppDim.gapM),
          if (latest.isEmpty)
            const Text(
              'Nessuna attività sanitaria.',
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
            for (var i = 0; i < latest.length; i++) ...[
              if (i > 0) const SizedBox(height: AppDim.gapS),
              _CompactHealthRow(record: latest[i]),
            ],
        ],
      ),
    );
  }
}

class _SpeseCard extends StatelessWidget {
  const _SpeseCard({required this.expenses});

  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
    final byCat = spesePerCategoria(expenses);
    final rows = ExpenseCategoria.values
        .where((cat) => (byCat[cat] ?? 0) > 0)
        .toList();
    final total = totaleSpese(expenses);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle(
            title: 'Spese sostenute',
            icon: IconBadge(AppIcons.spese, size: IconBadge.inTitle),
          ),
          const SizedBox(height: AppDim.gapM),
          if (rows.isEmpty)
            const Text(
              'Nessuna spesa.',
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
            for (final cat in rows) ...[
              KeyValueRow(
                label: expenseCategoriaLabel(cat),
                value: formatEuro(byCat[cat]!),
              ),
              const SizedBox(height: AppDim.gapS),
            ],
          KeyValueRow(
            label: 'Totale',
            value: formatEuro(total),
            valueColor: AppColor.green,
          ),
        ],
      ),
    );
  }
}

class _CompactHealthRow extends StatelessWidget {
  const _CompactHealthRow({required this.record});

  final HealthRecord record;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconBadge(AppIcons.perTrattamento(record.tipo.wire)),
        const SizedBox(width: AppDim.gapS),
        Expanded(
          child: Text(
            healthTipoLabel(record.tipo),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: AppText.value,
              fontWeight: FontWeight.w600,
              color: AppColor.ink,
              height: AppDim.lineH,
            ),
          ),
        ),
        const SizedBox(width: AppDim.gapS),
        Text(
          formatItalianDate(record.data),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: AppText.caption,
            fontWeight: FontWeight.w500,
            color: AppColor.muted,
            height: AppDim.lineH,
          ),
        ),
      ],
    );
  }
}
