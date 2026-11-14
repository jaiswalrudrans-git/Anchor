import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/expense_month_summary.dart';
import '../../../providers/expenses_providers.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/motion/animated_progress_bar.dart';

/// Permanent month-by-month history tab listing all closed months.
/// Tapping any month navigates to its full itemized ledger (read-only).
class ExpensesHistoryTab extends ConsumerWidget {
  final void Function(String monthKey)? onMonthTapped;

  const ExpensesHistoryTab({
    super.key,
    this.onMonthTapped,
  });

  Widget _buildSummaryCard(
    BuildContext context,
    WidgetRef ref,
    ExpenseMonthSummary summary,
  ) {
    final palette = context.palette;
    final progress = summary.allowance > 0
        ? (summary.spent / summary.allowance).clamp(0.0, 1.0)
        : 0.0;
    final pctText = summary.allowance > 0
        ? '${(summary.spent / summary.allowance * 100).toStringAsFixed(0)}% spent'
        : '0% spent';

    return Container(
      key: ValueKey('history_month_card_${summary.month}'),
      margin: const EdgeInsets.only(bottom: 12.0),
      child: AppCard(
        onTap: () {
          ref.read(selectedMonthKeyProvider.notifier).select(summary.month);
          onMonthTapped?.call(summary.month);
        },
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppDateUtils.formatMonthTitle(summary.month),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Ledger',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: palette.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: palette.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Mini bar of spent vs allowance
            AnimatedProgressBar(
              value: progress,
              height: 4.0,
              colorOverride: palette.accent,
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                pctText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: palette.textSecondary,
                  fontFeatures: AppTypography.tabularFigures,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Divider(height: 1, color: palette.border),
            const SizedBox(height: 12),

            // Stat rows
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Allowance',
                    AppDateUtils.formatCurrency(summary.allowance),
                    palette: palette,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Spent',
                    AppDateUtils.formatCurrency(summary.spent),
                    palette: palette,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Received',
                    AppDateUtils.formatCurrency(summary.received),
                    palette: palette,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Saved',
                    AppDateUtils.formatCurrency(summary.saved),
                    palette: palette,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Remainder',
                    AppDateUtils.formatCurrency(summary.remainder),
                    palette: palette,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Carried to Savings',
                    AppDateUtils.formatCurrency(summary.carriedToSavings),
                    isProminent: true,
                    palette: palette,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, {bool isProminent = false, required AppPalette palette}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: palette.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isProminent ? FontWeight.w700 : FontWeight.w500,
            color: palette.textPrimary,
            fontFeatures: AppTypography.tabularFigures,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries = ref.watch(monthSummariesProvider).value ?? [];

    if (summaries.isEmpty) {
      return const EmptyState(
        key: Key('history_empty_state'),
        icon: Icons.history_outlined,
        title: 'History appears after your first month closes.',
        message:
            'At the start of each new month, a permanent snapshot of your allowance, spending, and savings rollover is saved here.',
      );
    }

    return ListView.builder(
      itemCount: summaries.length,
      itemBuilder: (ctx, index) => _buildSummaryCard(
        context,
        ref,
        summaries[index],
      ),
    );
  }
}
