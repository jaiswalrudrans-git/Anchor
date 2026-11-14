import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/dimens.dart';
import '../../../core/constants/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/expense_utils.dart';
import '../../../models/expense_month_summary.dart';
import '../../../models/expense_transaction.dart';
import '../../../providers/expenses_providers.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/tag.dart';
import 'add_transaction_sheet.dart';

/// Monthly ledger tab containing the month selector, action button (current month only),
/// closed month snapshot card (past months only), and itemized transactions list grouped by day.
class MonthlyLedgerTab extends ConsumerWidget {
  const MonthlyLedgerTab({super.key});

  static final DateFormat _txTimeFormat = DateFormat('hh:mm a');

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ExpenseTransaction tx,
  ) async {
    final isSaved = tx.txType == 'saved';
    final message = isSaved
        ? 'Delete this savings transfer of ${AppDateUtils.formatCurrency(tx.amount)}?\nThis will deduct the amount from your Savings Locker.'
        : 'Delete "${tx.title}" (${AppDateUtils.formatCurrency(tx.amount)})?';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(allTransactionsProvider.notifier).deleteTransaction(tx);
        if (context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Transaction deleted.'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  ref
                      .read(allTransactionsProvider.notifier)
                      .restoreTransaction(tx);
                },
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
      }
    }
  }

  Future<void> _handleSwipeDelete(
    BuildContext context,
    WidgetRef ref,
    ExpenseTransaction tx,
  ) async {
    try {
      await ref.read(allTransactionsProvider.notifier).deleteTransaction(tx);
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transaction deleted.'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                ref
                    .read(allTransactionsProvider.notifier)
                    .restoreTransaction(tx);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  Widget _buildMonthSelector(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthKeyProvider);
    final availableMonths = ref.watch(availableMonthKeysProvider);
    final isCurrent = ref.watch(isCurrentMonthSelectedProvider);

    final currentIndex = availableMonths.indexOf(selectedMonth);
    final canGoPrev = currentIndex > 0;
    final canGoNext =
        currentIndex >= 0 && currentIndex < availableMonths.length - 1;

    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: AppDimens.borderRadiusSm,
        border: Border.all(color: palette.border, width: AppDimens.hairline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            key: const Key('prev_month_button'),
            icon: const Icon(Icons.chevron_left, size: 20),
            splashRadius: 18,
            onPressed: canGoPrev
                ? () => ref
                      .read(selectedMonthKeyProvider.notifier)
                      .selectPrevious(availableMonths)
                : null,
            tooltip: 'Previous month',
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    AppDateUtils.formatMonthTitle(selectedMonth),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: palette.accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'CURRENT',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: palette.onAccent,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            key: const Key('next_month_button'),
            icon: const Icon(Icons.chevron_right, size: 20),
            splashRadius: 18,
            onPressed: canGoNext
                ? () => ref
                      .read(selectedMonthKeyProvider.notifier)
                      .selectNext(availableMonths)
                : null,
            tooltip: 'Next month',
          ),
        ],
      ),
    );
  }

  Widget _buildClosedMonthSnapshot(
    BuildContext context,
    ExpenseMonthSummary? summary,
    String monthKey,
  ) {
    final palette = context.palette;

    if (summary == null) {
      return AppCard(
        key: const Key('closed_month_snapshot_card'),
        margin: const EdgeInsets.only(bottom: 12.0),
        child: Text(
          'Closed Month (Read Only)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: palette.textSecondary,
          ),
        ),
      );
    }

    final pctSpent = summary.allowance > 0
        ? (summary.spent / summary.allowance * 100).toStringAsFixed(0)
        : '0';

    return AppCard(
      key: const Key('closed_month_snapshot_card'),
      margin: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CLOSED MONTH SNAPSHOT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: palette.textSecondary,
                  letterSpacing: 0.6,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: palette.accentSoft,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$pctSpent% spent',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: palette.accent,
                        letterSpacing: 0.5,
                        fontFeatures: AppTypography.tabularFigures,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: palette.cardRaised,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: palette.border, width: 1),
                    ),
                    child: Text(
                      'READ ONLY',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSnapshotItem(
                  'Allowance',
                  AppDateUtils.formatCurrency(summary.allowance),
                  palette: palette,
                ),
              ),
              Expanded(
                child: _buildSnapshotItem(
                  'Received',
                  AppDateUtils.formatCurrency(summary.received),
                  palette: palette,
                ),
              ),
              Expanded(
                child: _buildSnapshotItem(
                  'Spent',
                  AppDateUtils.formatCurrency(summary.spent),
                  palette: palette,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSnapshotItem(
                  'Saved',
                  AppDateUtils.formatCurrency(summary.saved),
                  palette: palette,
                ),
              ),
              Expanded(
                child: _buildSnapshotItem(
                  'Remainder',
                  AppDateUtils.formatCurrency(summary.remainder),
                  palette: palette,
                ),
              ),
              Expanded(
                child: _buildSnapshotItem(
                  'Carried to Savings',
                  AppDateUtils.formatCurrency(summary.carriedToSavings),
                  isBold: true,
                  palette: palette,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSnapshotItem(
    String label,
    String value, {
    bool isBold = false,
    required AppPalette palette,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: palette.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: palette.textPrimary,
            fontFeatures: AppTypography.tabularFigures,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildTransactionRow(
    BuildContext context,
    WidgetRef ref,
    ExpenseTransaction tx,
    bool isCurrentMonth,
  ) {
    final palette = context.palette;
    final isSpent = tx.txType == 'spent';
    final isReceived = tx.txType == 'received';
    final isSaved = tx.txType == 'saved';

    final sign = isSpent ? '-' : (isReceived ? '+' : '');
    final prefix = isSaved ? '' : sign;
    final formattedAmount = '$prefix${AppDateUtils.formatCurrency(tx.amount)}';

    final rowCard = AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      child: Row(
        children: [
          // Category icon in an accentSoft rounded square
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isSpent
                  ? palette.accentSoft
                  : (isReceived
                        ? palette.success.withValues(alpha: 0.14)
                        : palette.accentSoft),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              getExpenseCategoryIcon(tx.category, tx.txType),
              size: 18,
              color: isSpent
                  ? palette.accent
                  : (isReceived ? palette.success : palette.accent),
            ),
          ),
          const SizedBox(width: 12),

          // Title & Category tag + Time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Tag(label: tx.category, color: palette.textSecondary),
                    Text(
                      _txTimeFormat.format(tx.txDate.toLocal()),
                      style: TextStyle(
                        fontSize: 11,
                        color: palette.textSecondary,
                        fontFeatures: AppTypography.tabularFigures,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Amount + Delete Action
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSaved) ...[
                Icon(Icons.savings_outlined, size: 14, color: palette.accent),
                const SizedBox(width: 4),
              ],
              Text(
                formattedAmount,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isSpent
                      ? palette.textPrimary
                      : (isReceived ? palette.success : palette.accent),
                  fontFeatures: AppTypography.tabularFigures,
                ),
              ),
              if (isCurrentMonth) ...[
                const SizedBox(width: 4),
                IconButton(
                  key: ValueKey('delete_tx_${tx.id}'),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: palette.textSecondary,
                  splashRadius: 18,
                  onPressed: () => _confirmDelete(context, ref, tx),
                  tooltip: 'Delete transaction',
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (!isCurrentMonth) {
      return Container(
        key: ValueKey('transaction_row_${tx.id}'),
        margin: const EdgeInsets.only(bottom: 8.0),
        child: rowCard,
      );
    }

    return Container(
      key: ValueKey('transaction_row_${tx.id}'),
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Dismissible(
        key: ValueKey('tx_dismiss_${tx.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20.0),
          decoration: BoxDecoration(
            color: palette.danger,
            borderRadius: AppDimens.borderRadiusMd,
          ),
          child: Icon(Icons.delete_outline, color: palette.onDanger, size: 20),
        ),
        onDismissed: (_) => _handleSwipeDelete(context, ref, tx),
        child: rowCard,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthKeyProvider);
    final isCurrent = ref.watch(isCurrentMonthSelectedProvider);
    final transactions = ref.watch(transactionsForSelectedMonthProvider);
    final pastSummary = ref.watch(summaryForSelectedMonthProvider);
    final palette = context.palette;

    final groupedDays = groupTransactionsByDay(transactions);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Month Selector
        _buildMonthSelector(context, ref),
        const SizedBox(height: 14),

        // Read-only snapshot banner for past closed months
        if (!isCurrent)
          _buildClosedMonthSnapshot(context, pastSummary, selectedMonth),

        // Action: + Log Transaction (ONLY add control on this page, current month only)
        if (isCurrent) ...[
          ElevatedButton.icon(
            key: const Key('add_transaction_button'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Log Transaction'),
            onPressed: () => AddTransactionSheet.show(context),
          ),
          const SizedBox(height: 14),
        ],

        // Transactions List Grouped by Day
        Expanded(
          child: transactions.isEmpty
              ? EmptyState(
                  key: const Key('empty_transactions_state'),
                  icon: Icons.receipt_long_outlined,
                  title: isCurrent
                      ? 'No transactions this month'
                      : 'No transactions recorded for this month.',
                  message: isCurrent
                      ? 'Log your first one to start tracking.'
                      : 'This closed month has no recorded transaction rows.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88.0),
                  itemCount: groupedDays.length,
                  itemBuilder: (ctx, dayIndex) {
                    final dayGroup = groupedDays[dayIndex];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Sticky-style Day Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            4.0,
                            10.0,
                            4.0,
                            6.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                dayGroup.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: palette.textSecondary,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              Text(
                                formatDayNetSpend(
                                  dayGroup.netSpend,
                                  includePrefix: true,
                                ),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: palette.textSecondary,
                                  fontFeatures: AppTypography.tabularFigures,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Transactions in this day
                        ...dayGroup.transactions.map(
                          (tx) =>
                              _buildTransactionRow(context, ref, tx, isCurrent),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}
