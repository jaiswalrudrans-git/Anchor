import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../providers/habits_providers.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/motion/fade_slide_in.dart';
import 'add_habit_sheet.dart';
import 'habit_card.dart';
import 'monthly_heatmap.dart';
import 'monthly_reality_report_card.dart';

/// Overview tab of the Habits screen:
/// - Daily Habit cards with playful today toggle, streak badge, mini 7-day strip, and actions
/// - Monthly Consistency Heatmap
/// - Monthly Reality Report Card
/// Responsive 2-column layout on expanded screens (>= 900).
class HabitsOverviewTab extends ConsumerWidget {
  const HabitsOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final habitsAsync = ref.watch(habitsProvider);

    return habitsAsync.when(
      loading: () => Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: CircularProgressIndicator(strokeWidth: 2, color: palette.accent),
        ),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text('Error loading habits: $err', style: TextStyle(color: palette.danger)),
        ),
      ),
      data: (habits) {
        if (habits.isEmpty) {
          return EmptyState(
            icon: Icons.repeat_outlined,
            title: 'No habits yet',
            message: 'Start with one small daily habit.',
            action: OutlinedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Habit'),
              onPressed: () => AddHabitSheet.show(context),
            ),
          );
        }

        final logsMap = ref.watch(habitLogsMapProvider);
        final today = AppDateUtils.today();

        return LayoutBuilder(
          builder: (context, constraints) {
            final isExpanded = constraints.maxWidth >= 900;

            final habitCardsList = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Daily Habits',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: palette.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${habits.length} active',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: habits.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final habit = habits[index];
                    final logged = logsMap[habit.id] ?? <DateTime>{};
                    final isLoggedToday = logged.contains(today);
                    final streak = ref.watch(habitStreakProvider(habit.id));

                    return FadeSlideIn(
                      index: index,
                      child: HabitCard(
                        habit: habit,
                        isLoggedToday: isLoggedToday,
                        streak: streak,
                        loggedDates: logged,
                      ),
                    );
                  },
                ),
              ],
            );

            if (isExpanded) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left column: Habit cards
                    Expanded(
                      flex: 5,
                      child: habitCardsList,
                    ),
                    const SizedBox(width: 24),
                    // Right column: Heatmap + Reality report
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          MonthlyHeatmap(habits: habits),
                          const SizedBox(height: 16),
                          const MonthlyRealityReportCard(),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            // Compact / Medium: Single column
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  habitCardsList,
                  const SizedBox(height: 24),
                  MonthlyHeatmap(habits: habits),
                  const SizedBox(height: 24),
                  const MonthlyRealityReportCard(),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
