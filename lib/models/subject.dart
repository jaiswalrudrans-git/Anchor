import 'package:flutter/foundation.dart';

import 'model_helpers.dart';

@immutable
class Subject {
  final String id;
  final String userId;
  final String name;
  final int sortOrder;

  const Subject({
    required this.id,
    required this.userId,
    required this.name,
    this.sortOrder = 0,
  });

  Subject copyWith({String? id, String? userId, String? name, int? sortOrder}) {
    return Subject(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      sortOrder: parseInt(json['sort_order'], 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'user_id': userId, 'name': name, 'sort_order': sortOrder};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Subject &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          name == other.name &&
          sortOrder == other.sortOrder;

  @override
  int get hashCode =>
      id.hashCode ^ userId.hashCode ^ name.hashCode ^ sortOrder.hashCode;
}
