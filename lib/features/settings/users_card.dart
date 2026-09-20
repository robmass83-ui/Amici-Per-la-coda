import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/volunteer.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../dogs/dogs_providers.dart';
import '../volunteers/volunteer_labels.dart';
import 'new_volunteer_sheet.dart';
import 'volunteer_detail_page.dart';

// ── CONTRATTO DI LAYOUT · Card Utenti ──────────────────────────────────────
// FormCard "Utenti"  AppIcons.volontari
// ├ per ogni volontario  InkWell  h=44
// │    ├ CircleAvatar 30  iniziali
// │    ├ SizedBox 8
// │    ├ Expanded Column
// │    │    ├ Row  nome 12sp w700 (barrato se disattivato) + badge
// │    │    └ email · ruolo  10sp muted  maxLines=1
// │    └ chevron
// │  ordinati: attivi prima, poi per nome
// └ AppButton ghost "➕ Nuovo volontario"
// ───────────────────────────────────────────────────────────────────────────

class UsersCard extends ConsumerWidget {
  const UsersCard({super.key});

  static const cardKey = Key('settings-utenti');
  static const nuovoKey = Key('settings-nuovo-volontario');

  static Key rowKey(String id) => Key('settings-utente-$id');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final volunteers = [
      ...ref.watch(volunteersStreamProvider).maybeWhen(
        data: (items) => items,
        orElse: () => const <Volunteer>[],
      ),
    ]..sort(compareVolunteers);

    return FormCard(
      key: cardKey,
      title: 'Utenti',
      icon: AppIcons.volontari,
      children: [
        for (final volunteer in volunteers)
          _UserRow(
            key: rowKey(volunteer.id),
            volunteer: volunteer,
            onTap: () => unawaited(
              VolunteerDetailPage.show(context, volunteer.id),
            ),
          ),
        AppButton(
          key: nuovoKey,
          label: '➕ Nuovo volontario',
          variant: AppButtonVariant.ghost,
          onPressed: () => unawaited(NewVolunteerSheet.show(context)),
        ),
      ],
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({
    super.key,
    required this.volunteer,
    required this.onTap,
  });

  final Volunteer volunteer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = volunteerDisplayName(volunteer);
    final subtitle =
        '${volunteer.email} · ${volunteerRuoloLabel(volunteer.ruolo)}';
    return SizedBox(
      height: AppDim.userRowH,
      child: Material(
        color: AppColor.card,
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              SizedBox(
                width: AppDim.userAvatar,
                height: AppDim.userAvatar,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: volunteerAvatarColor(volunteer),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      volunteerInitials(volunteer),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: AppText.caption,
                        fontWeight: FontWeight.w700,
                        color: volunteerAvatarForeground(volunteer),
                        height: AppDim.lineH,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDim.formRowGap),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: AppText.body,
                              fontWeight: FontWeight.w700,
                              color: volunteer.attivo
                                  ? AppColor.ink
                                  : AppColor.faint,
                              height: AppDim.lineH,
                              decoration: volunteer.attivo
                                  ? TextDecoration.none
                                  : TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                        if (!volunteer.attivo) ...[
                          const SizedBox(width: AppDim.gapXs),
                          const MiniBadge(
                            label: 'Disattivato',
                            variant: MiniBadgeVariant.neutral,
                          ),
                        ] else if (volunteer.mustChangePassword) ...[
                          const SizedBox(width: AppDim.gapXs),
                          const MiniBadge(
                            label: 'Password da cambiare',
                            variant: MiniBadgeVariant.orange,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      subtitle,
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
              const Icon(
                Icons.chevron_right_rounded,
                size: AppDim.iconNav,
                color: AppColor.faint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
