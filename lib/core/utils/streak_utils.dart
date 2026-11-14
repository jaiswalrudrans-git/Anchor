import 'package:flutter/foundation.dart';
import '../../models/habit.dart';
import 'date_utils.dart';

/// Pure data structure representing weekly habit statistics.
@immutable
class WeekStats {
  final int completions;
  final int eligibleDays;
  final int missed;
  final int rebounds;
  final double percentage;

  const WeekStats({
    required this.completions,
    required this.eligibleDays,
    required this.missed,
    required this.rebounds,
    required this.percentage,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeekStats &&
          runtimeType == other.runtimeType &&
          completions == other.completions &&
          eligibleDays == other.eligibleDays &&
          missed == other.missed &&
          rebounds == other.rebounds &&
          percentage == other.percentage;

  @override
  int get hashCode =>
      completions.hashCode ^
      eligibleDays.hashCode ^
      missed.hashCode ^
      rebounds.hashCode ^
      percentage.hashCode;
}

/// Pure data structure representing monthly habit statistics (for Reality Report Card).
@immutable
class MonthStats {
  final int completions;
  final int eligibleDays;
  final int missedDays;
  final int rebounds;
  final double percentage;

  const MonthStats({
    required this.completions,
    required this.eligibleDays,
    required this.missedDays,
    required this.rebounds,
    required this.percentage,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthStats &&
          runtimeType == other.runtimeType &&
          completions == other.completions &&
          eligibleDays == other.eligibleDays &&
          missedDays == other.missedDays &&
          rebounds == other.rebounds &&
          percentage == other.percentage;

  @override
  int get hashCode =>
      completions.hashCode ^
      eligibleDays.hashCode ^
      missedDays.hashCode ^
      rebounds.hashCode ^
      percentage.hashCode;
}

/// Status of a day cell in the habit matrix or weekly strip.
enum HabitDayStatus {
  completed,     // Solid #111111
  incomplete,    // Past or today with no log (outlined / interactive)
  future,        // Days after today (subtle #A1A1AA, inert)
  notApplicable, // Before habit creation date (subtle muted, inert)
}

/// Pure utility calculations for streaks, missed days, rebounds, and reports.
/// All methods take normalized date-only inputs and never read the clock themselves.
class StreakUtils {
  StreakUtils._();

  /// Calculates the current consecutive streak (in days).
  /// - Consecutive days ending today if today is logged;
  /// - Otherwise ending yesterday if yesterday is logged (an unlogged today does not zero the streak until the day is over);
  /// - If neither today nor yesterday is logged, streak is 0.
  static int currentStreak(Set<DateTime> logged, DateTime today) {
    if (logged.isEmpty) return 0;

    final normalizedSet = logged.map(AppDateUtils.dateOnly).toSet();
    final dToday = AppDateUtils.dateOnly(today);
    final dYesterday = dToday.subtract(const Duration(days: 1));

    DateTime cursor;
    if (normalizedSet.contains(dToday)) {
      cursor = dToday;
    } else if (normalizedSet.contains(dYesterday)) {
      cursor = dYesterday;
    } else {
      return 0;
    }

    int streak = 0;
    while (normalizedSet.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Calculates the number of missed days in [start, end] on or after [createdDate].
  /// Missed days = days in [max(start, createdDate), end] with no log.
  static int missedDays({
    required Set<DateTime> logged,
    required DateTime start,
    required DateTime end,
    required DateTime createdDate,
  }) {
    final dStart = AppDateUtils.dateOnly(start);
    final dEnd = AppDateUtils.dateOnly(end);
    final dCreated = AppDateUtils.dateOnly(createdDate);

    final effectiveStart = dStart.isAfter(dCreated) ? dStart : dCreated;
    if (effectiveStart.isAfter(dEnd)) return 0;

    final normalizedSet = logged.map(AppDateUtils.dateOnly).toSet();
    int missed = 0;
    DateTime cursor = effectiveStart;

    while (!cursor.isAfter(dEnd)) {
      if (!normalizedSet.contains(cursor)) {
        missed++;
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return missed;
  }

  /// Calculates rebounds in [start, end]:
  /// A rebound occurs on day D if:
  /// - D is within [start, end]
  /// - D >= createdDate and (D - 1) >= createdDate
  /// - D is logged, but (D - 1) was missed (not logged)
  static int rebounds({
    required Set<DateTime> logged,
    required DateTime start,
    required DateTime end,
    required DateTime createdDate,
  }) {
    final dStart = AppDateUtils.dateOnly(start);
    final dEnd = AppDateUtils.dateOnly(end);
    final dCreated = AppDateUtils.dateOnly(createdDate);

    // Both D and D - 1 must be within [start, end] and on/after createdDate.
    // Therefore, D - 1 >= max(start, createdDate), which means D >= max(start, createdDate) + 1 day.
    final effectiveBase = dStart.isAfter(dCreated) ? dStart : dCreated;
    final effectiveStart = effectiveBase.add(const Duration(days: 1));
    if (effectiveStart.isAfter(dEnd)) return 0;

    final normalizedSet = logged.map(AppDateUtils.dateOnly).toSet();
    int reboundCount = 0;
    DateTime cursor = effectiveStart;

    while (!cursor.isAfter(dEnd)) {
      final prevDay = cursor.subtract(const Duration(days: 1));
      if (normalizedSet.contains(cursor) && !normalizedSet.contains(prevDay)) {
        reboundCount++;
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return reboundCount;
  }

  /// Calculates week statistics for a habit:
  /// - [weekStart]: Monday of the week
  /// - [today]: Current date
  /// - [createdDate]: Habit creation date
  /// Eligible days are only days from max(weekStart, createdDate) through min(weekEnd, today).
  static WeekStats weekStats({
    required Set<DateTime> logged,
    required DateTime weekStart,
    required DateTime today,
    required DateTime createdDate,
  }) {
    final dWeekStart = AppDateUtils.dateOnly(weekStart);
    final dWeekEnd = dWeekStart.add(const Duration(days: 6));
    final dToday = AppDateUtils.dateOnly(today);
    final dCreated = AppDateUtils.dateOnly(createdDate);

    final effectiveStart = dWeekStart.isAfter(dCreated) ? dWeekStart : dCreated;
    final effectiveEnd = dWeekEnd.isBefore(dToday) ? dWeekEnd : dToday;

    if (effectiveStart.isAfter(effectiveEnd)) {
      return const WeekStats(
        completions: 0,
        eligibleDays: 0,
        missed: 0,
        rebounds: 0,
        percentage: 0.0,
      );
    }

    final normalizedSet = logged.map(AppDateUtils.dateOnly).toSet();
    int completions = 0;
    int eligibleDays = 0;
    DateTime cursor = effectiveStart;

    while (!cursor.isAfter(effectiveEnd)) {
      eligibleDays++;
      if (normalizedSet.contains(cursor)) {
        completions++;
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    final missed = eligibleDays - completions;
    final r = rebounds(
      logged: logged,
      start: effectiveStart,
      end: effectiveEnd,
      createdDate: createdDate,
    );
    final percentage = eligibleDays > 0 ? (completions / eligibleDays) * 100.0 : 0.0;

    return WeekStats(
      completions: completions,
      eligibleDays: eligibleDays,
      missed: missed,
      rebounds: r,
      percentage: percentage,
    );
  }

  /// Calculates monthly statistics for the Reality Report Card:
  /// - completions: count of logged days in the calendar month
  /// - missedDays: days from max(1st of month, createdDate) through yesterday with no log
  /// - rebounds: rebounds within the month on/after creation
  static MonthStats monthStats({
    required Set<DateTime> logged,
    required DateTime monthStart,
    required DateTime today,
    required DateTime createdDate,
  }) {
    final dMonthStart = AppDateUtils.dateOnly(monthStart);
    final dToday = AppDateUtils.dateOnly(today);
    final dCreated = AppDateUtils.dateOnly(createdDate);

    // End of the month (e.g. 28, 29, 30, or 31)
    final nextMonthFirst = DateTime(dMonthStart.year, dMonthStart.month + 1, 1);
    final dMonthEnd = nextMonthFirst.subtract(const Duration(days: 1));

    final normalizedSet = logged.map(AppDateUtils.dateOnly).toSet();

    // 1. Total completions in this month
    int completions = 0;
    DateTime cursor = dMonthStart;
    while (!cursor.isAfter(dMonthEnd)) {
      if (normalizedSet.contains(cursor)) {
        completions++;
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    // 2. Missed days through yesterday (since today is not over yet)
    final dYesterday = dToday.subtract(const Duration(days: 1));
    final missedEnd = dYesterday.isBefore(dMonthEnd) ? dYesterday : dMonthEnd;
    final missedStart = dMonthStart.isAfter(dCreated) ? dMonthStart : dCreated;

    int missed = 0;
    if (!missedStart.isAfter(missedEnd)) {
      DateTime mCursor = missedStart;
      while (!mCursor.isAfter(missedEnd)) {
        if (!normalizedSet.contains(mCursor)) {
          missed++;
        }
        mCursor = mCursor.add(const Duration(days: 1));
      }
    }

    // 3. Rebounds in this month
    final r = rebounds(
      logged: logged,
      start: dMonthStart,
      end: dMonthEnd,
      createdDate: createdDate,
    );

    // 4. Eligible days from creation through today or month end
    final eligibleEnd = dToday.isBefore(dMonthEnd) ? dToday : dMonthEnd;
    final eligibleStart = dMonthStart.isAfter(dCreated) ? dMonthStart : dCreated;
    final eligibleDays = eligibleStart.isAfter(eligibleEnd)
        ? 0
        : eligibleEnd.difference(eligibleStart).inDays + 1;

    final percentage = eligibleDays > 0 ? (completions / eligibleDays) * 100.0 : 0.0;

    return MonthStats(
      completions: completions,
      eligibleDays: eligibleDays,
      missedDays: missed,
      rebounds: r,
      percentage: percentage,
    );
  }

  /// Resolves the visual/interactive status for a specific date cell.
  static HabitDayStatus dayStatus({
    required DateTime date,
    required DateTime today,
    required DateTime createdDate,
    required bool isLogged,
  }) {
    final dDate = AppDateUtils.dateOnly(date);
    final dToday = AppDateUtils.dateOnly(today);
    final dCreated = AppDateUtils.dateOnly(createdDate);

    if (dDate.isBefore(dCreated)) {
      return HabitDayStatus.notApplicable;
    }
    if (dDate.isAfter(dToday)) {
      return HabitDayStatus.future;
    }
    return isLogged ? HabitDayStatus.completed : HabitDayStatus.incomplete;
  }

  /// Computes weekly completion percentage series for the [weeks] (default 6) ending with [weekStart].
  /// Weeks before [createdDate] where eligibleDays == 0 are skipped.
  static List<double> weeklyCompletionSeries({
    required Set<DateTime> logged,
    required DateTime weekStart,
    int weeks = 6,
    required DateTime today,
    required DateTime createdDate,
  }) {
    final result = <double>[];
    final dWeekStart = AppDateUtils.dateOnly(weekStart);

    for (int i = weeks - 1; i >= 0; i--) {
      final wStart = dWeekStart.subtract(Duration(days: i * 7));
      final stats = weekStats(
        logged: logged,
        weekStart: wStart,
        today: today,
        createdDate: createdDate,
      );
      if (stats.eligibleDays > 0) {
        result.add(stats.percentage);
      }
    }
    return result;
  }

  /// Computes the completion fraction (0.0 to 1.0) for each of the 7 days (Mon-Sun) of [weekStart].
  /// - For each day D: completed habits / eligible habits on day D.
  /// - Days after [today] or days with 0 eligible habits return 0.0.
  static List<double> dailyCompletionFractions({
    required List<Habit> habits,
    required Map<String, Set<DateTime>> habitLogsMap,
    required DateTime weekStart,
    required DateTime today,
  }) {
    final dWeekStart = AppDateUtils.dateOnly(weekStart);
    final dToday = AppDateUtils.dateOnly(today);
    final fractions = <double>[];

    for (int i = 0; i < 7; i++) {
      final day = dWeekStart.add(Duration(days: i));
      if (day.isAfter(dToday)) {
        fractions.add(0.0);
        continue;
      }

      int eligibleCount = 0;
      int completedCount = 0;

      for (final habit in habits) {
        final dCreated = AppDateUtils.dateOnly(habit.createdAt);
        if (!day.isBefore(dCreated)) {
          eligibleCount++;
          final logs = habitLogsMap[habit.id] ?? {};
          if (logs.any((l) => AppDateUtils.dateOnly(l) == day)) {
            completedCount++;
          }
        }
      }

      fractions.add(eligibleCount > 0 ? (completedCount / eligibleCount) : 0.0);
    }
    return fractions;
  }

  /// Counts how many days in the week [weekStart, min(weekEnd, today)] had all eligible habits completed.
  /// Requires eligible habits > 0 on that day.
  static int perfectDays({
    required List<Habit> habits,
    required Map<String, Set<DateTime>> habitLogsMap,
    required DateTime weekStart,
    required DateTime today,
  }) {
    final dWeekStart = AppDateUtils.dateOnly(weekStart);
    final dToday = AppDateUtils.dateOnly(today);
    int count = 0;

    for (int i = 0; i < 7; i++) {
      final day = dWeekStart.add(Duration(days: i));
      if (day.isAfter(dToday)) break;

      int eligibleCount = 0;
      int completedCount = 0;

      for (final habit in habits) {
        final dCreated = AppDateUtils.dateOnly(habit.createdAt);
        if (!day.isBefore(dCreated)) {
          eligibleCount++;
          final logs = habitLogsMap[habit.id] ?? {};
          if (logs.any((l) => AppDateUtils.dateOnly(l) == day)) {
            completedCount++;
          }
        }
      }

      if (eligibleCount > 0 && completedCount == eligibleCount) {
        count++;
      }
    }
    return count;
  }

  /// Finds the best and weakest day of the week based on completion fraction.
  /// Returns `(bestDay: int?, weakestDay: int?)` (1=Mon .. 7=Sun) or null if fewer than 3 eligible days.
  /// Ties show the earliest day.
  static ({int? bestDay, int? weakestDay})? bestAndWeakestDay({
    required List<Habit> habits,
    required Map<String, Set<DateTime>> habitLogsMap,
    required DateTime weekStart,
    required DateTime today,
  }) {
    final fractions = dailyCompletionFractions(
      habits: habits,
      habitLogsMap: habitLogsMap,
      weekStart: weekStart,
      today: today,
    );

    final dWeekStart = AppDateUtils.dateOnly(weekStart);
    final dToday = AppDateUtils.dateOnly(today);

    // Count eligible days in the week
    final eligibleDayIndices = <int>[];
    for (int i = 0; i < 7; i++) {
      final day = dWeekStart.add(Duration(days: i));
      if (day.isAfter(dToday)) continue;

      final hasEligibleHabits = habits.any((h) => !day.isBefore(AppDateUtils.dateOnly(h.createdAt)));
      if (hasEligibleHabits) {
        eligibleDayIndices.add(i);
      }
    }

    if (eligibleDayIndices.length < 3) return null;

    int bestIdx = eligibleDayIndices.first;
    int weakestIdx = eligibleDayIndices.first;

    for (final idx in eligibleDayIndices) {
      if (fractions[idx] > fractions[bestIdx]) {
        bestIdx = idx;
      }
      if (fractions[idx] < fractions[weakestIdx]) {
        weakestIdx = idx;
      }
    }

    return (bestDay: bestIdx + 1, weakestDay: weakestIdx + 1);
  }
}
