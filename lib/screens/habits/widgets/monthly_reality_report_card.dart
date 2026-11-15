import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/dimens.dart';
import '../../../core/constants/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../providers/habits_providers.dart';
import '../../../widgets/motion/count_up_text.dart';

/// Monthly Reality Report Card showing raw, honest monthly metrics:
/// - Total Completions
/// - Streak Breaks (Missed Days through yesterday)
/// - Rebounds (Days saved after a miss)
/// Styled with 3 StatChip-style cards and a neutral rule-based summary below.
class MonthlyRealityReportCard extends ConsumerWidget {
  const MonthlyRealityReportCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final report = ref.watch(monthlyRealityReportProvider);
    final monthName = DateFormat('MMMM yyyy').format(AppDateUtils.today());

    // Neutral rule-based summary
    String? summaryText;
    if (report.completions > 0 ||
        report.missedDays > 0 ||
        report.rebounds > 0) {
      if (report.rebounds > 0) {
        summaryText =
            'You bounced back ${report.rebounds} ${report.rebounds == 1 ? "time" : "times"} this month.';
      } else if (report.missedDays > 0) {
        summaryText =
            'You had ${report.missedDays} missed ${report.missedDays == 1 ? "day" : "days"} this month.';
      } else {
        summaryText =
            'You had a clean month with ${report.completions} completions so far.';
      }
    }

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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8.0,
            runSpacing: 4.0,
            children: [
              Text(
                'Reality Report',
                style: TextStyle(
                  fontSize: 16,
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
          const SizedBox(height: 14),

          // 3 StatChip-style cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 340;

              final children = [
                _buildStatChip(
                  key: const Key('reality_metric_completions'),
                  icon: Icons.check_circle_outline,
                  iconColor: palette.accent,
                  label: 'Completions',
                  value: report.completions,
                  palette: palette,
                ),
                _buildStatChip(
                  key: const Key('reality_metric_streak_breaks'),
                  icon: Icons.event_busy_outlined,
                  iconColor: palette.danger,
                  label: 'Missed days',
                  value: report.missedDays,
                  palette: palette,
                ),
                _buildStatChip(
                  key: const Key('reality_metric_rebounds'),
                  icon: Icons.trending_up,
                  iconColor: palette.success,
                  label: 'Rebounds',
                  value: report.rebounds,
                  palette: palette,
                ),
              ];

              if (isNarrow) {
                return Column(
                  children: children
                      .map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: c,
                        ),
                      )
                      .toList(),
                );
              }

              return Row(
                children: [
                  Expanded(child: children[0]),
                  const SizedBox(width: 8),
                  Expanded(child: children[1]),
                  const SizedBox(width: 8),
                  Expanded(child: children[2]),
                ],
              );
            },
          ),

          if (summaryText != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: palette.cardRaised,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: palette.border, width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: palette.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      summaryText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required Key key,
    required IconData icon,
    required Color iconColor,
    required String label,
    required int value,
    required AppPalette palette,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.cardRaised,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: palette.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          CountUpText(
            value: value,
            duration: const Duration(milliseconds: 400),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
