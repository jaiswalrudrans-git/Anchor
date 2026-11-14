import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/theme.dart';
import '../../core/services/expense_reset_service.dart';
import '../../providers/expenses_providers.dart';
import '../../widgets/responsive_container.dart';
import 'widgets/expense_metrics_header.dart';
import 'widgets/expenses_history_tab.dart';
import 'widgets/monthly_ledger_tab.dart';

/// Expenses screen:
/// - 4-metric header for active month (Allowance, Spent, Remaining, Savings)
/// - Segmented toggle between Ledger and History
/// - Itemized ledger with month browser and strict single add action
/// - Permanent closed months history with snapshot drill-down
class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  int _selectedSegment = 0; // 0 = Ledger, 1 = History

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runRolloverAndRefresh();
    });
  }

  Future<void> _runRolloverAndRefresh() async {
    try {
      await ref.read(expenseResetServiceProvider).runMonthlyReset();
      if (mounted) {
        await ref.read(expenseSettingsProvider.notifier).refreshSettings();
        await ref.read(allTransactionsProvider.notifier).refresh();
        await ref.read(monthSummariesProvider.notifier).refresh();
      }
    } catch (e) {
      debugPrint('ExpensesScreen: error during rollover/refresh: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Expenses',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            key: const Key('expenses_refresh_button'),
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh expenses',
            onPressed: _runRolloverAndRefresh,
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 900,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. 4-Metric Header (Active Month)
                const ExpenseMetricsHeader(),
                const SizedBox(height: 14),

                // 2. Segmented toggle: Ledger | History
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppTheme.borderRadius8,
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSegmentButton(
                          title: 'Monthly Ledger',
                          icon: Icons.receipt_long_outlined,
                          isSelected: _selectedSegment == 0,
                          onTap: () => setState(() => _selectedSegment = 0),
                        ),
                      ),
                      Container(width: 1, height: 32, color: AppColors.border),
                      Expanded(
                        child: _buildSegmentButton(
                          title: 'History',
                          icon: Icons.history_outlined,
                          isSelected: _selectedSegment == 1,
                          onTap: () => setState(() => _selectedSegment = 1),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 3. Main content: Ledger or History
                Expanded(
                  child: _selectedSegment == 0
                      ? const MonthlyLedgerTab()
                      : ExpensesHistoryTab(
                          onMonthTapped: (monthKey) {
                            setState(() => _selectedSegment = 0);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppTheme.borderRadius8,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryText : Colors.transparent,
          borderRadius: AppTheme.borderRadius8,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? AppColors.background : AppColors.secondaryText,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.background : AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
