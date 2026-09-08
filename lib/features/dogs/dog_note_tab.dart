import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format_it.dart';
import '../../data/models/dog.dart';
import '../../data/models/enums.dart';
import '../../data/models/note.dart';
import '../../data/models/volunteer.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import 'add_note_sheet.dart';
import 'dogs_providers.dart';
import 'tab_labels.dart';

// ── CONTRATTO DI LAYOUT · Tab Note ─────────────────────────────────────────
// Padding 12/9  Column stretch
// ├ nota × n  pad=10  radius=12
// │  Row  IconBadge 20 (flex none) · Expanded header 10sp maxLines=1
// │  SizedBox 6
// │  Text corpo 12sp  (wrap verticale)
// ├ SizedBox 9
// └ AppButton ghost  Aggiungi nota  h=40
// ───────────────────────────────────────────────────────────────────────────

class DogNoteTab extends ConsumerWidget {
  const DogNoteTab({super.key, required this.dog});

  static const addKey = Key('dog-add-note');

  final Dog dog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref
        .watch(notesByDogProvider(dog.id))
        .maybeWhen(data: (items) => items, orElse: () => const <Note>[]);
    final volunteers = ref
        .watch(volunteersStreamProvider)
        .maybeWhen(data: (items) => items, orElse: () => const <Volunteer>[]);
    final sorted = List<Note>.of(notes)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sorted.isEmpty)
          const Text(
            'Nessuna nota.',
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
            if (i > 0) const SizedBox(height: AppDim.gapM),
            _NoteCard(
              note: sorted[i],
              author: autoreEtichetta(volunteers, sorted[i].autoreId),
            ),
          ],
        const SizedBox(height: AppDim.gapM),
        AppButton(
          key: addKey,
          label: 'Aggiungi nota',
          variant: AppButtonVariant.ghost,
          onPressed: () => AddNoteSheet.open(context, dogId: dog.id),
        ),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.author});

  final Note note;
  final String author;

  @override
  Widget build(BuildContext context) {
    final colors = _noteColors(note.tipo);
    final header = note.tipo == NoteTipo.generale
        ? '$author · ${formatItalianDate(note.createdAt)}'
        : '${noteTipoLabel(note.tipo)} · $author · ${formatItalianDate(note.createdAt)}';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppDim.radCard),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: AppDim.cardPad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconBadge(
                  AppIcons.perNota(note.tipo.wire),
                  size: IconBadge.inTitle,
                ),
                const SizedBox(width: AppDim.gapS),
                Expanded(
                  child: Text(
                    header,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: AppText.caption,
                      fontWeight: FontWeight.w600,
                      color: colors.header,
                      height: AppDim.lineH,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDim.gapS),
            Text(
              note.testo,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: AppText.body,
                color: AppColor.ink,
                height: AppDim.lineH,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

({Color background, Color border, Color header}) _noteColors(NoteTipo tipo) {
  return switch (tipo) {
    NoteTipo.generale => (
      background: AppColor.card,
      border: AppColor.line,
      header: AppColor.muted,
    ),
    NoteTipo.comportamento => (
      background: AppColor.redSoft,
      border: AppColor.redSoft,
      header: AppColor.red,
    ),
    NoteTipo.alimentazione => (
      background: AppColor.blueSoft,
      border: AppColor.blueSoft,
      header: AppColor.blue,
    ),
    NoteTipo.attenzione => (
      background: AppColor.orangeSoft,
      border: AppColor.orangeSoft,
      header: AppColor.orange,
    ),
  };
}
