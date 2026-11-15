import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/streak_utils.dart';
import '../../../models/habit.dart';
import '../../../providers/habits_providers.dart';

/// Monthly micro-box matrix displaying habits across days 1..daysInMonth.
/// - Fixed left column for habit names
/// - Horizontally scrollable day cells
/// - Aggregate row at the bottom (solid if all habits done on that day)
/// - Interactive: tapping past/today cells toggles completion
class MonthlyMatrixGrid extends ConsumerWidget {
  final List<Habit> habits;

  const MonthlyMatrixGrid({super.key, required this.habits});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (habits.isEmpty) return const SizedBox.shrink();

    final palette = context.palette;
    final today = AppDateUtils.today();
    final nextMonthFirst = DateTime(today.year, today.month + 1, 1);
    final daysInMonth = nextMonthFirst.subtract(const Duration(days: 1)).day;
    final logsMap = ref.watch(habitLogsMapProvider);
    final monthName = DateFormat('MMMM yyyy').format(today);

    final daysList = List.generate(
      daysInMonth,
      (i) => DateTime(today.year, today.month, i + 1),
    );

    const double leftColWidth = 130.0;
    const double cellWidth = 28.0;
    const double rowHeight = 36.0;

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: AppTheme.borderRadius8,
        border: Border.all(color: palette.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Monthly Consistency Matrix',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  monthName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: palette.border),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fixed left column: Titles
              SizedBox(
                width: leftColWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header corner
                    Container(
                      height: rowHeight,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      color: palette.cardRaised,
                      child: Text(
                        'Habit',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: palette.textSecondary,
                        ),
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: palette.border),
                    // Habit names
                    ...habits.map(
                      (h) => Container(
                        height: rowHeight,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: palette.border,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Text(
                          h.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    // Aggregate row label
                    Container(
                      height: rowHeight,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      color: palette.cardRaised,
                      child: Text(
                        'All Habits',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Border separator
              Container(width: 1, color: palette.border),

              // Scrollable days grid
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: daysInMonth * cellWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Days Header Row (1..daysInMonth)
                        Container(
                          height: rowHeight,
                          color: palette.cardRaised,
                          child: Row(
                            children: daysList.map((d) {
                              final isToday = AppDateUtils.dateOnly(d) == today;
                              return SizedBox(
                                width: cellWidth,
                                child: Center(
                                  child: Text(
                                    '${d.day}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isToday
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isToday
                                          ? palette.textPrimary
                                          : palette.textSecondary,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        Divider(height: 1, thickness: 1, color: palette.border),

                        // Habit Rows
                        ...habits.map((habit) {
                          final logged = logsMap[habit.id] ?? <DateTime>{};
                          return Container(
                            height: rowHeight,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: palette.border,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Row(
                              children: daysList.map((d) {
                                final dDate = AppDateUtils.dateOnly(d);
                                final isLogged = logged.contains(dDate);
                                final status = StreakUtils.dayStatus(
                                  date: dDate,
                                  today: today,
                                  createdDate: habit.createdAt,
                                  isLogged: isLogged,
                                );

                                return SizedBox(
                                  width: cellWidth,
                                  child: Center(
                                    child: _buildMatrixCell(
                                      context: context,
                                      ref: ref,
                                      habitId: habit.id,
                                      date: dDate,
                                      status: status,
                                      keyPrefix:
                                          'matrix_cell_${habit.id}_${d.day}',
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        }),

                        // Aggregate Row
                        Container(
                          height: rowHeight,
                          color: palette.cardRaised,
                          child: Row(
                            children: daysList.map((d) {
                              final dDate = AppDateUtils.dateOnly(d);
                              final isFuture = dDate.isAfter(today);

                              // Active habits created on or before this day
                              final activeHabits = habits.where((h) {
                                return !AppDateUtils.dateOnly(h.createdAt)
                                    .isAfter(dDate);
                              }).toList();

                              if (activeHabits.isEmpty || isFuture) {
                                return SizedBox(
                                  width: cellWidth,
                                  child: Center(
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: isFuture
                                            ? Colors.transparent
                                            : palette.cardRaised,
                                        borderRadius: BorderRadius.circular(3),
                                        border: Border.all(
                                          color: isFuture
                                              ? palette.border.withValues(
                                                  alpha: 0.3,
                                                )
                                              : palette.border,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              final completedCount = activeHabits.where((h) {
                                final logged = logsMap[h.id] ?? <DateTime>{};
                                return logged.contains(dDate);
                              }).length;

                              final allCompleted =
                                  completedCount == activeHabits.length;

                              return SizedBox(
                                width: cellWidth,
                                child: Center(
                                  child: Tooltip(
                                    message:
                                        '$completedCount / ${activeHabits.length} habits done',
                                    child: Container(
                                      key: Key('matrix_aggregate_${d.day}'),
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: allCompleted
                                            ? palette.selectedFill
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(3),
                                        border: Border.all(
                                          color: allCompleted
                                              ? palette.selectedFill
                                              : palette.border,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixCell({
    required BuildContext context,
    required WidgetRef ref,
    required String habitId,
    required DateTime date,
    required HabitDayStatus status,
    required String keyPrefix,
  }) {
    final palette = context.palette;
    switch (status) {
      case HabitDayStatus.completed:
        return InkWell(
          key: Key(keyPrefix),
          onTap: () {
            ref.read(habitLogsProvider.notifier).toggleDate(habitId, date);
          },
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: palette.selectedFill,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(Icons.check, size: 12, color: palette.onSelected),
          ),
        );

      case HabitDayStatus.incomplete:
        return InkWell(
          key: Key(keyPrefix),
          onTap: () {
            ref.read(habitLogsProvider.notifier).toggleDate(habitId, date);
          },
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: palette.border, width: 1.5),
            ),
          ),
        );

      case HabitDayStatus.future:
        return Container(
          key: Key(keyPrefix),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: palette.border.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
        );

      case HabitDayStatus.notApplicable:
        return SizedBox(
          key: Key(keyPrefix),
          width: 18,
          height: 18,
          child: Center(
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: palette.border,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
    }
  }
}
