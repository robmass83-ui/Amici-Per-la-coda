import 'package:flutter/material.dart';

import '../../data/models/enums.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import 'dog_list_query.dart';

// ── CONTRATTO DI LAYOUT · Filtri e ordinamento (schermata 28) ──────────────
// AppSheet  titolo «Filtri e ordinamento»
// per ogni gruppo: etichetta 11sp w700 muted · SizedBox 6 · Wrap chip h=28
//   Stato · Taglia · Sesso ed età · Sanitario · Compatibilità
// Ordina per: AppSegmented h=32  3 segmenti  Ingresso ↓ · Nome A-Z · Permanenza
// Row  Azzera grey | Applica  h=40  gap=9
// ───────────────────────────────────────────────────────────────────────────

class DogFiltersSheet extends StatefulWidget {
  const DogFiltersSheet({super.key, required this.initial});

  final DogListFilters initial;

  static const tagliaGrandeKey = Key('filtri-taglia-grande');
  static const applyKey = Key('filtri-applica');
  static const azzeraKey = Key('filtri-azzera');

  static Future<DogListFilters?> open(
    BuildContext context, {
    required DogListFilters initial,
  }) {
    return AppSheet.present<DogListFilters>(
      context: context,
      builder: (context) => DogFiltersSheet(initial: initial),
    );
  }

  @override
  State<DogFiltersSheet> createState() => _DogFiltersSheetState();
}

class _DogFiltersSheetState extends State<DogFiltersSheet> {
  late DogListFilters _draft;

  static const _stati = <(DogStato, String)>[
    (DogStato.inRifugio, 'In rifugio'),
    (DogStato.inStallo, 'In stallo'),
    (DogStato.preaffido, 'Preaffido'),
    (DogStato.adottato, 'Adottato'),
    (DogStato.inCura, 'In cura'),
  ];

  static const _taglie = <(Taglia, String)>[
    (Taglia.piccola, 'Piccola'),
    (Taglia.media, 'Media'),
    (Taglia.grande, 'Grande'),
  ];

  static const _sessoEta = <(DogSessoEta, String)>[
    (DogSessoEta.femmine, 'Femmine'),
    (DogSessoEta.maschi, 'Maschi'),
    (DogSessoEta.cuccioli, 'Cuccioli'),
    (DogSessoEta.senior, 'Senior 8+'),
  ];

  static const _sanitari = <(DogSanitario, String)>[
    (DogSanitario.sterilizzati, 'Sterilizzati'),
    (DogSanitario.daSterilizzare, 'Da sterilizzare'),
    (DogSanitario.vacciniScaduti, 'Vaccini scaduti'),
    (DogSanitario.inTerapia, 'In terapia'),
  ];

  static const _compat = <(DogCompat, String)>[
    (DogCompat.cani, 'Con cani'),
    (DogCompat.gatti, 'Con gatti'),
    (DogCompat.bambini, 'Con bambini'),
  ];

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height - AppDim.appBarH * 3;
    return AppSheet(
      title: 'Filtri e ordinamento',
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _group(
                  'Stato',
                  [
                    for (final item in _stati)
                      AppChip(
                        label: item.$2,
                        selected: _draft.stati.contains(item.$1),
                        onSelected: () => _toggleStato(item.$1),
                      ),
                  ],
                ),
                const SizedBox(height: AppDim.gapL),
                _group(
                  'Taglia',
                  [
                    for (final item in _taglie)
                      AppChip(
                        key: item.$1 == Taglia.grande
                            ? DogFiltersSheet.tagliaGrandeKey
                            : null,
                        label: item.$2,
                        selected: _draft.taglie.contains(item.$1),
                        onSelected: () => _toggleTaglia(item.$1),
                      ),
                  ],
                ),
                const SizedBox(height: AppDim.gapL),
                _group(
                  'Sesso ed età',
                  [
                    for (final item in _sessoEta)
                      AppChip(
                        label: item.$2,
                        selected: _draft.sessoEta.contains(item.$1),
                        onSelected: () => _toggleSessoEta(item.$1),
                      ),
                  ],
                ),
                const SizedBox(height: AppDim.gapL),
                _group(
                  'Sanitario',
                  [
                    for (final item in _sanitari)
                      AppChip(
                        label: item.$2,
                        selected: _draft.sanitari.contains(item.$1),
                        onSelected: () => _toggleSanitario(item.$1),
                      ),
                  ],
                ),
                const SizedBox(height: AppDim.gapL),
                _group(
                  'Compatibilità',
                  [
                    for (final item in _compat)
                      AppChip(
                        label: item.$2,
                        selected: _draft.compatibilita.contains(item.$1),
                        onSelected: () => _toggleCompat(item.$1),
                      ),
                  ],
                ),
                const SizedBox(height: AppDim.gapL),
                const Text(
                  'Ordina per',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: AppText.label,
                    fontWeight: FontWeight.w700,
                    color: AppColor.ink2,
                    height: AppDim.lineH,
                  ),
                ),
                const SizedBox(height: AppDim.gapS),
                AppSegmented(
                  values: const ['Ingresso ↓', 'Nome A-Z', 'Permanenza'],
                  selectedIndex: _draft.sort.index,
                  onChanged: (index) => setState(() {
                    _draft = _draft.copyWith(sort: DogListSort.values[index]);
                  }),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDim.gapXl),
        Row(
          children: [
            Expanded(
              child: AppButton(
                key: DogFiltersSheet.azzeraKey,
                label: 'Azzera',
                variant: AppButtonVariant.grey,
                onPressed: () =>
                    Navigator.of(context).pop(const DogListFilters()),
              ),
            ),
            const SizedBox(width: AppDim.gapM),
            Expanded(
              child: AppButton(
                key: DogFiltersSheet.applyKey,
                label: 'Applica',
                onPressed: () => Navigator.of(context).pop(_draft),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _group(String title, List<Widget> chips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: AppText.label,
            fontWeight: FontWeight.w700,
            color: AppColor.ink2,
            height: AppDim.lineH,
          ),
        ),
        const SizedBox(height: AppDim.gapS),
        Wrap(
          spacing: AppDim.gapS,
          runSpacing: AppDim.gapS,
          children: chips,
        ),
      ],
    );
  }

  void _toggleStato(DogStato value) {
    setState(() {
      final next = {..._draft.stati};
      if (!next.add(value)) {
        next.remove(value);
      }
      _draft = _draft.copyWith(stati: next);
    });
  }

  void _toggleTaglia(Taglia value) {
    setState(() {
      final next = {..._draft.taglie};
      if (!next.add(value)) {
        next.remove(value);
      }
      _draft = _draft.copyWith(taglie: next);
    });
  }

  void _toggleSessoEta(DogSessoEta value) {
    setState(() {
      final next = {..._draft.sessoEta};
      if (!next.add(value)) {
        next.remove(value);
      }
      _draft = _draft.copyWith(sessoEta: next);
    });
  }

  void _toggleSanitario(DogSanitario value) {
    setState(() {
      final next = {..._draft.sanitari};
      if (!next.add(value)) {
        next.remove(value);
      }
      _draft = _draft.copyWith(sanitari: next);
    });
  }

  void _toggleCompat(DogCompat value) {
    setState(() {
      final next = {..._draft.compatibilita};
      if (!next.add(value)) {
        next.remove(value);
      }
      _draft = _draft.copyWith(compatibilita: next);
    });
  }
}
