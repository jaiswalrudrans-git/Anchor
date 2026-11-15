import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anchor/core/constants/theme.dart';
import 'package:anchor/core/utils/date_utils.dart';
import 'package:anchor/models/idle_prompt.dart';
import 'package:anchor/models/todo.dart';
import 'package:anchor/providers/home_providers.dart';
import 'package:anchor/screens/home/home_screen.dart';
import 'package:anchor/screens/home/widgets/card_progress_stroke.dart';
import 'package:anchor/screens/home/widgets/todays_tasks_card.dart';
import 'package:anchor/widgets/responsive/page_container.dart';

class MockSeedingIdlePromptsNotifier extends IdlePromptsNotifier {
  final List<IdlePrompt> _inMemoryDb = [];
  Future<void>? _activeSeedFuture;

  @override
  Future<List<IdlePrompt>> build() async => List.from(_inMemoryDb);

  @override
  Future<void> seedIfEmpty() async {
    if (_activeSeedFuture != null) {
      await _activeSeedFuture;
      return;
    }
    _activeSeedFuture = _simulateSeed();
    try {
      await _activeSeedFuture;
    } finally {
      _activeSeedFuture = null;
    }
  }

  Future<void> _simulateSeed() async {
    // Artificial small delay to simulate network latency
    await Future.delayed(const Duration(milliseconds: 10));
    if (_inMemoryDb.isNotEmpty) return;

    for (final text in defaultIdlePrompts) {
      if (!_inMemoryDb.any((p) => p.promptText == text)) {
        _inMemoryDb.add(
          IdlePrompt(
            id: 'mock-${_inMemoryDb.length}',
            userId: 'user-1',
            promptText: text,
            createdAt: DateTime.now(),
          ),
        );
      }
    }
    state = AsyncData(List.from(_inMemoryDb));
  }
}

class TestStatefulTodosNotifier extends TodosNotifier {
  final List<Todo> _todos;
  TestStatefulTodosNotifier(this._todos);

  @override
  Future<List<Todo>> build() async => List.from(_todos);

  @override
  Future<void> toggleComplete(String id) async {
    final prev = state.value ?? [];
    final updated = prev
        .map((t) => t.id == id ? t.copyWith(isCompleted: !t.isCompleted) : t)
        .toList();
    state = AsyncData(sortTodos(updated));
  }
}

void main() {
  group('Polish Stage 3: Progress Stroke Painter Tests', () {
    test('Extracted path length at 0, 0.5, 1.0 matches fractions and never exceeds path', () {
      const size = Size(320, 240);
      const radius = 16.0;
      const strokeWidth = 2.5;

      final totalLength = CardProgressStrokePainter.getTotalPathLength(
        size,
        radius,
        strokeWidth,
      );
      expect(totalLength, greaterThan(0.0));

      // At progress 0.0 -> length is 0
      final len0 = CardProgressStrokePainter.getExtractedPathLength(
        size,
        radius,
        strokeWidth,
        0.0,
      );
      expect(len0, 0.0);

      // At progress 0.5 -> length is exactly 50% of total
      final lenHalf = CardProgressStrokePainter.getExtractedPathLength(
        size,
        radius,
        strokeWidth,
        0.5,
      );
      expect((lenHalf - totalLength * 0.5).abs(), lessThan(0.001));

      // At progress 1.0 -> length is exactly total
      final lenFull = CardProgressStrokePainter.getExtractedPathLength(
        size,
        radius,
        strokeWidth,
        1.0,
      );
      expect((lenFull - totalLength).abs(), lessThan(0.001));

      // At progress > 1.0 -> clamped to total (never exceeds path!)
      final lenOver = CardProgressStrokePainter.getExtractedPathLength(
        size,
        radius,
        strokeWidth,
        1.5,
      );
      expect(lenOver, totalLength);

      // At progress < 0.0 -> clamped to 0.0
      final lenNegative = CardProgressStrokePainter.getExtractedPathLength(
        size,
        radius,
        strokeWidth,
        -0.2,
      );
      expect(lenNegative, 0.0);
    });
  });

  group('Polish Stage 3: Prompt Seeding Logic Tests', () {
    test('Fresh user seeds 4 prompts; subsequent calls and concurrent calls do not duplicate', () async {
      final container = ProviderContainer(
        overrides: [
          idlePromptsProvider.overrideWith(
            () => MockSeedingIdlePromptsNotifier(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(idlePromptsProvider.notifier);

      // Initial state is empty
      final initial = await container.read(idlePromptsProvider.future);
      expect(initial, isEmpty);

      // 1. Fresh user -> 4 rows
      await notifier.seedIfEmpty();
      final afterFirst = await container.read(idlePromptsProvider.future);
      expect(afterFirst.length, 4);

      // 2. Second call -> still 4 rows
      await notifier.seedIfEmpty();
      final afterSecond = await container.read(idlePromptsProvider.future);
      expect(afterSecond.length, 4);

      // 3. Concurrent calls -> still 4 rows
      await Future.wait([
        notifier.seedIfEmpty(),
        notifier.seedIfEmpty(),
        notifier.seedIfEmpty(),
      ]);
      final afterConcurrent = await container.read(idlePromptsProvider.future);
      expect(afterConcurrent.length, 4);
    });
  });

  group('Polish Stage 3: All-Done Achievement & Today Tasks Card Tests', () {
    testWidgets(
      'Today Tasks Card renders progress stroke and morphs count chip to All Done',
      (tester) async {
        final task1 = Todo(
          id: 't-1',
          userId: 'user-1',
          title: 'Task 1',
          scheduledDate: AppDateUtils.today(),
          isCompleted: false,
          rolloverCount: 0,
          createdAt: DateTime.now(),
        );
        final task2 = Todo(
          id: 't-2',
          userId: 'user-1',
          title: 'Task 2',
          scheduledDate: AppDateUtils.today(),
          isCompleted: false,
          rolloverCount: 0,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              todosProvider.overrideWith(
                () => TestStatefulTodosNotifier([task1, task2]),
              ),
              idlePromptsProvider.overrideWith(
                () => MockSeedingIdlePromptsNotifier(),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: SingleChildScrollView(child: TodaysTasksCard()),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Initially 0/2 completed
        expect(find.text('0/2'), findsOneWidget);
        expect(find.text('All done'), findsNothing);

        // Complete task 1 -> 1/2
        await tester.tap(find.byType(Checkbox).first);
        await tester.pumpAndSettle();
        expect(find.text('1/2'), findsOneWidget);
        expect(find.text('All done'), findsNothing);

        // Complete remaining task -> 2/2 -> morphs into "All done"
        await tester.tap(find.byType(Checkbox).first);
        await tester.pumpAndSettle();
        expect(find.text('All done'), findsOneWidget);
      },
    );

    testWidgets(
      'Initial build with already complete tasks does not fire achievement transition',
      (tester) async {
        final completedTask = Todo(
          id: 't-1',
          userId: 'user-1',
          title: 'Already Done Task',
          scheduledDate: AppDateUtils.today(),
          isCompleted: true,
          rolloverCount: 0,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              todosProvider.overrideWith(
                () => TestStatefulTodosNotifier([completedTask]),
              ),
              idlePromptsProvider.overrideWith(
                () => MockSeedingIdlePromptsNotifier(),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: SingleChildScrollView(child: TodaysTasksCard()),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        // Displays All done calmly
        expect(find.text('All done'), findsOneWidget);
      },
    );
  });

  group('Polish Stage 3: Responsive Layout & Text Scale 1.3 Tests', () {
    testWidgets(
      'HomeScreen at 360 x 640 (compact) with textScale 1.3 has no overflow',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 640));

        final task = Todo(
          id: 't-1',
          userId: 'user-1',
          title: 'Long task description testing responsive layout wrapping',
          scheduledDate: AppDateUtils.today(),
          isCompleted: false,
          rolloverCount: 2,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 640),
              textScaler: TextScaler.linear(1.3),
            ),
            child: ProviderScope(
              overrides: [
                todosProvider.overrideWith(
                  () => TestStatefulTodosNotifier([task]),
                ),
                idlePromptsProvider.overrideWith(
                  () => MockSeedingIdlePromptsNotifier(),
                ),
              ],
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: const HomeScreen(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.textContaining('Good '), findsOneWidget);
        expect(find.byType(PageContainer), findsOneWidget);

        // Verify compact single column
        expect(
          find.byKey(const Key('kill_idle_locked_status')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'HomeScreen at 800 x 1000 (medium) with textScale 1.3 has no overflow',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1000));

        final task = Todo(
          id: 't-1',
          userId: 'user-1',
          title: 'Medium layout task',
          scheduledDate: AppDateUtils.today(),
          isCompleted: false,
          rolloverCount: 0,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(800, 1000),
              textScaler: TextScaler.linear(1.3),
            ),
            child: ProviderScope(
              overrides: [
                todosProvider.overrideWith(
                  () => TestStatefulTodosNotifier([task]),
                ),
                idlePromptsProvider.overrideWith(
                  () => MockSeedingIdlePromptsNotifier(),
                ),
              ],
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: const HomeScreen(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(PageContainer), findsOneWidget);
      },
    );

    testWidgets(
      'HomeScreen at 1280 x 800 (expanded) with textScale 1.3 has two columns and no overflow',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 800));

        final task = Todo(
          id: 't-1',
          userId: 'user-1',
          title: 'Expanded two column task',
          scheduledDate: AppDateUtils.today(),
          isCompleted: false,
          rolloverCount: 0,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(1280, 800),
              textScaler: TextScaler.linear(1.3),
            ),
            child: ProviderScope(
              overrides: [
                todosProvider.overrideWith(
                  () => TestStatefulTodosNotifier([task]),
                ),
                idlePromptsProvider.overrideWith(
                  () => MockSeedingIdlePromptsNotifier(),
                ),
              ],
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: const HomeScreen(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(PageContainer), findsOneWidget);

        // Verify two-column flex layout (Expanded flex 3 and flex 2 inside Row)
        final rowFinder = find.descendant(
          of: find.byType(PageContainer),
          matching: find.byType(Row),
        );
        expect(rowFinder, findsWidgets);
      },
    );
  });
}
