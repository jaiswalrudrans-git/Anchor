import 'package:flutter_test/flutter_test.dart';
import 'package:anchor/core/utils/date_utils.dart';
import 'package:anchor/models/workout_day.dart';
import 'package:anchor/models/workout_exercise.dart';

void main() {
  group('Workout Models and Natural Daily Reset Logic', () {
    final today = AppDateUtils.today();
    final yesterday = today.subtract(const Duration(days: 1));

    test('WorkoutDay serializes and deserializes correctly', () {
      final day = WorkoutDay(
        id: 'day-1',
        userId: 'user-1',
        weekday: 1, // Monday
        splitTitle: 'Chest & Shoulders',
      );

      final json = day.toJson();
      expect(json['weekday'], 1);
      expect(json['split_title'], 'Chest & Shoulders');

      final reconstructed = WorkoutDay.fromJson(json);
      expect(reconstructed, day);
    });

    test('WorkoutExercise serializes and deserializes dates correctly', () {
      final exercise = WorkoutExercise(
        id: 'ex-1',
        userId: 'user-1',
        workoutDayId: 'day-1',
        exerciseName: 'Flat Dumbbell Press',
        setsReps: '4 x 10',
        lastCompletedDate: today,
      );

      final json = exercise.toJson();
      expect(json['exercise_name'], 'Flat Dumbbell Press');
      expect(json['sets_reps'], '4 x 10');
      expect(json['last_completed_date'], AppDateUtils.formatDbDate(today));

      final reconstructed = WorkoutExercise.fromJson(json);
      expect(reconstructed, exercise);
    });

    test('natural daily reset: exercise completed yesterday evaluates to false today without any reset job', () {
      final completedYesterday = WorkoutExercise(
        id: 'ex-1',
        userId: 'user-1',
        workoutDayId: 'day-1',
        exerciseName: 'Barbell Squats',
        setsReps: '5 x 5',
        lastCompletedDate: yesterday,
      );

      // Check condition: lastCompletedDate != null && dateOnly(lastCompletedDate!) == today
      final isDoneToday = completedYesterday.lastCompletedDate != null &&
          AppDateUtils.dateOnly(completedYesterday.lastCompletedDate!) == today;

      expect(isDoneToday, isFalse);
    });

    test('exercise completed today evaluates to true', () {
      final completedToday = WorkoutExercise(
        id: 'ex-2',
        userId: 'user-1',
        workoutDayId: 'day-1',
        exerciseName: 'Incline Dumbbell Press',
        setsReps: '3 x 12',
        lastCompletedDate: today,
      );

      final isDoneToday = completedToday.lastCompletedDate != null &&
          AppDateUtils.dateOnly(completedToday.lastCompletedDate!) == today;

      expect(isDoneToday, isTrue);
    });

    test('exercise with null lastCompletedDate evaluates to false', () {
      final uncompleted = WorkoutExercise(
        id: 'ex-3',
        userId: 'user-1',
        workoutDayId: 'day-1',
        exerciseName: 'Lateral Raises',
        setsReps: '4 x 15',
        lastCompletedDate: null,
      );

      final isDoneToday = uncompleted.lastCompletedDate != null &&
          AppDateUtils.dateOnly(uncompleted.lastCompletedDate!) == today;

      expect(isDoneToday, isFalse);
    });

    test('toggling clears lastCompletedDate with clearLastCompletedDate flag', () {
      final exercise = WorkoutExercise(
        id: 'ex-1',
        userId: 'user-1',
        workoutDayId: 'day-1',
        exerciseName: 'Dumbbell Curl',
        setsReps: '3 x 12',
        lastCompletedDate: today,
      );

      final toggledOff = exercise.copyWith(clearLastCompletedDate: true);
      expect(toggledOff.lastCompletedDate, isNull);

      final toggledOn = toggledOff.copyWith(lastCompletedDate: today);
      expect(toggledOn.lastCompletedDate, today);
    });
  });
}
