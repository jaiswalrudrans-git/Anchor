import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/expense_month_summary.dart';
import '../../../providers/expenses_providers.dart';
import '../../../widgets/empty_state.dart';

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
    return Container(
      key: ValueKey('history_month_card_${summary.month}'),
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppTheme.borderRadius8,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Material(
        color: AppColors.background,
        borderRadius: AppTheme.borderRadius8,
        child: InkWell(
          borderRadius: AppTheme.borderRadius8,
          onTap: () {
            ref.read(selectedMonthKeyProvider.notifier).select(summary.month);
            onMonthTapped?.call(summary.month);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppDateUtils.formatMonthTitle(summary.month),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Row(
                      children: [
                        const Text(
                          'View Ledger',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: AppColors.secondaryText,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        'Allowance',
                        AppDateUtils.formatCurrency(summary.allowance),
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Spent',
                        AppDateUtils.formatCurrency(summary.spent),
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Received',
                        AppDateUtils.formatCurrency(summary.received),
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
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Remainder',
                        AppDateUtils.formatCurrency(summary.remainder),
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Carried to Savings',
                        AppDateUtils.formatCurrency(summary.carriedToSavings),
                        isProminent: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, {bool isProminent = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.secondaryText,
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
            color: AppColors.primaryText,
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
