import 'package:flutter/foundation.dart';
import 'model_helpers.dart';

@immutable
class ChapterFile {
  final String id;
  final String userId;
  final String chapterId;
  final String fileName;
  final String fileType;
  final int fileSize;
  final String storagePath;
  final DateTime createdAt;

  const ChapterFile({
    required this.id,
    required this.userId,
    required this.chapterId,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.storagePath,
    required this.createdAt,
  });

  ChapterFile copyWith({
    String? id,
    String? userId,
    String? chapterId,
    String? fileName,
    String? fileType,
    int? fileSize,
    String? storagePath,
    DateTime? createdAt,
  }) {
    return ChapterFile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      chapterId: chapterId ?? this.chapterId,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      storagePath: storagePath ?? this.storagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ChapterFile.fromJson(Map<String, dynamic> json) {
    return ChapterFile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      chapterId: json['chapter_id'] as String,
      fileName: json['file_name'] as String,
      fileType: json['file_type'] as String,
      fileSize: parseInt(json['file_size'], 0),
      storagePath: json['storage_path'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'chapter_id': chapterId,
      'file_name': fileName,
      'file_type': fileType,
      'file_size': fileSize,
      'storage_path': storagePath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChapterFile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          chapterId == other.chapterId &&
          fileName == other.fileName &&
          fileType == other.fileType &&
          fileSize == other.fileSize &&
          storagePath == other.storagePath &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      chapterId.hashCode ^
      fileName.hashCode ^
      fileType.hashCode ^
      fileSize.hashCode ^
      storagePath.hashCode ^
      createdAt.hashCode;
}
