import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized || kIsWeb) return;

    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          debugPrint('Notification clicked: ${details.payload}');
        },
      );

      _isInitialized = true;
      debugPrint('Notification Service Initialized Successfully');
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
    }
  }

  /// Helper to get local timezone location safely
  tz.Location _getLocalLocation() {
    try {
      return tz.local;
    } catch (_) {
      return tz.getLocation('Asia/Kolkata'); // Fallback location
    }
  }

  /// Schedules daily notifications for a specific medicine times
  Future<List<int>> scheduleMedicineReminders({
    required String id,
    required String name,
    required String dosage,
    required List<String> times,
    required DateTime startDate,
    required DateTime endDate,
    required int durationDays,
  }) async {
    if (kIsWeb) {
      debugPrint('Web environment: Mock scheduling notifications for $name');
      return times.map((t) => (id.hashCode + t.hashCode).abs() % 100000).toList();
    }

    await init();
    final List<int> scheduledIds = [];

    try {
      final now = DateTime.now();
      final endDateTime = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

      if (now.isAfter(endDateTime)) {
        debugPrint('Medicine expired. Not scheduling notifications.');
        return [];
      }

      // Schedule for each selected time (Morning, Afternoon, Night)
      for (final timeLabel in times) {
        final hour = _getHourForTimeLabel(timeLabel);
        final uniqueId = (id.hashCode + timeLabel.hashCode).abs() % 100000;

        // Schedule for each day within the active duration range
        for (int dayOffset = 0; dayOffset < durationDays; dayOffset++) {
          final targetDay = startDate.add(Duration(days: dayOffset));
          final scheduledDate = DateTime(targetDay.year, targetDay.month, targetDay.day, hour, 0);

          if (scheduledDate.isAfter(now)) {
            final tzScheduledDate = tz.TZDateTime.from(scheduledDate, _getLocalLocation());
            final dailyNotificationId = uniqueId + dayOffset;

            await _localNotifications.zonedSchedule(
              dailyNotificationId,
              'Medicine Reminder 🔔',
              'Time to take your $name ($dosage) - $timeLabel',
              tzScheduledDate,
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'maatricare_medicine_channel',
                  'Medicine Reminders',
                  channelDescription: 'Channel for maternal medicine schedule alerts',
                  importance: Importance.max,
                  priority: Priority.high,
                  playSound: true,
                ),
                iOS: DarwinNotificationDetails(
                  presentAlert: true,
                  presentBadge: true,
                  presentSound: true,
                ),
              ),
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
            );

            scheduledIds.add(dailyNotificationId);
          }
        }
      }

      debugPrint('Scheduled ${scheduledIds.length} reminders for $name');
    } catch (e) {
      debugPrint('Error scheduling notifications: $e');
    }

    return scheduledIds;
  }

  /// Cancels specific notifications
  Future<void> cancelNotifications(List<int> notificationIds) async {
    if (kIsWeb) return;
    await init();
    try {
      for (final id in notificationIds) {
        await _localNotifications.cancel(id);
      }
      debugPrint('Cancelled notifications: $notificationIds');
    } catch (e) {
      debugPrint('Error cancelling notifications: $e');
    }
  }

  int _getHourForTimeLabel(String label) {
    switch (label) {
      case 'Morning':
        return 8; // 8:00 AM
      case 'Afternoon':
        return 14; // 2:00 PM
      case 'Night':
        return 20; // 8:00 PM
      default:
        return 8;
    }
  }
}
