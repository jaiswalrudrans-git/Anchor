import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/streak_utils.dart';
import '../../../models/habit.dart';
import '../../../providers/habits_providers.dart';
import '../../../widgets/empty_state.dart';

/// Weekly Report Tab displaying per-habit weekly performance cards,
/// 7-cell Mon–Sun strips, rebounds, week-over-week comparisons,
/// and an overall weekly summary.
class WeeklyReportTab extends ConsumerWidget {
  const WeeklyReportTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);

    return habitsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryText),
        ),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text('Error loading habits: $err', style: const TextStyle(color: AppColors.primaryText)),
        ),
      ),
      data: (habits) {
        if (habits.isEmpty) {
          return const EmptyState(
            icon: Icons.repeat_outlined,
            title: 'No habits yet',
            message: 'Create a habit to view detailed weekly consistency reports.',
          );
        }

        final weekStart = ref.watch(selectedWeekStartProvider);
        final weekEnd = weekStart.add(const Duration(days: 6));
        final today = AppDateUtils.today();
        final currentWeekStart = AppDateUtils.startOfWeek(today);
        final canGoForward = weekStart.isBefore(currentWeekStart);

        final summary = ref.watch(overallWeeklySummaryProvider);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Week Navigator
              _buildWeekNavigator(
                context: context,
                ref: ref,
                weekStart: weekStart,
                weekEnd: weekEnd,
                canGoForward: canGoForward,
              ),
              const SizedBox(height: 16),

              // If no habits existed during this selected week
              if (!summary.hasHabitsThisWeek) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: EmptyState(
                    icon: Icons.history,
                    title: 'No habits existed',
                    message: 'No habits were active during this week.\nUse the navigator above to view more recent weeks.',
                  ),
                ),
              ] else ...[
                // 2. Per-Habit Weekly Report Cards
                ...habits.where((h) {
                  final createdDate = AppDateUtils.dateOnly(h.createdAt);
                  return !createdDate.isAfter(weekEnd);
                }).map((habit) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildHabitWeeklyCard(
                      context: context,
                      ref: ref,
                      habit: habit,
                      weekStart: weekStart,
                      today: today,
                      isCurrentWeek: weekStart == currentWeekStart,
                    ),
                  );
                }),

                const SizedBox(height: 12),

                // 3. Overall Weekly Summary
                _buildOverallSummaryCard(summary: summary),

                const SizedBox(height: 32),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeekNavigator({
    required BuildContext context,
    required WidgetRef ref,
    required DateTime weekStart,
    required DateTime weekEnd,
    required bool canGoForward,
  }) {
    final startStr = DateFormat('d MMM').format(weekStart);
    final endStr = DateFormat('d MMM yyyy').format(weekEnd);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTheme.borderRadius8,
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            key: const Key('weekly_prev_week_button'),
            icon: const Icon(Icons.chevron_left, size: 22),
            color: AppColors.primaryText,
            tooltip: 'Previous week',
            onPressed: () {
              ref.read(selectedWeekStartProvider.notifier).previousWeek();
            },
          ),
          Text(
            'Week of $startStr – $endStr',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
              letterSpacing: -0.2,
            ),
          ),
          IconButton(
            key: const Key('weekly_next_week_button'),
            icon: const Icon(Icons.chevron_right, size: 22),
            color: canGoForward ? AppColors.primaryText : AppColors.disabled,
            tooltip: canGoForward ? 'Next week' : 'Cannot navigate to future',
            onPressed: canGoForward
                ? () {
                    ref.read(selectedWeekStartProvider.notifier).nextWeek();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildHabitWeeklyCard({
    required BuildContext context,
    required WidgetRef ref,
    required Habit habit,
    required DateTime weekStart,
    required DateTime today,
    required bool isCurrentWeek,
  }) {
    final data = ref.watch(weeklyHabitStatsProvider(habit.id));
    if (data == null) return const SizedBox.shrink();

    final stats = data.stats;
    final completionsText = isCurrentWeek
        ? '${stats.completions} / ${stats.eligibleDays} days so far'
        : '${stats.completions} / ${stats.eligibleDays} days';

    final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final logsMap = ref.watch(habitLogsMapProvider);
    final logged = logsMap[habit.id] ?? <DateTime>{};

    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      key: Key('weekly_habit_card_${habit.id}'),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppTheme.borderRadius8,
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Title, Streak, and %
          Row(
            children: [
              Expanded(
                child: Text(
                  habit.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Text(
                  '${data.currentStreak}d streak',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${stats.percentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          Text(
            completionsText,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 14),

          // 7-cell Mon–Sun Strip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final d = weekDays[index];
              final dDate = AppDateUtils.dateOnly(d);
              final isLogged = logged.contains(dDate);
              final status = StreakUtils.dayStatus(
                date: dDate,
                today: today,
                createdDate: habit.createdAt,
                isLogged: isLogged,
              );
              final isDayToday = dDate == today;

              return Expanded(
                child: Column(
                  children: [
                    Text(
                      dayLabels[index],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isDayToday ? FontWeight.w700 : FontWeight.w500,
                        color: isDayToday ? AppColors.primaryText : AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${d.day}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDayToday ? AppColors.primaryText : AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildStripCell(
                      context: context,
                      ref: ref,
                      habitId: habit.id,
                      date: dDate,
                      status: status,
                      cellKey: 'weekly_strip_cell_${habit.id}_$index',
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          const SizedBox(height: 10),

          // Bottom metrics: Missed, Rebounds, Comparison
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Missed: ${stats.missed}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Rebounds: ${stats.rebounds}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (data.comparisonText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Text(
                    data.comparisonText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStripCell({
    required BuildContext context,
    required WidgetRef ref,
    required String habitId,
    required DateTime date,
    required HabitDayStatus status,
    required String cellKey,
  }) {
    switch (status) {
      case HabitDayStatus.completed:
        return InkWell(
          key: Key(cellKey),
          onTap: () {
            ref.read(habitLogsProvider.notifier).toggleDate(habitId, date);
          },
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primaryText,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.check,
              size: 14,
              color: AppColors.background,
            ),
          ),
        );

      case HabitDayStatus.incomplete:
        return InkWell(
          key: Key(cellKey),
          onTap: () {
            ref.read(habitLogsProvider.notifier).toggleDate(habitId, date);
          },
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
          ),
        );

      case HabitDayStatus.future:
        return Container(
          key: Key(cellKey),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.disabled.withValues(alpha: 0.35), width: 1),
          ),
        );

      case HabitDayStatus.notApplicable:
        return SizedBox(
          key: Key(cellKey),
          width: 24,
          height: 24,
          child: Center(
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: AppColors.border,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
    }
  }

  Widget _buildOverallSummaryCard({required OverallWeeklySummary summary}) {
    return Container(
      key: const Key('weekly_overall_summary_card'),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTheme.borderRadius8,
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overall Weekly Summary',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.check_circle_outline, size: 16, color: AppColors.primaryText),
              const SizedBox(width: 8),
              Text(
                'Total Completions: ${summary.totalCompletions}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),
          if (summary.bestHabit != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.trending_up, size: 16, color: AppColors.primaryText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Best Habit: ${summary.bestHabit!.title} (${summary.bestHabitCompletions} completions)',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primaryText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (summary.weakestHabit != null && summary.weakestHabit != summary.bestHabit) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.trending_down, size: 16, color: AppColors.secondaryText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Weakest Habit: ${summary.weakestHabit!.title} (${summary.weakestHabitCompletions} completions)',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.secondaryText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
