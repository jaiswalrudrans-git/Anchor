import 'package:flutter/foundation.dart';
import '../core/utils/date_utils.dart';

@immutable
class WorkoutExercise {
  final String id;
  final String userId;
  final String workoutDayId;
  final String exerciseName;
  final String setsReps;
  final DateTime? lastCompletedDate;

  const WorkoutExercise({
    required this.id,
    required this.userId,
    required this.workoutDayId,
    required this.exerciseName,
    required this.setsReps,
    this.lastCompletedDate,
  });

  WorkoutExercise copyWith({
    String? id,
    String? userId,
    String? workoutDayId,
    String? exerciseName,
    String? setsReps,
    DateTime? lastCompletedDate,
    bool clearLastCompletedDate = false,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      workoutDayId: workoutDayId ?? this.workoutDayId,
      exerciseName: exerciseName ?? this.exerciseName,
      setsReps: setsReps ?? this.setsReps,
      lastCompletedDate: clearLastCompletedDate
          ? null
          : (lastCompletedDate ?? this.lastCompletedDate),
    );
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      workoutDayId: json['workout_day_id'] as String,
      exerciseName: json['exercise_name'] as String,
      setsReps: json['sets_reps'] as String,
      lastCompletedDate: json['last_completed_date'] != null
          ? AppDateUtils.parseDbDate(json['last_completed_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'workout_day_id': workoutDayId,
      'exercise_name': exerciseName,
      'sets_reps': setsReps,
      'last_completed_date': lastCompletedDate != null
          ? AppDateUtils.formatDbDate(lastCompletedDate!)
          : null,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutExercise &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          workoutDayId == other.workoutDayId &&
          exerciseName == other.exerciseName &&
          setsReps == other.setsReps &&
          lastCompletedDate == other.lastCompletedDate;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      workoutDayId.hashCode ^
      exerciseName.hashCode ^
      setsReps.hashCode ^
      lastCompletedDate.hashCode;
}
