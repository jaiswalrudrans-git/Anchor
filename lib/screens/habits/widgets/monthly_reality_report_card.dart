import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../providers/habits_providers.dart';

/// Monthly Reality Report Card showing raw, honest monthly metrics:
/// - Total Completions
/// - Streak Breaks (Missed Days through yesterday)
/// - Rebounds (Days saved after a miss)
class MonthlyRealityReportCard extends ConsumerWidget {
  const MonthlyRealityReportCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(monthlyRealityReportProvider);
    final monthName = DateFormat('MMMM yyyy').format(AppDateUtils.today());

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTheme.borderRadius8,
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reality Report',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                monthName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  key: const Key('reality_metric_completions'),
                  label: 'Completions',
                  value: '${report.completions}',
                  subtext: 'this month',
                ),
              ),
              Container(
                width: 1,
                height: 48,
                color: AppColors.border,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              Expanded(
                child: _buildMetricTile(
                  key: const Key('reality_metric_streak_breaks'),
                  label: 'Streak Breaks',
                  value: '${report.missedDays}',
                  subtext: 'days missed',
                ),
              ),
              Container(
                width: 1,
                height: 48,
                color: AppColors.border,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              Expanded(
                child: _buildMetricTile(
                  key: const Key('reality_metric_rebounds'),
                  label: 'Rebounds',
                  value: '${report.rebounds}',
                  subtext: 'bounce backs',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required Key key,
    required String label,
    required String value,
    required String subtext,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtext,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.secondaryText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
