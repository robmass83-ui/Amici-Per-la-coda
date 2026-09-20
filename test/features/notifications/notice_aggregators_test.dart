import 'package:amici_per_la_coda/features/notifications/notice_aggregators.dart';
import 'package:amici_per_la_coda/ui/tokens.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dog_fixtures.dart';

void main() {
  final now = DateTime.utc(2026, 9, 8);

  test('una scadenza sanitaria scaduta è urgente e rossa', () {
    final notices = buildNotices(
      dogs: testListDogs(),
      health: [
        testHealth(
          id: 'h-scad',
          dogId: 'fenice',
          prossimaScadenza: DateTime.utc(2026, 8, 1),
        ),
      ],
      appointments: const [],
      adoptions: const [],
      now: now,
    );
    expect(notices, hasLength(1));
    expect(notices.single.id, 'health-h-scad');
    expect(notices.single.severity, NoticeSeverity.urgente);
    expect(notices.single.dogId, 'fenice');
    expect(noticeAccent(notices.single.severity), AppColor.red);
  });

  test('le notifiche si raggruppano per giorno', () {
    final notices = buildNotices(
      dogs: testListDogs(),
      health: [
        testHealth(
          id: 'h-ieri',
          dogId: 'fenice',
          prossimaScadenza: DateTime.utc(2026, 9, 7),
        ),
      ],
      appointments: [
        testAppointment(
          id: 'ap-oggi',
          dogId: 'fenice',
          inizio: DateTime.utc(2026, 9, 8, 10),
        ),
      ],
      adoptions: const [],
      now: now,
    );
    final groups = groupNotices(notices, now);
    expect(groups.map((g) => g.label).toList(), containsAll(['Oggi', 'Ieri']));
  });
}
