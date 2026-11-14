import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/dimens.dart';
import '../../../core/constants/habit_icons.dart';
import '../../../core/constants/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/habit.dart';
import '../../../providers/habits_providers.dart';
import '../../../widgets/motion/animated_checkbox.dart';
import '../../../widgets/motion/fade_slide_in.dart';

/// Modal bottom sheet to toggle habit completions for a specific past or today date.
class DayLogSheet extends ConsumerWidget {
  final DateTime date;
  final List<Habit> habits;

  const DayLogSheet({super.key, required this.date, required this.habits});

  static Future<void> show(BuildContext context, {required DateTime date, required List<Habit> habits}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DayLogSheet(date: date, habits: habits),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final dateStr = DateFormat('EEE, d MMM yyyy').format(date);
    final logsMap = ref.watch(habitLogsMapProvider);
    final dDate = AppDateUtils.dateOnly(date);

    // Eligible habits created on or before this day
    final eligibleHabits = habits.where((h) {
      return !AppDateUtils.dateOnly(h.createdAt).isAfter(dDate);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          top: BorderSide(color: palette.border, width: 1.0),
          left: BorderSide(color: palette.border, width: 1.0),
          right: BorderSide(color: palette.border, width: 1.0),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Check or uncheck to adjust your history for this day.',
            style: TextStyle(fontSize: 13, color: palette.textSecondary),
          ),
          const SizedBox(height: 16),
          if (eligibleHabits.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No active habits existed on this day.',
                  style: TextStyle(color: palette.textSecondary, fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: eligibleHabits.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final habit = eligibleHabits[index];
                final isDone = (logsMap[habit.id] ?? <DateTime>{}).contains(dDate);

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: palette.cardRaised,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: palette.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        HabitIcons.getIcon(habit.icon),
                        size: 20,
                        color: palette.accent,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          habit.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                      AnimatedCheckbox(
                        key: Key('day_log_toggle_${habit.id}'),
                        value: isDone,
                        size: 24,
                        onChanged: (_) {
                          ref.read(habitLogsProvider.notifier).toggleDate(habit.id, dDate);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Calendar-style monthly heatmap replacing the dots matrix.
/// Features:
/// - 7 columns (Mon-Sun), one row per week, zero horizontal scrolling
/// - Filter chips: `All | habit item...`
/// - 5 intensity levels: none, 25%, 50%, 75%, 100%
/// - Tapping past/today opens DayLogSheet to fix forgotten logs
/// - Month navigation with limits (earliest habit creation to current month)
class MonthlyHeatmap extends ConsumerStatefulWidget {
  final List<Habit> habits;

  const MonthlyHeatmap({super.key, required this.habits});

  @override
  ConsumerState<MonthlyHeatmap> createState() => _MonthlyHeatmapState();
}

class _MonthlyHeatmapState extends ConsumerState<MonthlyHeatmap> {
  late DateTime _selectedMonth;
  String? _selectedHabitId; // null = All

  @override
  void initState() {
    super.initState();
    final today = AppDateUtils.today();
    _selectedMonth = DateTime(today.year, today.month, 1);
  }

  DateTime _getEarliestMonth() {
    if (widget.habits.isEmpty) return _selectedMonth;
    DateTime earliest = widget.habits.first.createdAt;
    for (final h in widget.habits) {
      if (h.createdAt.isBefore(earliest)) {
        earliest = h.createdAt;
      }
    }
    return DateTime(earliest.year, earliest.month, 1);
  }

  void _previousMonth() {
    final earliestMonth = _getEarliestMonth();
    final prev = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    if (!prev.isBefore(earliestMonth)) {
      setState(() => _selectedMonth = prev);
    }
  }

  void _nextMonth() {
    final today = AppDateUtils.today();
    final currentMonth = DateTime(today.year, today.month, 1);
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    if (!next.isAfter(currentMonth)) {
      setState(() => _selectedMonth = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.habits.isEmpty) return const SizedBox.shrink();

    final palette = context.palette;
    final today = AppDateUtils.today();
    final currentMonth = DateTime(today.year, today.month, 1);
    final earliestMonth = _getEarliestMonth();

    final canGoPrev = _selectedMonth.isAfter(earliestMonth);
    final canGoNext = _selectedMonth.isBefore(currentMonth);

    final monthTitle = DateFormat('MMMM yyyy').format(_selectedMonth);

    // Days in current selected month
    final nextMonthFirst = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    final daysInMonth = nextMonthFirst.subtract(const Duration(days: 1)).day;

    // Monday-based start: weekday 1 is Mon, 7 is Sun
    final firstWeekday = _selectedMonth.weekday; // 1..7
    final paddingDays = firstWeekday - 1; // 0..6

    final logsMap = ref.watch(habitLogsMapProvider);

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: palette.border, width: AppDimens.hairline),
      ),
      padding: const EdgeInsets.all(AppDimens.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header: Title + Prev / Next Month
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8.0,
            runSpacing: 6.0,
            children: [
              Text(
                'Monthly Consistency Heatmap',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: const Key('heatmap_prev_month_button'),
                    icon: const Icon(Icons.chevron_left, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Previous month',
                    onPressed: canGoPrev ? _previousMonth : null,
                    color: canGoPrev ? palette.textPrimary : palette.disabledForeground,
                  ),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      monthTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    key: const Key('heatmap_next_month_button'),
                    icon: const Icon(Icons.chevron_right, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Next month',
                    onPressed: canGoNext ? _nextMonth : null,
                    color: canGoNext ? palette.textPrimary : palette.disabledForeground,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. Filter chips: All | <habit icon + name>...
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'All Habits',
                  icon: Icons.grid_view,
                  isSelected: _selectedHabitId == null,
                  onTap: () => setState(() => _selectedHabitId = null),
                  palette: palette,
                ),
                const SizedBox(width: 8),
                ...widget.habits.map((h) {
                  final isSelected = _selectedHabitId == h.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _buildFilterChip(
                      label: h.title,
                      icon: HabitIcons.getIcon(h.icon),
                      isSelected: isSelected,
                      onTap: () => setState(() => _selectedHabitId = h.id),
                      palette: palette,
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Weekday Labels (Mon..Sun)
          Row(
            children: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((letter) {
              return Expanded(
                child: Center(
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // 4. Calendar Grid
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 4.0;
              final cellWidth = (constraints.maxWidth - (6 * gap)) / 7;
              final cellSize = cellWidth.clamp(28.0, 48.0);

              final totalSlots = paddingDays + daysInMonth;
              final rowCount = (totalSlots / 7).ceil();

              return Column(
                children: List.generate(rowCount, (rowIndex) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (colIndex) {
                        final slotIndex = (rowIndex * 7) + colIndex;
                        final dayNumber = slotIndex - paddingDays + 1;

                        if (dayNumber < 1 || dayNumber > daysInMonth) {
                          return SizedBox(width: cellSize, height: cellSize);
                        }

                        final dDate = DateTime(_selectedMonth.year, _selectedMonth.month, dayNumber);
                        final isToday = dDate == today;
                        final isFuture = dDate.isAfter(today);

                        // Calculate fraction and cell background
                        final intensity = _calculateIntensity(
                          date: dDate,
                          logsMap: logsMap,
                          isFuture: isFuture,
                        );

                        final cellKeyPrefix = _selectedHabitId ?? (widget.habits.isNotEmpty ? widget.habits.first.id : '');

                        return FadeSlideIn(
                          index: dayNumber - 1,
                          child: InkWell(
                            key: Key('matrix_cell_${cellKeyPrefix}_$dayNumber'),
                            borderRadius: BorderRadius.circular(8),
                            onTap: (isFuture || intensity.isPreCreation)
                                ? null
                                : () => DayLogSheet.show(
                                      context,
                                      date: dDate,
                                      habits: widget.habits,
                                    ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: cellSize,
                              height: cellSize,
                              decoration: BoxDecoration(
                                color: intensity.fillColor(palette),
                                borderRadius: BorderRadius.circular(8),
                                border: isToday
                                    ? Border.all(color: palette.accent, width: 2.0)
                                    : intensity.borderColor(palette) != null
                                        ? Border.all(color: intensity.borderColor(palette)!, width: 1.0)
                                        : null,
                              ),
                              child: Center(
                                child: Text(
                                  '$dayNumber',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                                    color: intensity.textColor(palette, isToday),
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 14),

          // 5. Legend row: Less ▢▢▢▢▢ More
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Less', style: TextStyle(fontSize: 11, color: palette.textSecondary)),
              const SizedBox(width: 6),
              _buildLegendBox(color: Colors.transparent, borderColor: palette.border),
              const SizedBox(width: 4),
              _buildLegendBox(color: palette.accent.withValues(alpha: 0.25)),
              const SizedBox(width: 4),
              _buildLegendBox(color: palette.accent.withValues(alpha: 0.50)),
              const SizedBox(width: 4),
              _buildLegendBox(color: palette.accent.withValues(alpha: 0.75)),
              const SizedBox(width: 4),
              _buildLegendBox(color: palette.accent),
              const SizedBox(width: 6),
              Text('More', style: TextStyle(fontSize: 11, color: palette.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required AppPalette palette,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? palette.accentSoft : palette.cardRaised,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? palette.accent : palette.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? palette.accent : palette.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? palette.accent : palette.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendBox({required Color color, Color? borderColor}) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
        border: borderColor != null ? Border.all(color: borderColor, width: 1) : null,
      ),
    );
  }

  _HeatmapIntensity _calculateIntensity({
    required DateTime date,
    required Map<String, Set<DateTime>> logsMap,
    required bool isFuture,
  }) {
    if (isFuture) {
      return const _HeatmapIntensity(tier: _IntensityTier.future);
    }

    if (_selectedHabitId != null) {
      final habit = widget.habits.firstWhere((h) => h.id == _selectedHabitId, orElse: () => widget.habits.first);
      if (date.isBefore(AppDateUtils.dateOnly(habit.createdAt))) {
        return const _HeatmapIntensity(tier: _IntensityTier.preCreation);
      }
      final isDone = (logsMap[habit.id] ?? {}).contains(date);
      return _HeatmapIntensity(tier: isDone ? _IntensityTier.oneHundred : _IntensityTier.zero);
    }

    // All habits view
    final activeHabits = widget.habits.where((h) => !date.isBefore(AppDateUtils.dateOnly(h.createdAt))).toList();
    if (activeHabits.isEmpty) {
      return const _HeatmapIntensity(tier: _IntensityTier.preCreation);
    }

    final doneCount = activeHabits.where((h) => (logsMap[h.id] ?? {}).contains(date)).length;
    final frac = doneCount / activeHabits.length;

    if (frac == 0.0) return const _HeatmapIntensity(tier: _IntensityTier.zero);
    if (frac <= 0.33) return const _HeatmapIntensity(tier: _IntensityTier.twentyFive);
    if (frac <= 0.66) return const _HeatmapIntensity(tier: _IntensityTier.fifty);
    if (frac < 1.0) return const _HeatmapIntensity(tier: _IntensityTier.seventyFive);
    return const _HeatmapIntensity(tier: _IntensityTier.oneHundred);
  }
}

enum _IntensityTier { preCreation, future, zero, twentyFive, fifty, seventyFive, oneHundred }

class _HeatmapIntensity {
  final _IntensityTier tier;

  const _HeatmapIntensity({required this.tier});

  bool get isPreCreation => tier == _IntensityTier.preCreation;
  bool get isFuture => tier == _IntensityTier.future;

  Color fillColor(AppPalette palette) {
    switch (tier) {
      case _IntensityTier.preCreation:
      case _IntensityTier.future:
        return Colors.transparent;
      case _IntensityTier.zero:
        return palette.card;
      case _IntensityTier.twentyFive:
        return palette.accent.withValues(alpha: 0.25);
      case _IntensityTier.fifty:
        return palette.accent.withValues(alpha: 0.50);
      case _IntensityTier.seventyFive:
        return palette.accent.withValues(alpha: 0.75);
      case _IntensityTier.oneHundred:
        return palette.accent;
    }
  }

  Color? borderColor(AppPalette palette) {
    switch (tier) {
      case _IntensityTier.preCreation:
        return palette.border.withValues(alpha: 0.25);
      case _IntensityTier.future:
        return palette.border.withValues(alpha: 0.35);
      case _IntensityTier.zero:
        return palette.border;
      case _IntensityTier.twentyFive:
      case _IntensityTier.fifty:
      case _IntensityTier.seventyFive:
      case _IntensityTier.oneHundred:
        return null;
    }
  }

  Color textColor(AppPalette palette, bool isToday) {
    if (tier == _IntensityTier.oneHundred) {
      return palette.onAccent;
    }
    if (tier == _IntensityTier.future || tier == _IntensityTier.preCreation) {
      return palette.textMuted;
    }
    return isToday ? palette.accent : palette.textPrimary;
  }
}
