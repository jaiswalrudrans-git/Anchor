import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../providers/expenses_providers.dart';
import 'edit_allowance_dialog.dart';

/// 4-Metric header for the active month:
/// 1. Monthly Allowance (editable via modal dialog)
/// 2. Spent This Month
/// 3. Remaining Balance = (Allowance + Received) - (Spent + Saved)
/// 4. Savings Locker = Total accumulated savings
class ExpenseMetricsHeader extends ConsumerWidget {
  const ExpenseMetricsHeader({super.key});

  Widget _buildMetricCard({
    required BuildContext context,
    required String label,
    required String formattedValue,
    required Key key,
    Widget? trailingAction,
    bool isHighlighted = false,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppTheme.borderRadius8,
        border: Border.all(
          color: isHighlighted ? AppColors.primaryText : AppColors.border,
          width: isHighlighted ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryText,
                    letterSpacing: 0.6,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ?trailingAction,
            ],
          ),
          const SizedBox(height: 6),
          Text(
            formattedValue,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(expenseSettingsProvider).value;
    final allowance = settings?.monthlyAllowance ?? 0.0;
    final totalSavings = settings?.totalSavings ?? 0.0;

    final spent = ref.watch(currentMonthSpentProvider);
    final remaining = ref.watch(currentMonthRemainingBalanceProvider);

    final allowanceCard = _buildMetricCard(
      context: context,
      label: 'MONTHLY ALLOWANCE',
      formattedValue: AppDateUtils.formatCurrency(allowance),
      key: const Key('metric_card_allowance'),
      trailingAction: IconButton(
        key: const Key('edit_allowance_button'),
        icon: const Icon(Icons.edit_outlined, size: 15),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        splashRadius: 14,
        tooltip: 'Edit monthly allowance',
        onPressed: () => EditAllowanceDialog.show(context, allowance),
      ),
    );

    final spentCard = _buildMetricCard(
      context: context,
      label: 'SPENT THIS MONTH',
      formattedValue: AppDateUtils.formatCurrency(spent),
      key: const Key('metric_card_spent'),
    );

    final remainingCard = _buildMetricCard(
      context: context,
      label: 'REMAINING BALANCE',
      formattedValue: AppDateUtils.formatCurrency(remaining),
      key: const Key('metric_card_remaining'),
      isHighlighted: true,
    );

    final savingsCard = _buildMetricCard(
      context: context,
      label: 'SAVINGS LOCKER',
      formattedValue: AppDateUtils.formatCurrency(totalSavings),
      key: const Key('metric_card_savings'),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;

        if (isWide) {
          return Row(
            children: [
              Expanded(child: allowanceCard),
              const SizedBox(width: 8),
              Expanded(child: spentCard),
              const SizedBox(width: 8),
              Expanded(child: remainingCard),
              const SizedBox(width: 8),
              Expanded(child: savingsCard),
            ],
          );
        }

        // 2x2 grid for mobile / compact screens
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: allowanceCard),
                const SizedBox(width: 8),
                Expanded(child: spentCard),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: remainingCard),
                const SizedBox(width: 8),
                Expanded(child: savingsCard),
              ],
            ),
          ],
        );
      },
    );
  }
}
