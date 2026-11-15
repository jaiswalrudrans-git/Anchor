import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/services/expense_reset_service.dart';
import '../core/utils/app_log.dart';
import '../core/utils/date_utils.dart';
import '../models/expense_month_summary.dart';
import '../models/expense_settings.dart';
import '../models/expense_transaction.dart';

const _uuid = Uuid();

// =========================================================================
// 1. EXPENSE SETTINGS NOTIFIER & PROVIDER
// =========================================================================

class ExpenseSettingsNotifier extends AsyncNotifier<ExpenseSettings?> {
  SupabaseClient? get _supabase {
    try {
      if (Supabase.instance.isInitialized) {
        return Supabase.instance.client;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<ExpenseSettings?> build() async {
    return _fetchOrCreateSettings();
  }

  Future<ExpenseSettings?> _fetchOrCreateSettings() async {
    final client = _supabase;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return null;

    final currentMonth = AppDateUtils.monthKey(DateTime.now());

    try {
      final res = await client
          .from('expense_settings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (res != null) {
        return ExpenseSettings.fromJson(res);
      }

      // Seed default settings row if missing
      final defaultSettings = ExpenseSettings(
        userId: user.id,
        monthlyAllowance: 0.0,
        totalSavings: 0.0,
        lastResetMonth: currentMonth,
      );

      await client.from('expense_settings').insert(defaultSettings.toJson());
      return defaultSettings;
    } catch (e) {
      AppLog.e(
        'ExpenseSettingsNotifier._fetchOrCreateSettings error',
        e,
      );
      return null;
    }
  }

  Future<void> refreshSettings() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchOrCreateSettings());
  }

  Future<void> updateAllowance(double newAllowance) async {
    final client = _supabase;
    final user = client?.auth.currentUser;
    final current = state.value;
    if (client == null || user == null || current == null) {
      throw StateError(
        'Cannot update allowance: unauthenticated or uninitialized',
      );
    }

    if (newAllowance < 0) {
      throw ArgumentError('Allowance cannot be negative');
    }

    final updated = current.copyWith(monthlyAllowance: newAllowance);
    state = AsyncData(updated);

    try {
      await client
          .from('expense_settings')
          .update({'monthly_allowance': newAllowance})
          .eq('user_id', user.id);
    } catch (e) {
      state = AsyncData(current);
      AppLog.e('updateAllowance failed', e);
      rethrow;
    }
  }

  Future<void> adjustSavings(double delta) async {
    final client = _supabase;
    final user = client?.auth.currentUser;
    final current = state.value;
    if (current == null) return;

    final newSavings = max(0.0, current.totalSavings + delta);
    final updated = current.copyWith(totalSavings: newSavings);
    state = AsyncData(updated);

    if (client != null && user != null) {
      try {
        await client
            .from('expense_settings')
            .update({'total_savings': newSavings})
            .eq('user_id', user.id);
      } catch (e) {
        state = AsyncData(current);
        AppLog.e('adjustSavings failed', e);
        rethrow;
      }
    }
  }
}

final expenseSettingsProvider =
    AsyncNotifierProvider<ExpenseSettingsNotifier, ExpenseSettings?>(() {
      return ExpenseSettingsNotifier();
    });

// =========================================================================
// 2. TRANSACTIONS NOTIFIER & PROVIDER
// =========================================================================

class AllTransactionsNotifier extends AsyncNotifier<List<ExpenseTransaction>> {
  SupabaseClient? get _supabase {
    try {
      if (Supabase.instance.isInitialized) {
        return Supabase.instance.client;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<List<ExpenseTransaction>> build() async {
    return _fetchTransactions();
  }

  Future<List<ExpenseTransaction>> _fetchTransactions() async {
    final client = _supabase;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return [];

    try {
      final res = await client
          .from('expense_transactions')
          .select()
          .eq('user_id', user.id)
          .order('tx_date', ascending: false);

      final list = res as List<dynamic>;
      return list
          .map((j) => ExpenseTransaction.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLog.e('AllTransactionsNotifier._fetchTransactions error', e);
      return [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchTransactions());
  }

  Future<ExpenseTransaction> logTransaction({
    required String title,
    required String category,
    required double amount,
    required String txType,
  }) async {
    final client = _supabase;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw StateError('User not authenticated');
    }

    if (amount <= 0) {
      throw ArgumentError('Transaction amount must be strictly greater than 0');
    }

    final newTx = ExpenseTransaction(
      id: _uuid.v4(),
      userId: user.id,
      title: title.trim(),
      category: category.trim(),
      amount: amount,
      txType: txType,
      txDate: DateTime.now(),
    );

    final currentTxs = state.value ?? [];
    // Optimistic insert: newest first
    state = AsyncData([newTx, ...currentTxs]);

    try {
      // 1. Insert transaction into Supabase
      await client.from('expense_transactions').insert(newTx.toJson());

      // 2. If 'saved', increment total_savings in expense_settings
      if (txType == 'saved') {
        final currentSettings = ref.read(expenseSettingsProvider).value;
        if (currentSettings != null) {
          final newTotalSavings = currentSettings.totalSavings + amount;
          try {
            await client
                .from('expense_settings')
                .update({'total_savings': newTotalSavings})
                .eq('user_id', user.id);
            await ref.read(expenseSettingsProvider.notifier).refreshSettings();
          } catch (settingsError) {
            // Rollback inserted transaction if savings update failed
            await client
                .from('expense_transactions')
                .delete()
                .eq('id', newTx.id);
            rethrow;
          }
        }
      }

      return newTx;
    } catch (e) {
      // Rollback optimistic state
      state = AsyncData(currentTxs);
      AppLog.e('logTransaction error', e);
      rethrow;
    }
  }

  Future<void> deleteTransaction(ExpenseTransaction tx) async {
    final client = _supabase;
    final user = client?.auth.currentUser;

    final currentTxs = state.value ?? [];
    final updatedTxs = currentTxs.where((t) => t.id != tx.id).toList();

    // Optimistic delete
    state = AsyncData(updatedTxs);

    try {
      // 1. If deleting a 'saved' transaction, decrement total_savings
      if (tx.txType == 'saved') {
        await ref
            .read(expenseSettingsProvider.notifier)
            .adjustSavings(-tx.amount);
      }

      // 2. Delete transaction row if authenticated
      if (client != null && user != null) {
        await client.from('expense_transactions').delete().eq('id', tx.id);
      }
    } catch (e) {
      // Rollback optimistic delete
      state = AsyncData(currentTxs);
      AppLog.e('deleteTransaction error', e);
      rethrow;
    }
  }

  Future<void> restoreTransaction(ExpenseTransaction tx) async {
    final client = _supabase;
    final user = client?.auth.currentUser;

    final currentTxs = state.value ?? [];
    final updatedTxs = [tx, ...currentTxs.where((t) => t.id != tx.id)]
      ..sort((a, b) => b.txDate.compareTo(a.txDate));
    state = AsyncData(updatedTxs);

    try {
      if (tx.txType == 'saved') {
        await ref
            .read(expenseSettingsProvider.notifier)
            .adjustSavings(tx.amount);
      }

      if (client != null && user != null) {
        await client.from('expense_transactions').insert(tx.toJson());
      }
    } catch (e) {
      AppLog.e('restoreTransaction error', e);
    }
  }
}

final allTransactionsProvider =
    AsyncNotifierProvider<AllTransactionsNotifier, List<ExpenseTransaction>>(
      () {
        return AllTransactionsNotifier();
      },
    );

// =========================================================================
// 3. MONTH SUMMARIES NOTIFIER & PROVIDER
// =========================================================================

class MonthSummariesNotifier extends AsyncNotifier<List<ExpenseMonthSummary>> {
  SupabaseClient? get _supabase {
    try {
      if (Supabase.instance.isInitialized) {
        return Supabase.instance.client;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<List<ExpenseMonthSummary>> build() async {
    return _fetchSummaries();
  }

  Future<List<ExpenseMonthSummary>> _fetchSummaries() async {
    final client = _supabase;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return [];

    try {
      final res = await client
          .from('expense_month_summaries')
          .select()
          .eq('user_id', user.id)
          .order('month', ascending: false);

      final list = res as List<dynamic>;
      return list
          .map((j) => ExpenseMonthSummary.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLog.e('MonthSummariesNotifier._fetchSummaries error', e);
      return [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchSummaries());
  }
}

final monthSummariesProvider =
    AsyncNotifierProvider<MonthSummariesNotifier, List<ExpenseMonthSummary>>(
      () {
        return MonthSummariesNotifier();
      },
    );

// =========================================================================
// 4. MONTH SELECTION & NAVIGATION PROVIDERS
// =========================================================================

class SelectedMonthKeyNotifier extends Notifier<String> {
  @override
  String build() {
    return AppDateUtils.monthKey(DateTime.now());
  }

  void select(String monthKey) => state = monthKey;

  void selectPrevious(List<String> availableMonths) {
    final index = availableMonths.indexOf(state);
    if (index > 0) {
      state = availableMonths[index - 1];
    }
  }

  void selectNext(List<String> availableMonths) {
    final index = availableMonths.indexOf(state);
    if (index >= 0 && index < availableMonths.length - 1) {
      state = availableMonths[index + 1];
    }
  }
}

final selectedMonthKeyProvider =
    NotifierProvider<SelectedMonthKeyNotifier, String>(() {
      return SelectedMonthKeyNotifier();
    });

/// List of all available month keys in chronological ascending order,
/// covering the earliest tracked month up to the current active month.
final availableMonthKeysProvider = Provider<List<String>>((ref) {
  final currentMonth = AppDateUtils.monthKey(DateTime.now());
  final monthsSet = <String>{currentMonth};

  final settings = ref.watch(expenseSettingsProvider).value;
  if (settings != null && settings.lastResetMonth.isNotEmpty) {
    monthsSet.add(settings.lastResetMonth);
  }

  final summaries = ref.watch(monthSummariesProvider).value ?? [];
  for (final s in summaries) {
    monthsSet.add(s.month);
  }

  final transactions = ref.watch(allTransactionsProvider).value ?? [];
  for (final t in transactions) {
    monthsSet.add(AppDateUtils.monthKey(t.txDate));
  }

  // Fill in any gaps between earliest month and currentMonth so navigation is continuous
  final sortedList = monthsSet.toList()..sort();
  final earliestMonth = sortedList.first;

  String cursor = earliestMonth;
  final continuousSet = <String>{};
  while (!AppDateUtils.isMonthBefore(currentMonth, cursor)) {
    continuousSet.add(cursor);
    cursor = AppDateUtils.nextMonthKey(cursor);
  }
  continuousSet.add(currentMonth);

  final result = continuousSet.toList()..sort();
  return result;
});

/// Whether the selected month is the active current month.
final isCurrentMonthSelectedProvider = Provider<bool>((ref) {
  final selected = ref.watch(selectedMonthKeyProvider);
  final current = AppDateUtils.monthKey(DateTime.now());
  return selected == current;
});

/// Transactions for the currently selected month, newest first.
final transactionsForSelectedMonthProvider = Provider<List<ExpenseTransaction>>(
  (ref) {
    final selectedMonth = ref.watch(selectedMonthKeyProvider);
    final allTxs = ref.watch(allTransactionsProvider).value ?? [];
    return allTxs
        .where((t) => AppDateUtils.monthKey(t.txDate) == selectedMonth)
        .toList();
  },
);

/// Closed month summary for the selected month (if it is a past closed month).
final summaryForSelectedMonthProvider = Provider<ExpenseMonthSummary?>((ref) {
  final selectedMonth = ref.watch(selectedMonthKeyProvider);
  final summaries = ref.watch(monthSummariesProvider).value ?? [];
  try {
    return summaries.firstWhere((s) => s.month == selectedMonth);
  } catch (_) {
    return null;
  }
});

// =========================================================================
// 5. CURRENT MONTH 4-METRIC HEADER PROVIDERS
// =========================================================================

final currentMonthTransactionsProvider = Provider<List<ExpenseTransaction>>((
  ref,
) {
  final currentMonth = AppDateUtils.monthKey(DateTime.now());
  final allTxs = ref.watch(allTransactionsProvider).value ?? [];
  return allTxs
      .where((t) => AppDateUtils.monthKey(t.txDate) == currentMonth)
      .toList();
});

final currentMonthSpentProvider = Provider<double>((ref) {
  final txs = ref.watch(currentMonthTransactionsProvider);
  return txs
      .where((t) => t.txType == 'spent')
      .fold<double>(0.0, (sum, t) => sum + t.amount);
});

final currentMonthReceivedProvider = Provider<double>((ref) {
  final txs = ref.watch(currentMonthTransactionsProvider);
  return txs
      .where((t) => t.txType == 'received')
      .fold<double>(0.0, (sum, t) => sum + t.amount);
});

final currentMonthSavedProvider = Provider<double>((ref) {
  final txs = ref.watch(currentMonthTransactionsProvider);
  return txs
      .where((t) => t.txType == 'saved')
      .fold<double>(0.0, (sum, t) => sum + t.amount);
});

final currentMonthRemainingBalanceProvider = Provider<double>((ref) {
  final settings = ref.watch(expenseSettingsProvider).value;
  final allowance = settings?.monthlyAllowance ?? 0.0;
  final received = ref.watch(currentMonthReceivedProvider);
  final spent = ref.watch(currentMonthSpentProvider);
  final saved = ref.watch(currentMonthSavedProvider);

  return ExpenseResetService.computeRemainingBalance(
    allowance: allowance,
    received: received,
    spent: spent,
    saved: saved,
  );
});
