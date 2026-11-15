import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anchor/core/constants/theme.dart';
import 'package:anchor/core/utils/date_utils.dart';
import 'package:anchor/models/idle_prompt.dart';
import 'package:anchor/models/todo.dart';
import 'package:anchor/providers/home_providers.dart';
import 'package:anchor/screens/home/home_screen.dart';
import 'package:anchor/screens/home/widgets/academic_radar_slot.dart';

class TestTodosNotifier extends TodosNotifier {
  final List<Todo> _initial;
  TestTodosNotifier(this._initial);

  @override
  Future<List<Todo>> build() async => _initial;

  @override
  Future<Todo?> addTodo(String title, DateTime date) async {
    final item = Todo(
      id: 'test-${DateTime.now().millisecondsSinceEpoch}',
      userId: 'test-user',
      title: title,
      scheduledDate: AppDateUtils.dateOnly(date),
      isCompleted: false,
      rolloverCount: 0,
      createdAt: DateTime.now(),
    );
    final prev = state.value ?? [];
    state = AsyncData([...prev, item]);
    return item;
  }

  @override
  Future<void> toggleComplete(String id) async {
    final prev = state.value ?? [];
    final updated = prev
        .map((t) => t.id == id ? t.copyWith(isCompleted: !t.isCompleted) : t)
        .toList();
    state = AsyncData(updated);
  }

  @override
  Future<void> refreshTodos() async {
    // No-op for test
  }
}

class TestIdlePromptsNotifier extends IdlePromptsNotifier {
  @override
  Future<List<IdlePrompt>> build() async => [
    IdlePrompt(
      id: '1',
      userId: 'test-user',
      promptText: 'Solve 1 DSA problem right now',
      createdAt: DateTime.now(),
    ),
  ];
}

void main() {
  group('HomeScreen & Kill Idle Time Widget Tests', () {
    testWidgets(
      'Kill Idle button is hidden when tasks are pending; shows status message',
      (tester) async {
        final pendingTask = Todo(
          id: 'todo-1',
          userId: 'test-user',
          title: 'Complete Stage 2',
          scheduledDate: AppDateUtils.today(),
          isCompleted: false,
          rolloverCount: 0,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              todosProvider.overrideWith(
                () => TestTodosNotifier([pendingTask]),
              ),
              idlePromptsProvider.overrideWith(() => TestIdlePromptsNotifier()),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Kill Idle Time button must NOT be present
        expect(find.byKey(const Key('kill_idle_time_button')), findsNothing);

        // Status text must be visible
        expect(
          find.byKey(const Key('kill_idle_locked_status')),
          findsOneWidget,
        );
        expect(
          find.text('1 task left today. Finish them to unlock Kill Idle Time.'),
          findsOneWidget,
        );

        // Task row must be visible
        expect(find.text('Complete Stage 2'), findsOneWidget);

        // Academic radar slot exists and workout strip does not
        expect(find.byType(AcademicRadarSlot), findsOneWidget);
        expect(find.text('Workout'), findsNothing);
      },
    );

    testWidgets(
      'Checking the last pending task unlocks Kill Idle Time button instantly',
      (tester) async {
        final pendingTask = Todo(
          id: 'todo-1',
          userId: 'test-user',
          title: 'Only task for today',
          scheduledDate: AppDateUtils.today(),
          isCompleted: false,
          rolloverCount: 0,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              todosProvider.overrideWith(
                () => TestTodosNotifier([pendingTask]),
              ),
              idlePromptsProvider.overrideWith(() => TestIdlePromptsNotifier()),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Initially locked
        expect(find.byKey(const Key('kill_idle_time_button')), findsNothing);

        // Check the checkbox to complete the task
        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();

        // Now Kill Idle Time button must be unlocked and prominent
        expect(find.byKey(const Key('kill_idle_time_button')), findsOneWidget);
        expect(find.byKey(const Key('kill_idle_locked_status')), findsNothing);
      },
    );

    testWidgets(
      'Home has exactly one inline task input and no duplicate Add Task button',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              todosProvider.overrideWith(() => TestTodosNotifier([])),
              idlePromptsProvider.overrideWith(() => TestIdlePromptsNotifier()),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Duplicate add controls are removed
        expect(
          find.byKey(const Key('home_add_todo_action_button')),
          findsNothing,
        );
        expect(find.byType(FloatingActionButton), findsNothing);

        // Exactly one inline task input on Today's Tasks card
        expect(find.byKey(const Key('home_quick_add_input')), findsOneWidget);
        expect(find.byKey(const Key('home_quick_add_button')), findsOneWidget);

        // Add a task via the inline input
        await tester.enterText(
          find.byKey(const Key('home_quick_add_input')),
          'New Task from Inline',
        );
        await tester.tap(find.byKey(const Key('home_quick_add_button')));
        await tester.pumpAndSettle();

        expect(find.text('New Task from Inline'), findsOneWidget);
      },
    );
  });
}
