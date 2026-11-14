import 'package:flutter/foundation.dart';
import 'model_helpers.dart';

@immutable
class Chapter {
  final String id;
  final String userId;
  final String moduleId;
  final String title;
  final int sortOrder;

  const Chapter({
    required this.id,
    required this.userId,
    required this.moduleId,
    required this.title,
    this.sortOrder = 0,
  });

  Chapter copyWith({
    String? id,
    String? userId,
    String? moduleId,
    String? title,
    int? sortOrder,
  }) {
    return Chapter(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      moduleId: moduleId ?? this.moduleId,
      title: title ?? this.title,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      moduleId: json['module_id'] as String,
      title: json['title'] as String,
      sortOrder: parseInt(json['sort_order'], 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'module_id': moduleId,
      'title': title,
      'sort_order': sortOrder,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Chapter &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          moduleId == other.moduleId &&
          title == other.title &&
          sortOrder == other.sortOrder;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      moduleId.hashCode ^
      title.hashCode ^
      sortOrder.hashCode;
}
