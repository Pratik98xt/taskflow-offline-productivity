import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      tz_data.initializeTimeZones();

      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      const initializationSettings = InitializationSettings(
        android: androidSettings,
      );

      await _notifications.initialize(settings: initializationSettings);

      await requestPermission();
    } catch (e) {
      debugPrint('Notification initialization failed: $e');
    }
  }

  static Future<void> cancelTaskNotification(int taskId) async {
    try {
      await _notifications.cancel(id: taskId);
    } catch (e) {
      debugPrint('Notification cancellation failed: $e');
    }
  }

  static Future<void> requestPermission() async {
    try {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await androidImplementation?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Notification permission error: $e');
    }
  }

  static Future<void> scheduleTaskNotification({
    required int taskId,
    required String title,
    required DateTime dueDate,
  }) async {
    try {
      if (dueDate.isBefore(DateTime.now())) return;

      final scheduledDate = tz.TZDateTime.from(dueDate, tz.local);

      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'task_deadlines',
          'Task Deadlines',
          channelDescription: 'Reminders for upcoming task deadlines',
          importance: Importance.max,
          priority: Priority.high,
        ),
      );

      await _notifications.zonedSchedule(
        id: taskId,
        title: 'Task Deadline Reminder',
        body: 'Your task "$title" is due now.',
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Notification scheduling failed: $e');
    }
  }
}
