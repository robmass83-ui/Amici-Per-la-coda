import 'package:flutter/material.dart';

import '../../data/models/enums.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import 'volunteer_labels.dart';

// ── CONTRATTO DI LAYOUT · Privilegi volontario ─────────────────────────────
// Column stretch
// ├ AppFormField label PRIVILEGI
// │    child AppSegmented 2  Volontario | Responsabile  h=32  larghezza piena
// ├ SizedBox 8
// └ Text hint 10sp muted  maxLines=4
// ───────────────────────────────────────────────────────────────────────────

class VolunteerPrivilegePicker extends StatelessWidget {
  const VolunteerPrivilegePicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final VolunteerRuolo selected;
  final ValueChanged<VolunteerRuolo> onChanged;

  static const segmentedKey = Key('volunteer-privilegi-segmenti');
  static const hintKey = Key('volunteer-privilegi-hint');

  @override
  Widget build(BuildContext context) {
    final index = assignableVolunteerRuoli.indexOf(
      isAssignableVolunteerRuolo(selected)
          ? selected
          : VolunteerRuolo.volontario,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFormField(
          label: 'Privilegi',
          child: AppSegmented(
            key: segmentedKey,
            values: [
              for (final ruolo in assignableVolunteerRuoli)
                volunteerRuoloLabel(ruolo),
            ],
            selectedIndex: index < 0 ? 0 : index,
            onChanged: (i) => onChanged(assignableVolunteerRuoli[i]),
          ),
        ),
        const SizedBox(height: AppDim.formRowGap),
        Text(
          key: hintKey,
          volunteerRuoloHint(
            isAssignableVolunteerRuolo(selected)
                ? selected
                : VolunteerRuolo.volontario,
          ),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: AppText.caption,
            color: AppColor.muted,
            height: AppDim.lineH,
          ),
        ),
      ],
    );
  }
}
