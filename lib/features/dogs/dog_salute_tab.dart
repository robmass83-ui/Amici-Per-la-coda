import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format_it.dart';
import '../../data/models/dog.dart';
import '../../data/models/health_record.dart';
import '../../data/models/weight.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import 'add_treatment_sheet.dart';
import 'add_weight_sheet.dart';
import 'dogs_providers.dart';
import 'health_labels.dart';
import 'peso_chart.dart';
import 'scadenze.dart';

// ── CONTRATTO DI LAYOUT · Tab Salute ───────────────────────────────────────
// Padding  L/R=12  T/B=9
// Column  crossAxisAlignment=stretch
// ├ AppCard  Prossime scadenze
// │  ├ SectionTitle  IconBadge scadenza 20×20
// │  ├ SizedBox h=9
// │  └ Row × n
// │     IconBadge 27  (flex: none) · SizedBox 6
// │     Expanded descrizione 11.5sp maxLines=1
// │     etichetta 10sp w700  (flex: none)  rosso se scaduto/≤7gg
// ├ SizedBox h=9
// ├ AppCard  Libretto sanitario
// │  └ TimelineList  title maxLines=2  subtitle maxLines=3
// ├ SizedBox h=9
// ├ AppCard  Andamento peso
// │  ├ PesoChart  h=72 + etichette 9sp  (serie da weights)
// │  ├ SizedBox h=6
// │  └ Text caption 10.5sp maxLines=2
// ├ SizedBox h=9
// ├ AppButton ghost  h=40  «Aggiungi trattamento»
// ├ SizedBox h=9
// └ AppButton ghost  h=40  «Registra peso»
// ───────────────────────────────────────────────────────────────────────────

class DogSaluteTab extends ConsumerWidget {
  const DogSaluteTab({super.key, required this.dog});

  static const addTreatmentKey = Key('dog-add-treatment');
  static const addWeightKey = Key('dog-add-weight');
  static const scadenzeKey = Key('dog-prossime-scadenze');

  final Dog dog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(dogListNowProvider);
    final health = ref
        .watch(healthByDogProvider(dog.id))
        .maybeWhen(data: (items) => items, orElse: () => const <HealthRecord>[]);
    final weights = ref
        .watch(weightsByDogProvider(dog.id))
        .maybeWhen(data: (items) => items, orElse: () => const <Weight>[]);
    final scadenze = prossimeScadenzeDi(health);
    final libretto = healthSortedByDataDesc(health);
    final punti = pesoPuntiDa(weights);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          key: scadenzeKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle(
                title: 'Prossime scadenze',
                icon: IconBadge(AppIcons.scadenza, size: IconBadge.inTitle),
              ),
              const SizedBox(height: AppDim.gapM),
              if (scadenze.isEmpty)
                const Text(
                  'Nessuna scadenza in programma.',
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
                for (var i = 0; i < scadenze.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppDim.gapS),
                  _ScadenzaRow(record: scadenze[i], now: now),
                ],
            ],
          ),
        ),
        const SizedBox(height: AppDim.gapM),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle(
                title: 'Libretto sanitario',
                icon: IconBadge(AppIcons.libretto, size: IconBadge.inTitle),
              ),
              const SizedBox(height: AppDim.gapM),
              if (libretto.isEmpty)
                const Text(
                  'Nessuna voce nel libretto.',
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
                TimelineList(
                  items: [
                    for (final record in libretto)
                      TimelineItem(
                        title: healthTipoLabel(record.tipo),
                        subtitle: _librettoSubtitle(record),
                      ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: AppDim.gapM),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle(
                title: 'Andamento peso',
                icon: IconBadge(AppIcons.peso, size: IconBadge.inTitle),
              ),
              const SizedBox(height: AppDim.gapM),
              PesoChart(punti: punti),
              if (punti.isNotEmpty) const SizedBox(height: AppDim.gapS),
              Text(
                pesoAndamentoCaption(punti),
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
        ),
        const SizedBox(height: AppDim.gapM),
        AppButton(
          key: addTreatmentKey,
          label: 'Aggiungi trattamento',
          variant: AppButtonVariant.ghost,
          onPressed: () => AddTreatmentSheet.open(context, dogId: dog.id),
        ),
        const SizedBox(height: AppDim.gapM),
        AppButton(
          key: addWeightKey,
          label: 'Registra peso',
          variant: AppButtonVariant.ghost,
          onPressed: () => AddWeightSheet.open(context, dogId: dog.id),
        ),
      ],
    );
  }
}

class _ScadenzaRow extends StatelessWidget {
  const _ScadenzaRow({required this.record, required this.now});

  final HealthRecord record;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final scadenza = record.prossimaScadenza!;
    final fascia = fasciaScadenza(scadenza, now);
    final color = switch (fascia) {
      ScadenzaFascia.scaduto || ScadenzaFascia.entro7 => AppColor.red,
      ScadenzaFascia.entro30 => AppColor.orange,
      ScadenzaFascia.lontano => AppColor.muted,
    };
    final label = record.descrizione.isEmpty
        ? healthTipoLabel(record.tipo)
        : record.descrizione;
    return Row(
      children: [
        IconBadge(AppIcons.perTrattamento(record.tipo.wire)),
        const SizedBox(width: AppDim.gapS),
        Expanded(
          child: Text(
            label,
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
          etichettaScadenza(scadenza, now),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: AppText.caption,
            fontWeight: FontWeight.w700,
            color: color,
            height: AppDim.lineH,
          ),
        ),
      ],
    );
  }
}

String _librettoSubtitle(HealthRecord record) {
  final head = record.veterinario.isEmpty
      ? formatItalianDate(record.data)
      : '${formatItalianDate(record.data)} · ${record.veterinario}';
  final extra = <String>[
    if (record.descrizione.isNotEmpty) record.descrizione,
    if (record.lotto.isNotEmpty) 'Lotto ${record.lotto}',
  ];
  if (extra.isEmpty) {
    return head;
  }
  return '$head\n${extra.join(' · ')}';
}
