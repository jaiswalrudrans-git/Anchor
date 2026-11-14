import 'package:flutter/foundation.dart';
import 'model_helpers.dart';

@immutable
class ExpenseMonthSummary {
  final String id;
  final String userId;
  final String month; // 'YYYY-MM'
  final double allowance;
  final double received;
  final double spent;
  final double saved;
  final double remainder;
  final double carriedToSavings;
  final DateTime closedAt;

  const ExpenseMonthSummary({
    required this.id,
    required this.userId,
    required this.month,
    required this.allowance,
    required this.received,
    required this.spent,
    required this.saved,
    required this.remainder,
    required this.carriedToSavings,
    required this.closedAt,
  });

  ExpenseMonthSummary copyWith({
    String? id,
    String? userId,
    String? month,
    double? allowance,
    double? received,
    double? spent,
    double? saved,
    double? remainder,
    double? carriedToSavings,
    DateTime? closedAt,
  }) {
    return ExpenseMonthSummary(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      month: month ?? this.month,
      allowance: allowance ?? this.allowance,
      received: received ?? this.received,
      spent: spent ?? this.spent,
      saved: saved ?? this.saved,
      remainder: remainder ?? this.remainder,
      carriedToSavings: carriedToSavings ?? this.carriedToSavings,
      closedAt: closedAt ?? this.closedAt,
    );
  }

  factory ExpenseMonthSummary.fromJson(Map<String, dynamic> json) {
    return ExpenseMonthSummary(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      month: json['month'] as String,
      allowance: parseDouble(json['allowance'], 0.0),
      received: parseDouble(json['received'], 0.0),
      spent: parseDouble(json['spent'], 0.0),
      saved: parseDouble(json['saved'], 0.0),
      remainder: parseDouble(json['remainder'], 0.0),
      carriedToSavings: parseDouble(json['carried_to_savings'], 0.0),
      closedAt: DateTime.parse(json['closed_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'month': month,
      'allowance': allowance,
      'received': received,
      'spent': spent,
      'saved': saved,
      'remainder': remainder,
      'carried_to_savings': carriedToSavings,
      'closed_at': closedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseMonthSummary &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          month == other.month &&
          allowance == other.allowance &&
          received == other.received &&
          spent == other.spent &&
          saved == other.saved &&
          remainder == other.remainder &&
          carriedToSavings == other.carriedToSavings &&
          closedAt == other.closedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      month.hashCode ^
      allowance.hashCode ^
      received.hashCode ^
      spent.hashCode ^
      saved.hashCode ^
      remainder.hashCode ^
      carriedToSavings.hashCode ^
      closedAt.hashCode;
}
