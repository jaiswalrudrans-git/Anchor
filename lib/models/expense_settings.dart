import 'package:flutter/foundation.dart';
import 'model_helpers.dart';

@immutable
class ExpenseSettings {
  final String userId;
  final double monthlyAllowance;
  final double totalSavings;
  final String lastResetMonth; // 'YYYY-MM'

  const ExpenseSettings({
    required this.userId,
    this.monthlyAllowance = 0.0,
    this.totalSavings = 0.0,
    required this.lastResetMonth,
  });

  ExpenseSettings copyWith({
    String? userId,
    double? monthlyAllowance,
    double? totalSavings,
    String? lastResetMonth,
  }) {
    return ExpenseSettings(
      userId: userId ?? this.userId,
      monthlyAllowance: monthlyAllowance ?? this.monthlyAllowance,
      totalSavings: totalSavings ?? this.totalSavings,
      lastResetMonth: lastResetMonth ?? this.lastResetMonth,
    );
  }

  factory ExpenseSettings.fromJson(Map<String, dynamic> json) {
    return ExpenseSettings(
      userId: json['user_id'] as String,
      monthlyAllowance: parseDouble(json['monthly_allowance'], 0.0),
      totalSavings: parseDouble(json['total_savings'], 0.0),
      lastResetMonth: json['last_reset_month'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'monthly_allowance': monthlyAllowance,
      'total_savings': totalSavings,
      'last_reset_month': lastResetMonth,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseSettings &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          monthlyAllowance == other.monthlyAllowance &&
          totalSavings == other.totalSavings &&
          lastResetMonth == other.lastResetMonth;

  @override
  int get hashCode =>
      userId.hashCode ^
      monthlyAllowance.hashCode ^
      totalSavings.hashCode ^
      lastResetMonth.hashCode;
}
