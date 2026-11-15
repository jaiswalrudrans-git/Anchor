import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anchor/core/constants/theme.dart';
import 'package:anchor/core/services/expense_reset_service.dart';
import 'package:anchor/core/utils/date_utils.dart';
import 'package:anchor/core/utils/expense_utils.dart';
import 'package:anchor/models/expense_month_summary.dart';
import 'package:anchor/models/expense_settings.dart';
import 'package:anchor/models/expense_transaction.dart';
import 'package:anchor/providers/expenses_providers.dart';
import 'package:anchor/screens/expenses/expenses_screen.dart';

class FakeExpenseResetService extends ExpenseResetService {
  @override
  Future<void> runMonthlyReset() async {}
}

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

  @override
  Future<void> adjustSavings(double delta) async {
    if (_current != null) {
      final newSavings = (_current!.totalSavings + delta).clamp(
        0.0,
        double.infinity,
      );
      _current = _current!.copyWith(totalSavings: newSavings);
      state = AsyncData(_current);
    }
  }
}

class TestAllTransactionsNotifier extends AllTransactionsNotifier {
  List<ExpenseTransaction> _transactions;
  TestAllTransactionsNotifier(this._transactions);

  @override
  Future<List<ExpenseTransaction>> build() async => _transactions;

  @override
  Future<void> refresh() async {
    state = AsyncData(_transactions);
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
      userId: 'u',
      title: title.trim(),
      category: category.trim(),
      amount: amount,
      txType: txType,
      txDate: DateTime.now(),
    );
    _transactions = [newTx, ..._transactions];
    state = AsyncData(_transactions);
    if (txType == 'saved') {
      await ref.read(expenseSettingsProvider.notifier).adjustSavings(amount);
    }
    return newTx;
  }

  @override
  Future<void> deleteTransaction(ExpenseTransaction tx) async {
    _transactions = _transactions.where((t) => t.id != tx.id).toList();
    state = AsyncData(_transactions);
    if (tx.txType == 'saved') {
      await ref
          .read(expenseSettingsProvider.notifier)
          .adjustSavings(-tx.amount);
    }
  }

  @override
  Future<void> restoreTransaction(ExpenseTransaction tx) async {
    _transactions = [tx, ..._transactions];
    state = AsyncData(_transactions);
    if (tx.txType == 'saved') {
      await ref.read(expenseSettingsProvider.notifier).adjustSavings(tx.amount);
    }
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

void main() {
  group('Polish Stage 6 - Spending Bar Tone Thresholds & Pure Helpers', () {
    test(
      'Spending tone thresholds (<75% accent, 75-100% warning, >100% danger)',
      () {
        expect(getSpendingTone(74.9, 100.0), SpendingTone.accent);
        expect(getSpendingTone(75.0, 100.0), SpendingTone.warning);
        expect(getSpendingTone(100.0, 100.0), SpendingTone.warning);
        expect(getSpendingTone(100.1, 100.0), SpendingTone.danger);
        expect(getSpendingTone(150.0, 100.0), SpendingTone.danger);
      },
    );

    test('Zero or unset allowance returns accent tone', () {
      expect(getSpendingTone(100.0, 0.0), SpendingTone.accent);
      expect(getSpendingTone(100.0, -50.0), SpendingTone.accent);
    });

    test('Spending captions format within budget and over budget properly', () {
      expect(
        getSpendingCaption(1200.0, 5000.0),
        '${AppDateUtils.formatCurrency(1200.0)} of ${AppDateUtils.formatCurrency(5000.0)} spent',
      );
      expect(
        getSpendingCaption(5500.0, 5000.0),
        'Over budget by ${AppDateUtils.formatCurrency(500.0)}',
      );
      expect(
        getSpendingCaption(300.0, 0.0),
        '${AppDateUtils.formatCurrency(300.0)} spent',
      );
    });
  });

  group('Polish Stage 6 - Ledger Day Grouping & Net Spend Calculations', () {
    final now = DateTime(2026, 11, 14, 15, 30);
    final todayMidnight = DateTime(2026, 11, 14, 0, 1);
    final yesterdayEvening = DateTime(2026, 11, 13, 23, 59);
    final olderDate = DateTime(2026, 11, 10, 12, 0);

    test('formatDayHeader accurately identifies Today, Yesterday, and dates at midnight boundaries', () {
      expect(formatDayHeader(todayMidnight, now), 'Today');
      expect(formatDayHeader(yesterdayEvening, now), 'Yesterday');
      expect(formatDayHeader(olderDate, now), 'Tue, 10 Nov');
    });

    test('calculateDayNetSpend and formatDayNetSpend compute net outflow and inflow', () {
      final txSpent1 = ExpenseTransaction(
        id: '1',
        userId: 'u',
        title: 'Lunch',
        category: 'Food',
        amount: 250.0,
        txType: 'spent',
        txDate: now,
      );
      final txSpent2 = ExpenseTransaction(
        id: '2',
        userId: 'u',
        title: 'Coffee',
        category: 'Food',
        amount: 50.0,
        txType: 'spent',
        txDate: now,
      );
      final txReceived = ExpenseTransaction(
        id: '3',
        userId: 'u',
        title: 'Freelance Refund',
        category: 'General',
        amount: 100.0,
        txType: 'received',
        txDate: now,
      );
      final txSaved = ExpenseTransaction(
        id: '4',
        userId: 'u',
        title: 'Emergency Stash',
        category: 'Personal',
        amount: 200.0,
        txType: 'saved',
        txDate: now,
      );

      final net = calculateDayNetSpend([
        txSpent1,
        txSpent2,
        txReceived,
        txSaved,
      ]);
      // Net = received (100) - spent (300) - saved (200) = -400.0
      expect(net, -400.0);
      expect(
        formatDayNetSpend(net, includePrefix: true),
        'Net: -${AppDateUtils.formatCurrency(400.0)}',
      );

      final netPositive = calculateDayNetSpend([txReceived]);
      expect(netPositive, 100.0);
      expect(
        formatDayNetSpend(netPositive, includePrefix: true),
        'Net: +${AppDateUtils.formatCurrency(100.0)}',
      );
    });

    test(
      'groupTransactionsByDay groups transactions by calendar day descending',
      () {
        final t1 = ExpenseTransaction(
          id: '1',
          userId: 'u',
          title: 'Today Tx',
          category: 'Food',
          amount: 100.0,
          txType: 'spent',
          txDate: DateTime(2026, 11, 14, 10, 0),
        );
        final t2 = ExpenseTransaction(
          id: '2',
          userId: 'u',
          title: 'Yesterday Tx',
          category: 'Travel',
          amount: 50.0,
          txType: 'spent',
          txDate: DateTime(2026, 11, 13, 14, 0),
        );
        final t3 = ExpenseTransaction(
          id: '3',
          userId: 'u',
          title: 'Earlier Today Tx',
          category: 'Food',
          amount: 25.0,
          txType: 'spent',
          txDate: DateTime(2026, 11, 14, 8, 0),
        );

        final grouped = groupTransactionsByDay([t1, t2, t3], now);
        expect(grouped.length, 2);
        expect(grouped[0].label, 'Today');
        expect(grouped[0].transactions.length, 2);
        expect(grouped[0].netSpend, -125.0);
        expect(grouped[1].label, 'Yesterday');
        expect(grouped[1].transactions.length, 1);
        expect(grouped[1].netSpend, -50.0);
      },
    );
  });

  group('Polish Stage 6 - Swipe Delete & Undo for Savings Transactions', () {
    testWidgets(
      'Swipe delete of saved transaction decrements total_savings; undo restores both',
      (tester) async {
        const settings = ExpenseSettings(
          userId: 'u',
          monthlyAllowance: 5000.0,
          totalSavings: 1000.0,
          lastResetMonth: '2026-11',
        );

        final savedTx = ExpenseTransaction(
          id: 'tx-save-1',
          userId: 'u',
          title: 'Locker Deposit',
          category: 'General',
          amount: 300.0,
          txType: 'saved',
          txDate: DateTime.now(),
        );

        final settingsNotifier = TestExpenseSettingsNotifier(settings);
        final txNotifier = TestAllTransactionsNotifier([savedTx]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              expenseResetServiceProvider.overrideWithValue(
                FakeExpenseResetService(),
              ),
              expenseSettingsProvider.overrideWith(() => settingsNotifier),
              allTransactionsProvider.overrideWith(() => txNotifier),
              monthSummariesProvider.overrideWith(
                () => TestMonthSummariesNotifier([]),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const ExpensesScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Locker Deposit'), findsOneWidget);
        expect(settingsNotifier._current!.totalSavings, 1000.0);

        // Perform swipe to delete
        await tester.drag(
          find.byKey(ValueKey('tx_dismiss_${savedTx.id}')),
          const Offset(-500, 0),
        );
        await tester.pumpAndSettle();

        // Transaction removed and savings decremented by 300
        expect(find.text('Locker Deposit'), findsNothing);
        expect(settingsNotifier._current!.totalSavings, 700.0);

        // Tap Undo in SnackBar
        expect(find.text('Undo'), findsOneWidget);
        await tester.tap(find.text('Undo'));
        await tester.pumpAndSettle();

        // Both transaction and savings restored
        expect(find.text('Locker Deposit'), findsOneWidget);
        expect(settingsNotifier._current!.totalSavings, 1000.0);
      },
    );
  });

  group('Polish Stage 6 - Form Isolation & 360 dp Mobile No-Wrap', () {
    testWidgets(
      'AddTransactionSheet shortened labels do not wrap at 360 dp width',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        const settings = ExpenseSettings(
          userId: 'u',
          monthlyAllowance: 5000.0,
          totalSavings: 1000.0,
          lastResetMonth: '2026-11',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              expenseResetServiceProvider.overrideWithValue(
                FakeExpenseResetService(),
              ),
              expenseSettingsProvider.overrideWith(
                () => TestExpenseSettingsNotifier(settings),
              ),
              allTransactionsProvider.overrideWith(
                () => TestAllTransactionsNotifier([]),
              ),
              monthSummariesProvider.overrideWith(
                () => TestMonthSummariesNotifier([]),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const MediaQuery(
                data: MediaQueryData(
                  size: Size(360, 640),
                  textScaler: TextScaler.linear(1.3),
                ),
                child: ExpensesScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Open AddTransactionSheet
        await tester.tap(find.byKey(const Key('add_transaction_button')));
        await tester.pumpAndSettle();

        // Shortened labels present: Spent, Received, Savings
        expect(find.text('Spent'), findsOneWidget);
        expect(find.text('Received'), findsOneWidget);
        expect(find.text('Savings'), findsOneWidget);

        // Select Savings -> shows helper caption
        await tester.tap(find.text('Savings'));
        await tester.pumpAndSettle();
        expect(find.text('Move to savings'), findsOneWidget);

        // Save button is initially disabled (empty amount)
        final saveBtnFinder = find.byKey(const Key('save_transaction_button'));
        ElevatedButton btn = tester.widget<ElevatedButton>(saveBtnFinder);
        expect(btn.onPressed, isNull);

        // Enter amount -> button enabled
        await tester.enterText(
          find.byKey(const Key('transaction_amount_field')),
          '250',
        );
        await tester.pumpAndSettle();
        btn = tester.widget<ElevatedButton>(saveBtnFinder);
        expect(btn.onPressed, isNotNull);

        final testException = tester.takeException();
        expect(testException, isNull);
      },
    );
  });

  group(
    'Polish Stage 6 - Responsive Layouts & Text Scale 1.3 Zero Overflow',
    () {
      testWidgets(
        'Compact mobile (360x640) text scale 1.3 renders Expenses without overflow',
        (tester) async {
          tester.view.physicalSize = const Size(360, 640);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          const settings = ExpenseSettings(
            userId: 'u',
            monthlyAllowance: 10000.0,
            totalSavings: 5000.0,
            lastResetMonth: '2026-11',
          );

          final tx = ExpenseTransaction(
            id: 'tx-1',
            userId: 'u',
            title: 'Grocery Store Run',
            category: 'Food',
            amount: 850.0,
            txType: 'spent',
            txDate: DateTime.now(),
          );

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                expenseResetServiceProvider.overrideWithValue(
                  FakeExpenseResetService(),
                ),
                expenseSettingsProvider.overrideWith(
                  () => TestExpenseSettingsNotifier(settings),
                ),
                allTransactionsProvider.overrideWith(
                  () => TestAllTransactionsNotifier([tx]),
                ),
                monthSummariesProvider.overrideWith(
                  () => TestMonthSummariesNotifier([]),
                ),
              ],
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: const MediaQuery(
                  data: MediaQueryData(
                    size: Size(360, 640),
                    textScaler: TextScaler.linear(1.3),
                  ),
                  child: ExpensesScreen(),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Grocery Store Run'), findsOneWidget);
          final testException = tester.takeException();
          expect(testException, isNull);
        },
      );

      testWidgets(
        'Medium tablet (800x1000) text scale 1.3 renders Expenses without overflow',
        (tester) async {
          tester.view.physicalSize = const Size(800, 1000);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                expenseResetServiceProvider.overrideWithValue(
                  FakeExpenseResetService(),
                ),
                expenseSettingsProvider.overrideWith(
                  () => TestExpenseSettingsNotifier(null),
                ),
                allTransactionsProvider.overrideWith(
                  () => TestAllTransactionsNotifier([]),
                ),
                monthSummariesProvider.overrideWith(
                  () => TestMonthSummariesNotifier([]),
                ),
              ],
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: const MediaQuery(
                  data: MediaQueryData(
                    size: Size(800, 1000),
                    textScaler: TextScaler.linear(1.3),
                  ),
                  child: ExpensesScreen(),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final testException = tester.takeException();
          expect(testException, isNull);
        },
      );

      testWidgets(
        'Expanded desktop (1280x800) text scale 1.3 renders Expenses without overflow',
        (tester) async {
          tester.view.physicalSize = const Size(1280, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          const settings = ExpenseSettings(
            userId: 'u',
            monthlyAllowance: 10000.0,
            totalSavings: 5000.0,
            lastResetMonth: '2026-11',
          );

          final tx = ExpenseTransaction(
            id: 'tx-1',
            userId: 'u',
            title: 'Textbook Purchase',
            category: 'College/Study',
            amount: 1200.0,
            txType: 'spent',
            txDate: DateTime.now(),
          );

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                expenseResetServiceProvider.overrideWithValue(
                  FakeExpenseResetService(),
                ),
                expenseSettingsProvider.overrideWith(
                  () => TestExpenseSettingsNotifier(settings),
                ),
                allTransactionsProvider.overrideWith(
                  () => TestAllTransactionsNotifier([tx]),
                ),
                monthSummariesProvider.overrideWith(
                  () => TestMonthSummariesNotifier([]),
                ),
              ],
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: const MediaQuery(
                  data: MediaQueryData(
                    size: Size(1280, 800),
                    textScaler: TextScaler.linear(1.3),
                  ),
                  child: ExpensesScreen(),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Textbook Purchase'), findsOneWidget);
          final testException = tester.takeException();
          expect(testException, isNull);
        },
      );
    },
  );
}
