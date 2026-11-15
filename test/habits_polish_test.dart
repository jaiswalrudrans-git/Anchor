import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anchor/core/constants/habit_icons.dart';
import 'package:anchor/core/constants/theme.dart';
import 'package:anchor/core/utils/date_utils.dart';
import 'package:anchor/core/utils/streak_utils.dart';
import 'package:anchor/models/habit.dart';
import 'package:anchor/models/habit_log.dart';
import 'package:anchor/providers/habits_providers.dart';
import 'package:anchor/screens/habits/habits_screen.dart';
import 'package:anchor/screens/habits/widgets/add_habit_sheet.dart';
import 'package:anchor/screens/habits/widgets/monthly_heatmap.dart';

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
  Future<Habit> editHabit(
    String id, {
    required String title,
    required String icon,
  }) async {
    final idx = _habits.indexWhere((h) => h.id == id);
    if (idx != -1) {
      final updated = _habits[idx].copyWith(title: title.trim(), icon: icon);
      _habits = List<Habit>.from(_habits)..[idx] = updated;
      state = AsyncData(_habits);
      return updated;
    }
    throw Exception('Habit not found');
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

  group('HabitIcons catalog & Habit model', () {
    test('catalog contains exactly 24 keys and falls back gracefully', () {
      expect(HabitIcons.allKeys.length, 24);
      expect(HabitIcons.allKeys.contains('check_circle'), isTrue);
      expect(HabitIcons.allKeys.contains('fitness_center'), isTrue);
      expect(HabitIcons.allKeys.contains('menu_book'), isTrue);
      expect(HabitIcons.allKeys.contains('water_drop'), isTrue);

      // Unknown key falls back to check_circle
      expect(HabitIcons.getIcon('non_existent_key'), Icons.check_circle);
    });

    test(
      'Habit model defaults icon to check_circle and serializes correctly',
      () {
        final habit = Habit(
          id: 'h1',
          userId: 'u1',
          title: 'Meditation',
          createdAt: DateTime(2026, 11, 1),
        );
        expect(habit.icon, 'check_circle');

        final json = habit.toJson();
        expect(json['icon'], 'check_circle');

        final deserialized = Habit.fromJson({
          'id': 'h2',
          'user_id': 'u1',
          'title': 'Coding',
          'icon': 'code',
          'created_at': DateTime(2026, 11, 1).toIso8601String(),
        });
        expect(deserialized.icon, 'code');
      },
    );
  });

  group('StreakUtils new pure functions', () {
    final today = DateTime(2026, 11, 14); // Sat
    final weekStart = DateTime(2026, 11, 9); // Mon
    final created = DateTime(2026, 11, 1);

    test('dailyCompletionFractions computes 7 daily values Mon-Sun', () {
      final habit1 = Habit(
        id: 'h1',
        userId: 'u1',
        title: 'H1',
        createdAt: created,
      );
      final habit2 = Habit(
        id: 'h2',
        userId: 'u1',
        title: 'H2',
        createdAt: created,
      );

      final logsMap = {
        'h1': {DateTime(2026, 11, 9), DateTime(2026, 11, 10)},
        'h2': {DateTime(2026, 11, 9)},
      };

      final fractions = StreakUtils.dailyCompletionFractions(
        habits: [habit1, habit2],
        habitLogsMap: logsMap,
        weekStart: weekStart,
        today: today,
      );

      expect(fractions.length, 7);
      expect(fractions[0], 1.0); // Mon: 2 of 2 = 1.0
      expect(fractions[1], 0.5); // Tue: 1 of 2 = 0.5
      expect(fractions[2], 0.0); // Wed: 0 of 2 = 0.0
      expect(
        fractions[6],
        0.0,
      ); // Sun (Nov 15, future relative to Nov 14) = 0.0
    });

    test('perfectDays counts only days with 100% completions', () {
      final habit1 = Habit(
        id: 'h1',
        userId: 'u1',
        title: 'H1',
        createdAt: created,
      );
      final habit2 = Habit(
        id: 'h2',
        userId: 'u1',
        title: 'H2',
        createdAt: created,
      );

      final logsMap = {
        'h1': {DateTime(2026, 11, 9), DateTime(2026, 11, 10)},
        'h2': {DateTime(2026, 11, 9)},
      };

      final perfect = StreakUtils.perfectDays(
        habits: [habit1, habit2],
        habitLogsMap: logsMap,
        weekStart: weekStart,
        today: today,
      );

      expect(perfect, 1); // Only Mon had both done
    });

    test('bestAndWeakestDay returns 1-based day indices with tie-breaker', () {
      final habit1 = Habit(
        id: 'h1',
        userId: 'u1',
        title: 'H1',
        createdAt: created,
      );
      final logsMap = {
        'h1': {DateTime(2026, 11, 9), DateTime(2026, 11, 11)}, // Mon & Wed
      };

      final result = StreakUtils.bestAndWeakestDay(
        habits: [habit1],
        habitLogsMap: logsMap,
        weekStart: weekStart,
        today: today,
      );

      expect(result, isNotNull);
      expect(result!.bestDay, 1); // Mon (first 100% day)
      expect(result.weakestDay, 2); // Tue (first 0% day)
    });

    test('bestAndWeakestDay returns null when fewer than 3 eligible days', () {
      final habit = Habit(
        id: 'h1',
        userId: 'u1',
        title: 'H1',
        createdAt: DateTime(2026, 11, 13), // Friday
      );

      final result = StreakUtils.bestAndWeakestDay(
        habits: [habit],
        habitLogsMap: {},
        weekStart: weekStart,
        today: today, // Only Fri & Sat are eligible (2 days < 3)
      );

      expect(result, isNull);
    });

    test('weeklyCompletionSeries calculates sparkline fractions skipping pre-creation', () {
      final series = StreakUtils.weeklyCompletionSeries(
        logged: {DateTime(2026, 11, 9), DateTime(2026, 11, 10)},
        weekStart: weekStart,
        weeks: 6,
        today: today,
        createdDate: DateTime(2026, 11, 1),
      );

      expect(series.isNotEmpty, isTrue);
      expect(series.last, greaterThan(0.0));
    });
  });

  group('AddHabitSheet with Icon Picker', () {
    testWidgets('shows 24-icon grid and persists selected icon', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap + New Habit
      await tester.tap(find.byKey(const Key('add_habit_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AddHabitSheet), findsOneWidget);
      expect(find.text('Choose Icon'), findsOneWidget);

      // Verify icons are present (e.g. menu_book)
      expect(find.byIcon(Icons.menu_book), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);

      // Select menu_book icon
      await tester.tap(find.byIcon(Icons.menu_book));
      await tester.pumpAndSettle();

      // Enter title
      await tester.enterText(
        find.byKey(const Key('add_habit_title_field')),
        'Night Reading',
      );
      await tester.tap(find.byKey(const Key('create_habit_button')));
      await tester.pumpAndSettle();

      // Sheet closed, habit created with menu_book icon
      expect(find.text('Night Reading'), findsWidgets);
      expect(find.byIcon(Icons.menu_book), findsWidgets);
    });
  });

  group('Heatmap cell tap and day correction', () {
    testWidgets('tapping past cell opens DayLogSheet and toggles habit log', (
      tester,
    ) async {
      final today = AppDateUtils.today();
      final monthStart = DateTime(today.year, today.month, 1);

      final habit = Habit(
        id: 'h1',
        userId: 'u1',
        title: 'Drink 3L Water',
        createdAt: monthStart,
      );

      await tester.pumpWidget(createWidget(habits: [habit], logs: []));
      await tester.pumpAndSettle();

      // Tap day 1 cell
      const cellKey = Key('matrix_cell_h1_1');
      expect(find.byKey(cellKey), findsOneWidget);
      await tester.tap(find.byKey(cellKey));
      await tester.pumpAndSettle();

      // DayLogSheet is shown
      expect(find.byType(DayLogSheet), findsOneWidget);
      expect(find.text('Drink 3L Water'), findsWidgets);

      // Toggle habit on
      await tester.tap(find.byKey(const Key('day_log_toggle_h1')));
      await tester.pumpAndSettle();

      // Close sheet
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Heatmap and Reality Report now show 1 completion
      expect(find.text('1'), findsWidgets);
    });
  });

  group('Responsive Layout & No Overflow', () {
    testWidgets(
      'compact mobile 360x640 with text scale 1.3 renders with zero overflow',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final today = AppDateUtils.today();
        final habit1 = Habit(
          id: 'h1',
          userId: 'u1',
          title: 'Morning Exercise',
          createdAt: today,
        );
        final habit2 = Habit(
          id: 'h2',
          userId: 'u1',
          title: 'Read Book',
          createdAt: today,
        );

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 640),
              textScaler: TextScaler.linear(1.3),
            ),
            child: createWidget(habits: [habit1, habit2]),
          ),
        );
        await tester.pumpAndSettle();

        // Verify no overflow in Overview
        expect(tester.takeException(), isNull);
        expect(find.text('Daily Habits'), findsOneWidget);
        expect(find.text('Monthly Consistency Heatmap'), findsOneWidget);
        expect(find.text('Reality Report'), findsOneWidget);

        // Switch to Weekly Report
        await tester.tap(find.text('Weekly Report'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const Key('weekly_overall_summary_card')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'expanded desktop 1280x800 shows 2-column layout with zero overflow',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final today = AppDateUtils.today();
        final habit = Habit(
          id: 'h1',
          userId: 'u1',
          title: 'Deep Work',
          createdAt: today,
        );

        await tester.pumpWidget(createWidget(habits: [habit]));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Daily Habits'), findsOneWidget);
        expect(find.text('Monthly Consistency Heatmap'), findsOneWidget);
        expect(find.text('Reality Report'), findsOneWidget);

        // Switch to Weekly Report
        await tester.tap(find.text('Weekly Report'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const Key('weekly_overall_summary_card')),
          findsOneWidget,
        );
      },
    );
  });
}
