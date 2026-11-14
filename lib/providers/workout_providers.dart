import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/date_utils.dart';
import '../models/workout_day.dart';
import '../models/workout_exercise.dart';

const _uuid = Uuid();

SupabaseClient? get _supabase {
  try {
    return Supabase.instance.client;
  } catch (_) {
    return null;
  }
}

// =============================================================================
// 1. WORKOUT DAYS NOTIFIER & PROVIDER
// =============================================================================

class WorkoutDaysNotifier extends AsyncNotifier<List<WorkoutDay>> {
  @override
  Future<List<WorkoutDay>> build() async {
    return _fetchDays();
  }

  Future<List<WorkoutDay>> _fetchDays() async {
    final client = _supabase;
    if (client == null) return [];

    final user = client.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await client
          .from('workout_days')
          .select()
          .order('weekday', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => WorkoutDay.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('WorkoutDaysNotifier._fetchDays error: $e');
      return [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchDays());
  }

  /// Sets or updates the split title for a given weekday (1..7).
  /// Creates the workout_days row lazily if it does not yet exist.
  Future<WorkoutDay> setSplitTitle(int weekday, String title) async {
    final client = _supabase;
    final user = client?.auth.currentUser;
    final trimmed = title.trim();

    final current = state.value ?? [];
    final existingIndex = current.indexWhere((d) => d.weekday == weekday);

    WorkoutDay day;
    if (existingIndex != -1) {
      day = current[existingIndex].copyWith(splitTitle: trimmed);
      final updated = List<WorkoutDay>.from(current);
      updated[existingIndex] = day;
      state = AsyncData(updated);
    } else {
      day = WorkoutDay(
        id: _uuid.v4(),
        userId: user?.id ?? 'test_user',
        weekday: weekday,
        splitTitle: trimmed,
      );
      state = AsyncData([...current, day]);
    }

    if (client != null && user != null) {
      try {
        await client.from('workout_days').upsert(
          {
            'id': day.id,
            'user_id': day.userId,
            'weekday': day.weekday,
            'split_title': day.splitTitle,
          },
          onConflict: 'user_id,weekday',
        );
      } catch (e) {
        state = AsyncData(current);
        debugPrint('setSplitTitle error: $e');
        rethrow;
      }
    }

    return day;
  }
}

final workoutDaysProvider = AsyncNotifierProvider<WorkoutDaysNotifier, List<WorkoutDay>>(() {
  return WorkoutDaysNotifier();
});

// =============================================================================
// 2. WORKOUT EXERCISES NOTIFIER & PROVIDER
// =============================================================================

class WorkoutExercisesNotifier extends AsyncNotifier<List<WorkoutExercise>> {
  @override
  Future<List<WorkoutExercise>> build() async {
    return _fetchExercises();
  }

  Future<List<WorkoutExercise>> _fetchExercises() async {
    final client = _supabase;
    if (client == null) return [];

    final user = client.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await client
          .from('workout_exercises')
          .select()
          .order('exercise_name', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => WorkoutExercise.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('WorkoutExercisesNotifier._fetchExercises error: $e');
      return [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchExercises());
  }

  /// Adds an exercise to a specific weekday.
  /// Lazily creates the workout_day if one does not exist.
  Future<WorkoutExercise> addExercise({
    required int weekday,
    required String exerciseName,
    required String setsReps,
  }) async {
    final client = _supabase;
    final user = client?.auth.currentUser;

    final trimmedName = exerciseName.trim();
    final trimmedSets = setsReps.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Exercise name cannot be empty');
    }

    // Ensure workout_day exists for this weekday
    final days = ref.read(workoutDaysProvider).value ?? [];
    WorkoutDay? day = days.cast<WorkoutDay?>().firstWhere(
      (d) => d?.weekday == weekday,
      orElse: () => null,
    );

    day ??= await ref.read(workoutDaysProvider.notifier).setSplitTitle(weekday, 'Workout Day');

    final newExercise = WorkoutExercise(
      id: _uuid.v4(),
      userId: user?.id ?? 'test_user',
      workoutDayId: day.id,
      exerciseName: trimmedName,
      setsReps: trimmedSets.isNotEmpty ? trimmedSets : '3 x 10',
      lastCompletedDate: null,
    );

    final current = state.value ?? [];
    state = AsyncData([...current, newExercise]);

    if (client != null && user != null) {
      try {
        await client.from('workout_exercises').insert({
          'id': newExercise.id,
          'user_id': newExercise.userId,
          'workout_day_id': newExercise.workoutDayId,
          'exercise_name': newExercise.exerciseName,
          'sets_reps': newExercise.setsReps,
          'last_completed_date': null,
        });
      } catch (e) {
        state = AsyncData(current);
        debugPrint('addExercise error: $e');
        rethrow;
      }
    }

    return newExercise;
  }

  /// Deletes an exercise template.
  Future<void> deleteExercise(String exerciseId) async {
    final client = _supabase;
    final current = state.value ?? [];
    final updated = current.where((e) => e.id != exerciseId).toList();
    state = AsyncData(updated);

    if (client != null) {
      try {
        await client.from('workout_exercises').delete().eq('id', exerciseId);
      } catch (e) {
        state = AsyncData(current);
        debugPrint('deleteExercise error: $e');
        rethrow;
      }
    }
  }

  /// Toggles today's completion for an exercise.
  /// Sets last_completed_date = today, or null if already completed today.
  Future<void> toggleExerciseToday(String exerciseId) async {
    final client = _supabase;
    final today = AppDateUtils.today();
    final todayStr = AppDateUtils.formatDbDate(today);

    final current = state.value ?? [];
    final index = current.indexWhere((e) => e.id == exerciseId);
    if (index == -1) return;

    final exercise = current[index];
    final isCompletedToday = exercise.lastCompletedDate != null &&
        AppDateUtils.dateOnly(exercise.lastCompletedDate!) == today;

    final updatedExercise = exercise.copyWith(
      lastCompletedDate: isCompletedToday ? null : today,
      clearLastCompletedDate: isCompletedToday,
    );

    final updated = List<WorkoutExercise>.from(current);
    updated[index] = updatedExercise;
    state = AsyncData(updated);

    if (client != null) {
      try {
        await client.from('workout_exercises').update({
          'last_completed_date': isCompletedToday ? null : todayStr,
        }).eq('id', exerciseId);
      } catch (e) {
        state = AsyncData(current);
        debugPrint('toggleExerciseToday error: $e');
        rethrow;
      }
    }
  }
}

final workoutExercisesProvider =
    AsyncNotifierProvider<WorkoutExercisesNotifier, List<WorkoutExercise>>(() {
  return WorkoutExercisesNotifier();
});

// =============================================================================
// 3. SELECTED WEEKDAY PROVIDER (Workout Tab)
// 1 = Monday .. 7 = Sunday, defaults to today's weekday
// =============================================================================

class SelectedWeekdayNotifier extends Notifier<int> {
  @override
  int build() {
    return DateTime.now().weekday;
  }

  void setWeekday(int weekday) {
    if (weekday >= 1 && weekday <= 7) {
      state = weekday;
    }
  }
}

final selectedWeekdayProvider =
    NotifierProvider<SelectedWeekdayNotifier, int>(() {
  return SelectedWeekdayNotifier();
});

// =============================================================================
// 4. DERIVED WORKOUT PROVIDERS
// =============================================================================

/// Returns the WorkoutDay for a given weekday (1..7).
final workoutDayForWeekdayProvider =
    Provider.family<WorkoutDay?, int>((ref, weekday) {
  final days = ref.watch(workoutDaysProvider).value ?? [];
  return days.cast<WorkoutDay?>().firstWhere(
    (d) => d?.weekday == weekday,
    orElse: () => null,
  );
});

/// Returns exercises for a given weekday (1..7).
final exercisesForWeekdayProvider =
    Provider.family<List<WorkoutExercise>, int>((ref, weekday) {
  final day = ref.watch(workoutDayForWeekdayProvider(weekday));
  if (day == null) return [];
  final allExercises = ref.watch(workoutExercisesProvider).value ?? [];
  return allExercises.where((e) => e.workoutDayId == day.id).toList();
});

/// Today's weekday (1 = Monday .. 7 = Sunday).
final todaysWeekdayProvider = Provider<int>((ref) {
  return DateTime.now().weekday;
});

/// Today's WorkoutDay.
final todaysWorkoutDayProvider = Provider<WorkoutDay?>((ref) {
  final todayWeekday = ref.watch(todaysWeekdayProvider);
  return ref.watch(workoutDayForWeekdayProvider(todayWeekday));
});

/// Today's WorkoutExercises.
final todaysExercisesProvider = Provider<List<WorkoutExercise>>((ref) {
  final todayWeekday = ref.watch(todaysWeekdayProvider);
  return ref.watch(exercisesForWeekdayProvider(todayWeekday));
});
