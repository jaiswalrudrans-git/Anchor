import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../providers/workout_providers.dart';

/// Compact Today's Workout Strip displayed on the Home screen.
/// Directly synchronizes with WorkoutScreen state via Riverpod providers.
class WorkoutStripSlot extends ConsumerWidget {
  const WorkoutStripSlot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todaysDay = ref.watch(todaysWorkoutDayProvider);
    final todaysExercises = ref.watch(todaysExercisesProvider);
    final today = AppDateUtils.today();

    final hasSplit = todaysDay != null && todaysDay.splitTitle.trim().isNotEmpty;
    final splitTitle = hasSplit ? todaysDay.splitTitle : 'No workout planned';

    final completedCount = todaysExercises.where((e) {
      return e.lastCompletedDate != null &&
          AppDateUtils.dateOnly(e.lastCompletedDate!) == today;
    }).length;

    return Container(
      key: const Key('workout_strip_slot'),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTheme.borderRadius8,
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            children: [
              const Icon(Icons.fitness_center, size: 16, color: AppColors.primaryText),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasSplit ? 'Today: $splitTitle' : 'Today\'s Workout',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (todaysExercises.isNotEmpty)
                Text(
                  '$completedCount / ${todaysExercises.length} done',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryText,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Content: Empty state, Rest day, or Exercise checklist
          if (!hasSplit) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'No workout planned. Set it up in Workout.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
          ] else if (todaysExercises.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                splitTitle.toLowerCase().contains('rest')
                    ? 'Recovery day scheduled. Enjoy your rest!'
                    : 'No exercises added for today. Add exercises in the Workout tab.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: todaysExercises.length,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final exercise = todaysExercises[index];
                final isCompletedToday = exercise.lastCompletedDate != null &&
                    AppDateUtils.dateOnly(exercise.lastCompletedDate!) == today;

                return InkWell(
                  key: Key('home_workout_exercise_row_${exercise.id}'),
                  onTap: () {
                    ref.read(workoutExercisesProvider.notifier).toggleExerciseToday(exercise.id);
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        // Checkbox
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isCompletedToday ? AppColors.primaryText : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isCompletedToday ? AppColors.primaryText : AppColors.border,
                              width: 1.5,
                            ),
                          ),
                          child: isCompletedToday
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: AppColors.background,
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),

                        // Exercise name
                        Expanded(
                          child: Text(
                            exercise.setsReps.isNotEmpty
                                ? '${exercise.exerciseName} — ${exercise.setsReps}'
                                : exercise.exerciseName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isCompletedToday ? AppColors.secondaryText : AppColors.primaryText,
                              decoration: isCompletedToday ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
