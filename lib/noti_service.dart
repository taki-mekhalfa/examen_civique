import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotiService {
  final notificationPlugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  bool get initialized => _initialized;

  Future<void> initNotification() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const initSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );
    await notificationPlugin.initialize(initSettings);

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        notificationPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    _initialized = true;
  }

  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'weekly_channel',
        'Rappels hebdomadaires',
        channelDescription: 'Notification pour réviser l\'examen civique',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        interruptionLevel: InterruptionLevel.active,
      ),
    );
  }

  Future<void> showNotification(String? title, String? body) async {
    await notificationPlugin.show(24101996, title, body, notificationDetails());
  }

  Future<void> scheduleSaturdayTenAM() async {
    await notificationPlugin.zonedSchedule(
      24101996,
      'C\'est l\'heure de réviser\u00A0!\u00A0🇫🇷',
      'Prépare ton examen civique maintenant.',
      _nextSaturdayTenAM(),
      notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  tz.TZDateTime _nextSaturdayTenAM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      10,
      0,
    );

    while (scheduledDate.weekday != 6 || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> cancelAll() async {
    await notificationPlugin.cancelAll();
  }
}
