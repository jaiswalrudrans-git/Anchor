import 'package:flutter/foundation.dart';

import '../core/utils/date_utils.dart';

@immutable
class HabitLog {
  final String id;
  final String userId;
  final String habitId;
  final DateTime logDate;

  const HabitLog({
    required this.id,
    required this.userId,
    required this.habitId,
    required this.logDate,
  });

  HabitLog copyWith({
    String? id,
    String? userId,
    String? habitId,
    DateTime? logDate,
  }) {
    return HabitLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      habitId: habitId ?? this.habitId,
      logDate: logDate ?? this.logDate,
    );
  }

  factory HabitLog.fromJson(Map<String, dynamic> json) {
    return HabitLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      habitId: json['habit_id'] as String,
      logDate: AppDateUtils.parseDbDate(json['log_date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'habit_id': habitId,
      'log_date': AppDateUtils.formatDbDate(logDate),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitLog &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          habitId == other.habitId &&
          logDate == other.logDate;

  @override
  int get hashCode =>
      id.hashCode ^ userId.hashCode ^ habitId.hashCode ^ logDate.hashCode;
}
