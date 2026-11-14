import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/theme.dart';
import '../../core/utils/date_utils.dart';
import '../../models/workout_exercise.dart';
import '../../providers/workout_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/responsive_container.dart';
import 'widgets/add_exercise_sheet.dart';
import 'widgets/edit_split_dialog.dart';

/// Workout Screen (Stage 7).
/// Manages 7-day weekly workout splits, templates, and daily completion checklist.
/// - 7 tabs Mon..Sun (defaults to today's weekday)
/// - Editable split header per weekday
/// - Exercise checklist: toggleable ONLY on today's tab (display-only on other days)
/// - Checked state derived naturally from `last_completed_date == today`
/// - Single page-specific add control: `+ Add Exercise`
class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  static const _dayShortNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _dayFullNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    final selectedWeekday = ref.watch(selectedWeekdayProvider);
    final todayWeekday = ref.watch(todaysWeekdayProvider);
    final isTodayTab = selectedWeekday == todayWeekday;

    final workoutDay = ref.watch(workoutDayForWeekdayProvider(selectedWeekday));
    final exercises = ref.watch(exercisesForWeekdayProvider(selectedWeekday));
    final today = AppDateUtils.today();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Workout',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: OutlinedButton.icon(
              key: const Key('add_exercise_button'),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Exercise', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryText,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadius8),
              ),
              onPressed: () => AddExerciseSheet.show(context, selectedWeekday),
            ),
          ),
          IconButton(
            key: const Key('workout_refresh_button'),
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh workout',
            onPressed: () async {
              await ref.read(workoutDaysProvider.notifier).refresh();
              await ref.read(workoutExercisesProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 7-Day Tabs (Mon..Sun)
              Container(
                margin: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppTheme.borderRadius8,
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  children: List.generate(7, (index) {
                    final weekday = index + 1;
                    final isSelected = weekday == selectedWeekday;
                    final isToday = weekday == todayWeekday;

                    return Expanded(
                      child: InkWell(
                        key: Key('workout_weekday_tab_$weekday'),
                        onTap: () {
                          ref.read(selectedWeekdayProvider.notifier).setWeekday(weekday);
                        },
                        borderRadius: AppTheme.borderRadius8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryText : Colors.transparent,
                            borderRadius: AppTheme.borderRadius8,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _dayShortNames[index],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.background
                                      : (isToday ? AppColors.primaryText : AppColors.secondaryText),
                                ),
                              ),
                              if (isToday)
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.background : AppColors.primaryText,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // 2. Day Status Notice (if not viewing today)
              if (!isTodayTab)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 14, color: AppColors.secondaryText),
                      const SizedBox(width: 6),
                      Text(
                        'Viewing ${_dayFullNames[selectedWeekday - 1]} schedule (Checklist active on ${_dayShortNames[todayWeekday - 1]})',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),

              // 3. Editable Split Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
                child: _buildSplitHeader(context, selectedWeekday, workoutDay),
              ),

              // 4. Exercise Checklist or Empty State
              Expanded(
                child: exercises.isEmpty
                    ? _buildEmptyState(context, selectedWeekday, workoutDay)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 32.0),
                        itemCount: exercises.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final exercise = exercises[index];
                          final isCompletedToday = exercise.lastCompletedDate != null &&
                              AppDateUtils.dateOnly(exercise.lastCompletedDate!) == today;

                          return _buildExerciseRow(
                            context: context,
                            exercise: exercise,
                            isCompletedToday: isCompletedToday,
                            isTodayTab: isTodayTab,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSplitHeader(BuildContext context, int weekday, dynamic workoutDay) {
    final splitTitle = workoutDay?.splitTitle ?? '';
    final hasTitle = splitTitle.trim().isNotEmpty;

    return InkWell(
      key: const Key('workout_split_header'),
      onTap: () {
        EditSplitDialog.show(context, weekday, splitTitle);
      },
      borderRadius: AppTheme.borderRadius8,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppTheme.borderRadius8,
          border: Border.all(color: AppColors.border, width: 1.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Row(
          children: [
            const Icon(Icons.fitness_center, size: 18, color: AppColors.primaryText),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dayFullNames[weekday - 1].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasTitle ? splitTitle : 'Tap to set split (e.g. Chest & Shoulders / Rest Day)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: hasTitle ? FontWeight.w600 : FontWeight.w400,
                      color: hasTitle ? AppColors.primaryText : AppColors.disabled,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.edit_outlined, size: 16, color: AppColors.secondaryText),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseRow({
    required BuildContext context,
    required WorkoutExercise exercise,
    required bool isCompletedToday,
    required bool isTodayTab,
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
          // Checkbox (interactive ONLY if today's tab)
          InkWell(
            key: Key('exercise_checkbox_${exercise.id}'),
            onTap: isTodayTab
                ? () {
                    ref.read(workoutExercisesProvider.notifier).toggleExerciseToday(exercise.id);
                  }
                : null,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompletedToday
                    ? AppColors.primaryText
                    : (isTodayTab ? Colors.transparent : AppColors.surface),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isCompletedToday
                      ? AppColors.primaryText
                      : (isTodayTab ? AppColors.border : AppColors.disabled.withValues(alpha: 0.4)),
                  width: 1.5,
                ),
              ),
              child: isCompletedToday
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: AppColors.background,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 14),

          // Exercise Name and Sets/Reps
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.exerciseName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCompletedToday ? AppColors.secondaryText : AppColors.primaryText,
                    decoration: isCompletedToday ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (exercise.setsReps.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    exercise.setsReps,
                    style: TextStyle(
                      fontSize: 12,
                      color: isCompletedToday ? AppColors.disabled : AppColors.secondaryText,
                      decoration: isCompletedToday ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Delete Button
          IconButton(
            key: Key('delete_exercise_${exercise.id}'),
            icon: const Icon(Icons.delete_outline, size: 18),
            color: AppColors.secondaryText,
            tooltip: 'Delete exercise',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Exercise'),
                  content: Text('Are you sure you want to delete "${exercise.exerciseName}"?'),
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
                await ref.read(workoutExercisesProvider.notifier).deleteExercise(exercise.id);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, int weekday, dynamic workoutDay) {
    final title = workoutDay?.splitTitle ?? '';
    final isRestDay = title.toLowerCase().contains('rest');

    if (isRestDay) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppTheme.borderRadius8,
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: const Icon(Icons.hotel_outlined, size: 28, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryText),
              ),
              const SizedBox(height: 6),
              const Text(
                'Recovery day scheduled. No exercises needed.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
              ),
            ],
          ),
        ),
      );
    }

    return EmptyState(
      icon: Icons.fitness_center_outlined,
      title: 'No exercises planned',
      message: 'Add exercise templates for ${_dayFullNames[weekday - 1]}.\nChecklist resets naturally every morning.',
      action: OutlinedButton.icon(
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Add Exercise'),
        onPressed: () => AddExerciseSheet.show(context, weekday),
      ),
    );
  }
}
