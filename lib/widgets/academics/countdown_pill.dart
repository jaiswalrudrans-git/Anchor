import 'package:flutter/material.dart';

import '../../core/constants/theme.dart';
import 'urgency_tone.dart';

/// Pure helper returning the standard label for a countdown pill.
String countdownPillLabel(int daysLeft) {
  if (daysLeft == 0) return 'Today';
  if (daysLeft > 0) return '${daysLeft}d';
  return 'Overdue ${daysLeft.abs()}d';
}

/// Small pill badge showing remaining days with semantic urgency coloring.
class CountdownPill extends StatelessWidget {
  final int daysLeft;
  final UrgencyTone? toneOverride;

  const CountdownPill({
    super.key,
    required this.daysLeft,
    this.toneOverride,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tone = toneOverride ?? UrgencyTone.fromDaysLeft(daysLeft);
    final label = countdownPillLabel(daysLeft);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.5),
      decoration: BoxDecoration(
        color: tone.background(palette),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: tone.border(palette),
          width: 1.0,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: tone.foreground(palette),
          fontFeatures: AppTypography.tabularFigures,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}
