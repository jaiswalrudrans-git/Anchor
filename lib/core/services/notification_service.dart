import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../models/academic_item.dart';
import '../utils/date_utils.dart';

/// Notification service for scheduled academic reminders on Android.
/// On Windows or unsupported platforms, all schedule/cancel calls are safe no-ops.
class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _isInitialized = false;

  static const String academicChannelId = 'anchor_academic_reminders';
  static const String academicChannelName = 'Academic Reminders';
  static const String academicChannelDesc =
      'Reminders for upcoming assignments and exams';

  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _notificationsPlugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Deterministic 31-bit positive int notification ID from UUID.
  static int notificationId(String uuid) {
    return uuid.hashCode & 0x7fffffff;
  }

  /// Pure function: calculates the assignment reminder time (21:00 local on due_date - 1 day).
  /// Returns null if that moment has already passed.
  static DateTime? assignmentReminderTime(DateTime dueDate, [DateTime? now]) {
    final cleanDue = AppDateUtils.dateOnly(dueDate);
    final targetDay = cleanDue.subtract(const Duration(days: 1));
    final reminder = DateTime(targetDay.year, targetDay.month, targetDay.day, 21, 0, 0);

    final current = now ?? DateTime.now();
    if (current.isAfter(reminder)) {
      return null;
    }
    return reminder;
  }

  /// Pure function: calculates the exam reminder time (08:00 local on due_date - 3 days).
  /// Returns null if that moment has already passed.
  static DateTime? examReminderTime(DateTime dueDate, [DateTime? now]) {
    final cleanDue = AppDateUtils.dateOnly(dueDate);
    final targetDay = cleanDue.subtract(const Duration(days: 3));
    final reminder = DateTime(targetDay.year, targetDay.month, targetDay.day, 8, 0, 0);

    final current = now ?? DateTime.now();
    if (current.isAfter(reminder)) {
      return null;
    }
    return reminder;
  }

  /// Whether scheduled notifications are supported on the current platform.
  bool get isSupportedPlatform => !kIsWeb && Platform.isAndroid;

  /// Initializes timezone data and notification plugin. Safe no-op on non-Android.
  Future<void> initialize() async {
    if (!isSupportedPlatform) return;
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
      try {
        final timezoneInfo = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
      } catch (e) {
        debugPrint('NotificationService: local timezone detection fallback: $e');
      }

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);

      await _notificationsPlugin.initialize(settings: initSettings);

      // Create high-importance notification channel
      final androidChannel = AndroidNotificationChannel(
        academicChannelId,
        academicChannelName,
        description: academicChannelDesc,
        importance: Importance.high,
      );

      final androidImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImpl != null) {
        await androidImpl.createNotificationChannel(androidChannel);

        // Request permissions for Android 13+ and exact alarms
        await androidImpl.requestNotificationsPermission();
        await androidImpl.requestExactAlarmsPermission();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService initialization failed: $e');
    }
  }

  /// Schedules a notification for an assignment at 21:00 on (due_date - 1 day).
  /// Safe no-op on Windows/web or if reminder time has already passed.
  Future<void> scheduleAssignment(AcademicItem assignment) async {
    if (!isSupportedPlatform) return;
    if (assignment.isCompleted) {
      await cancelReminder(assignment.id);
      return;
    }

    final reminder = assignmentReminderTime(assignment.dueDate);
    if (reminder == null) {
      await cancelReminder(assignment.id);
      return;
    }

    await initialize();

    final id = notificationId(assignment.id);
    final scheduledDate = tz.TZDateTime.from(reminder, tz.local);

    const androidDetails = AndroidNotificationDetails(
      academicChannelId,
      academicChannelName,
      channelDescription: academicChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: 'Assignment Due Tomorrow',
        body: assignment.title,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      // Fallback to inexact scheduling if exact alarm permission was denied
      try {
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: 'Assignment Due Tomorrow',
          body: assignment.title,
          scheduledDate: scheduledDate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexact,
        );
      } catch (inner) {
        debugPrint('NotificationService: failed to schedule assignment: $inner');
      }
    }
  }

  /// Schedules a notification for an exam at 08:00 on (due_date - 3 days).
  /// Safe no-op on Windows/web or if reminder time has already passed.
  Future<void> scheduleExam(AcademicItem exam) async {
    if (!isSupportedPlatform) return;

    final reminder = examReminderTime(exam.dueDate);
    if (reminder == null) {
      await cancelReminder(exam.id);
      return;
    }

    await initialize();

    final id = notificationId(exam.id);
    final scheduledDate = tz.TZDateTime.from(reminder, tz.local);

    const androidDetails = AndroidNotificationDetails(
      academicChannelId,
      academicChannelName,
      channelDescription: academicChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: 'Exam in 3 Days',
        body: exam.title,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      try {
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: 'Exam in 3 Days',
          body: exam.title,
          scheduledDate: scheduledDate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexact,
        );
      } catch (inner) {
        debugPrint('NotificationService: failed to schedule exam: $inner');
      }
    }
  }

  /// Cancels any scheduled reminder for the specified item UUID.
  Future<void> cancelReminder(String itemId) async {
    if (!isSupportedPlatform) return;
    try {
      await initialize();
      final id = notificationId(itemId);
      await _notificationsPlugin.cancel(id: id);
    } catch (e) {
      debugPrint('NotificationService: cancel reminder error: $e');
    }
  }

  /// Resyncs all notifications on app start (Android only).
  /// Cancels all and reschedules future incomplete assignments and future exams.
  Future<void> resyncAll(List<AcademicItem> items) async {
    if (!isSupportedPlatform) return;

    try {
      await initialize();
      await _notificationsPlugin.cancelAll();

      for (final item in items) {
        if (item.itemType == 'assignment' && !item.isCompleted) {
          await scheduleAssignment(item);
        } else if (item.itemType == 'exam') {
          await scheduleExam(item);
        }
      }
    } catch (e) {
      debugPrint('NotificationService: resyncAll error: $e');
    }
  }
}

/// Provider for the singleton [NotificationService].
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
