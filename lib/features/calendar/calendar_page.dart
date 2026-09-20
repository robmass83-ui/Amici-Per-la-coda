import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format_it.dart';
import '../../data/data_providers.dart';
import '../../data/models/adoption.dart';
import '../../data/models/appointment.dart';
import '../../data/models/dog.dart';
import '../../data/models/health_record.dart';
import '../../router.dart';
import '../affido/affido_providers.dart';
import '../dashboard/home_providers.dart';
import '../dogs/dogs_providers.dart';
import '../dogs/edit_permissions.dart';
import '../dogs/record_actions.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import 'add_appointment_sheet.dart';
import 'calendar_events.dart';

// ── CONTRATTO DI LAYOUT · Calendario (Step 15) ─────────────────────────────
// ListView padding=12
// ├ Row  titolo mese 15sp w800  ·  ‹ ›  muted  gap 12  (hit 40×40)
// ├ SizedBox 9
// ├ AppCard padding=10
// │    7 colonne gap 3
// │    header L M M G V S D  9.5sp muted w700  padV=4
// │    6 settimane × 7 giorni  (sempre 42 celle, h=40)
// │    fuori mese: faint · oggi: fill green testo bianco w700
// │    selezionato: fill greenSoft · pallini 4dp  orange=affido  blue=vet
// ├ SizedBox 8
// ├ Wrap  legend 10sp  ● Adozioni/affidi orange  ● Veterinario blue
// ├ SizedBox 12
// ├ SectionTitle  "Oggi · <giorno>"  icona 20
// ├ SizedBox 9
// ├ AppCard
// │    Row  ora 11sp w700 w=42  |  bordo 2.5  | titolo 12sp w700 · sub 10.5
// │    divider 1 fra le voci · vuoto: EmptyState compact
// ├ SizedBox 12
// ├ SectionTitle  "Prossimi giorni"
// ├ SizedBox 9
// ├ AppCard  data dd/MM · titolo · ora|tutto il g.  (max 4)
// ├ SizedBox 12
// └ AppButton ghost  "Nuovo appuntamento"  (solo canWriteRecords)
// ───────────────────────────────────────────────────────────────────────────

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  static const listKey = Key('calendar-list');
  static const gridKey = Key('calendar-grid');
  static const prevKey = Key('calendar-prev');
  static const nextKey = Key('calendar-next');
  static const addKey = Key('calendar-add');
  static const todayKey = Key('calendar-today');

  static Key cellKey(int index) => Key('calendar-cell-$index');
  static Key dayKey(DateTime day) {
    final d = calendarDay(day);
    return Key('calendar-day-${d.year}-${d.month}-${d.day}');
  }

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = calendarDay(ref.read(dogListNowProvider));
    _month = DateTime(now.year, now.month);
    _selected = now;
  }

  void _shiftMonth(int delta) {
    final next = DateTime(_month.year, _month.month + delta);
    final today = calendarDay(ref.read(dogListNowProvider));
    setState(() {
      _month = next;
      if (today.year == next.year && today.month == next.month) {
        _selected = today;
      } else {
        _selected = next;
      }
    });
  }

  void _selectDay(DateTime day) {
    final d = calendarDay(day);
    setState(() {
      _month = DateTime(d.year, d.month);
      _selected = d;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canWrite = canWriteRecords(ref.watch(currentVolunteerProvider));
    final now = calendarDay(ref.watch(dogListNowProvider));
    final appointments = ref
        .watch(appointmentsStreamProvider)
        .maybeWhen(
          data: (list) => list,
          orElse: () => const <Appointment>[],
        );
    final health = ref
        .watch(healthAllProvider)
        .maybeWhen(
          data: (list) => list,
          orElse: () => const <HealthRecord>[],
        );
    final dogs = ref
        .watch(dogsStreamProvider)
        .maybeWhen(data: (list) => list, orElse: () => const <Dog>[]);
    final adoptions = ref
        .watch(adoptionsStreamProvider)
        .maybeWhen(
          data: (list) => list,
          orElse: () => const <Adoption>[],
        );

    final events = calendarEventsFrom(
      appointments: appointments,
      health: health,
      dogs: dogs,
      adoptions: adoptions,
    );
    final dayEvents = eventsOnDay(events, _selected);
    final upcoming = upcomingEvents(events, after: _selected);
    final days = monthGridDays(_month);

    return ListView(
      key: CalendarPage.listKey,
      padding: AppDim.pagePad,
      children: [
        _MonthHeader(
          title: formatItalianMonthYear(_month),
          onPrev: () => _shiftMonth(-1),
          onNext: () => _shiftMonth(1),
        ),
        const SizedBox(height: AppDim.gapM),
        AppCard(
          child: _MonthGrid(
            days: days,
            month: _month,
            today: now,
            selected: _selected,
            events: events,
            onSelect: _selectDay,
          ),
        ),
        const SizedBox(height: AppDim.formRowGap),
        const _Legend(),
        const SizedBox(height: AppDim.gapL),
        SectionTitle(
          title: calendarDaySectionTitle(selected: _selected, now: now),
          icon: const IconBadge(AppIcons.data, size: IconBadge.inTitle),
        ),
        const SizedBox(height: AppDim.gapM),
        AppCard(
          child: dayEvents.isEmpty
              ? const EmptyState(
                  compact: true,
                  icon: IconBadge(AppIcons.data, size: IconBadge.inTitle),
                  message: 'Nessun impegno per questo giorno.',
                )
              : Column(
                  children: [
                    for (var i = 0; i < dayEvents.length; i++) ...[
                      if (i > 0) const _EventDivider(),
                      _DayEventRow(
                        event: dayEvents[i],
                        canWrite: canWrite,
                        onTap: () => _openEvent(dayEvents[i], canWrite),
                        onEdit: () => _editAppointment(dayEvents[i]),
                        onDelete: () => _deleteAppointment(dayEvents[i]),
                      ),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: AppDim.gapL),
        const SectionTitle(
          title: 'Prossimi giorni',
          icon: IconBadge(AppIcons.scadenza, size: IconBadge.inTitle),
        ),
        const SizedBox(height: AppDim.gapM),
        AppCard(
          child: upcoming.isEmpty
              ? const EmptyState(
                  compact: true,
                  icon: IconBadge(AppIcons.scadenza, size: IconBadge.inTitle),
                  message: 'Nessun impegno in programma.',
                )
              : Column(
                  children: [
                    for (var i = 0; i < upcoming.length; i++) ...[
                      if (i > 0) const _EventDivider(),
                      _UpcomingRow(
                        event: upcoming[i],
                        onTap: () => _openEvent(upcoming[i], canWrite),
                      ),
                    ],
                  ],
                ),
        ),
        if (canWrite) ...[
          const SizedBox(height: AppDim.gapL),
          AppButton(
            key: CalendarPage.addKey,
            label: 'Nuovo appuntamento',
            variant: AppButtonVariant.ghost,
            onPressed: () => AddAppointmentSheet.open(
              context,
              initialDay: _selected,
            ),
          ),
        ],
        const SizedBox(height: AppDim.gapXl),
      ],
    );
  }

  void _openEvent(CalendarEvent event, bool canWrite) {
    switch (event.source) {
      case CalendarEventSource.appointment:
        if (canWrite && event.appointment != null) {
          _editAppointment(event);
        }
      case CalendarEventSource.health:
        final dogId = event.dogId;
        if (dogId != null && dogId.isNotEmpty) {
          context.push(AppRoutes.dog(dogId));
        }
      case CalendarEventSource.preaffido:
        final adoptionId = event.adoptionId;
        if (adoptionId != null && adoptionId.isNotEmpty) {
          context.push(AppRoutes.richiesta(adoptionId));
        }
    }
  }

  void _editAppointment(CalendarEvent event) {
    final appointment = event.appointment;
    if (appointment == null) {
      return;
    }
    AddAppointmentSheet.open(context, existing: appointment);
  }

  Future<void> _deleteAppointment(CalendarEvent event) async {
    final appointment = event.appointment;
    if (appointment == null) {
      return;
    }
    final appointments = ref.read(appointmentRepositoryProvider);
    final ok = await confirmDeleteNamed(
      context,
      'l\'appuntamento «${appointment.titolo}»',
    );
    if (!ok) {
      return;
    }
    await appointments?.delete(appointment.id);
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.title,
    required this.onPrev,
    required this.onNext,
  });

  final String title;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: AppText.title,
              fontWeight: FontWeight.w800,
              color: AppColor.ink,
              height: AppDim.lineH,
            ),
          ),
        ),
        const SizedBox(width: AppDim.gapL),
        _MonthNavButton(
          key: CalendarPage.prevKey,
          icon: Icons.chevron_left_rounded,
          onTap: onPrev,
        ),
        const SizedBox(width: AppDim.gapL),
        _MonthNavButton(
          key: CalendarPage.nextKey,
          icon: Icons.chevron_right_rounded,
          onTap: onNext,
        ),
      ],
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  const _MonthNavButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppDim.minTouch,
      height: AppDim.minTouch,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDim.radIconBox),
          child: Icon(icon, size: AppDim.iconNav, color: AppColor.muted),
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.days,
    required this.month,
    required this.today,
    required this.selected,
    required this.events,
    required this.onSelect,
  });

  final List<DateTime> days;
  final DateTime month;
  final DateTime today;
  final DateTime selected;
  final List<CalendarEvent> events;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: CalendarPage.gridKey,
      children: [
        Row(
          children: [
            for (var i = 0; i < calendarWeekdays.length; i++) ...[
              if (i > 0) const SizedBox(width: AppDim.calGap),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDim.calWeekdayPadV,
                  ),
                  child: Text(
                    calendarWeekdays[i],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: AppText.statNote,
                      fontWeight: FontWeight.w700,
                      color: AppColor.muted,
                      height: AppDim.lineH,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppDim.calGap),
        for (var week = 0; week < 6; week++) ...[
          if (week > 0) const SizedBox(height: AppDim.calGap),
          Row(
            children: [
              for (var col = 0; col < 7; col++) ...[
                if (col > 0) const SizedBox(width: AppDim.calGap),
                Expanded(
                  child: _DayCell(
                    index: week * 7 + col,
                    day: days[week * 7 + col],
                    inMonth: days[week * 7 + col].month == month.month,
                    isToday: sameCalendarDay(days[week * 7 + col], today),
                    isSelected: sameCalendarDay(days[week * 7 + col], selected),
                    dots: calendarDotsOn(events, days[week * 7 + col]),
                    onTap: () => onSelect(days[week * 7 + col]),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.index,
    required this.day,
    required this.inMonth,
    required this.isToday,
    required this.isSelected,
    required this.dots,
    required this.onTap,
  });

  final int index;
  final DateTime day;
  final bool inMonth;
  final bool isToday;
  final bool isSelected;
  final Set<CalendarDotKind> dots;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = isToday
        ? AppColor.green
        : (isSelected ? AppColor.greenSoft : null);
    final color = isToday
        ? AppColor.card
        : (inMonth ? AppColor.ink2 : AppColor.faint);
    return SizedBox(
      key: CalendarPage.cellKey(index),
      height: AppDim.minTouch,
      child: Material(
        key: isToday ? CalendarPage.todayKey : null,
        color: fill,
        type: fill == null ? MaterialType.transparency : MaterialType.canvas,
        borderRadius: BorderRadius.circular(AppDim.calDayR),
        child: InkWell(
          key: CalendarPage.dayKey(day),
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDim.calDayR),
          child: Stack(
            children: [
              Center(
                child: Text(
                  '${day.day}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: AppText.segmented,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                    height: AppDim.lineH,
                  ),
                ),
              ),
              if (dots.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: AppDim.calDotBottom,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (dots.contains(CalendarDotKind.affido))
                        const _EventDot(AppColor.orange),
                      if (dots.contains(CalendarDotKind.affido) &&
                          dots.contains(CalendarDotKind.vet))
                        const SizedBox(width: AppDim.gapHair),
                      if (dots.contains(CalendarDotKind.vet))
                        const _EventDot(AppColor.blue),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventDot extends StatelessWidget {
  const _EventDot(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDim.calDot,
      height: AppDim.calDot,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: AppDim.gapL,
      runSpacing: AppDim.gapXs,
      children: [
        _LegendItem(color: AppColor.orange, label: 'Adozioni/affidi'),
        _LegendItem(color: AppColor.blue, label: 'Veterinario'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _EventDot(color),
        const SizedBox(width: AppDim.gapS),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: AppText.caption,
            fontWeight: FontWeight.w600,
            color: color,
            height: AppDim.lineH,
          ),
        ),
      ],
    );
  }
}

class _EventDivider extends StatelessWidget {
  const _EventDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppDim.gapS),
      child: SizedBox(
        height: AppDim.gapHair,
        width: double.infinity,
        child: ColoredBox(color: AppColor.line2),
      ),
    );
  }
}

class _DayEventRow extends StatelessWidget {
  const _DayEventRow({
    required this.event,
    required this.canWrite,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final CalendarEvent event;
  final bool canWrite;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final appointment = event.appointment;
    return GestureDetector(
      onTap: onTap,
      onLongPress: canWrite && appointment != null
          ? () => openRecordActions(
              context,
              onEdit: onEdit,
              onDelete: onDelete,
            )
          : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppDim.minTouch),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: AppDim.calTimeW,
              child: Text(
                calendarTimeLabel(event),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: AppText.segmented,
                  fontWeight: FontWeight.w700,
                  color: event.accent,
                  height: AppDim.lineH,
                ),
              ),
            ),
            const SizedBox(width: AppDim.gapS),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: event.accent,
                      width: AppDim.calAccentW,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: AppDim.gapM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
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
                      if (event.subtitle.isNotEmpty)
                        Text(
                          event.subtitle,
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
              ),
            ),
            if (appointment != null)
              RecordMenuButton(
                id: appointment.id,
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

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({required this.event, required this.onTap});

  final CalendarEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppDim.minTouch),
        child: Row(
          children: [
            IconBadge(event.icon, size: IconBadge.inTitle),
            const SizedBox(width: AppDim.gapS),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: formatItalianDayMonth(event.at),
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: AppText.body,
                        fontWeight: FontWeight.w700,
                        color: AppColor.ink,
                        height: AppDim.lineH,
                      ),
                    ),
                    TextSpan(
                      text: ' · ${event.title}',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: AppText.body,
                        fontWeight: FontWeight.w500,
                        color: AppColor.ink,
                        height: AppDim.lineH,
                      ),
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppDim.gapS),
            Text(
              calendarTimeLabel(event),
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
    );
  }
}
