import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anchor/core/constants/theme.dart';
import 'package:anchor/core/utils/date_utils.dart';
import 'package:anchor/models/habit.dart';
import 'package:anchor/models/habit_log.dart';
import 'package:anchor/providers/habits_providers.dart';
import 'package:anchor/screens/habits/habits_screen.dart';
import 'package:anchor/screens/habits/widgets/add_habit_sheet.dart';

class TestHabitsNotifier extends HabitsNotifier {
  List<Habit> _habits;
  TestHabitsNotifier(this._habits);

  @override
  Future<List<Habit>> build() async => _habits;

  @override
  Future<void> refresh() async {
    state = AsyncData(_habits);
  }

  @override
  Future<Habit> createHabit(
    String title, {
    String icon = 'check_circle',
  }) async {
    final newHabit = Habit(
      id: 'habit-${_habits.length + 1}',
      userId: 'user-1',
      title: title.trim(),
      icon: icon,
      createdAt: DateTime.now(),
    );
    _habits = [..._habits, newHabit];
    state = AsyncData(_habits);
    return newHabit;
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    _habits = _habits.where((h) => h.id != habitId).toList();
    state = AsyncData(_habits);
    ref.read(habitLogsProvider.notifier).removeLogsForHabit(habitId);
  }
}

class TestHabitLogsNotifier extends HabitLogsNotifier {
  List<HabitLog> _logs;
  TestHabitLogsNotifier(this._logs);

  @override
  Future<List<HabitLog>> build() async => _logs;

  @override
  Future<void> refresh() async {
    state = AsyncData(_logs);
  }

  @override
  void removeLogsForHabit(String habitId) {
    _logs = _logs.where((l) => l.habitId != habitId).toList();
    state = AsyncData(_logs);
  }

  @override
  Future<void> toggleToday(String habitId) async {
    await toggleDate(habitId, AppDateUtils.today());
  }

  @override
  Future<void> toggleDate(String habitId, DateTime date) async {
    final dDate = AppDateUtils.dateOnly(date);
    final dToday = AppDateUtils.today();
    if (dDate.isAfter(dToday)) return;

    final existingIndex = _logs.indexWhere(
      (l) => l.habitId == habitId && AppDateUtils.dateOnly(l.logDate) == dDate,
    );

    if (existingIndex != -1) {
      _logs = List<HabitLog>.from(_logs)..removeAt(existingIndex);
    } else {
      final newLog = HabitLog(
        id: 'log-${_logs.length + 1}',
        userId: 'user-1',
        habitId: habitId,
        logDate: dDate,
      );
      _logs = List<HabitLog>.from(_logs)..add(newLog);
    }
    state = AsyncData(_logs);
  }
}

void main() {
  Widget createWidget({List<Habit>? habits, List<HabitLog>? logs}) {
    final hList = habits ?? [];
    final lList = logs ?? [];

    return ProviderScope(
      overrides: [
        habitsProvider.overrideWith(() => TestHabitsNotifier(hList)),
        habitLogsProvider.overrideWith(() => TestHabitLogsNotifier(lList)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const HabitsScreen(),
      ),
    );
  }

  group('HabitsScreen Layout and Controls', () {
    testWidgets(
      'renders Overview and Weekly Report segmented tabs and New Habit button, ZERO FAB',
      (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Top segmented toggle
        expect(find.text('Overview'), findsOneWidget);
        expect(find.text('Weekly Report'), findsOneWidget);

        // Sole add control: New Habit
        expect(find.byKey(const Key('add_habit_button')), findsOneWidget);

        // Verify ZERO FloatingActionButton
        expect(find.byType(FloatingActionButton), findsNothing);

        // Empty state initially
        expect(find.text('No habits yet'), findsOneWidget);
      },
    );

    testWidgets(
      "'+ New Habit' opens AddHabitSheet with ONLY the habit title field",
      (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Tap + New Habit
        await tester.tap(find.byKey(const Key('add_habit_button')));
        await tester.pumpAndSettle();

        // Verify AddHabitSheet is shown
        expect(find.byType(AddHabitSheet), findsOneWidget);
        expect(find.byKey(const Key('add_habit_title_field')), findsOneWidget);
        expect(find.byKey(const Key('create_habit_button')), findsOneWidget);

        // Verify NO other inputs exist (no category dropdown, no amount field, no dates, etc.)
        expect(find.byType(DropdownButtonFormField), findsNothing);
        expect(find.byType(Radio), findsNothing);
        expect(find.byType(Checkbox), findsNothing);

        // Enter title and submit
        await tester.enterText(
          find.byKey(const Key('add_habit_title_field')),
          'Morning Run',
        );
        await tester.tap(find.byKey(const Key('create_habit_button')));
        await tester.pumpAndSettle();

        // Form closed and habit now displayed (both in row and matrix)
        expect(find.text('Morning Run'), findsWidgets);
        expect(find.text('0d streak'), findsOneWidget);
      },
    );
  });

  group('Daily Habit Rows & Today Toggle', () {
    testWidgets(
      'one-tap today toggle inserts log and updates streak immediately',
      (tester) async {
        final today = AppDateUtils.today();
        final yesterday = today.subtract(const Duration(days: 1));

        final habit = Habit(
          id: 'h1',
          userId: 'user-1',
          title: 'Read 20 pages',
          createdAt: today.subtract(const Duration(days: 5)),
        );

        // Yesterday was logged (so unlogged today still holds 1d streak)
        final logYesterday = HabitLog(
          id: 'l1',
          userId: 'user-1',
          habitId: 'h1',
          logDate: yesterday,
        );

        await tester.pumpWidget(
          createWidget(habits: [habit], logs: [logYesterday]),
        );
        await tester.pumpAndSettle();

        // Habit row displayed with 1d streak (appears in habit row and matrix)
        expect(find.text('Read 20 pages'), findsWidgets);
        expect(find.text('1d streak'), findsOneWidget);

        // Tap today toggle
        await tester.tap(find.byKey(const Key('habit_today_toggle_h1')));
        await tester.pumpAndSettle();

        // Streak immediately becomes 2d
        expect(find.text('2d streak'), findsOneWidget);

        // Tap again to toggle off
        await tester.tap(find.byKey(const Key('habit_today_toggle_h1')));
        await tester.pumpAndSettle();

        // Reverts back to 1d streak
        expect(find.text('1d streak'), findsOneWidget);
      },
    );

    testWidgets('delete habit shows confirmation dialog and removes habit', (
      tester,
    ) async {
      final habit = Habit(
        id: 'h1',
        userId: 'user-1',
        title: 'Cold Shower',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createWidget(habits: [habit]));
      await tester.pumpAndSettle();

      expect(find.text('Cold Shower'), findsWidgets);

      // Tap delete icon
      await tester.tap(find.byKey(const Key('delete_habit_h1')));
      await tester.pumpAndSettle();

      // Confirm dialog appears
      expect(find.text('Delete Habit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Confirm delete
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Habit is gone and empty state returns
      expect(find.text('Cold Shower'), findsNothing);
      expect(find.text('No habits yet'), findsOneWidget);
    });
  });

  group('Monthly Reality Report Card & Matrix Grid', () {
    testWidgets('displays Reality Report figures and Matrix cells', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final today = AppDateUtils.today();
      final monthStart = DateTime(today.year, today.month, 1);

      final habit = Habit(
        id: 'h1',
        userId: 'user-1',
        title: 'Meditation',
        createdAt: monthStart,
      );

      // Logged on day 1 and day 2
      final l1 = HabitLog(
        id: 'l1',
        userId: 'user-1',
        habitId: 'h1',
        logDate: monthStart,
      );
      final l2 = HabitLog(
        id: 'l2',
        userId: 'user-1',
        habitId: 'h1',
        logDate: monthStart.add(const Duration(days: 1)),
      );

      await tester.pumpWidget(createWidget(habits: [habit], logs: [l1, l2]));
      await tester.pumpAndSettle();

      // Verify Reality Report Card title
      expect(find.text('Reality Report'), findsOneWidget);
      expect(
        find.byKey(const Key('reality_metric_completions')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('reality_metric_streak_breaks')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('reality_metric_rebounds')), findsOneWidget);

      // Verify Heatmap title
      expect(find.text('Monthly Consistency Heatmap'), findsOneWidget);

      // Tapping a past cell opens DayLogSheet, where toggling un-logs it
      const cellKey = Key('matrix_cell_h1_1'); // Day 1
      expect(find.byKey(cellKey), findsOneWidget);

      // Tap cell to open day log sheet
      await tester.tap(find.byKey(cellKey));
      await tester.pumpAndSettle();

      // Tap habit toggle in DayLogSheet
      expect(find.byKey(const Key('day_log_toggle_h1')), findsOneWidget);
      await tester.tap(find.byKey(const Key('day_log_toggle_h1')));
      await tester.pumpAndSettle();

      // Completions should now be 1
      expect(find.text('1'), findsWidgets);
    });
  });

  group('Weekly Report Tab', () {
    testWidgets(
      'navigates to Weekly Report tab, shows per-habit stats and 7-cell strip',
      (tester) async {
        final today = AppDateUtils.today();
        final habit = Habit(
          id: 'h1',
          userId: 'user-1',
          title: 'Journaling',
          createdAt: today.subtract(const Duration(days: 14)),
        );

        await tester.pumpWidget(createWidget(habits: [habit]));
        await tester.pumpAndSettle();

        // Switch to Weekly Report
        await tester.tap(find.text('Weekly Report'));
        await tester.pumpAndSettle();

        // Per-habit card visible
        expect(find.byKey(const Key('weekly_habit_card_h1')), findsOneWidget);
        expect(find.text('Journaling'), findsOneWidget);

        // 7-cell strip visible
        expect(find.byKey(const Key('weekly_strip_cell_h1_0')), findsOneWidget);
        expect(find.byKey(const Key('weekly_strip_cell_h1_6')), findsOneWidget);

        // Overall weekly summary visible
        expect(
          find.byKey(const Key('weekly_overall_summary_card')),
          findsOneWidget,
        );

        // Next week button is disabled at current week
        final nextButton = tester.widget<IconButton>(
          find.byKey(const Key('weekly_next_week_button')),
        );
        expect(nextButton.onPressed, isNull);

        // Can navigate to previous week
        await tester.tap(find.byKey(const Key('weekly_prev_week_button')));
        await tester.pumpAndSettle();

        // Now next week button is enabled
        final nextButtonAfterPrev = tester.widget<IconButton>(
          find.byKey(const Key('weekly_next_week_button')),
        );
        expect(nextButtonAfterPrev.onPressed, isNotNull);
      },
    );
  });
}
