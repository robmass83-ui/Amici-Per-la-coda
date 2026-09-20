import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format_it.dart';
import '../../data/data_providers.dart';
import '../../data/models/dog.dart';
import '../../data/models/expense.dart';
import '../../data/models/sponsorship.dart';
import '../affido/affido_providers.dart';
import '../auth/auth_providers.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import 'add_expense_sheet.dart';
import 'add_sponsorship_sheet.dart';
import 'dogs_providers.dart';
import 'edit_permissions.dart';
import 'health_labels.dart';
import 'record_actions.dart';

// ── CONTRATTO DI LAYOUT · Tab Spese ────────────────────────────────────────
// Padding 12/9  Column stretch
// ├ AppCard  totale  testo centrato
// │  etichetta 10sp  · cifra 26sp green  · caption 10.5sp maxLines=2
// ├ SizedBox 9
// ├ AppCard  Ripartizione
// │  per categoria: KeyValueRow + barra h=6  widthFactor=%/100
// ├ SizedBox 9
// ├ AppCard  Movimenti
// │  IconBadge 27 · Expanded desc maxLines=1 · importo flex none
// ├ SizedBox 9
// ├ AppCard  Adozione a distanza
// │  se ci sono sostenitori attivi:
// │    KeyValueRow × 3  (sostenitori, contributo/mese, copertura ≤100%)
// │  altrimenti:
// │    Text 10.5sp  «Attiva un'adozione a distanza»  maxLines=2
// ├ SizedBox 9
// └ se canWrite: AppButton ghost  Registra spesa  h=40
//                 AppButton ghost  Adozione a distanza  h=40
// ───────────────────────────────────────────────────────────────────────────

class DogSpeseTab extends ConsumerWidget {
  const DogSpeseTab({super.key, required this.dog});

  static const addKey = Key('dog-add-expense');
  static const addSponsorshipKey = Key('dog-add-sponsorship');
  static const totaleKey = Key('dog-spese-totale');
  static const sponsorshipKey = Key('dog-adozione-distanza');
  static const sponsorshipEmptyKey = Key('dog-adozione-distanza-vuoto');

  final Dog dog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canWrite = canWriteRecords(ref.watch(currentVolunteerProvider));
    final now = ref.watch(dogListNowProvider);
    final expenses = ref
        .watch(expensesByDogProvider(dog.id))
        .maybeWhen(data: (items) => items, orElse: () => const <Expense>[]);
    final sponsorships = ref
        .watch(sponsorshipsByDogProvider(dog.id))
        .maybeWhen(
          data: (items) => items,
          orElse: () => const <Sponsorship>[],
        );
    final total = totaleSpese(expenses);
    final parts = ripartizioneSpese(expenses);
    final sorted = List<Expense>.of(expenses)
      ..sort((a, b) => b.data.compareTo(a.data));
    final media = expenses.isEmpty
        ? null
        : mediaMensileSpese(expenses, from: dog.dataIngresso, now: now);
    final adozione = riepilogoAdozioneADistanza(
      sponsorships: sponsorships,
      expenses: expenses,
      from: dog.dataIngresso,
      now: now,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            children: [
              const Text(
                'Totale sostenuto',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: AppText.caption,
                  color: AppColor.muted,
                  height: AppDim.lineH,
                ),
              ),
              const SizedBox(height: AppDim.gapXs),
              Text(
                formatEuro(total),
                key: totaleKey,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: AppText.display,
                  fontWeight: FontWeight.w800,
                  color: AppColor.green,
                  height: AppDim.lineH,
                ),
              ),
              const SizedBox(height: AppDim.gapXs),
              Text(
                media == null
                    ? 'Nessuna spesa registrata.'
                    : 'dal ${formatItalianDate(dog.dataIngresso)} · media ${formatEuro(media)}/mese',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
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
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle(
                title: 'Ripartizione',
                icon: IconBadge(AppIcons.ripartizione, size: IconBadge.inTitle),
              ),
              const SizedBox(height: AppDim.gapM),
              if (parts.isEmpty)
                const Text(
                  'Nessuna ripartizione.',
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
                for (var i = 0; i < parts.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppDim.gapM),
                  _RipartoRiga(voce: parts[i]),
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
                title: 'Movimenti',
                icon: IconBadge(AppIcons.movimento, size: IconBadge.inTitle),
              ),
              const SizedBox(height: AppDim.gapM),
              if (sorted.isEmpty)
                const Text(
                  'Nessun movimento.',
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
                for (var i = 0; i < sorted.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppDim.gapS),
                  _MovimentoRow(
                    expense: sorted[i],
                    canWrite: canWrite,
                    onEdit: () => AddExpenseSheet.open(
                      context,
                      dogId: dog.id,
                      existing: sorted[i],
                    ),
                    onDelete: () => _deleteExpense(context, ref, sorted[i]),
                  ),
                ],
            ],
          ),
        ),
        const SizedBox(height: AppDim.gapM),
        AppCard(
          key: sponsorshipKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle(
                title: 'Adozione a distanza',
                icon: IconBadge(AppIcons.aDistanza, size: IconBadge.inTitle),
              ),
              const SizedBox(height: AppDim.gapM),
              if (adozione == null)
                const Text(
                  'Attiva un\'adozione a distanza',
                  key: sponsorshipEmptyKey,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: AppText.label,
                    color: AppColor.muted,
                    height: AppDim.lineH,
                  ),
                )
              else ...[
                KeyValueRow(
                  label: 'Sostenitori attivi',
                  value: '${adozione.sostenitoriAttivi}',
                ),
                const SizedBox(height: AppDim.gapS),
                KeyValueRow(
                  label: 'Contributo mensile',
                  value: '${formatEuro(adozione.contributoMensile)}/mese',
                ),
                const SizedBox(height: AppDim.gapS),
                KeyValueRow(
                  label: 'Copertura spese',
                  value: '${adozione.coperturaPercentuale}%',
                  valueColor: AppColor.green,
                ),
              ],
              if (sponsorships.isNotEmpty) ...[
                const SizedBox(height: AppDim.gapM),
                for (final item in sponsorships)
                  _SponsorshipRow(
                    sponsorship: item,
                    canWrite: canWrite,
                    onEdit: () => AddSponsorshipSheet.open(
                      context,
                      dogId: dog.id,
                      existing: item,
                    ),
                    onClose: item.attiva
                        ? () => _closeSponsorship(context, ref, item)
                        : null,
                  ),
              ],
            ],
          ),
        ),
        if (canWrite) ...[
          const SizedBox(height: AppDim.gapM),
          AppButton(
            key: addKey,
            label: 'Registra spesa',
            variant: AppButtonVariant.ghost,
            onPressed: () => AddExpenseSheet.open(context, dogId: dog.id),
          ),
          const SizedBox(height: AppDim.gapM),
          AppButton(
            key: addSponsorshipKey,
            label: 'Adozione a distanza',
            variant: AppButtonVariant.ghost,
            onPressed: () => AddSponsorshipSheet.open(context, dogId: dog.id),
          ),
        ],
      ],
    );
  }
}

class _RipartoRiga extends StatelessWidget {
  const _RipartoRiga({required this.voce});

  final RipartoVoce voce;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyValueRow(
          label: '${expenseCategoriaLabel(voce.categoria)} · ${voce.percentuale}%',
          value: formatEuro(voce.importo),
        ),
        const SizedBox(height: AppDim.gapXs),
        _PercentBar(factor: voce.percentuale / 100),
      ],
    );
  }
}

class _PercentBar extends StatelessWidget {
  const _PercentBar({required this.factor});

  final double factor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDim.gapS,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColor.greenSoft,
          borderRadius: BorderRadius.circular(AppDim.radChip),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: factor.clamp(0, 1),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColor.green,
                borderRadius: BorderRadius.circular(AppDim.radChip),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

class _MovimentoRow extends StatelessWidget {
  const _MovimentoRow({
    required this.expense,
    required this.canWrite,
    required this.onEdit,
    required this.onDelete,
  });

  final Expense expense;
  final bool canWrite;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final label = expense.descrizione.isEmpty
        ? expenseCategoriaLabel(expense.categoria)
        : expense.descrizione;
    final extra = expense.fornitore.isEmpty ? '' : ' · ${expense.fornitore}';
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
          IconBadge(AppIcons.perSpesa(expense.categoria.wire)),
          const SizedBox(width: AppDim.gapS),
          Expanded(
            child: Text(
              '$label$extra',
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
            formatEuro(expense.importo),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: AppText.caption,
              fontWeight: FontWeight.w700,
              color: AppColor.ink,
              height: AppDim.lineH,
            ),
          ),
          RecordMenuButton(
            id: expense.id,
            canEdit: canWrite,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }
}

class _SponsorshipRow extends StatelessWidget {
  const _SponsorshipRow({
    required this.sponsorship,
    required this.canWrite,
    required this.onEdit,
    this.onClose,
  });

  final Sponsorship sponsorship;
  final bool canWrite;
  final VoidCallback onEdit;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final nome =
        '${sponsorship.sostenitore.nome} ${sponsorship.sostenitore.cognome}'
            .trim();
    return GestureDetector(
      onLongPress: canWrite
          ? () => openRecordActions(
              context,
              onEdit: onEdit,
              onDelete: onClose,
              deleteLabel: 'Chiudi',
            )
          : null,
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$nome · ${formatEuro(sponsorship.importoMensile)}/mese'
              '${sponsorship.attiva ? '' : ' · chiusa'}',
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
            id: sponsorship.id,
            canEdit: canWrite,
            onEdit: onEdit,
            onDelete: onClose,
            deleteLabel: 'Chiudi',
          ),
        ],
      ),
    );
  }
}

Future<void> _deleteExpense(
  BuildContext context,
  WidgetRef ref,
  Expense expense,
) async {
  final nome = expense.descrizione.isEmpty
      ? expenseCategoriaLabel(expense.categoria)
      : expense.descrizione;
  final expenses = ref.read(expenseRepositoryProvider);
  final dogs = ref.read(dogRepositoryProvider);
  final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
  final ok = await confirmDeleteNamed(
    context,
    'la spesa «$nome» del ${formatItalianDate(expense.data)}',
  );
  if (!ok) {
    return;
  }
  await expenses?.delete(expense.id);
  if (expense.dogId != null) {
    await touchDogAudit(dogs: dogs, dogId: expense.dogId!, uid: uid);
  }
}

Future<void> _closeSponsorship(
  BuildContext context,
  WidgetRef ref,
  Sponsorship sponsorship,
) async {
  final nome =
      '${sponsorship.sostenitore.nome} ${sponsorship.sostenitore.cognome}'
          .trim();
  final sponsorships = ref.read(sponsorshipRepositoryProvider);
  final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
  final ok = await confirmAction(
    context: context,
    title: 'Chiudi adozione a distanza',
    message: 'Chiudere l\'adozione a distanza di $nome?',
    confirmLabel: 'Chiudi',
  );
  if (!ok) {
    return;
  }
  final now = DateTime.now();
  await sponsorships?.save(
    sponsorship.copyWith(
      attiva: false,
      al: now,
      audit: sponsorship.audit.touched(uid, now),
    ),
  );
}
