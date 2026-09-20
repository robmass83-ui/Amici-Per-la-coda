import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format_it.dart';
import '../../data/models/appointment.dart';
import '../../router.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../calendar/add_appointment_sheet.dart';
import '../dashboard/home_providers.dart';
import '../dogs/dogs_providers.dart';
import 'notice_aggregators.dart';
import 'notice_providers.dart';

// ── CONTRATTO DI LAYOUT · Notifiche (Step 17-bis, schermata 24) ────────────
// ListView padding=12
// header trailing «Segna lette» 11.5sp green w600 min 40×40
// per giorno: SectionTitle 10sp muted
//   AppCard  bordo sinistro 3  (rosso/arancio/verde)
//     Row  IconBadge 16  gap=9  Expanded
//       titolo 12sp w700 maxLines=2
//       testo 10.8sp muted maxLines=2
//       orario 9.5sp faint
//     SizedBox 8 fra le card
// ───────────────────────────────────────────────────────────────────────────

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  static const listKey = Key('notifiche-list');
  static const markReadKey = Key('notifiche-segna-lette');

  static Key noticeKey(String id) => Key('notifica-$id');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(dogListNowProvider);
    final notices = ref.watch(noticesProvider);
    final read = ref.watch(readNoticeIdsProvider);
    final unread = notices.where((item) => !read.contains(item.id)).toList();
    final groups = groupNotices(unread, now);

    return AppScaffold(
      title: 'Notifiche',
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.altro);
        }
      },
      headerActions: [
        GestureDetector(
          key: markReadKey,
          behavior: HitTestBehavior.opaque,
          onTap: () => ref.read(readNoticeIdsProvider.notifier).markAll(
                notices.map((item) => item.id),
              ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AppDim.minTouch,
              minHeight: AppDim.minTouch,
            ),
            child: const Center(
              child: Text(
                'Segna lette',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
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
      body: groups.isEmpty
          ? const Center(
              child: EmptyState(
                icon: IconBadge(AppIcons.notifiche),
                message: 'Nessuna notifica.',
                compact: true,
              ),
            )
          : ListView(
              key: listKey,
              padding: AppDim.pagePad,
              children: [
                for (var g = 0; g < groups.length; g++) ...[
                  if (g > 0) const SizedBox(height: AppDim.gapL),
                  Text(
                    groups[g].label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: AppText.caption,
                      fontWeight: FontWeight.w700,
                      letterSpacing: AppDim.groupTracking,
                      color: AppColor.muted,
                      height: AppDim.lineH,
                    ),
                  ),
                  const SizedBox(height: AppDim.gapS),
                  for (var i = 0; i < groups[g].items.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppDim.gapS),
                    _NoticeCard(
                      notice: groups[g].items[i],
                      onTap: () => _open(context, ref, groups[g].items[i]),
                    ),
                  ],
                ],
              ],
            ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice, required this.onTap});

  final AppNotice notice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = noticeAccent(notice.severity);
    return Material(
      color: AppColor.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDim.radCard),
        side: const BorderSide(color: AppColor.line),
      ),
      child: InkWell(
        key: NotificationsPage.noticeKey(notice.id),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDim.radCard),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(
                color: accent,
                child: const SizedBox(width: AppDim.notifyAccentW),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppDim.gapL),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconBadge(notice.icon, size: IconBadge.inNotice),
                    const SizedBox(width: AppDim.gapM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notice.title,
                            maxLines: 2,
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
                            notice.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: AppText.todo,
                              color: AppColor.muted,
                              height: AppDim.lineH,
                            ),
                          ),
                          Text(
                            formatItalianTime(notice.at),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: AppText.statNote,
                              color: AppColor.faint,
                              height: AppDim.lineH,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

Future<void> _open(
  BuildContext context,
  WidgetRef ref,
  AppNotice notice,
) async {
  final appointmentId = notice.appointmentId;
  if (appointmentId != null) {
    final list = ref.read(appointmentsStreamProvider).maybeWhen(
          data: (items) => items,
          orElse: () => const <Appointment>[],
        );
    for (final item in list) {
      if (item.id == appointmentId) {
        await AddAppointmentSheet.open(context, existing: item);
        return;
      }
    }
  }
  final adoptionId = notice.adoptionId;
  if (adoptionId != null) {
    unawaited(context.push(AppRoutes.richiesta(adoptionId)));
    return;
  }
  final dogId = notice.dogId;
  if (dogId != null) {
    AppRoutes.openDog(context, dogId, from: AppRoutes.notifiche);
  }
}
