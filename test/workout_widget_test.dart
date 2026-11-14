import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anchor/core/constants/theme.dart';
import 'package:anchor/core/utils/date_utils.dart';
import 'package:anchor/models/workout_day.dart';
import 'package:anchor/models/workout_exercise.dart';
import 'package:anchor/providers/workout_providers.dart';
import 'package:anchor/screens/home/widgets/workout_strip_slot.dart';
import 'package:anchor/screens/workout/workout_screen.dart';
import 'package:anchor/screens/workout/widgets/add_exercise_sheet.dart';
import 'package:anchor/screens/workout/widgets/edit_split_dialog.dart';

class TestWorkoutDaysNotifier extends WorkoutDaysNotifier {
  List<WorkoutDay> _days;
  TestWorkoutDaysNotifier(this._days);

  @override
  Future<List<WorkoutDay>> build() async => _days;

  @override
  Future<void> refresh() async {
    state = AsyncData(_days);
  }

  @override
  Future<WorkoutDay> setSplitTitle(int weekday, String title) async {
    final trimmed = title.trim();
    final index = _days.indexWhere((d) => d.weekday == weekday);
    WorkoutDay day;
    if (index != -1) {
      day = _days[index].copyWith(splitTitle: trimmed);
      _days = List<WorkoutDay>.from(_days);
      _days[index] = day;
    } else {
      day = WorkoutDay(
        id: 'day-$weekday',
        userId: 'user-1',
        weekday: weekday,
        splitTitle: trimmed,
      );
      _days = [..._days, day];
    }
    state = AsyncData(_days);
    return day;
  }
}

class TestWorkoutExercisesNotifier extends WorkoutExercisesNotifier {
  List<WorkoutExercise> _exercises;
  TestWorkoutExercisesNotifier(this._exercises);

  @override
  Future<List<WorkoutExercise>> build() async => _exercises;

  @override
  Future<void> refresh() async {
    state = AsyncData(_exercises);
  }

  @override
  Future<WorkoutExercise> addExercise({
    required int weekday,
    required String exerciseName,
    required String setsReps,
  }) async {
    final days = ref.read(workoutDaysProvider).value ?? [];
    WorkoutDay? day = days.cast<WorkoutDay?>().firstWhere(
      (d) => d?.weekday == weekday,
      orElse: () => null,
    );
    day ??= await ref.read(workoutDaysProvider.notifier).setSplitTitle(weekday, 'Workout Day');

    final newExercise = WorkoutExercise(
      id: 'ex-${_exercises.length + 1}',
      userId: 'user-1',
      workoutDayId: day.id,
      exerciseName: exerciseName.trim(),
      setsReps: setsReps.trim().isNotEmpty ? setsReps.trim() : '3 x 10',
      lastCompletedDate: null,
    );

    _exercises = [..._exercises, newExercise];
    state = AsyncData(_exercises);
    return newExercise;
  }

  @override
  Future<void> deleteExercise(String exerciseId) async {
    _exercises = _exercises.where((e) => e.id != exerciseId).toList();
    state = AsyncData(_exercises);
  }

  @override
  Future<void> toggleExerciseToday(String exerciseId) async {
    final today = AppDateUtils.today();
    final index = _exercises.indexWhere((e) => e.id == exerciseId);
    if (index == -1) return;

    final exercise = _exercises[index];
    final isDone = exercise.lastCompletedDate != null &&
        AppDateUtils.dateOnly(exercise.lastCompletedDate!) == today;

    final updated = exercise.copyWith(
      lastCompletedDate: isDone ? null : today,
      clearLastCompletedDate: isDone,
    );
    _exercises = List<WorkoutExercise>.from(_exercises);
    _exercises[index] = updated;
    state = AsyncData(_exercises);
  }
}

void main() {
  final todayWeekday = DateTime.now().weekday;
  final otherWeekday = todayWeekday == 7 ? 1 : todayWeekday + 1;

  Widget createWorkoutScreenWidget({
    List<WorkoutDay>? days,
    List<WorkoutExercise>? exercises,
  }) {
    final dList = days ?? [];
    final eList = exercises ?? [];

    return ProviderScope(
      overrides: [
        workoutDaysProvider.overrideWith(() => TestWorkoutDaysNotifier(dList)),
        workoutExercisesProvider.overrideWith(() => TestWorkoutExercisesNotifier(eList)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const WorkoutScreen(),
      ),
    );
  }

  Widget createHomeWorkoutStripWidget({
    List<WorkoutDay>? days,
    List<WorkoutExercise>? exercises,
  }) {
    final dList = days ?? [];
    final eList = exercises ?? [];

    return ProviderScope(
      overrides: [
        workoutDaysProvider.overrideWith(() => TestWorkoutDaysNotifier(dList)),
        workoutExercisesProvider.overrideWith(() => TestWorkoutExercisesNotifier(eList)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16.0),
            child: WorkoutStripSlot(),
          ),
        ),
      ),
    );
  }

  group('WorkoutScreen Layout & Split Header', () {
    testWidgets('renders 7 weekday tabs and defaults to today weekday', (tester) async {
      await tester.pumpWidget(createWorkoutScreenWidget());
      await tester.pumpAndSettle();

      // Check for all 7 weekday tabs
      for (int i = 1; i <= 7; i++) {
        expect(find.byKey(Key('workout_weekday_tab_$i')), findsOneWidget);
      }

      // Add exercise button in header
      expect(find.byKey(const Key('add_exercise_button')), findsOneWidget);

      // Verify NO FloatingActionButton
      expect(find.byType(FloatingActionButton), findsNothing);

      // Split header placeholder shown
      expect(find.text('Tap to set split (e.g. Chest & Shoulders / Rest Day)'), findsOneWidget);
    });

    testWidgets('tap split header opens EditSplitDialog and updates title', (tester) async {
      await tester.pumpWidget(createWorkoutScreenWidget());
      await tester.pumpAndSettle();

      // Tap split header
      await tester.tap(find.byKey(const Key('workout_split_header')));
      await tester.pumpAndSettle();

      // EditSplitDialog is shown
      expect(find.byType(EditSplitDialog), findsOneWidget);
      expect(find.byKey(const Key('split_title_field')), findsOneWidget);

      // Enter title and save
      await tester.enterText(find.byKey(const Key('split_title_field')), 'Push (Chest & Triceps)');
      await tester.tap(find.byKey(const Key('save_split_title_button')));
      await tester.pumpAndSettle();

      // Updated title displayed on screen
      expect(find.text('Push (Chest & Triceps)'), findsOneWidget);
    });
  });

  group('Add Exercise & Strict Isolation', () {
    testWidgets("'+ Add Exercise' opens AddExerciseSheet with ONLY name and sets/reps fields", (tester) async {
      await tester.pumpWidget(createWorkoutScreenWidget());
      await tester.pumpAndSettle();

      // Tap Add Exercise
      await tester.tap(find.byKey(const Key('add_exercise_button')));
      await tester.pumpAndSettle();

      // Verify AddExerciseSheet is displayed
      expect(find.byType(AddExerciseSheet), findsOneWidget);
      expect(find.byKey(const Key('exercise_name_field')), findsOneWidget);
      expect(find.byKey(const Key('exercise_sets_reps_field')), findsOneWidget);
      expect(find.byKey(const Key('save_exercise_button')), findsOneWidget);

      // Verify NO foreign fields (no dropdown, no radio, no checkbox, no date picker)
      expect(find.byType(DropdownButtonFormField), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.byType(Radio), findsNothing);

      // Fill in and submit
      await tester.enterText(find.byKey(const Key('exercise_name_field')), 'Incline Dumbbell Press');
      await tester.enterText(find.byKey(const Key('exercise_sets_reps_field')), '4 x 10');
      await tester.tap(find.byKey(const Key('save_exercise_button')));
      await tester.pumpAndSettle();

      // Exercise is now visible in the checklist
      expect(find.text('Incline Dumbbell Press'), findsOneWidget);
      expect(find.text('4 x 10'), findsOneWidget);
    });
  });

  group('Checklist Today-Only Toggling Rule', () {
    testWidgets('checkbox is interactive on today tab, but DISABLED on other days tab', (tester) async {
      final dayToday = WorkoutDay(
        id: 'day-today',
        userId: 'user-1',
        weekday: todayWeekday,
        splitTitle: 'Leg Day',
      );

      final dayOther = WorkoutDay(
        id: 'day-other',
        userId: 'user-1',
        weekday: otherWeekday,
        splitTitle: 'Arm Day',
      );

      final exToday = WorkoutExercise(
        id: 'ex-today-1',
        userId: 'user-1',
        workoutDayId: 'day-today',
        exerciseName: 'Barbell Squats',
        setsReps: '4 x 8',
        lastCompletedDate: null,
      );

      final exOther = WorkoutExercise(
        id: 'ex-other-1',
        userId: 'user-1',
        workoutDayId: 'day-other',
        exerciseName: 'Barbell Curls',
        setsReps: '3 x 12',
        lastCompletedDate: null,
      );

      await tester.pumpWidget(createWorkoutScreenWidget(
        days: [dayToday, dayOther],
        exercises: [exToday, exOther],
      ));
      await tester.pumpAndSettle();

      // Currently on today's tab: exToday is visible
      expect(find.text('Barbell Squats'), findsOneWidget);

      // Tap checkbox for exToday
      final todayCheckbox = find.byKey(const Key('exercise_checkbox_ex-today-1'));
      expect(todayCheckbox, findsOneWidget);

      // Verify uncompleted initially (no check icon)
      expect(find.descendant(of: todayCheckbox, matching: find.byIcon(Icons.check)), findsNothing);

      // Tap to complete
      await tester.tap(todayCheckbox);
      await tester.pumpAndSettle();

      // Now check icon appears
      expect(find.descendant(of: todayCheckbox, matching: find.byIcon(Icons.check)), findsOneWidget);

      // Switch to other weekday tab
      await tester.tap(find.byKey(Key('workout_weekday_tab_$otherWeekday')));
      await tester.pumpAndSettle();

      // Now exOther is visible
      expect(find.text('Barbell Curls'), findsOneWidget);

      // Notice for other day shown
      expect(find.textContaining('Viewing'), findsOneWidget);

      // Tap other day's checkbox: should be a NO-OP (disabled)
      final otherCheckbox = find.byKey(const Key('exercise_checkbox_ex-other-1'));
      expect(otherCheckbox, findsOneWidget);
      await tester.tap(otherCheckbox);
      await tester.pumpAndSettle();

      // Check icon does NOT appear because it cannot be marked on other days!
      expect(find.descendant(of: otherCheckbox, matching: find.byIcon(Icons.check)), findsNothing);
    });

    testWidgets('delete exercise shows confirmation dialog and removes exercise', (tester) async {
      final day = WorkoutDay(
        id: 'day-today',
        userId: 'user-1',
        weekday: todayWeekday,
        splitTitle: 'Chest Day',
      );

      final exercise = WorkoutExercise(
        id: 'ex-1',
        userId: 'user-1',
        workoutDayId: 'day-today',
        exerciseName: 'Cable Flyes',
        setsReps: '3 x 15',
      );

      await tester.pumpWidget(createWorkoutScreenWidget(
        days: [day],
        exercises: [exercise],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Cable Flyes'), findsOneWidget);

      // Tap delete
      await tester.tap(find.byKey(const Key('delete_exercise_ex-1')));
      await tester.pumpAndSettle();

      // Confirm dialog appears
      expect(find.text('Delete Exercise'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Exercise is gone
      expect(find.text('Cable Flyes'), findsNothing);
    });
  });

  group('Home WorkoutStripSlot', () {
    testWidgets('renders empty state when no workout planned', (tester) async {
      await tester.pumpWidget(createHomeWorkoutStripWidget());
      await tester.pumpAndSettle();

      expect(find.text('Today\'s Workout'), findsOneWidget);
      expect(find.text('No workout planned. Set it up in Workout.'), findsOneWidget);
    });

    testWidgets('renders split title and rest day message on rest day', (tester) async {
      final day = WorkoutDay(
        id: 'day-1',
        userId: 'user-1',
        weekday: todayWeekday,
        splitTitle: 'Rest Day',
      );

      await tester.pumpWidget(createHomeWorkoutStripWidget(days: [day]));
      await tester.pumpAndSettle();

      expect(find.text('Today: Rest Day'), findsOneWidget);
      expect(find.text('Recovery day scheduled. Enjoy your rest!'), findsOneWidget);
    });

    testWidgets('renders exercises checklist and toggles synchronously with shared provider', (tester) async {
      final day = WorkoutDay(
        id: 'day-1',
        userId: 'user-1',
        weekday: todayWeekday,
        splitTitle: 'Upper Body',
      );

      final exercise = WorkoutExercise(
        id: 'ex-1',
        userId: 'user-1',
        workoutDayId: 'day-1',
        exerciseName: 'Pull-ups',
        setsReps: '3 x max',
        lastCompletedDate: null,
      );

      await tester.pumpWidget(createHomeWorkoutStripWidget(
        days: [day],
        exercises: [exercise],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Today: Upper Body'), findsOneWidget);
      expect(find.text('Pull-ups — 3 x max'), findsOneWidget);
      expect(find.text('0 / 1 done'), findsOneWidget);

      // Tap row to toggle
      await tester.tap(find.byKey(const Key('home_workout_exercise_row_ex-1')));
      await tester.pumpAndSettle();

      // Now 1 / 1 done
      expect(find.text('1 / 1 done'), findsOneWidget);
    });
  });
}
