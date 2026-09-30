import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:christmas_buddy/src/countdown/christmas_countdown.dart';
import 'package:christmas_buddy/src/settings/app_settings.dart';

/// One notification each December morning with the sleeps left. All 25 are
/// scheduled up front, so the app does not need to run in the background.
class ReminderScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  Future<void>? _pending;

  Future<void> _init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint('Could not read the local timezone: $e');
    }
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  /// Asks for permission where the platform needs it. Returns true when
  /// notifications may be shown.
  Future<bool> requestPermission() async {
    try {
      await _init();
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? true;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? true;
      }
      return true;
    } catch (e) {
      debugPrint('Notification permission failed: $e');
      return false;
    }
  }

  /// Reschedules everything from the current settings. Safe to call often;
  /// calls are serialised.
  Future<void> sync(AppSettings settings) {
    final previous = _pending ?? Future.value();
    return _pending = previous.then((_) => _sync(settings)).catchError((Object e) {
      debugPrint('Reminder sync failed: $e');
    });
  }

  Future<void> _sync(AppSettings settings) async {
    await _init();
    await _plugin.cancelAll();
    if (!settings.reminderOn) return;

    final countdown = ChristmasCountdown(christmasDay: settings.christmasDay);
    final now = tz.TZDateTime.now(tz.local);
    final year = (now.month == 12 && now.day >= 26) ? now.year + 1 : now.year;

    for (var day = 1; day <= 25; day++) {
      final when = tz.TZDateTime(tz.local, year, 12, day, settings.reminderHour, settings.reminderMinute);
      if (!when.isAfter(now)) continue;
      final date = DateTime(year, 12, day);
      final String body;
      if (countdown.isChristmas(date)) {
        body = 'Merry Christmas from Pip and everyone at the North Pole!';
      } else {
        final sleeps = countdown.sleeps(date);
        body = sleeps == 1
            ? 'One more sleep until Christmas! Pip is hiding somewhere new.'
            : '$sleeps sleeps until Christmas. Pip has found a new hiding spot!';
      }
      await _plugin.zonedSchedule(
        day,
        'Christmas Buddy',
        body,
        when,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminder',
            'Daily reminder',
            channelDescription: 'One note each December morning',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
