import 'package:flutter/foundation.dart';
import '../core/utils/date_utils.dart';

@immutable
class Todo {
  final String id;
  final String userId;
  final String title;
  final DateTime scheduledDate;
  final bool isCompleted;
  final int rolloverCount;
  final DateTime createdAt;

  const Todo({
    required this.id,
    required this.userId,
    required this.title,
    required this.scheduledDate,
    required this.isCompleted,
    this.rolloverCount = 0,
    required this.createdAt,
  });

  Todo copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? scheduledDate,
    bool? isCompleted,
    int? rolloverCount,
    DateTime? createdAt,
  }) {
    return Todo(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      isCompleted: isCompleted ?? this.isCompleted,
      rolloverCount: rolloverCount ?? this.rolloverCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      scheduledDate: AppDateUtils.parseDbDate(json['scheduled_date'] as String),
      isCompleted: json['is_completed'] as bool? ?? false,
      rolloverCount: (json['rollover_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'scheduled_date': AppDateUtils.formatDbDate(scheduledDate),
      'is_completed': isCompleted,
      'rollover_count': rolloverCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Todo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          title == other.title &&
          scheduledDate == other.scheduledDate &&
          isCompleted == other.isCompleted &&
          rolloverCount == other.rolloverCount &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      title.hashCode ^
      scheduledDate.hashCode ^
      isCompleted.hashCode ^
      rolloverCount.hashCode ^
      createdAt.hashCode;
}
