import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/habit_icons.dart';
import '../../../core/constants/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../providers/habits_providers.dart';
import '../../app_card.dart';
import '../../empty_state.dart';
import '../../motion/animated_checkbox.dart';

/// Checklist of user habits for Today only inside Quick Add.
/// Strictly check-off only (no text field, no create control).
class HabitTodayChecklist extends ConsumerWidget {
  final VoidCallback onOpenHabits;

  const HabitTodayChecklist({
    super.key,
    required this.onOpenHabits,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final habitsAsync = ref.watch(habitsProvider);
    final logsAsync = ref.watch(habitLogsProvider);

    final habits = habitsAsync.value ?? [];
    final logs = logsAsync.value ?? [];
    final today = AppDateUtils.today();

    if (habits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EmptyState(
              icon: Icons.repeat_outlined,
              title: 'No habits yet',
              message: 'Set up habits in the Habits tab.',
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              key: const Key('quick_add_open_habits_button'),
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Open Habits'),
              onPressed: onOpenHabits,
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Today's Habits (Tap to mark done)",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: 8),

        ...habits.map((habit) {
          final isLoggedToday = logs.any((l) =>
              l.habitId == habit.id &&
              AppDateUtils.dateOnly(l.logDate) == today);
          final streak = ref.watch(habitStreakProvider(habit.id));

          return Container(
            key: ValueKey('quick_add_habit_${habit.id}'),
            margin: const EdgeInsets.only(bottom: 8.0),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              child: Row(
                children: [
                  // Habit Icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isLoggedToday
                          ? palette.accentSoft
                          : palette.cardRaised,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isLoggedToday ? palette.accent : palette.border,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      HabitIcons.getIcon(habit.icon),
                      size: 18,
                      color: isLoggedToday ? palette.accent : palette.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Habit Title & Streak Chip
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isLoggedToday
                                ? palette.textSecondary
                                : palette.textPrimary,
                            decoration: isLoggedToday
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              size: 14,
                              color: streak > 0 ? palette.accent : palette.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${streak}d streak',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: streak > 0 ? palette.textPrimary : palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Animated Checkbox
                  AnimatedCheckbox(
                    key: ValueKey('quick_add_habit_checkbox_${habit.id}'),
                    value: isLoggedToday,
                    onChanged: (_) {
                      ref.read(habitLogsProvider.notifier).toggleToday(habit.id);
                    },
                    size: 28,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
