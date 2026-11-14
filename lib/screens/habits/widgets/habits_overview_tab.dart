import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/habit.dart';
import '../../../providers/habits_providers.dart';
import '../../../widgets/empty_state.dart';
import 'add_habit_sheet.dart';
import 'monthly_matrix_grid.dart';
import 'monthly_reality_report_card.dart';

/// Overview tab of the Habits screen:
/// - Daily Habit rows with one-tap today toggle, streak badge, and delete
/// - Monthly Reality Report Card
/// - Monthly Consistency Matrix Grid
class HabitsOverviewTab extends ConsumerWidget {
  const HabitsOverviewTab({super.key});

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
          return EmptyState(
            icon: Icons.repeat_outlined,
            title: 'No habits yet',
            message: 'Build consistency by tracking daily habits.\nTap "+ New Habit" to create your first one.',
            action: OutlinedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Habit'),
              onPressed: () => AddHabitSheet.show(context),
            ),
          );
        }

        final logsMap = ref.watch(habitLogsMapProvider);
        final today = AppDateUtils.today();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Daily Habit Rows Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daily Habits',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    '${habits.length} active',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: habits.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final habit = habits[index];
                  final logged = logsMap[habit.id] ?? <DateTime>{};
                  final isLoggedToday = logged.contains(today);
                  final streak = ref.watch(habitStreakProvider(habit.id));

                  return _buildHabitRow(
                    context: context,
                    ref: ref,
                    habit: habit,
                    isLoggedToday: isLoggedToday,
                    streak: streak,
                  );
                },
              ),

              const SizedBox(height: 24),

              // 2. Monthly Reality Report Card
              const MonthlyRealityReportCard(),

              const SizedBox(height: 24),

              // 3. Monthly Consistency Matrix Grid
              MonthlyMatrixGrid(habits: habits),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHabitRow({
    required BuildContext context,
    required WidgetRef ref,
    required Habit habit,
    required bool isLoggedToday,
    required int streak,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppTheme.borderRadius8,
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      child: Row(
        children: [
          // One-tap today toggle
          InkWell(
            key: Key('habit_today_toggle_${habit.id}'),
            onTap: () {
              ref.read(habitLogsProvider.notifier).toggleToday(habit.id);
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isLoggedToday ? AppColors.primaryText : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isLoggedToday ? AppColors.primaryText : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: isLoggedToday
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: AppColors.background,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 14),

          // Habit Title
          Expanded(
            child: Text(
              habit.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isLoggedToday ? AppColors.secondaryText : AppColors.primaryText,
                decoration: isLoggedToday ? TextDecoration.lineThrough : null,
              ),
            ),
          ),

          // Streak Badge
          Container(
            key: Key('habit_streak_badge_${habit.id}'),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department,
                  size: 14,
                  color: streak > 0 ? AppColors.primaryText : AppColors.disabled,
                ),
                const SizedBox(width: 4),
                Text(
                  '${streak}d streak',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: streak > 0 ? AppColors.primaryText : AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Delete Habit Button
          IconButton(
            key: Key('delete_habit_${habit.id}'),
            icon: const Icon(Icons.delete_outline, size: 18),
            color: AppColors.secondaryText,
            tooltip: 'Delete habit',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Habit'),
                  content: Text('Are you sure you want to delete "${habit.title}"? All logged history will be permanently deleted.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryText,
                        foregroundColor: AppColors.background,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref.read(habitsProvider.notifier).deleteHabit(habit.id);
              }
            },
          ),
        ],
      ),
    );
  }
}
