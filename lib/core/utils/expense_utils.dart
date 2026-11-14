import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/expense_transaction.dart';
import '../constants/categories.dart';
import 'date_utils.dart';

/// Spending progress tone:
/// - accent (< 75%)
/// - warning (75% to 100%)
/// - danger (> 100%)
enum SpendingTone {
  accent,
  warning,
  danger,
}

/// Computes the spending progress tone according to budget thresholds.
SpendingTone getSpendingTone(double spent, double allowance) {
  if (allowance <= 0) return SpendingTone.accent;
  final ratio = spent / allowance;
  if (ratio > 1.0) {
    return SpendingTone.danger;
  } else if (ratio >= 0.75) {
    return SpendingTone.warning;
  } else {
    return SpendingTone.accent;
  }
}

/// Returns the formatted spending caption.
/// E.g. "₹1,200.00 of ₹5,000.00 spent" or "Over budget by ₹500.00".
String getSpendingCaption(double spent, double allowance) {
  if (allowance <= 0) {
    return '${AppDateUtils.formatCurrency(spent)} spent';
  }
  if (spent > allowance) {
    final overBudget = spent - allowance;
    return 'Over budget by ${AppDateUtils.formatCurrency(overBudget)}';
  }
  return '${AppDateUtils.formatCurrency(spent)} of ${AppDateUtils.formatCurrency(allowance)} spent';
}

/// Fixed category icons across Anchor Expenses.
IconData getExpenseCategoryIcon(String category, [String? txType]) {
  if (txType == 'saved') return Icons.savings_outlined;
  switch (category) {
    case ExpenseCategories.food:
      return Icons.restaurant_outlined;
    case ExpenseCategories.travel:
      return Icons.directions_car_outlined;
    case ExpenseCategories.collegeStudy:
      return Icons.school_outlined;
    case ExpenseCategories.gymDiet:
      return Icons.fitness_center_outlined;
    case ExpenseCategories.personal:
      return Icons.person_outline;
    case ExpenseCategories.general:
    default:
      return Icons.category_outlined;
  }
}

/// Calendar day grouping header formatting.
/// Accurately formats "Today", "Yesterday", or "Mon, 10 Nov" at calendar date boundaries.
String formatDayHeader(DateTime txDate, [DateTime? relativeTo]) {
  final now = relativeTo ?? DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final local = txDate.toLocal();
  final txDay = DateTime(local.year, local.month, local.day);

  if (txDay == today) {
    return 'Today';
  } else if (txDay == yesterday) {
    return 'Yesterday';
  } else {
    return DateFormat('EEE, d MMM').format(local);
  }
}

/// Calculates net spend for a given list of transactions.
/// Net spend = received - spent - saved (negative means net money outflow).
double calculateDayNetSpend(List<ExpenseTransaction> txs) {
  double spentTotal = 0.0;
  double receivedTotal = 0.0;
  double savedTotal = 0.0;

  for (final tx in txs) {
    if (tx.txType == 'spent') {
      spentTotal += tx.amount;
    } else if (tx.txType == 'received') {
      receivedTotal += tx.amount;
    } else if (tx.txType == 'saved') {
      savedTotal += tx.amount;
    }
  }

  return receivedTotal - spentTotal - savedTotal;
}

/// Formats the net spend string.
/// E.g. "-₹250.00" (if outflow), "+₹500.00" (if inflow), "₹0.00" (if zero).
/// When [includePrefix] is true, prefixes with "Net: ".
String formatDayNetSpend(double net, {bool includePrefix = false}) {
  final prefix = includePrefix ? 'Net: ' : '';
  if (net < 0) {
    return '$prefix-${AppDateUtils.formatCurrency(-net)}';
  } else if (net > 0) {
    return '$prefix+${AppDateUtils.formatCurrency(net)}';
  } else {
    return '$prefix${AppDateUtils.formatCurrency(0.0)}';
  }
}

/// Encapsulates a day's transactions and net total.
class DayGroupedTransactions {
  final DateTime date;
  final String label;
  final List<ExpenseTransaction> transactions;
  final double netSpend;

  const DayGroupedTransactions({
    required this.date,
    required this.label,
    required this.transactions,
    required this.netSpend,
  });
}

/// Groups a list of transactions descending by calendar day.
List<DayGroupedTransactions> groupTransactionsByDay(
  List<ExpenseTransaction> txs, [
  DateTime? relativeTo,
]) {
  if (txs.isEmpty) return [];

  // Sort descending by date
  final sorted = List<ExpenseTransaction>.from(txs)
    ..sort((a, b) => b.txDate.compareTo(a.txDate));

  final Map<String, List<ExpenseTransaction>> groups = {};
  final Map<String, DateTime> groupDateMap = {};

  for (final tx in sorted) {
    final local = tx.txDate.toLocal();
    final key = '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
    groups.putIfAbsent(key, () => []).add(tx);
    groupDateMap.putIfAbsent(key, () => DateTime(local.year, local.month, local.day));
  }

  final List<DayGroupedTransactions> result = [];
  for (final entry in groups.entries) {
    final date = groupDateMap[entry.key]!;
    final label = formatDayHeader(date, relativeTo);
    final net = calculateDayNetSpend(entry.value);
    result.add(DayGroupedTransactions(
      date: date,
      label: label,
      transactions: entry.value,
      netSpend: net,
    ));
  }

  return result;
}
