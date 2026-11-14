import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/expense_month_summary.dart';
import '../../../models/expense_transaction.dart';
import '../../../providers/expenses_providers.dart';
import '../../../widgets/empty_state.dart';
import 'add_transaction_sheet.dart';

/// Monthly ledger tab containing the month selector, action button (current month only),
/// closed month snapshot card (past months only), and itemized transactions list.
class MonthlyLedgerTab extends ConsumerWidget {
  const MonthlyLedgerTab({super.key});

  static final DateFormat _txDateFormat = DateFormat('MMM d, hh:mm a');

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction deleted.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  Widget _buildMonthSelector(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthKeyProvider);
    final availableMonths = ref.watch(availableMonthKeysProvider);
    final isCurrent = ref.watch(isCurrentMonthSelectedProvider);

    final currentIndex = availableMonths.indexOf(selectedMonth);
    final canGoPrev = currentIndex > 0;
    final canGoNext = currentIndex >= 0 && currentIndex < availableMonths.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTheme.borderRadius8,
        border: Border.all(color: AppColors.border, width: 1),
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppDateUtils.formatMonthTitle(selectedMonth),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
              if (isCurrent) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryText,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'CURRENT',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.background,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
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
    if (summary == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppTheme.borderRadius8,
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'Closed Month (Read Only)',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
    }

    return Container(
      key: const Key('closed_month_snapshot_card'),
      margin: const EdgeInsets.only(bottom: 14.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTheme.borderRadius8,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CLOSED MONTH SNAPSHOT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryText,
                  letterSpacing: 0.6,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'READ ONLY',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                    letterSpacing: 0.5,
                  ),
                ),
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
                ),
              ),
              Expanded(
                child: _buildSnapshotItem(
                  'Received',
                  AppDateUtils.formatCurrency(summary.received),
                ),
              ),
              Expanded(
                child: _buildSnapshotItem(
                  'Spent',
                  AppDateUtils.formatCurrency(summary.spent),
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
                ),
              ),
              Expanded(
                child: _buildSnapshotItem(
                  'Remainder',
                  AppDateUtils.formatCurrency(summary.remainder),
                ),
              ),
              Expanded(
                child: _buildSnapshotItem(
                  'Carried to Savings',
                  AppDateUtils.formatCurrency(summary.carriedToSavings),
                  isBold: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSnapshotItem(String label, String value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.secondaryText),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: AppColors.primaryText,
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
    final isSpent = tx.txType == 'spent';
    final isReceived = tx.txType == 'received';
    final isSaved = tx.txType == 'saved';

    final sign = isSpent ? '-' : (isReceived ? '+' : '');
    final prefix = isSaved ? 'Saved ' : sign;
    final formattedAmount = '$prefix${AppDateUtils.formatCurrency(tx.amount)}';

    return Container(
      key: ValueKey('transaction_row_${tx.id}'),
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppTheme.borderRadius8,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Material(
        color: AppColors.background,
        borderRadius: AppTheme.borderRadius8,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 2.0),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Icon(
              isSaved
                  ? Icons.savings_outlined
                  : (isReceived
                      ? Icons.arrow_downward_outlined
                      : Icons.arrow_upward_outlined),
              size: 18,
              color: AppColors.primaryText,
            ),
          ),
          title: Text(
            tx.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Text(
                  tx.category,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _txDateFormat.format(tx.txDate.toLocal()),
                style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formattedAmount,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isSpent
                      ? AppColors.primaryText
                      : (isReceived ? AppColors.primaryText : AppColors.secondaryText),
                ),
              ),
              if (isCurrentMonth) ...[
                const SizedBox(width: 4),
                IconButton(
                  key: ValueKey('delete_tx_${tx.id}'),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: AppColors.secondaryText,
                  splashRadius: 18,
                  onPressed: () => _confirmDelete(context, ref, tx),
                  tooltip: 'Delete transaction',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthKeyProvider);
    final isCurrent = ref.watch(isCurrentMonthSelectedProvider);
    final transactions = ref.watch(transactionsForSelectedMonthProvider);
    final pastSummary = ref.watch(summaryForSelectedMonthProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Month Selector
        _buildMonthSelector(context, ref),
        const SizedBox(height: 14),

        // Read-only snapshot banner for past closed months
        if (!isCurrent) _buildClosedMonthSnapshot(context, pastSummary, selectedMonth),

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

        // Transactions List
        Expanded(
          child: transactions.isEmpty
              ? EmptyState(
                  key: const Key('empty_transactions_state'),
                  icon: Icons.receipt_long_outlined,
                  title: isCurrent
                      ? 'No transactions this month.'
                      : 'No transactions recorded for this month.',
                  message: isCurrent
                      ? 'Tap "Log Transaction" to record expenses, income, or savings.'
                      : 'This closed month has no recorded transaction rows.',
                )
              : ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (ctx, index) => _buildTransactionRow(
                    context,
                    ref,
                    transactions[index],
                    isCurrent,
                  ),
                ),
        ),
      ],
    );
  }
}
