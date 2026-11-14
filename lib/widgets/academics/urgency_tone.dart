import 'package:flutter/material.dart';

import '../../core/constants/theme.dart';

/// Semantic urgency tone for deadlines and countdowns.
/// Normal: Accent tone
/// Soon: Warning tone (<= 2 days for assignments, <= 3 days for exams)
/// Overdue: Danger tone (< 0 days)
enum UrgencyTone {
  normal,
  soon,
  overdue;

  static UrgencyTone fromDaysLeft(int daysLeft, {int soonThreshold = 2}) {
    if (daysLeft < 0) return UrgencyTone.overdue;
    if (daysLeft <= soonThreshold) return UrgencyTone.soon;
    return UrgencyTone.normal;
  }

  Color foreground(AppPalette palette) => switch (this) {
        UrgencyTone.overdue => palette.danger,
        UrgencyTone.soon => palette.warning,
        UrgencyTone.normal => palette.accent,
      };

  Color background(AppPalette palette) => switch (this) {
        UrgencyTone.overdue => palette.dangerSoft,
        UrgencyTone.soon => palette.warningSoft,
        UrgencyTone.normal => palette.accentSoft,
      };

  Color border(AppPalette palette) => switch (this) {
        UrgencyTone.overdue => palette.danger.withValues(alpha: 0.3),
        UrgencyTone.soon => palette.warning.withValues(alpha: 0.3),
        UrgencyTone.normal => palette.accent.withValues(alpha: 0.3),
      };
}
