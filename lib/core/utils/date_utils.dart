import 'package:intl/intl.dart';

/// Utilities for handling date-only values consistently without timezone shifts.
class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _dbDateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _monthKeyFormat = DateFormat('yyyy-MM');
  static final DateFormat _monthTitleFormat = DateFormat('MMMM yyyy');

  static final NumberFormat _inCurrency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// Formats an amount with Indian Rupee grouping and symbol (e.g. ₹1,23,456.00).
  static String formatCurrency(num amount) {
    return _inCurrency.format(amount);
  }

  /// Returns a [DateTime] with only the year, month, and day (midnight local).
  static DateTime dateOnly(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  /// Returns today's date with time set to midnight local.
  static DateTime today() {
    return dateOnly(DateTime.now());
  }

  /// Returns tomorrow's date with time set to midnight local.
  static DateTime tomorrow() {
    final t = today();
    return DateTime(t.year, t.month, t.day + 1);
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

  /// Parses a 'YYYY-MM' string into a [DateTime] for the 1st of that month.
  static DateTime parseMonthKey(String monthKey) {
    final parts = monthKey.trim().split('-');
    if (parts.length != 2) {
      throw FormatException('Invalid month key (expected yyyy-MM): $monthKey');
    }
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    return DateTime(year, month, 1);
  }

  /// Formats 'YYYY-MM' to a friendly title like 'November 2026'.
  static String formatMonthTitle(String monthKey) {
    final dt = parseMonthKey(monthKey);
    return _monthTitleFormat.format(dt);
  }

  /// Computes the subsequent month key 'YYYY-MM'.
  static String nextMonthKey(String monthKey) {
    final parts = monthKey.trim().split('-');
    int year = int.parse(parts[0]);
    int month = int.parse(parts[1]);
    if (month == 12) {
      year += 1;
      month = 1;
    } else {
      month += 1;
    }
    return '$year-${month.toString().padLeft(2, '0')}';
  }

  /// Computes the previous month key 'YYYY-MM'.
  static String prevMonthKey(String monthKey) {
    final parts = monthKey.trim().split('-');
    int year = int.parse(parts[0]);
    int month = int.parse(parts[1]);
    if (month == 1) {
      year -= 1;
      month = 12;
    } else {
      month -= 1;
    }
    return '$year-${month.toString().padLeft(2, '0')}';
  }

  /// Returns true if monthKey [a] is strictly before monthKey [b] ('YYYY-MM').
  static bool isMonthBefore(String a, String b) {
    return a.compareTo(b) < 0;
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
