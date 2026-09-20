import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format_it.dart';
import '../../data/data_providers.dart';
import '../../data/models/dog.dart';
import '../../data/models/health_record.dart';
import '../../data/models/weight.dart';
import '../affido/affido_providers.dart';
import '../auth/auth_providers.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import 'add_treatment_sheet.dart';
import 'add_weight_sheet.dart';
import 'dogs_providers.dart';
import 'edit_permissions.dart';
import 'health_labels.dart';
import 'patologie.dart';
import 'patologie_sheet.dart';
import 'peso_chart.dart';
import 'record_actions.dart';
import 'scadenze.dart';

// ── CONTRATTO DI LAYOUT · Tab Salute ───────────────────────────────────────
// Padding  L/R=12  T/B=9
// Column  crossAxisAlignment=stretch
// ├ AppCard  Patologie
// │  ├ SectionTitle  IconBadge patologia 20×20
// │  ├ SizedBox h=9
// │  ├ Wrap MiniBadge  (preset selezionati)  oppure Text caption
// │  ├ Text nota libera 11.5sp maxLines=6  (se presente)
// │  └ se canWrite: SizedBox 9 + AppButton ghost «Aggiungi/Modifica patologie»
// ├ SizedBox h=9
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
  static const patologieKey = Key('dog-salute-patologie');
  static const editPatologieKey = Key('dog-edit-patologie');

  final Dog dog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canWrite = canWriteRecords(ref.watch(currentVolunteerProvider));
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
        _PatologieCard(dog: dog, canWrite: canWrite),
        const SizedBox(height: AppDim.gapM),
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
                  _ScadenzaRow(
                    record: scadenze[i],
                    now: now,
                    onTap: () => AddTreatmentSheet.open(
                      context,
                      dogId: dog.id,
                      existing: scadenze[i],
                    ),
                  ),
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
                for (final record in libretto)
                  _LibrettoRow(
                    record: record,
                    canWrite: canWrite,
                    onEdit: () => AddTreatmentSheet.open(
                      context,
                      dogId: dog.id,
                      existing: record,
                    ),
                    onDelete: () => _deleteTreatment(context, ref, record),
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
              if (weights.isNotEmpty) ...[
                const SizedBox(height: AppDim.gapM),
                for (final weight in weights.reversed)
                  _PesataRow(
                    weight: weight,
                    canWrite: canWrite,
                    onEdit: () => AddWeightSheet.open(
                      context,
                      dogId: dog.id,
                      existing: weight,
                    ),
                    onDelete: () => _deleteWeight(context, ref, weight),
                  ),
              ],
            ],
          ),
        ),
        if (canWrite) ...[
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
      ],
    );
  }
}

class _PatologieCard extends StatelessWidget {
  const _PatologieCard({required this.dog, required this.canWrite});

  final Dog dog;
  final bool canWrite;

  @override
  Widget build(BuildContext context) {
    final testo = dog.patologie;
    final selezionate = patologiePresetSelezionate(testo);
    final nota = patologieNotaLibera(testo);
    return AppCard(
      key: DogSaluteTab.patologieKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle(
            title: 'Patologie',
            icon: IconBadge(AppIcons.patologia, size: IconBadge.inTitle),
          ),
          const SizedBox(height: AppDim.gapM),
          if (!haPatologie(testo))
            const Text(
              'Nessuna patologia.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: AppText.caption,
                color: AppColor.muted,
                height: AppDim.lineH,
              ),
            )
          else ...[
            if (selezionate.isNotEmpty)
              Wrap(
                spacing: AppDim.gapS,
                runSpacing: AppDim.gapS,
                children: [
                  for (final tag in selezionate)
                    MiniBadge(label: tag, variant: MiniBadgeVariant.red),
                ],
              ),
            if (nota.isNotEmpty) ...[
              if (selezionate.isNotEmpty) const SizedBox(height: AppDim.gapS),
              Text(
                nota,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: AppText.value,
                  fontWeight: FontWeight.w600,
                  color: AppColor.ink,
                  height: AppDim.lineH,
                ),
              ),
            ],
          ],
          if (canWrite) ...[
            const SizedBox(height: AppDim.gapM),
            AppButton(
              key: DogSaluteTab.editPatologieKey,
              label: haPatologie(testo)
                  ? 'Modifica patologie'
                  : 'Aggiungi patologia',
              variant: AppButtonVariant.ghost,
              onPressed: () => PatologieSheet.open(context, dog: dog),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScadenzaRow extends StatelessWidget {
  const _ScadenzaRow({
    required this.record,
    required this.now,
    required this.onTap,
  });

  final HealthRecord record;
  final DateTime now;
  final VoidCallback onTap;

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
    return InkWell(
      onTap: onTap,
      child: Row(
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
      ),
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

Future<void> _deleteTreatment(
  BuildContext context,
  WidgetRef ref,
  HealthRecord record,
) async {
  final tipo = healthTipoLabel(record.tipo).toLowerCase();
  final health = ref.read(healthRepositoryProvider);
  final dogs = ref.read(dogRepositoryProvider);
  final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
  final ok = await confirmDeleteNamed(
    context,
    'la $tipo del ${formatItalianDate(record.data)}',
  );
  if (!ok) {
    return;
  }
  await health?.delete(record.id);
  await touchDogAudit(dogs: dogs, dogId: record.dogId, uid: uid);
}

Future<void> _deleteWeight(
  BuildContext context,
  WidgetRef ref,
  Weight weight,
) async {
  final weights = ref.read(weightRepositoryProvider);
  final dogs = ref.read(dogRepositoryProvider);
  final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
  final ok = await confirmDeleteNamed(
    context,
    'la pesata del ${formatItalianDate(weight.data)}',
  );
  if (!ok) {
    return;
  }
  await weights?.delete(weight.id);
  await touchDogAudit(dogs: dogs, dogId: weight.dogId, uid: uid);
}

class _LibrettoRow extends StatelessWidget {
  const _LibrettoRow({
    required this.record,
    required this.canWrite,
    required this.onEdit,
    required this.onDelete,
  });

  final HealthRecord record;
  final bool canWrite;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: canWrite
          ? () => openRecordActions(
              context,
              onEdit: onEdit,
              onDelete: onDelete,
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppDim.gapM),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    healthTipoLabel(record.tipo),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: AppText.body,
                      fontWeight: FontWeight.w600,
                      color: AppColor.ink,
                      height: AppDim.lineH,
                    ),
                  ),
                  Text(
                    _librettoSubtitle(record),
                    maxLines: 3,
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
            RecordMenuButton(
              id: record.id,
              canEdit: canWrite,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _PesataRow extends StatelessWidget {
  const _PesataRow({
    required this.weight,
    required this.canWrite,
    required this.onEdit,
    required this.onDelete,
  });

  final Weight weight;
  final bool canWrite;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: canWrite
          ? () => openRecordActions(
              context,
              onEdit: onEdit,
              onDelete: onDelete,
            )
          : null,
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${formatItalianDate(weight.data)} · ${formatItalianNumber(weight.kg)} kg',
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
          RecordMenuButton(
            id: weight.id,
            canEdit: canWrite,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }
}
