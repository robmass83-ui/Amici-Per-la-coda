import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../features/notifications/local_notification_plan.dart';

const romeTimeZone = 'Europe/Rome';
const scadenzeChannelId = 'scadenze';

void initializeNotificationTimeZone() {
  tzdata.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation(romeTimeZone));
}

tz.TZDateTime eightAmInRome(DateTime wall) {
  final rome = tz.getLocation(romeTimeZone);
  return tz.TZDateTime(
    rome,
    wall.year,
    wall.month,
    wall.day,
    wall.hour,
    wall.minute,
  );
}

abstract interface class LocalNotifications {
  Future<void> initialize();
  Future<void> requestPermission();
  Future<void> cancelAll();
  Future<void> scheduleAll(List<PlannedNotification> plan);
}

class NoopLocalNotifications implements LocalNotifications {
  const NoopLocalNotifications();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> requestPermission() async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> scheduleAll(List<PlannedNotification> plan) async {}
}

class RecordingLocalNotifications implements LocalNotifications {
  final scheduled = <PlannedNotification>[];
  var initialized = false;
  var permissionRequested = false;
  var cancelCount = 0;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<void> requestPermission() async {
    permissionRequested = true;
  }

  @override
  Future<void> cancelAll() async {
    cancelCount++;
    scheduled.clear();
  }

  @override
  Future<void> scheduleAll(List<PlannedNotification> plan) async {
    scheduled
      ..clear()
      ..addAll(plan);
  }
}

class PluginLocalNotifications implements LocalNotifications {
  PluginLocalNotifications([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      scadenzeChannelId,
      'Scadenze e preaffidi',
      channelDescription: 'Vaccini, trattamenti e preaffidi in scadenza',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_stat_notify',
    ),
  );

  @override
  Future<void> initialize() async {
    initializeNotificationTimeZone();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_notify'),
      ),
    );
  }

  @override
  Future<void> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<void> scheduleAll(List<PlannedNotification> plan) async {
    await cancelAll();
    for (final item in plan) {
      await _plugin.zonedSchedule(
        id: item.id,
        title: item.title,
        body: item.body,
        scheduledDate: eightAmInRome(item.at),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: item.payload,
        matchDateTimeComponents: switch (item.repeat) {
          LocalNoticeRepeat.none => null,
          LocalNoticeRepeat.daily => DateTimeComponents.time,
          LocalNoticeRepeat.weeklyMonday => DateTimeComponents.dayOfWeekAndTime,
        },
      );
    }
  }
}
