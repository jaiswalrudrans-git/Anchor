import 'package:intl/intl.dart';

/// Utilities for handling date-only values consistently without timezone shifts.
class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _dbDateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _monthKeyFormat = DateFormat('yyyy-MM');

  /// Returns a [DateTime] with only the year, month, and day (midnight local).
  static DateTime dateOnly(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  /// Returns today's date with time set to midnight local.
  static DateTime today() {
    return dateOnly(DateTime.now());
  }

  /// Formats a [DateTime] to 'yyyy-MM-dd' for database storage.
  static String formatDbDate(DateTime dt) {
    return _dbDateFormat.format(dt);
  }

  /// Parses a 'yyyy-MM-dd' string into a date-only local [DateTime].
  static DateTime parseDbDate(String dateStr) {
    final parts = dateStr.trim().split('-');
    if (parts.length != 3) {
      throw FormatException('Invalid date format (expected yyyy-MM-dd): $dateStr');
    }
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    return DateTime(year, month, day);
  }

  /// Returns the 'YYYY-MM' month key for a given [DateTime].
  static String monthKey(DateTime dt) {
    return _monthKeyFormat.format(dt);
  }

  /// Returns the Monday of the week for the given [DateTime] as a date-only [DateTime].
  /// Dart DateTime.weekday: 1 = Monday, ..., 7 = Sunday.
  static DateTime startOfWeek(DateTime dt) {
    final d = dateOnly(dt);
    final daysToSubtract = d.weekday - DateTime.monday;
    return DateTime(d.year, d.month, d.day - daysToSubtract);
  }

  /// Returns the number of days between [a] and [b] using calendar date-only values.
  /// Result is positive if [b] is after [a], negative if [b] is before [a], 0 if same day.
  /// Immune to DST transitions by calculating UTC midnight difference.
  static int daysBetween(DateTime a, DateTime b) {
    final utcA = DateTime.utc(a.year, a.month, a.day);
    final utcB = DateTime.utc(b.year, b.month, b.day);
    return utcB.difference(utcA).inDays;
  }
}
