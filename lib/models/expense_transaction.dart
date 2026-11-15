import 'package:flutter/foundation.dart';

import 'model_helpers.dart';

@immutable
class ExpenseTransaction {
  final String id;
  final String userId;
  final String title;
  final String category;
  final double amount;
  final String txType; // 'spent' | 'received' | 'saved'
  final DateTime txDate;

  const ExpenseTransaction({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.amount,
    required this.txType,
    required this.txDate,
  });

  ExpenseTransaction copyWith({
    String? id,
    String? userId,
    String? title,
    String? category,
    double? amount,
    String? txType,
    DateTime? txDate,
  }) {
    return ExpenseTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      txType: txType ?? this.txType,
      txDate: txDate ?? this.txDate,
    );
  }

  factory ExpenseTransaction.fromJson(Map<String, dynamic> json) {
    return ExpenseTransaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      amount: parseDouble(json['amount'], 0.0),
      txType: json['tx_type'] as String,
      txDate: DateTime.parse(json['tx_date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'category': category,
      'amount': amount,
      'tx_type': txType,
      'tx_date': txDate.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseTransaction &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          title == other.title &&
          category == other.category &&
          amount == other.amount &&
          txType == other.txType &&
          txDate == other.txDate;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      title.hashCode ^
      category.hashCode ^
      amount.hashCode ^
      txType.hashCode ^
      txDate.hashCode;
}
