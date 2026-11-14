import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/dimens.dart';
import '../../core/constants/theme.dart';
import '../../core/services/expense_reset_service.dart';
import '../../providers/expenses_providers.dart';
import '../../widgets/responsive/page_container.dart';
import 'widgets/expense_metrics_header.dart';
import 'widgets/expenses_history_tab.dart';
import 'widgets/monthly_ledger_tab.dart';

/// Expenses screen:
/// - 4-metric header for active month (Allowance, Spent, Remaining, Savings)
/// - Spending progress bar with budget tones
/// - Segmented toggle between Ledger and History with 200 ms cross-fade
/// - Itemized ledger with day grouping and swipe-to-delete + undo
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
    final palette = context.palette;

    return Scaffold(
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
        child: PageContainer(
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
                  color: palette.card,
                  borderRadius: AppDimens.borderRadiusSm,
                  border: Border.all(color: palette.border, width: AppDimens.hairline),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSegmentButton(
                        title: 'Monthly Ledger',
                        icon: Icons.receipt_long_outlined,
                        isSelected: _selectedSegment == 0,
                        onTap: () => setState(() => _selectedSegment = 0),
                        palette: palette,
                      ),
                    ),
                    Container(width: 1, height: 28, color: palette.border),
                    Expanded(
                      child: _buildSegmentButton(
                        title: 'History',
                        icon: Icons.history_outlined,
                        isSelected: _selectedSegment == 1,
                        onTap: () => setState(() => _selectedSegment = 1),
                        palette: palette,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. Main content: Ledger or History with 200 ms cross-fade
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ...previousChildren,
                        ?currentChild,
                      ],
                    );
                  },
                  child: _selectedSegment == 0
                      ? const MonthlyLedgerTab(key: ValueKey('monthly_ledger_view'))
                      : ExpensesHistoryTab(
                          key: const ValueKey('expenses_history_view'),
                          onMonthTapped: (monthKey) {
                            setState(() => _selectedSegment = 0);
                          },
                        ),
                ),
              ),
            ],
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
    required AppPalette palette,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppDimens.borderRadiusSm,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? palette.selectedFill : Colors.transparent,
          borderRadius: AppDimens.borderRadiusSm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? palette.onSelected : palette.textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? palette.onSelected : palette.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
