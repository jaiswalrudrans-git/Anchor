import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anchor/core/constants/theme.dart';
import 'package:anchor/core/services/expense_reset_service.dart';
import 'package:anchor/core/utils/date_utils.dart';
import 'package:anchor/models/expense_month_summary.dart';
import 'package:anchor/models/expense_settings.dart';
import 'package:anchor/models/expense_transaction.dart';
import 'package:anchor/providers/expenses_providers.dart';
import 'package:anchor/screens/expenses/expenses_screen.dart';

class TestExpenseSettingsNotifier extends ExpenseSettingsNotifier {
  ExpenseSettings? _current;
  TestExpenseSettingsNotifier(this._current);

  @override
  Future<ExpenseSettings?> build() async => _current;

  @override
  Future<void> refreshSettings() async {
    state = AsyncData(_current);
  }

  @override
  Future<void> updateAllowance(double newAllowance) async {
    if (_current != null) {
      _current = _current!.copyWith(monthlyAllowance: newAllowance);
      state = AsyncData(_current);
    }
  }
}

class TestAllTransactionsNotifier extends AllTransactionsNotifier {
  List<ExpenseTransaction> _txs;
  TestAllTransactionsNotifier(this._txs);

  @override
  Future<List<ExpenseTransaction>> build() async => _txs;

  @override
  Future<void> refresh() async {
    state = AsyncData(_txs);
  }

  @override
  Future<ExpenseTransaction> logTransaction({
    required String title,
    required String category,
    required double amount,
    required String txType,
  }) async {
    final newTx = ExpenseTransaction(
      id: 'tx-new',
      userId: 'user-1',
      title: title,
      category: category,
      amount: amount,
      txType: txType,
      txDate: DateTime.now(),
    );
    _txs = [newTx, ..._txs];
    state = AsyncData(_txs);
    return newTx;
  }

  @override
  Future<void> deleteTransaction(ExpenseTransaction tx) async {
    _txs = _txs.where((t) => t.id != tx.id).toList();
    state = AsyncData(_txs);
  }
}

class TestMonthSummariesNotifier extends MonthSummariesNotifier {
  final List<ExpenseMonthSummary> _summaries;
  TestMonthSummariesNotifier(this._summaries);

  @override
  Future<List<ExpenseMonthSummary>> build() async => _summaries;

  @override
  Future<void> refresh() async {
    state = AsyncData(_summaries);
  }
}

class FakeExpenseResetService extends ExpenseResetService {
  @override
  Future<void> runMonthlyReset() async {}
}

void main() {
  final currentMonthKey = AppDateUtils.monthKey(DateTime.now());
  final pastMonthKey = AppDateUtils.prevMonthKey(currentMonthKey);

  final testSettings = ExpenseSettings(
    userId: 'user-1',
    monthlyAllowance: 10000.0,
    totalSavings: 25000.0,
    lastResetMonth: currentMonthKey,
  );

  final testCurrentTx1 = ExpenseTransaction(
    id: 'tx-1',
    userId: 'user-1',
    title: 'Textbooks',
    category: 'College/Study',
    amount: 1500.0,
    txType: 'spent',
    txDate: DateTime.now(),
  );

  final testCurrentTx2 = ExpenseTransaction(
    id: 'tx-2',
    userId: 'user-1',
    title: 'Tutoring Stipend',
    category: 'General',
    amount: 3000.0,
    txType: 'received',
    txDate: DateTime.now(),
  );

  final testPastTx = ExpenseTransaction(
    id: 'tx-past-1',
    userId: 'user-1',
    title: 'Gym Membership',
    category: 'Gym/Diet',
    amount: 1200.0,
    txType: 'spent',
    txDate: AppDateUtils.parseMonthKey(pastMonthKey),
  );

  final testPastSummary = ExpenseMonthSummary(
    id: 'sum-1',
    userId: 'user-1',
    month: pastMonthKey,
    allowance: 10000.0,
    received: 1000.0,
    spent: 6000.0,
    saved: 1000.0,
    remainder: 4000.0,
    carriedToSavings: 4000.0,
    closedAt: DateTime.now(),
  );

  group('ExpensesScreen 4-Metric Header and Allowance Edit Tests', () {
    testWidgets('Header displays Allowance, Spent, Remaining, and Savings values', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseResetServiceProvider.overrideWithValue(FakeExpenseResetService()),
            expenseSettingsProvider.overrideWith(() => TestExpenseSettingsNotifier(testSettings)),
            allTransactionsProvider.overrideWith(() => TestAllTransactionsNotifier([testCurrentTx1, testCurrentTx2])),
            monthSummariesProvider.overrideWith(() => TestMonthSummariesNotifier([])),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ExpensesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check cards
      expect(find.byKey(const Key('metric_card_allowance')), findsOneWidget);
      expect(find.text('MONTHLY ALLOWANCE'), findsOneWidget);
      expect(find.descendant(
        of: find.byKey(const Key('metric_card_allowance')),
        matching: find.text('₹10,000.00'),
      ), findsOneWidget);

      expect(find.byKey(const Key('metric_card_spent')), findsOneWidget);
      expect(find.text('SPENT THIS MONTH'), findsOneWidget);
      expect(find.descendant(
        of: find.byKey(const Key('metric_card_spent')),
        matching: find.text('₹1,500.00'),
      ), findsOneWidget);

      expect(find.byKey(const Key('metric_card_remaining')), findsOneWidget);
      expect(find.text('REMAINING BALANCE'), findsOneWidget);
      // (10000 + 3000) - (1500 + 0) = 11500
      expect(find.descendant(
        of: find.byKey(const Key('metric_card_remaining')),
        matching: find.text('₹11,500.00'),
      ), findsOneWidget);

      expect(find.byKey(const Key('metric_card_savings')), findsOneWidget);
      expect(find.text('SAVINGS LOCKER'), findsOneWidget);
      expect(find.descendant(
        of: find.byKey(const Key('metric_card_savings')),
        matching: find.text('₹25,000.00'),
      ), findsOneWidget);
    });

    testWidgets('Tapping edit allowance button opens EditAllowanceDialog and updates allowance', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseResetServiceProvider.overrideWithValue(FakeExpenseResetService()),
            expenseSettingsProvider.overrideWith(() => TestExpenseSettingsNotifier(testSettings)),
            allTransactionsProvider.overrideWith(() => TestAllTransactionsNotifier([])),
            monthSummariesProvider.overrideWith(() => TestMonthSummariesNotifier([])),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ExpensesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap edit button
      await tester.tap(find.byKey(const Key('edit_allowance_button')));
      await tester.pumpAndSettle();

      // Edit allowance dialog appears
      expect(find.byKey(const Key('edit_allowance_dialog')), findsOneWidget);
      expect(find.text('Set Monthly Allowance'), findsOneWidget);

      // Enter new allowance
      await tester.enterText(find.byKey(const Key('allowance_input_field')), '15000');
      await tester.tap(find.byKey(const Key('save_allowance_button')));
      await tester.pumpAndSettle();

      // Updated allowance shown in header
      expect(find.descendant(
        of: find.byKey(const Key('metric_card_allowance')),
        matching: find.text('₹15,000.00'),
      ), findsOneWidget);
    });
  });

  group('Add Transaction Flow and Form Isolation Tests', () {
    testWidgets('+ Log Transaction is the only add control and opens AddTransactionSheet with transaction fields only', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseResetServiceProvider.overrideWithValue(FakeExpenseResetService()),
            expenseSettingsProvider.overrideWith(() => TestExpenseSettingsNotifier(testSettings)),
            allTransactionsProvider.overrideWith(() => TestAllTransactionsNotifier([])),
            monthSummariesProvider.overrideWith(() => TestMonthSummariesNotifier([])),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ExpensesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no FloatingActionButton
      expect(find.byType(FloatingActionButton), findsNothing);

      // Verify + Log Transaction exists
      final addBtn = find.byKey(const Key('add_transaction_button'));
      expect(addBtn, findsOneWidget);

      // Tap to open sheet
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      // Verify AddTransactionSheet opens
      expect(find.byKey(const Key('add_transaction_sheet')), findsOneWidget);
      expect(find.text('LOG TRANSACTION'), findsOneWidget);

      // Verify ONLY transaction fields exist
      expect(find.byKey(const Key('transaction_type_toggle')), findsOneWidget);
      expect(find.byKey(const Key('transaction_amount_field')), findsOneWidget);
      expect(find.byKey(const Key('transaction_title_field')), findsOneWidget);
      expect(find.byKey(const Key('save_transaction_button')), findsOneWidget);

      // Assert foreign fields do not exist
      expect(find.text('Due Date'), findsNothing);
      expect(find.text('Exam Date'), findsNothing);
      expect(find.text('Scheduled Date'), findsNothing);
    });
  });

  group('Transaction Ledger and Deletion Tests', () {
    testWidgets('Displays transactions with category, date, amount, and delete confirmation works', (tester) async {
      final txNotifier = TestAllTransactionsNotifier([testCurrentTx1]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseResetServiceProvider.overrideWithValue(FakeExpenseResetService()),
            expenseSettingsProvider.overrideWith(() => TestExpenseSettingsNotifier(testSettings)),
            allTransactionsProvider.overrideWith(() => txNotifier),
            monthSummariesProvider.overrideWith(() => TestMonthSummariesNotifier([])),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ExpensesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check transaction row contents
      expect(find.text('Textbooks'), findsOneWidget);
      expect(find.text('College/Study'), findsOneWidget);
      expect(find.text('-₹1,500.00'), findsOneWidget);

      // Tap delete icon
      await tester.tap(find.byKey(const ValueKey('delete_tx_tx-1')));
      await tester.pumpAndSettle();

      // Confirmation dialog appears
      expect(find.text('Delete Transaction'), findsOneWidget);
      expect(find.textContaining('Textbooks'), findsWidgets);

      // Confirm delete
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      // Transaction removed, empty state shown
      expect(find.text('Textbooks'), findsNothing);
      expect(find.byKey(const Key('empty_transactions_state')), findsOneWidget);
    });
  });

  group('Month Browsing and Past Month Read-Only Behavior', () {
    testWidgets('Past month shows closed month snapshot card, hides + Log Transaction and delete buttons', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseResetServiceProvider.overrideWithValue(FakeExpenseResetService()),
            expenseSettingsProvider.overrideWith(() => TestExpenseSettingsNotifier(testSettings)),
            allTransactionsProvider.overrideWith(() => TestAllTransactionsNotifier([testPastTx])),
            monthSummariesProvider.overrideWith(() => TestMonthSummariesNotifier([testPastSummary])),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ExpensesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // In current month, + Log Transaction is visible
      expect(find.byKey(const Key('add_transaction_button')), findsOneWidget);

      // Navigate to previous month
      await tester.tap(find.byKey(const Key('prev_month_button')));
      await tester.pumpAndSettle();

      // In past month:
      // 1. + Log Transaction is HIDDEN
      expect(find.byKey(const Key('add_transaction_button')), findsNothing);

      // 2. Closed month snapshot card is VISIBLE
      expect(find.byKey(const Key('closed_month_snapshot_card')), findsOneWidget);
      expect(find.text('CLOSED MONTH SNAPSHOT'), findsOneWidget);
      expect(find.text('READ ONLY'), findsOneWidget);

      // 3. Past transaction is visible but has NO delete button
      expect(find.text('Gym Membership'), findsOneWidget);
      expect(find.byKey(const ValueKey('delete_tx_tx-past-1')), findsNothing);
    });
  });

  group('History Tab Tests', () {
    testWidgets('History tab displays closed months and tapping month navigates to its ledger', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseResetServiceProvider.overrideWithValue(FakeExpenseResetService()),
            expenseSettingsProvider.overrideWith(() => TestExpenseSettingsNotifier(testSettings)),
            allTransactionsProvider.overrideWith(() => TestAllTransactionsNotifier([testPastTx])),
            monthSummariesProvider.overrideWith(() => TestMonthSummariesNotifier([testPastSummary])),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ExpensesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to History tab
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // Verify closed month card exists in History
      expect(find.byKey(ValueKey('history_month_card_$pastMonthKey')), findsOneWidget);
      expect(find.text('Carried to Savings'), findsOneWidget);

      // Tap on the card
      await tester.tap(find.byKey(ValueKey('history_month_card_$pastMonthKey')));
      await tester.pumpAndSettle();

      // Navigated to ledger for that past month
      expect(find.byKey(const Key('closed_month_snapshot_card')), findsOneWidget);
      expect(find.text('Gym Membership'), findsOneWidget);
    });

    testWidgets('Empty history displays "History appears after your first month closes."', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseResetServiceProvider.overrideWithValue(FakeExpenseResetService()),
            expenseSettingsProvider.overrideWith(() => TestExpenseSettingsNotifier(testSettings)),
            allTransactionsProvider.overrideWith(() => TestAllTransactionsNotifier([])),
            monthSummariesProvider.overrideWith(() => TestMonthSummariesNotifier([])),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ExpensesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to History tab
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // Verify empty state
      expect(find.byKey(const Key('history_empty_state')), findsOneWidget);
      expect(find.text('History appears after your first month closes.'), findsOneWidget);
    });
  });
}
