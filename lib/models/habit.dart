import 'package:flutter/foundation.dart';

@immutable
class Habit {
  final String id;
  final String userId;
  final String title;
  final String icon;
  final DateTime createdAt;

  const Habit({
    required this.id,
    required this.userId,
    required this.title,
    this.icon = 'check_circle',
    required this.createdAt,
  });

  Habit copyWith({
    String? id,
    String? userId,
    String? title,
    String? icon,
    DateTime? createdAt,
  }) {
    return Habit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      icon: json['icon'] as String? ?? 'check_circle',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'icon': icon,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Habit &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          title == other.title &&
          icon == other.icon &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      title.hashCode ^
      icon.hashCode ^
      createdAt.hashCode;
}
