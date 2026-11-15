import 'package:flutter/foundation.dart';

@immutable
class IdlePrompt {
  final String id;
  final String userId;
  final String promptText;
  final DateTime createdAt;

  const IdlePrompt({
    required this.id,
    required this.userId,
    required this.promptText,
    required this.createdAt,
  });

  IdlePrompt copyWith({
    String? id,
    String? userId,
    String? promptText,
    DateTime? createdAt,
  }) {
    return IdlePrompt(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      promptText: promptText ?? this.promptText,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory IdlePrompt.fromJson(Map<String, dynamic> json) {
    return IdlePrompt(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      promptText: json['prompt_text'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'prompt_text': promptText,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IdlePrompt &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          promptText == other.promptText &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^ userId.hashCode ^ promptText.hashCode ^ createdAt.hashCode;
}
