import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/date_utils.dart';
import '../core/utils/streak_utils.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';

const _uuid = Uuid();

SupabaseClient? get _supabase {
  try {
    return Supabase.instance.client;
  } catch (_) {
    return null;
  }
}

// =============================================================================
// 1. HABITS NOTIFIER & PROVIDER
// =============================================================================

class HabitsNotifier extends AsyncNotifier<List<Habit>> {
  @override
  Future<List<Habit>> build() async {
    return _fetchHabits();
  }

  Future<List<Habit>> _fetchHabits() async {
    final client = _supabase;
    if (client == null) return [];

    final user = client.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await client
          .from('habits')
          .select()
          .order('created_at', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => Habit.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('HabitsNotifier._fetchHabits error: $e');
      return [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchHabits());
  }

  Future<Habit> createHabit(String title) async {
    final client = _supabase;
    final user = client?.auth.currentUser;
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Habit title cannot be empty');
    }

    final newHabit = Habit(
      id: _uuid.v4(),
      userId: user?.id ?? 'test_user',
      title: trimmed,
      createdAt: DateTime.now(),
    );

    final current = state.value ?? [];
    state = AsyncData([...current, newHabit]);

    if (client != null && user != null) {
      try {
        await client.from('habits').insert({
          'id': newHabit.id,
          'user_id': newHabit.userId,
          'title': newHabit.title,
          'created_at': newHabit.createdAt.toIso8601String(),
        });
      } catch (e) {
        state = AsyncData(current);
        debugPrint('createHabit error: $e');
        rethrow;
      }
    }

    return newHabit;
  }

  Future<void> deleteHabit(String habitId) async {
    final client = _supabase;
    final current = state.value ?? [];
    final updated = current.where((h) => h.id != habitId).toList();
    state = AsyncData(updated);

    // Also remove logs for this habit optimistically
    ref.read(habitLogsProvider.notifier).removeLogsForHabit(habitId);

    if (client != null) {
      try {
        await client.from('habits').delete().eq('id', habitId);
      } catch (e) {
        state = AsyncData(current);
        debugPrint('deleteHabit error: $e');
        rethrow;
      }
    }
  }
}

final habitsProvider = AsyncNotifierProvider<HabitsNotifier, List<Habit>>(() {
  return HabitsNotifier();
});

// =============================================================================
// 2. HABIT LOGS NOTIFIER & PROVIDER
// =============================================================================

class HabitLogsNotifier extends AsyncNotifier<List<HabitLog>> {
  @override
  Future<List<HabitLog>> build() async {
    return _fetchLogs();
  }

  Future<List<HabitLog>> _fetchLogs() async {
    final client = _supabase;
    if (client == null) return [];

    final user = client.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await client
          .from('habit_logs')
          .select()
          .order('log_date', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => HabitLog.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('HabitLogsNotifier._fetchLogs error: $e');
      return [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchLogs());
  }

  void removeLogsForHabit(String habitId) {
    final current = state.value ?? [];
    final filtered = current.where((log) => log.habitId != habitId).toList();
    state = AsyncData(filtered);
  }

  /// Toggles today's log for the given habit.
  Future<void> toggleToday(String habitId) async {
    await toggleDate(habitId, AppDateUtils.today());
  }

  /// Toggles log for a specific date (past or today only).
  /// Future dates are ignored.
  /// Uses upsert with ignore-duplicates or delete against UNIQUE(habit_id, log_date).
  Future<void> toggleDate(String habitId, DateTime date) async {
    final dDate = AppDateUtils.dateOnly(date);
    final dToday = AppDateUtils.today();

    // Cannot log future dates
    if (dDate.isAfter(dToday)) return;

    final client = _supabase;
    final user = client?.auth.currentUser;
    final dateStr = AppDateUtils.formatDbDate(dDate);

    final currentLogs = state.value ?? [];
    final existingIndex = currentLogs.indexWhere(
      (l) => l.habitId == habitId && AppDateUtils.dateOnly(l.logDate) == dDate,
    );

    if (existingIndex != -1) {
      // Currently logged -> DELETE log
      final updatedLogs = List<HabitLog>.from(currentLogs)..removeAt(existingIndex);
      state = AsyncData(updatedLogs);

      if (client != null && user != null) {
        try {
          await client
              .from('habit_logs')
              .delete()
              .eq('habit_id', habitId)
              .eq('log_date', dateStr);
        } catch (e) {
          state = AsyncData(currentLogs);
          debugPrint('toggleDate delete error: $e');
          rethrow;
        }
      }
    } else {
      // Currently unlogged -> INSERT log
      final newLog = HabitLog(
        id: _uuid.v4(),
        userId: user?.id ?? 'test_user',
        habitId: habitId,
        logDate: dDate,
      );

      final updatedLogs = List<HabitLog>.from(currentLogs)..add(newLog);
      state = AsyncData(updatedLogs);

      if (client != null && user != null) {
        try {
          await client.from('habit_logs').upsert(
            {
              'id': newLog.id,
              'user_id': newLog.userId,
              'habit_id': newLog.habitId,
              'log_date': dateStr,
            },
            onConflict: 'habit_id,log_date',
            ignoreDuplicates: true,
          );
        } catch (e) {
          state = AsyncData(currentLogs);
          debugPrint('toggleDate insert error: $e');
          rethrow;
        }
      }
    }
  }
}

final habitLogsProvider = AsyncNotifierProvider<HabitLogsNotifier, List<HabitLog>>(() {
  return HabitLogsNotifier();
});

// =============================================================================
// 3. HABIT LOGS MAP PROVIDER
// habitId -> Set of normalized date-only log dates
// =============================================================================

final habitLogsMapProvider = Provider<Map<String, Set<DateTime>>>((ref) {
  final logsAsync = ref.watch(habitLogsProvider);
  final logs = logsAsync.value ?? [];
  final map = <String, Set<DateTime>>{};

  for (final log in logs) {
    map.putIfAbsent(log.habitId, () => <DateTime>{}).add(AppDateUtils.dateOnly(log.logDate));
  }

  return map;
});

// =============================================================================
// 4. HABIT STREAK PROVIDER (family by habitId)
// =============================================================================

final habitStreakProvider = Provider.family<int, String>((ref, habitId) {
  final logsMap = ref.watch(habitLogsMapProvider);
  final logged = logsMap[habitId] ?? <DateTime>{};
  return StreakUtils.currentStreak(logged, AppDateUtils.today());
});

// =============================================================================
// 5. SELECTED WEEK START PROVIDER (Weekly Report navigation)
// =============================================================================

class SelectedWeekStartNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    return AppDateUtils.startOfWeek(AppDateUtils.today());
  }

  void previousWeek() {
    state = state.subtract(const Duration(days: 7));
  }

  void nextWeek() {
    final next = state.add(const Duration(days: 7));
    final currentWeek = AppDateUtils.startOfWeek(AppDateUtils.today());
    // Cannot navigate into the future
    if (!next.isAfter(currentWeek)) {
      state = next;
    }
  }

  void resetToCurrent() {
    state = AppDateUtils.startOfWeek(AppDateUtils.today());
  }
}

final selectedWeekStartProvider = NotifierProvider<SelectedWeekStartNotifier, DateTime>(() {
  return SelectedWeekStartNotifier();
});

// =============================================================================
// 6. MONTHLY REALITY REPORT PROVIDER
// Aggregated stats for current month across all habits
// =============================================================================

final monthlyRealityReportProvider = Provider<MonthStats>((ref) {
  final habits = ref.watch(habitsProvider).value ?? [];
  final logsMap = ref.watch(habitLogsMapProvider);
  final today = AppDateUtils.today();
  final monthStart = DateTime(today.year, today.month, 1);

  if (habits.isEmpty) {
    return const MonthStats(
      completions: 0,
      eligibleDays: 0,
      missedDays: 0,
      rebounds: 0,
      percentage: 0.0,
    );
  }

  int totalCompletions = 0;
  int totalMissed = 0;
  int totalRebounds = 0;
  int totalEligible = 0;

  for (final habit in habits) {
    final logged = logsMap[habit.id] ?? <DateTime>{};
    final stats = StreakUtils.monthStats(
      logged: logged,
      monthStart: monthStart,
      today: today,
      createdDate: habit.createdAt,
    );
    totalCompletions += stats.completions;
    totalMissed += stats.missedDays;
    totalRebounds += stats.rebounds;
    totalEligible += stats.eligibleDays;
  }

  final percentage = totalEligible > 0 ? (totalCompletions / totalEligible) * 100.0 : 0.0;

  return MonthStats(
    completions: totalCompletions,
    eligibleDays: totalEligible,
    missedDays: totalMissed,
    rebounds: totalRebounds,
    percentage: percentage,
  );
});

// =============================================================================
// 7. WEEKLY HABIT STATS PROVIDER & DATA CLASS
// =============================================================================

@immutable
class WeeklyHabitReportData {
  final Habit habit;
  final WeekStats stats;
  final int? prevWeekCompletions;
  final int? diff;
  final String comparisonText;
  final int currentStreak;

  const WeeklyHabitReportData({
    required this.habit,
    required this.stats,
    required this.prevWeekCompletions,
    required this.diff,
    required this.comparisonText,
    required this.currentStreak,
  });
}

final weeklyHabitStatsProvider = Provider.family<WeeklyHabitReportData?, String>((ref, habitId) {
  final habits = ref.watch(habitsProvider).value ?? [];
  final habitIndex = habits.indexWhere((h) => h.id == habitId);
  if (habitIndex == -1) return null;

  final habit = habits[habitIndex];
  final logsMap = ref.watch(habitLogsMapProvider);
  final logged = logsMap[habitId] ?? <DateTime>{};
  final today = AppDateUtils.today();
  final weekStart = ref.watch(selectedWeekStartProvider);

  final stats = StreakUtils.weekStats(
    logged: logged,
    weekStart: weekStart,
    today: today,
    createdDate: habit.createdAt,
  );

  final streak = StreakUtils.currentStreak(logged, today);

  // Check previous week
  final prevWeekStart = weekStart.subtract(const Duration(days: 7));
  final prevWeekEnd = prevWeekStart.add(const Duration(days: 6));
  final createdDateOnly = AppDateUtils.dateOnly(habit.createdAt);

  int? prevCompletions;
  int? diff;
  String comparisonText = '';

  // Only compare if habit existed during previous week (i.e. created on or before prevWeekEnd)
  if (!createdDateOnly.isAfter(prevWeekEnd)) {
    final prevStats = StreakUtils.weekStats(
      logged: logged,
      weekStart: prevWeekStart,
      today: today,
      createdDate: habit.createdAt,
    );
    prevCompletions = prevStats.completions;
    diff = stats.completions - prevCompletions;

    if (diff > 0) {
      comparisonText = '+$diff vs last week';
    } else if (diff < 0) {
      comparisonText = '$diff vs last week';
    } else {
      comparisonText = 'same';
    }
  }

  return WeeklyHabitReportData(
    habit: habit,
    stats: stats,
    prevWeekCompletions: prevCompletions,
    diff: diff,
    comparisonText: comparisonText,
    currentStreak: streak,
  );
});

// =============================================================================
// 8. OVERALL WEEKLY SUMMARY PROVIDER
// =============================================================================

@immutable
class OverallWeeklySummary {
  final int totalCompletions;
  final Habit? bestHabit;
  final int bestHabitCompletions;
  final Habit? weakestHabit;
  final int weakestHabitCompletions;
  final bool hasHabitsThisWeek;

  const OverallWeeklySummary({
    required this.totalCompletions,
    this.bestHabit,
    this.bestHabitCompletions = 0,
    this.weakestHabit,
    this.weakestHabitCompletions = 0,
    this.hasHabitsThisWeek = false,
  });
}

final overallWeeklySummaryProvider = Provider<OverallWeeklySummary>((ref) {
  final habits = ref.watch(habitsProvider).value ?? [];
  final logsMap = ref.watch(habitLogsMapProvider);
  final weekStart = ref.watch(selectedWeekStartProvider);
  final weekEnd = weekStart.add(const Duration(days: 6));
  final today = AppDateUtils.today();

  if (habits.isEmpty) {
    return const OverallWeeklySummary(totalCompletions: 0);
  }

  // Filter habits that existed during or before this week
  final activeHabits = habits.where((h) {
    final created = AppDateUtils.dateOnly(h.createdAt);
    return !created.isAfter(weekEnd);
  }).toList();

  if (activeHabits.isEmpty) {
    return const OverallWeeklySummary(totalCompletions: 0, hasHabitsThisWeek: false);
  }

  int totalCompletions = 0;
  Habit? best;
  int bestCount = -1;
  Habit? weakest;
  int weakestCount = 999999;

  for (final habit in activeHabits) {
    final logged = logsMap[habit.id] ?? <DateTime>{};
    final stats = StreakUtils.weekStats(
      logged: logged,
      weekStart: weekStart,
      today: today,
      createdDate: habit.createdAt,
    );

    totalCompletions += stats.completions;

    if (stats.completions > bestCount) {
      bestCount = stats.completions;
      best = habit;
    }

    if (stats.completions < weakestCount) {
      weakestCount = stats.completions;
      weakest = habit;
    }
  }

  return OverallWeeklySummary(
    totalCompletions: totalCompletions,
    bestHabit: best,
    bestHabitCompletions: bestCount >= 0 ? bestCount : 0,
    weakestHabit: weakest,
    weakestHabitCompletions: weakestCount < 999999 ? weakestCount : 0,
    hasHabitsThisWeek: true,
  );
});
