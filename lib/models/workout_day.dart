import 'package:flutter/foundation.dart';
import 'model_helpers.dart';

@immutable
class WorkoutDay {
  final String id;
  final String userId;
  final int weekday; // 1..7 (1=Mon)
  final String splitTitle;

  const WorkoutDay({
    required this.id,
    required this.userId,
    required this.weekday,
    required this.splitTitle,
  });

  WorkoutDay copyWith({
    String? id,
    String? userId,
    int? weekday,
    String? splitTitle,
  }) {
    return WorkoutDay(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      weekday: weekday ?? this.weekday,
      splitTitle: splitTitle ?? this.splitTitle,
    );
  }

  factory WorkoutDay.fromJson(Map<String, dynamic> json) {
    return WorkoutDay(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      weekday: parseInt(json['weekday'], 1),
      splitTitle: json['split_title'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'weekday': weekday,
      'split_title': splitTitle,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutDay &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          weekday == other.weekday &&
          splitTitle == other.splitTitle;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      weekday.hashCode ^
      splitTitle.hashCode;
}
