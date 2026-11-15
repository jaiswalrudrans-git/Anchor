import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/dimens.dart';
import '../../../core/constants/habit_icons.dart';
import '../../../core/constants/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/haptics.dart';
import '../../../models/habit.dart';
import '../../../providers/habits_providers.dart';
import '../../../widgets/motion/animated_checkbox.dart';
import 'add_habit_sheet.dart';

/// Custom painter for the 6-8 radiating accent dots on today completion.
class RadiatingDotsPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color dotColor;

  RadiatingDotsPainter({required this.progress, required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = dotColor.withValues(alpha: (1.0 - progress).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    const dotCount = 8;
    final currentDistance = 16.0 + (progress * 22.0);
    final dotRadius = (2.2 * (1.0 - (progress * 0.35))).clamp(0.8, 2.5);

    for (int i = 0; i < dotCount; i++) {
      final angle = (i * 2 * math.pi) / dotCount;
      final offset = Offset(
        center.dx + math.cos(angle) * currentDistance,
        center.dy + math.sin(angle) * currentDistance,
      );
      canvas.drawCircle(offset, dotRadius, paint);
    }
  }

  @override
  bool shouldRepaint(RadiatingDotsPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.dotColor != dotColor;
}

/// Rich habit card (Overview) with playful motion, mini 7-day strip,
/// milestone pulse, icon bounce & tilt, and radiating dots.
class HabitCard extends ConsumerStatefulWidget {
  final Habit habit;
  final bool isLoggedToday;
  final int streak;
  final Set<DateTime> loggedDates;

  const HabitCard({
    super.key,
    required this.habit,
    required this.isLoggedToday,
    required this.streak,
    required this.loggedDates,
  });

  @override
  ConsumerState<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends ConsumerState<HabitCard>
    with TickerProviderStateMixin {
  late final AnimationController _iconController;
  late final Animation<double> _iconBounce;
  late final Animation<double> _iconTilt;

  late final AnimationController _dotsController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  int? _activeMilestone;
  Timer? _milestoneTimer;

  @override
  void initState() {
    super.initState();

    // 1. Icon bounce & tilt: translates up 6dp and tilts ~0.08 rad
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _iconBounce =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 40),
          TweenSequenceItem(tween: Tween(begin: -6.0, end: 0.0), weight: 60),
        ]).animate(
          CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
        );

    _iconTilt =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.08), weight: 40),
          TweenSequenceItem(tween: Tween(begin: -0.08, end: 0.0), weight: 60),
        ]).animate(
          CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
        );

    // 2. Radiating dots
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    // 3. Flame milestone pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseScale =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 40),
          TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 60),
        ]).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    _milestoneTimer?.cancel();
    _iconController.dispose();
    _dotsController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onToggleToday() {
    final willLog = !widget.isLoggedToday;

    if (willLog) {
      // User is ticking it!
      final nextStreak = widget.streak + 1;
      if (nextStreak == 7 || nextStreak == 30 || nextStreak == 100) {
        setState(() {
          _activeMilestone = nextStreak;
        });
        _pulseController.forward(from: 0.0);
        _milestoneTimer?.cancel();
        _milestoneTimer = Timer(const Duration(milliseconds: 4000), () {
          if (mounted) {
            setState(() {
              _activeMilestone = null;
            });
          }
        });
      }

      _iconController.forward(from: 0.0);
      _dotsController.forward(from: 0.0);
      Haptics.light();
    } else {
      // Quiet reversal on un-ticking (snappy, no dots)
      _dotsController.reset();
      _iconController.reset();
    }

    ref.read(habitLogsProvider.notifier).toggleToday(widget.habit.id);
  }

  Future<void> _confirmDelete() async {
    final palette = context.palette;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text(
          'Are you sure you want to delete "${widget.habit.title}"? All logged history will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.danger,
              foregroundColor: palette.onAccent,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(habitsProvider.notifier).deleteHabit(widget.habit.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final today = AppDateUtils.today();
    final iconData = HabitIcons.getIcon(widget.habit.icon);

    // Mini 7-day strip (ending today)
    final last7Days = List.generate(
      7,
      (i) => today.subtract(Duration(days: 6 - i)),
    );

    return InkWell(
      onLongPress: () =>
          AddHabitSheet.show(context, initialHabit: widget.habit),
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      child: Container(
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          border: Border.all(color: palette.border, width: AppDimens.hairline),
        ),
        padding: const EdgeInsets.all(AppDimens.cardPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Leading Icon in 44dp rounded square with bounce & tilt
            AnimatedBuilder(
              animation: _iconController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _iconBounce.value),
                  child: Transform.rotate(angle: _iconTilt.value, child: child),
                );
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: palette.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(iconData, size: 22, color: palette.accent),
                ),
              ),
            ),
            const SizedBox(width: AppDimens.space12),

            // 2. Center Column: Title + Mini 7-day strip + Streak badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.habit.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: widget.isLoggedToday
                          ? palette.textSecondary
                          : palette.textPrimary,
                      decoration: widget.isLoggedToday
                          ? TextDecoration.lineThrough
                          : null,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Mini 7-day strip
                  Wrap(
                    spacing: 3.0,
                    runSpacing: 2.0,
                    children: last7Days.map((d) {
                      final isToday = d == today;
                      final isPreCreation = d.isBefore(
                        AppDateUtils.dateOnly(widget.habit.createdAt),
                      );
                      final isDone = widget.loggedDates.contains(d);

                      return Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isPreCreation
                              ? Colors.transparent
                              : isDone
                              ? palette.accent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(2.5),
                          border: Border.all(
                            color: isToday
                                ? palette.accent
                                : isPreCreation
                                ? palette.border.withValues(alpha: 0.25)
                                : isDone
                                ? palette.accent
                                : palette.border,
                            width: isToday ? 1.5 : 1.0,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 6),

                  // Streak chip + milestone inline label
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6.0,
                    runSpacing: 4.0,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseScale.value,
                            child: child,
                          );
                        },
                        child: Container(
                          key: Key('habit_streak_badge_${widget.habit.id}'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: palette.cardRaised,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: palette.border, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                size: 13,
                                color: widget.streak > 0
                                    ? palette.accent
                                    : palette.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  transitionBuilder: (child, anim) {
                                    return ClipRect(
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0.0, 0.5),
                                          end: Offset.zero,
                                        ).animate(anim),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Text(
                                    '${widget.streak}d streak',
                                    key: ValueKey<int>(widget.streak),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: widget.streak > 0
                                          ? palette.textPrimary
                                          : palette.textSecondary,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_activeMilestone != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: palette.accentSoft,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: palette.accent, width: 1),
                          ),
                          child: Text(
                            '$_activeMilestone-day streak!',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: palette.accent,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // 3. Right: Trailing Actions + Large AnimatedCheckbox
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  key: Key('delete_habit_${widget.habit.id}'),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  visualDensity: VisualDensity.compact,
                  color: palette.textSecondary,
                  tooltip: 'Delete habit',
                  onPressed: _confirmDelete,
                ),
                const SizedBox(height: 4),
                RepaintBoundary(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Radiating dots painter
                      AnimatedBuilder(
                        animation: _dotsController,
                        builder: (context, _) {
                          return CustomPaint(
                            size: const Size(40, 40),
                            painter: RadiatingDotsPainter(
                              progress: _dotsController.value,
                              dotColor: palette.accent,
                            ),
                          );
                        },
                      ),
                      // AnimatedCheckbox (32dp, playful: true)
                      AnimatedCheckbox(
                        key: Key('habit_today_toggle_${widget.habit.id}'),
                        value: widget.isLoggedToday,
                        playful: true,
                        size: 32.0,
                        onChanged: (_) => _onToggleToday(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
