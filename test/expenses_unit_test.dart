import 'package:flutter_test/flutter_test.dart';
import 'package:anchor/core/services/expense_reset_service.dart';
import 'package:anchor/core/utils/date_utils.dart';

void main() {
  group('MonthClose Pure Calculation Tests', () {
    test(
      'surplus month: remainder positive carries entire remainder to savings',
      () {
        // allowance 10000, received 2000, spent 6000, saved 1000
        // remainder = (10000 + 2000) - (6000 + 1000) = 5000
        final close = ExpenseResetService.computeMonthClose(
          allowance: 10000.0,
          received: 2000.0,
          spent: 6000.0,
          saved: 1000.0,
        );

        expect(close.allowance, 10000.0);
        expect(close.received, 2000.0);
        expect(close.spent, 6000.0);
        expect(close.saved, 1000.0);
        expect(close.remainder, 5000.0);
        expect(close.carriedToSavings, 5000.0);
      },
    );

    test('deficit month: remainder negative carries 0 to savings', () {
      // allowance 5000, received 0, spent 7500, saved 0
      // remainder = -2500 -> carried = 0
      final close = ExpenseResetService.computeMonthClose(
        allowance: 5000.0,
        received: 0.0,
        spent: 7500.0,
        saved: 0.0,
      );

      expect(close.remainder, -2500.0);
      expect(close.carriedToSavings, 0.0);
    });

    test('break-even month: remainder 0 carries 0 to savings', () {
      final close = ExpenseResetService.computeMonthClose(
        allowance: 6000.0,
        received: 1000.0,
        spent: 7000.0,
        saved: 0.0,
      );

      expect(close.remainder, 0.0);
      expect(close.carriedToSavings, 0.0);
    });

    test('saved transfers reduce remainder so savings are not double-counted on close', () {
      // allowance 8000, received 0, spent 2000, saved 4000
      // remainder = 8000 - (2000 + 4000) = 2000
      // carried = 2000 (the 4000 was already transferred during the month)
      final close = ExpenseResetService.computeMonthClose(
        allowance: 8000.0,
        received: 0.0,
        spent: 2000.0,
        saved: 4000.0,
      );

      expect(close.remainder, 2000.0);
      expect(close.carriedToSavings, 2000.0);
    });

    test('remaining balance formula matches active month expectation', () {
      final balance = ExpenseResetService.computeRemainingBalance(
        allowance: 12000.0,
        received: 3000.0,
        spent: 4500.0,
        saved: 1500.0,
      );

      expect(balance, 9000.0);
    });
  });

  group('Month Key Utilities Tests', () {
    test(
      'nextMonthKey rolls over across years and standard months correctly',
      () {
        expect(AppDateUtils.nextMonthKey('2026-01'), '2026-02');
        expect(AppDateUtils.nextMonthKey('2026-11'), '2026-12');
        expect(AppDateUtils.nextMonthKey('2026-12'), '2027-01');
      },
    );

    test(
      'prevMonthKey rolls back across years and standard months correctly',
      () {
        expect(AppDateUtils.prevMonthKey('2026-02'), '2026-01');
        expect(AppDateUtils.prevMonthKey('2026-01'), '2025-12');
        expect(AppDateUtils.prevMonthKey('2026-11'), '2026-10');
      },
    );

    test('formatMonthTitle formats YYYY-MM to readable title', () {
      expect(AppDateUtils.formatMonthTitle('2026-11'), 'November 2026');
      expect(AppDateUtils.formatMonthTitle('2027-01'), 'January 2027');
    });

    test('isMonthBefore compares YYYY-MM strings chronologically', () {
      expect(AppDateUtils.isMonthBefore('2026-08', '2026-11'), isTrue);
      expect(AppDateUtils.isMonthBefore('2026-11', '2026-11'), isFalse);
      expect(AppDateUtils.isMonthBefore('2026-12', '2026-11'), isFalse);
    });

    test('formatCurrency formats Indian rupee symbol and groupings', () {
      final formatted = AppDateUtils.formatCurrency(123456.78);
      expect(formatted, contains('₹'));
      expect(formatted, contains('1,23,456.78'));
    });
  });

  group('Multi-Month Rollover Logic Simulation', () {
    test('3-month gap simulation snapshots every month and accumulates total_savings without double count', () {
      const initialAllowance = 10000.0;
      double totalSavings = 5000.0;
      String lastResetMonth = '2026-08';
      const currentMonth = '2026-11';

      // Mock month transaction totals
      final monthData = {
        '2026-08': {'spent': 4000.0, 'received': 1000.0, 'saved': 1000.0},
        '2026-09': {'spent': 12000.0, 'received': 0.0, 'saved': 0.0},
        '2026-10': {'spent': 7000.0, 'received': 2000.0, 'saved': 500.0},
      };

      final snapshots = <String, MonthClose>{};
      double accumulatedSavings = 0.0;
      String cursor = lastResetMonth;

      while (AppDateUtils.isMonthBefore(cursor, currentMonth)) {
        final data = monthData[cursor]!;
        final close = ExpenseResetService.computeMonthClose(
          allowance: initialAllowance,
          received: data['received']!,
          spent: data['spent']!,
          saved: data['saved']!,
        );
        snapshots[cursor] = close;
        accumulatedSavings += close.carriedToSavings;
        cursor = AppDateUtils.nextMonthKey(cursor);
      }

      totalSavings += accumulatedSavings;
      lastResetMonth = currentMonth;

      // Verify all 3 months closed
      expect(snapshots.length, 3);

      // Month 1 (2026-08): (10000 + 1000) - (4000 + 1000) = 6000 carried
      expect(snapshots['2026-08']!.carriedToSavings, 6000.0);

      // Month 2 (2026-09): (10000 + 0) - (12000 + 0) = -2000 -> 0 carried
      expect(snapshots['2026-09']!.carriedToSavings, 0.0);

      // Month 3 (2026-10): (10000 + 2000) - (7000 + 500) = 4500 carried
      expect(snapshots['2026-10']!.carriedToSavings, 4500.0);

      // Total savings = 5000 + 6000 + 0 + 4500 = 15500
      expect(totalSavings, 15500.0);
      expect(lastResetMonth, '2026-11');

      // Re-running rollover immediately does nothing (idempotent)
      double secondPassAccumulated = 0.0;
      String secondCursor = lastResetMonth;
      while (AppDateUtils.isMonthBefore(secondCursor, currentMonth)) {
        secondPassAccumulated += 1.0;
        secondCursor = AppDateUtils.nextMonthKey(secondCursor);
      }
      expect(secondPassAccumulated, 0.0);
      expect(totalSavings, 15500.0);
    });
  });
}
