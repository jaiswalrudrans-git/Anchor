import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/motion.dart';
import '../../core/constants/theme.dart';
import 'urgency_tone.dart';

/// Pure calculation of proximity fill fraction for a deadline.
/// Fill = 1 - min(max(daysLeft, 0), 14) / 14.
/// 14+ days: 0.0
/// 7 days: 0.5
/// 0 days or overdue (< 0): 1.0
double deadlineBarFill(int daysLeft) {
  final clamped = math.min(math.max(daysLeft, 0), 14);
  return 1.0 - (clamped / 14.0);
}

/// A thin 4dp animated bar indicating deadline proximity.
class DeadlineBar extends StatelessWidget {
  final int daysLeft;
  final UrgencyTone? toneOverride;

  const DeadlineBar({super.key, required this.daysLeft, this.toneOverride});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tone = toneOverride ?? UrgencyTone.fromDaysLeft(daysLeft);
    final targetFill = deadlineBarFill(daysLeft);
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return Container(
      height: 4.0,
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.border.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(2.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: disableAnimations
          ? FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: targetFill,
              child: Container(
                decoration: BoxDecoration(
                  color: tone.foreground(palette),
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            )
          : TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: targetFill),
              duration: Motion.base,
              curve: Motion.standard,
              builder: (context, value, _) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: tone.foreground(palette),
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
