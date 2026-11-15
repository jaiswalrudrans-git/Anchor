import 'package:flutter/foundation.dart';

import '../core/utils/date_utils.dart';

@immutable
class AcademicItem {
  final String id;
  final String userId;
  final String? subjectId;
  final String title;
  final String itemType; // 'assignment' | 'exam'
  final DateTime dueDate;
  final bool isCompleted;
  final DateTime createdAt;

  const AcademicItem({
    required this.id,
    required this.userId,
    this.subjectId,
    required this.title,
    required this.itemType,
    required this.dueDate,
    required this.isCompleted,
    required this.createdAt,
  });

  AcademicItem copyWith({
    String? id,
    String? userId,
    String? subjectId,
    String? title,
    String? itemType,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return AcademicItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      itemType: itemType ?? this.itemType,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory AcademicItem.fromJson(Map<String, dynamic> json) {
    return AcademicItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      subjectId: json['subject_id'] as String?,
      title: json['title'] as String,
      itemType: json['item_type'] as String,
      dueDate: AppDateUtils.parseDbDate(json['due_date'] as String),
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'subject_id': subjectId,
      'title': title,
      'item_type': itemType,
      'due_date': AppDateUtils.formatDbDate(dueDate),
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcademicItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          subjectId == other.subjectId &&
          title == other.title &&
          itemType == other.itemType &&
          dueDate == other.dueDate &&
          isCompleted == other.isCompleted &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      subjectId.hashCode ^
      title.hashCode ^
      itemType.hashCode ^
      dueDate.hashCode ^
      isCompleted.hashCode ^
      createdAt.hashCode;
}
