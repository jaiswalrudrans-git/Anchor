import 'package:flutter/foundation.dart';

import 'model_helpers.dart';

@immutable
class AcademicModule {
  final String id;
  final String userId;
  final String subjectId;
  final String title;
  final int sortOrder;

  const AcademicModule({
    required this.id,
    required this.userId,
    required this.subjectId,
    required this.title,
    this.sortOrder = 0,
  });

  AcademicModule copyWith({
    String? id,
    String? userId,
    String? subjectId,
    String? title,
    int? sortOrder,
  }) {
    return AcademicModule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  factory AcademicModule.fromJson(Map<String, dynamic> json) {
    return AcademicModule(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      subjectId: json['subject_id'] as String,
      title: json['title'] as String,
      sortOrder: parseInt(json['sort_order'], 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'subject_id': subjectId,
      'title': title,
      'sort_order': sortOrder,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcademicModule &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          subjectId == other.subjectId &&
          title == other.title &&
          sortOrder == other.sortOrder;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      subjectId.hashCode ^
      title.hashCode ^
      sortOrder.hashCode;
}
