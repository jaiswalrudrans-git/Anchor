import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../models/expense_month_summary.dart';
import '../../models/expense_settings.dart';
import '../utils/app_log.dart';
import '../utils/date_utils.dart';

const _uuid = Uuid();

/// Pure data structure representing the calculation of a closed month.
@immutable
class MonthClose {
  final double allowance;
  final double received;
  final double spent;
  final double saved;
  final double remainder;
  final double carriedToSavings;

  const MonthClose({
    required this.allowance,
    required this.received,
    required this.spent,
    required this.saved,
    required this.remainder,
    required this.carriedToSavings,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthClose &&
          runtimeType == other.runtimeType &&
          allowance == other.allowance &&
          received == other.received &&
          spent == other.spent &&
          saved == other.saved &&
          remainder == other.remainder &&
          carriedToSavings == other.carriedToSavings;

  @override
  int get hashCode =>
      allowance.hashCode ^
      received.hashCode ^
      spent.hashCode ^
      saved.hashCode ^
      remainder.hashCode ^
      carriedToSavings.hashCode;
}

/// Service managing the monthly allowance ledger rollover,
/// closing past months, computing savings transfers, and saving historical snapshots.
class ExpenseResetService {
  final SupabaseClient? client;
  bool _isRunning = false;

  ExpenseResetService({this.client});

  SupabaseClient? get _supabase {
    if (client != null) return client;
    try {
      if (Supabase.instance.isInitialized) {
        return Supabase.instance.client;
      }
    } catch (_) {}
    return null;
  }

  // =========================================================================
  // PURE UTILITY FUNCTIONS (Directly unit testable without Supabase)
  // =========================================================================

  /// Pure computation for closing a month:
  /// - remainder = (allowance + received) - (spent + saved)
  /// - carried_to_savings = max(remainder, 0)
  /// Note: 'saved' transactions were ALREADY transferred to total_savings when logged,
  /// so they reduce the remaining balance and are not double-added.
  static MonthClose computeMonthClose({
    required double allowance,
    required double received,
    required double spent,
    required double saved,
  }) {
    final remainder = (allowance + received) - (spent + saved);
    final carriedToSavings = remainder > 0 ? remainder : 0.0;
    return MonthClose(
      allowance: allowance,
      received: received,
      spent: spent,
      saved: saved,
      remainder: remainder,
      carriedToSavings: carriedToSavings,
    );
  }

  /// Pure calculation of remaining balance for the active month:
  /// (allowance + received) - (spent + saved)
  static double computeRemainingBalance({
    required double allowance,
    required double received,
    required double spent,
    required double saved,
  }) {
    return (allowance + received) - (spent + saved);
  }

  // =========================================================================
  // MONTHLY ROLLOVER ENGINE
  // =========================================================================

  /// Executes monthly rollover logic:
  /// 1. Auto-seeds default expense_settings if missing.
  /// 2. If current month > last_reset_month, iterates month by month through all closed months.
  /// 3. Computes sums, remainder, and carried_to_savings for each closed month.
  /// 4. Upserts snapshot into expense_month_summaries.
  /// 5. In a single update, updates last_reset_month = currentMonth and accumulates total_savings.
  Future<void> runMonthlyReset() async {
    if (_isRunning) return;
    _isRunning = true;

    try {
      final client = _supabase;
      final user = client?.auth.currentUser;
      if (client == null || user == null) return;

      final now = DateTime.now();
      final currentMonth = AppDateUtils.monthKey(now);

      // 1. Fetch current expense_settings
      final settingsRes = await client
          .from('expense_settings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (settingsRes == null) {
        // First app open for this user: insert default settings starting in current month
        final defaultSettings = ExpenseSettings(
          userId: user.id,
          monthlyAllowance: 0.0,
          totalSavings: 0.0,
          lastResetMonth: currentMonth,
        );
        await client.from('expense_settings').insert(defaultSettings.toJson());
        return;
      }

      final settings = ExpenseSettings.fromJson(settingsRes);
      final lastResetMonth = settings.lastResetMonth;

      // 2. If already up to date, nothing to close
      if (!AppDateUtils.isMonthBefore(lastResetMonth, currentMonth)) {
        return;
      }

      // 3. Multi-month loop: from lastResetMonth up to (excluding) currentMonth
      String iteratingMonth = lastResetMonth;
      double accumulatedSavings = 0.0;

      while (AppDateUtils.isMonthBefore(iteratingMonth, currentMonth)) {
        final startDt = AppDateUtils.parseMonthKey(iteratingMonth);
        final nextMonthKey = AppDateUtils.nextMonthKey(iteratingMonth);
        final nextStartDt = AppDateUtils.parseMonthKey(nextMonthKey);

        // Fetch all transactions for iteratingMonth
        final txRes = await client
            .from('expense_transactions')
            .select()
            .eq('user_id', user.id)
            .gte('tx_date', startDt.toUtc().toIso8601String())
            .lt('tx_date', nextStartDt.toUtc().toIso8601String());

        final txList = (txRes as List<dynamic>).cast<Map<String, dynamic>>();

        double spentSum = 0.0;
        double receivedSum = 0.0;
        double savedSum = 0.0;

        for (final row in txList) {
          final type = row['tx_type'] as String?;
          final amt = (row['amount'] as num?)?.toDouble() ?? 0.0;
          if (type == 'spent') {
            spentSum += amt;
          } else if (type == 'received') {
            receivedSum += amt;
          } else if (type == 'saved') {
            savedSum += amt;
          }
        }

        final close = computeMonthClose(
          allowance: settings.monthlyAllowance,
          received: receivedSum,
          spent: spentSum,
          saved: savedSum,
        );

        // Upsert idempotent snapshot for this closed month
        final summary = ExpenseMonthSummary(
          id: _uuid.v4(),
          userId: user.id,
          month: iteratingMonth,
          allowance: close.allowance,
          received: close.received,
          spent: close.spent,
          saved: close.saved,
          remainder: close.remainder,
          carriedToSavings: close.carriedToSavings,
          closedAt: DateTime.now(),
        );

        await client
            .from('expense_month_summaries')
            .upsert(summary.toJson(), onConflict: 'user_id,month');

        accumulatedSavings += close.carriedToSavings;
        iteratingMonth = nextMonthKey;
      }

      // 4. Update last_reset_month and total_savings in a SINGLE atomic operation
      final newTotalSavings = settings.totalSavings + accumulatedSavings;
      await client
          .from('expense_settings')
          .update({
            'total_savings': newTotalSavings,
            'last_reset_month': currentMonth,
          })
          .eq('user_id', user.id);
    } catch (e) {
      AppLog.e('ExpenseResetService.runMonthlyReset error', e);
    } finally {
      _isRunning = false;
    }
  }
}

/// Riverpod provider for [ExpenseResetService].
final expenseResetServiceProvider = Provider<ExpenseResetService>((ref) {
  return ExpenseResetService();
});
