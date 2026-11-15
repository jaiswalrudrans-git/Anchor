import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/dimens.dart';
import '../../../core/constants/habit_icons.dart';
import '../../../core/constants/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/streak_utils.dart';
import '../../../models/habit.dart';
import '../../../providers/habits_providers.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/motion/count_up_text.dart';

/// Custom painter for the animated completion ring.
class CompletionRingPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  CompletionRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    this.strokeWidth = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0.0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CompletionRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.progressColor != progressColor ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// Custom painter for 6-week trend sparklines.
class SparklinePainter extends CustomPainter {
  final List<double> data; // 0.0 to 1.0
  final Color color;

  SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final stepX = size.width / (data.length - 1);
    const padY = 4.0;
    final availableH = size.height - (padY * 2);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - padY - (data[i].clamp(0.0, 1.0) * availableH);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // End dot
    final lastX = size.width;
    final lastY = size.height - padY - (data.last.clamp(0.0, 1.0) * availableH);
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(lastX, lastY), 3.0, dotPaint);
  }

  @override
  bool shouldRepaint(SparklinePainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.color != color;
}

/// Weekly Report Tab displaying:
/// 1. Summary hero card (120dp ring, check-ins, perfect days, comparison chip)
/// 2. Daily vertical bars (Mon-Sun, best day dot, today highlighted)
/// 3. Insight chips (Best day, Weakest day, Longest streak)
/// 4. Per-habit cards with sparklines, rings, 7-cell strips, and stats
class WeeklyReportTab extends ConsumerWidget {
  const WeeklyReportTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final habitsAsync = ref.watch(habitsProvider);

    return habitsAsync.when(
      loading: () => Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: palette.accent,
          ),
        ),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Error loading habits: $err',
            style: TextStyle(color: palette.danger),
          ),
        ),
      ),
      data: (habits) {
        if (habits.isEmpty) {
          return const EmptyState(
            icon: Icons.repeat_outlined,
            title: 'No habits yet',
            message:
                'Create a habit to view detailed weekly consistency reports.',
          );
        }

        final weekStart = ref.watch(selectedWeekStartProvider);
        final weekEnd = weekStart.add(const Duration(days: 6));
        final today = AppDateUtils.today();
        final currentWeekStart = AppDateUtils.startOfWeek(today);
        final canGoForward = weekStart.isBefore(currentWeekStart);

        final logsMap = ref.watch(habitLogsMapProvider);

        // Check if any habit existed during this week
        final habitsActiveThisWeek = habits.where((h) {
          return !AppDateUtils.dateOnly(h.createdAt).isAfter(weekEnd);
        }).toList();

        final hasHabitsThisWeek = habitsActiveThisWeek.isNotEmpty;

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

              if (!hasHabitsThisWeek)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: EmptyState(
                    icon: Icons.history,
                    title: 'Nothing to report for this week.',
                    message: 'No habits were active during this week.\nUse the navigator above to view more recent weeks.',
                  ),
                )
              else ...[
                // Layout for compact vs expanded
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isExpanded = constraints.maxWidth >= 900;

                    if (isExpanded) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left column: Hero card + Daily bars + Insights
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildSummaryHeroCard(
                                  context: context,
                                  habits: habitsActiveThisWeek,
                                  logsMap: logsMap,
                                  weekStart: weekStart,
                                  today: today,
                                ),
                                const SizedBox(height: 16),
                                _buildDailyBarsCard(
                                  context: context,
                                  habits: habitsActiveThisWeek,
                                  logsMap: logsMap,
                                  weekStart: weekStart,
                                  today: today,
                                ),
                                const SizedBox(height: 16),
                                _buildInsightChips(
                                  context: context,
                                  ref: ref,
                                  habits: habitsActiveThisWeek,
                                  logsMap: logsMap,
                                  weekStart: weekStart,
                                  today: today,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Right column: Per-habit cards
                          Expanded(
                            flex: 6,
                            child: LayoutBuilder(
                              builder: (context, rightConstraints) {
                                final cardWidth =
                                    rightConstraints.maxWidth >= 640
                                    ? (rightConstraints.maxWidth - 12) / 2
                                    : rightConstraints.maxWidth;

                                return Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: habitsActiveThisWeek.map((habit) {
                                    return SizedBox(
                                      width: cardWidth,
                                      child: _buildHabitWeeklyCard(
                                        context: context,
                                        ref: ref,
                                        habit: habit,
                                        weekStart: weekStart,
                                        today: today,
                                        logsMap: logsMap,
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }

                    // Compact layout: Single column
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSummaryHeroCard(
                          context: context,
                          habits: habitsActiveThisWeek,
                          logsMap: logsMap,
                          weekStart: weekStart,
                          today: today,
                        ),
                        const SizedBox(height: 16),
                        _buildDailyBarsCard(
                          context: context,
                          habits: habitsActiveThisWeek,
                          logsMap: logsMap,
                          weekStart: weekStart,
                          today: today,
                        ),
                        const SizedBox(height: 16),
                        _buildInsightChips(
                          context: context,
                          ref: ref,
                          habits: habitsActiveThisWeek,
                          logsMap: logsMap,
                          weekStart: weekStart,
                          today: today,
                        ),
                        const SizedBox(height: 20),

                        // Section header
                        Text(
                          'Per-Habit Performance',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: palette.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 12),

                        ...habitsActiveThisWeek.map((habit) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _buildHabitWeeklyCard(
                              context: context,
                              ref: ref,
                              habit: habit,
                              weekStart: weekStart,
                              today: today,
                              logsMap: logsMap,
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
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
    final palette = context.palette;
    final startStr = DateFormat('d MMM').format(weekStart);
    final endStr = DateFormat('d MMM yyyy').format(weekEnd);

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: palette.border, width: AppDimens.hairline),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            key: const Key('weekly_prev_week_button'),
            icon: const Icon(Icons.chevron_left, size: 22),
            color: palette.textPrimary,
            tooltip: 'Previous week',
            onPressed: () {
              ref.read(selectedWeekStartProvider.notifier).previousWeek();
            },
          ),
          Flexible(
            child: Text(
              'Week of $startStr – $endStr',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ),
          IconButton(
            key: const Key('weekly_next_week_button'),
            icon: const Icon(Icons.chevron_right, size: 22),
            color: canGoForward
                ? palette.textPrimary
                : palette.disabledForeground,
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

  Widget _buildSummaryHeroCard({
    required BuildContext context,
    required List<Habit> habits,
    required Map<String, Set<DateTime>> logsMap,
    required DateTime weekStart,
    required DateTime today,
  }) {
    final palette = context.palette;

    // Calculate total check-ins & eligible habit-days so far
    int totalCompletions = 0;
    int totalEligibleDays = 0;

    for (final habit in habits) {
      final stats = StreakUtils.weekStats(
        logged: logsMap[habit.id] ?? {},
        weekStart: weekStart,
        today: today,
        createdDate: habit.createdAt,
      );
      totalCompletions += stats.completions;
      totalEligibleDays += stats.eligibleDays;
    }

    final double overallPercent = totalEligibleDays > 0
        ? (totalCompletions / totalEligibleDays) * 100
        : 0.0;
    final int perfectDaysCount = StreakUtils.perfectDays(
      habits: habits,
      habitLogsMap: logsMap,
      weekStart: weekStart,
      today: today,
    );

    // Calculate last week comparison
    final prevWeekStart = weekStart.subtract(const Duration(days: 7));
    int prevCompletions = 0;
    int prevEligibleDays = 0;

    for (final habit in habits) {
      final prevStats = StreakUtils.weekStats(
        logged: logsMap[habit.id] ?? {},
        weekStart: prevWeekStart,
        today: today,
        createdDate: habit.createdAt,
      );
      prevCompletions += prevStats.completions;
      prevEligibleDays += prevStats.eligibleDays;
    }

    String? comparisonChip;
    Color comparisonColor = palette.textSecondary;
    if (prevEligibleDays > 0) {
      final prevPercent = (prevCompletions / prevEligibleDays) * 100;
      final diff = (overallPercent - prevPercent).round();
      if (diff > 0) {
        comparisonChip = '+$diff% vs last week';
        comparisonColor = palette.success;
      } else if (diff < 0) {
        comparisonChip = '$diff% vs last week';
        comparisonColor = palette.danger;
      } else {
        comparisonChip = 'Same as last week';
      }
    }

    return Container(
      key: const Key('weekly_overall_summary_card'),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: palette.border, width: AppDimens.hairline),
      ),
      padding: const EdgeInsets.all(AppDimens.cardPadding),
      child: Row(
        children: [
          // 120dp animated completion ring
          SizedBox(
            width: 120,
            height: 120,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: overallPercent / 100),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, ringProgress, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(120, 120),
                      painter: CompletionRingPainter(
                        progress: ringProgress,
                        trackColor: palette.border,
                        progressColor: palette.accent,
                        strokeWidth: 10,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CountUpText(
                          value: overallPercent,
                          duration: const Duration(milliseconds: 500),
                          formatter: (val) => '${val.round()}%',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'completed',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 20),

          // Beside it: X of Y check-ins, Perfect days, Comparison chip
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Weekly Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$totalCompletions of $totalEligibleDays check-ins',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Perfect days: $perfectDaysCount',
                  style: TextStyle(fontSize: 13, color: palette.textSecondary),
                ),
                if (comparisonChip != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: palette.cardRaised,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: palette.border, width: 1),
                    ),
                    child: Text(
                      comparisonChip,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: comparisonColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyBarsCard({
    required BuildContext context,
    required List<Habit> habits,
    required Map<String, Set<DateTime>> logsMap,
    required DateTime weekStart,
    required DateTime today,
  }) {
    final palette = context.palette;
    final fractions = StreakUtils.dailyCompletionFractions(
      habits: habits,
      habitLogsMap: logsMap,
      weekStart: weekStart,
      today: today,
    );

    // Find best day index
    int? bestIndex;
    double maxFrac = 0.0;
    for (int i = 0; i < 7; i++) {
      if (fractions[i] > maxFrac) {
        maxFrac = fractions[i];
        bestIndex = i;
      }
    }

    final dWeekStart = AppDateUtils.dateOnly(weekStart);
    final dToday = AppDateUtils.today();
    const dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

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
          Text(
            'Daily Activity',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final dayDate = dWeekStart.add(Duration(days: i));
                final isFuture = dayDate.isAfter(dToday);
                final isToday = dayDate == dToday;
                final isBest = bestIndex == i && maxFrac > 0;
                final frac = fractions[i];

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Best day dot
                      if (isBest)
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: palette.accent,
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        const SizedBox(height: 9),

                      // Vertical bar
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                              begin: 0.0,
                              end: isFuture ? 0.0 : frac,
                            ),
                            duration: Duration(milliseconds: 300 + (i * 40)),
                            curve: Curves.easeOutCubic,
                            builder: (context, animatedFrac, _) {
                              return Container(
                                width: 14,
                                height: (animatedFrac * 60).clamp(4.0, 60.0),
                                decoration: BoxDecoration(
                                  color: isFuture
                                      ? Colors.transparent
                                      : (animatedFrac > 0
                                            ? palette.accent
                                            : palette.border.withValues(
                                                alpha: 0.4,
                                              )),
                                  borderRadius: BorderRadius.circular(4),
                                  border: isFuture
                                      ? Border.all(
                                          color: palette.border.withValues(
                                            alpha: 0.35,
                                          ),
                                          width: 1,
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Day label
                      Text(
                        dayLetters[i],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isToday
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isToday
                              ? palette.accent
                              : palette.textSecondary,
                        ),
                      ),
                      Text(
                        '${dayDate.day}',
                        style: TextStyle(
                          fontSize: 9,
                          color: isToday ? palette.accent : palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightChips({
    required BuildContext context,
    required WidgetRef ref,
    required List<Habit> habits,
    required Map<String, Set<DateTime>> logsMap,
    required DateTime weekStart,
    required DateTime today,
  }) {
    final palette = context.palette;
    final bestWeakest = StreakUtils.bestAndWeakestDay(
      habits: habits,
      habitLogsMap: logsMap,
      weekStart: weekStart,
      today: today,
    );

    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Find longest current streak habit
    Habit? longestStreakHabit;
    int longestStreak = -1;
    for (final h in habits) {
      final streak = ref.watch(habitStreakProvider(h.id));
      if (streak > longestStreak) {
        longestStreak = streak;
        longestStreakHabit = h;
      }
    }

    final chips = <Widget>[];

    if (bestWeakest != null && bestWeakest.bestDay != null) {
      chips.add(
        _buildChip(
          icon: Icons.trending_up,
          iconColor: palette.success,
          text: 'Best day: ${dayNames[bestWeakest.bestDay! - 1]}',
          palette: palette,
        ),
      );
    }

    if (bestWeakest != null &&
        bestWeakest.weakestDay != null &&
        bestWeakest.weakestDay != bestWeakest.bestDay) {
      chips.add(
        _buildChip(
          icon: Icons.trending_down,
          iconColor: palette.danger,
          text: 'Weakest day: ${dayNames[bestWeakest.weakestDay! - 1]}',
          palette: palette,
        ),
      );
    }

    if (longestStreakHabit != null && longestStreak > 0) {
      chips.add(
        _buildChip(
          icon: Icons.local_fire_department,
          iconColor: palette.accent,
          text: 'Longest streak: ${longestStreakHabit.title} ${longestStreak}d',
          palette: palette,
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  Widget _buildChip({
    required IconData icon,
    required Color iconColor,
    required String text,
    required AppPalette palette,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.cardRaised,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: palette.textPrimary,
            ),
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
    required Map<String, Set<DateTime>> logsMap,
  }) {
    final palette = context.palette;
    final logged = logsMap[habit.id] ?? <DateTime>{};
    final stats = StreakUtils.weekStats(
      logged: logged,
      weekStart: weekStart,
      today: today,
      createdDate: habit.createdAt,
    );

    final currentStreak = ref.watch(habitStreakProvider(habit.id));

    // 6-week sparkline data
    final sparklineData = StreakUtils.weeklyCompletionSeries(
      logged: logged,
      weekStart: weekStart,
      weeks: 6,
      today: today,
      createdDate: habit.createdAt,
    );

    final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      key: Key('weekly_habit_card_${habit.id}'),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: palette.border, width: AppDimens.hairline),
      ),
      padding: const EdgeInsets.all(AppDimens.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Icon + Name + Sparkline + Ring
          Row(
            children: [
              Icon(
                HabitIcons.getIcon(habit.icon),
                size: 20,
                color: palette.accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  habit.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 6-week trend sparkline
              if (sparklineData.length >= 2) ...[
                SizedBox(
                  width: 50,
                  height: 24,
                  child: CustomPaint(
                    painter: SparklinePainter(
                      data: sparklineData,
                      color: palette.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Small completion ring with percent
              SizedBox(
                width: 38,
                height: 38,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(38, 38),
                      painter: CompletionRingPainter(
                        progress: stats.percentage / 100,
                        trackColor: palette.border,
                        progressColor: palette.accent,
                        strokeWidth: 4,
                      ),
                    ),
                    Text(
                      '${stats.percentage.round()}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          Text(
            '${stats.completions} / ${stats.eligibleDays} days so far',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: palette.textSecondary,
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
                        fontWeight: isDayToday
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isDayToday
                            ? palette.textPrimary
                            : palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${d.day}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDayToday
                            ? palette.textPrimary
                            : palette.textSecondary,
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
          Divider(height: 1, thickness: 1, color: palette.border),
          const SizedBox(height: 10),

          // Bottom metrics: Missed, Rebounds, Streak
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12.0,
            runSpacing: 6.0,
            children: [
              Text(
                'Missed: ${stats.missed}',
                style: TextStyle(
                  fontSize: 12,
                  color: palette.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Rebounds: ${stats.rebounds}',
                style: TextStyle(
                  fontSize: 12,
                  color: palette.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: palette.cardRaised,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: palette.border, width: 0.5),
                ),
                child: Text(
                  '${currentStreak}d streak',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: currentStreak > 0
                        ? palette.textPrimary
                        : palette.textSecondary,
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
    final palette = context.palette;
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
              color: palette.accent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(Icons.check, size: 14, color: palette.onAccent),
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
              color: palette.card,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: palette.border, width: 1.5),
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
            border: Border.all(
              color: palette.border.withValues(alpha: 0.35),
              width: 1,
            ),
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
