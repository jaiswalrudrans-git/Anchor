import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/dimens.dart';
import '../../../core/constants/motion.dart';
import '../../../core/constants/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/expense_utils.dart';
import '../../../providers/expenses_providers.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/motion/animated_progress_bar.dart';
import '../../../widgets/motion/count_up_text.dart';
import 'edit_allowance_dialog.dart';

/// 4-Metric header for the active month:
/// 1. Monthly Allowance (editable via modal dialog)
/// 2. Spent This Month
/// 3. Remaining Balance = (Allowance + Received) - (Spent + Saved)
/// 4. Savings Locker = Total accumulated savings
///
/// Features a spending progress bar directly under the header for the current month
/// with budget tone thresholds (<75% accent, 75-100% warning, >100% danger).
class ExpenseMetricsHeader extends ConsumerWidget {
  const ExpenseMetricsHeader({super.key});

  Widget _buildMetricCard({
    required BuildContext context,
    required String label,
    required double value,
    required Key key,
    Widget? trailingAction,
    bool isRemainingCard = false,
    bool isPositive = true,
  }) {
    final palette = context.palette;

    Color? bg;
    Color? border;
    if (isRemainingCard) {
      bg = isPositive ? palette.accentSoft : palette.dangerSoft;
      border = isPositive
          ? palette.accent.withValues(alpha: 0.35)
          : palette.danger.withValues(alpha: 0.35);
    }

    return KeyedSubtree(
      key: key,
      child: AppCard(
        backgroundColor: bg,
        borderColor: border,
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: palette.textSecondary,
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
            CountUpText(
              value: value,
              duration: const Duration(milliseconds: 300),
              formatter: (v) => AppDateUtils.formatCurrency(v.toDouble()),
              style: TextStyle(
                fontSize: isRemainingCard ? 18 : 16,
                fontWeight: FontWeight.w700,
                color: isRemainingCard
                    ? (isPositive ? palette.textPrimary : palette.danger)
                    : palette.textPrimary,
                letterSpacing: -0.3,
                fontFeatures: AppTypography.tabularFigures,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final isCurrent = ref.watch(isCurrentMonthSelectedProvider);

    final settings = ref.watch(expenseSettingsProvider).value;
    final allowance = settings?.monthlyAllowance ?? 0.0;
    final totalSavings = settings?.totalSavings ?? 0.0;

    final spent = ref.watch(currentMonthSpentProvider);
    final remaining = ref.watch(currentMonthRemainingBalanceProvider);

    final allowanceCard = _buildMetricCard(
      context: context,
      label: 'MONTHLY ALLOWANCE',
      value: allowance,
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
      value: spent,
      key: const Key('metric_card_spent'),
    );

    final remainingCard = _buildMetricCard(
      context: context,
      label: 'REMAINING BALANCE',
      value: remaining,
      key: const Key('metric_card_remaining'),
      isRemainingCard: true,
      isPositive: remaining >= 0,
    );

    final savingsCard = _buildMetricCard(
      context: context,
      label: 'SAVINGS LOCKER',
      value: totalSavings,
      key: const Key('metric_card_savings'),
    );

    final tone = getSpendingTone(spent, allowance);
    final toneColor = tone == SpendingTone.danger
        ? palette.danger
        : (tone == SpendingTone.warning ? palette.warning : palette.accent);
    final isOverBudget = spent > allowance && allowance > 0;
    final progressFraction = allowance > 0 ? (spent / allowance).clamp(0.0, 1.0) : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 4 Metrics Grid: 1 row on medium/expanded (>=600), 2x2 on compact
            if (isWide)
              Row(
                children: [
                  Expanded(child: allowanceCard),
                  const SizedBox(width: 8),
                  Expanded(child: spentCard),
                  const SizedBox(width: 8),
                  Expanded(child: remainingCard),
                  const SizedBox(width: 8),
                  Expanded(child: savingsCard),
                ],
              )
            else
              Column(
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
              ),

            // Spending progress bar (Current month only)
            if (isCurrent) ...[
              const SizedBox(height: 12),
              if (allowance <= 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: palette.card,
                    borderRadius: AppDimens.borderRadiusSm,
                    border: Border.all(color: palette.border, width: AppDimens.hairline),
                  ),
                  child: constraints.maxWidth < 450
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, size: 16, color: palette.textSecondary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Set your monthly allowance to track your spending.',
                                    style: TextStyle(fontSize: 12, color: palette.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                key: const Key('set_allowance_nudge_button'),
                                onPressed: () => EditAllowanceDialog.show(context, allowance),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Set allowance',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: palette.accent,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: palette.textSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Set your monthly allowance to track your spending.',
                                style: TextStyle(fontSize: 12, color: palette.textSecondary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              key: const Key('set_allowance_nudge_button'),
                              onPressed: () => EditAllowanceDialog.show(context, allowance),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Set allowance',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: palette.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                )
              else ...[
                AnimatedProgressBar(
                  value: progressFraction,
                  height: 6.0,
                  colorOverride: toneColor,
                  duration: Motion.base,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        getSpendingCaption(spent, allowance),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isOverBudget ? FontWeight.w600 : FontWeight.w500,
                          color: isOverBudget ? palette.danger : palette.textSecondary,
                          fontFeatures: AppTypography.tabularFigures,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(spent / allowance * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: toneColor,
                        fontFeatures: AppTypography.tabularFigures,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        );
      },
    );
  }
}
