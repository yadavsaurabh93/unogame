import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    // Request Android 13+ Permissions
    var androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();

    // Create Notification Channel Explicitly for High Priority
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'uno_channel_high_v1', // New ID to force settings reset
      'UNO High Importance',
      description: 'Critical Game Alerts & Reminders',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    await androidImplementation?.createNotificationChannel(channel);

    // Set correct timezone (Assuming India based on user context, fallback for reliability)
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    } catch (e) {
      debugPrint("Timezone mismatch: $e");
    }

    // Schedule our Mast Reminders
    scheduleDailyReminders();
  }

  static Future<void> scheduleDailyReminders() async {
    // We want 2 notifications per day at different times
    // Notification 1: Morning (11:00 AM)
    await scheduleNotification(
      id: 101,
      title: "UNO GOD: CHALLENGE ALERT! 🃏",
      body: "Bhai, UNO ki yaad aa rahi hai? Chalo ek game ho jaye! 🔥",
      hour: 11,
      minute: 0,
    );

    // Notification 2: Evening (7:30 PM)
    await scheduleNotification(
      id: 102,
      title: "GOD PULSE CALLING... 👑",
      body: "Sab wait kar rahe hain! UNO God banne ka time aa gaya hai. 🦾",
      hour: 19,
      minute: 30,
    );
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'uno_channel_high_v1',
          'UNO Reminders',
          channelDescription: 'Notifications to remind you to play UNO',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        ),
      ),
      // Use 'inexactAllowWhileIdle' (Confirmed working on CPH2617)
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // matchDateTimeComponents: DateTimeComponents.time, // REMOVED to fix Exact Alarm issue
    );
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
