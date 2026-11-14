import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anchor/core/constants/theme.dart';
import 'package:anchor/core/utils/date_utils.dart';
import 'package:anchor/models/academic_item.dart';
import 'package:anchor/models/expense_month_summary.dart';
import 'package:anchor/models/expense_settings.dart';
import 'package:anchor/models/expense_transaction.dart';
import 'package:anchor/models/habit.dart';
import 'package:anchor/models/habit_log.dart';
import 'package:anchor/models/subject.dart';
import 'package:anchor/models/todo.dart';
import 'package:anchor/providers/academics_providers.dart';
import 'package:anchor/providers/expenses_providers.dart';
import 'package:anchor/providers/habits_providers.dart';
import 'package:anchor/providers/home_providers.dart';
import 'package:anchor/screens/main_shell.dart';
import 'package:anchor/widgets/quick_add/quick_add_sheet.dart';

// Test Notifiers
class CustomNavIndexNotifier extends MainNavIndexNotifier {
  final int initial;
  CustomNavIndexNotifier(this.initial);
  @override
  int build() => initial;
}

class CustomSegmentNotifier extends AcademicsActiveSegmentNotifier {
  final AcademicsSegment initial;
  CustomSegmentNotifier(this.initial);
  @override
  AcademicsSegment build() => initial;
}

class TestTodosNotifier extends TodosNotifier {
  final List<Todo> todos;
  TestTodosNotifier(this.todos);

  @override
  Future<List<Todo>> build() async => todos;

  @override
  Future<Todo?> addTodo(String title, DateTime date) async {
    final item = Todo(
      id: 'todo-${DateTime.now().millisecondsSinceEpoch}',
      userId: 'test-user',
      title: title,
      scheduledDate: AppDateUtils.dateOnly(date),
      isCompleted: false,
      rolloverCount: 0,
      createdAt: DateTime.now(),
    );
    todos.add(item);
    state = AsyncData(List.from(todos));
    return item;
  }

  @override
  Future<void> delete(String id) async {
    todos.removeWhere((t) => t.id == id);
    state = AsyncData(List.from(todos));
  }

  @override
  Future<void> refreshTodos() async {
    state = AsyncData(List.from(todos));
  }
}

class TestAcademicItemsNotifier extends AcademicItemsNotifier {
  final List<AcademicItem> items;
  TestAcademicItemsNotifier(this.items);

  @override
  Future<List<AcademicItem>> build() async => items;

  @override
  Future<AcademicItem?> addItem({
    required String title,
    required String itemType,
    required DateTime dueDate,
    String? subjectId,
  }) async {
    final item = AcademicItem(
      id: 'item-${DateTime.now().millisecondsSinceEpoch}',
      userId: 'test-user',
      title: title,
      itemType: itemType,
      dueDate: AppDateUtils.dateOnly(dueDate),
      subjectId: subjectId,
      isCompleted: false,
      createdAt: DateTime.now(),
    );
    items.add(item);
    state = AsyncData(List.from(items));
    return item;
  }

  @override
  Future<void> deleteItem(String id) async {
    items.removeWhere((i) => i.id == id);
    state = AsyncData(List.from(items));
  }

  @override
  Future<void> refresh() async {
    state = AsyncData(List.from(items));
  }
}

class TestSubjectsNotifier extends SubjectsNotifier {
  final List<Subject> subjects;
  TestSubjectsNotifier(this.subjects);

  @override
  Future<List<Subject>> build() async => subjects;
}

class TestAllTransactionsNotifier extends AllTransactionsNotifier {
  final List<ExpenseTransaction> txs;
  TestAllTransactionsNotifier(this.txs);

  @override
  Future<List<ExpenseTransaction>> build() async => txs;

  @override
  Future<ExpenseTransaction> logTransaction({
    required double amount,
    required String title,
    required String category,
    required String txType,
  }) async {
    final tx = ExpenseTransaction(
      id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
      userId: 'test-user',
      amount: amount,
      title: title,
      category: category,
      txType: txType,
      txDate: DateTime.now(),
    );
    txs.insert(0, tx);
    state = AsyncData(List.from(txs));
    return tx;
  }

  @override
  Future<void> deleteTransaction(ExpenseTransaction tx) async {
    txs.removeWhere((t) => t.id == tx.id);
    state = AsyncData(List.from(txs));
  }

  @override
  Future<void> refresh() async {
    state = AsyncData(List.from(txs));
  }
}

class TestMonthSummariesNotifier extends MonthSummariesNotifier {
  final List<ExpenseMonthSummary> summaries;
  TestMonthSummariesNotifier(this.summaries);

  @override
  Future<List<ExpenseMonthSummary>> build() async => summaries;

  @override
  Future<void> refresh() async {
    state = AsyncData(List.from(summaries));
  }
}

class TestExpenseSettingsNotifier extends ExpenseSettingsNotifier {
  final ExpenseSettings settings;
  TestExpenseSettingsNotifier(this.settings);

  @override
  Future<ExpenseSettings?> build() async => settings;

  @override
  Future<void> refreshSettings() async {
    state = AsyncData(settings);
  }
}

class TestHabitsNotifier extends HabitsNotifier {
  final List<Habit> habits;
  TestHabitsNotifier(this.habits);

  @override
  Future<List<Habit>> build() async => habits;
}

class TestHabitLogsNotifier extends HabitLogsNotifier {
  final List<HabitLog> logs;
  TestHabitLogsNotifier(this.logs);

  @override
  Future<List<HabitLog>> build() async => logs;

  @override
  Future<void> toggleToday(String habitId) async {
    final today = AppDateUtils.today();
    final idx = logs.indexWhere((l) =>
        l.habitId == habitId && AppDateUtils.dateOnly(l.logDate) == today);
    if (idx >= 0) {
      logs.removeAt(idx);
    } else {
      logs.add(HabitLog(
        id: 'log-${DateTime.now().millisecondsSinceEpoch}',
        userId: 'test-user',
        habitId: habitId,
        logDate: today,
      ));
    }
    state = AsyncData(List.from(logs));
  }

  @override
  Future<void> refresh() async {
    state = AsyncData(List.from(logs));
  }
}

void main() {
  group('1. quickAddContextProvider Smart Default Mapping', () {
    test('Maps Home (0) to To-do', () {
      final container = ProviderContainer(
        overrides: [
          mainNavIndexProvider.overrideWith(() => CustomNavIndexNotifier(0)),
        ],
      );
      expect(container.read(quickAddContextProvider), QuickAddType.todo);
    });

    test('Maps Academics (1) Syllabus / Assignments segment to Assignment', () {
      final container = ProviderContainer(
        overrides: [
          mainNavIndexProvider.overrideWith(() => CustomNavIndexNotifier(1)),
          academicsActiveSegmentProvider.overrideWith(
            () => CustomSegmentNotifier(AcademicsSegment.assignments),
          ),
        ],
      );
      expect(container.read(quickAddContextProvider), QuickAddType.assignment);
    });

    test('Maps Academics (1) Exams segment to Exam', () {
      final container = ProviderContainer(
        overrides: [
          mainNavIndexProvider.overrideWith(() => CustomNavIndexNotifier(1)),
          academicsActiveSegmentProvider.overrideWith(
            () => CustomSegmentNotifier(AcademicsSegment.exams),
          ),
        ],
      );
      expect(container.read(quickAddContextProvider), QuickAddType.exam);
    });

    test('Maps Expenses (2) to Expense', () {
      final container = ProviderContainer(
        overrides: [
          mainNavIndexProvider.overrideWith(() => CustomNavIndexNotifier(2)),
        ],
      );
      expect(container.read(quickAddContextProvider), QuickAddType.expense);
    });

    test('Maps Habits (3) to Habit', () {
      final container = ProviderContainer(
        overrides: [
          mainNavIndexProvider.overrideWith(() => CustomNavIndexNotifier(3)),
        ],
      );
      expect(container.read(quickAddContextProvider), QuickAddType.habit);
    });
  });

  group('2. Quick Add Creation & Undo Tests', () {
    testWidgets('Creates To-do and Undo reverses it', (tester) async {
      tester.view.physicalSize = const Size(500, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final testTodos = <Todo>[];
      final container = ProviderContainer(
        overrides: [
          mainNavIndexProvider.overrideWith(() => CustomNavIndexNotifier(0)),
          todosProvider.overrideWith(() => TestTodosNotifier(testTodos)),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  key: const Key('open_quick_add'),
                  onPressed: () => QuickAddSheet.show(ctx),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open sheet via QuickAddSheet.show
      await tester.tap(find.byKey(const Key('open_quick_add')));
      await tester.pumpAndSettle();

      // Enter Title
      await tester.enterText(find.byKey(const Key('add_todo_title_field')), 'Submit Report');
      await tester.pumpAndSettle();

      // Submit Done
      await tester.tap(find.byKey(const Key('quick_add_done_button')));
      await tester.pumpAndSettle();

      // Verifies todo was added
      expect(testTodos.length, 1);
      expect(testTodos.first.title, 'Submit Report');

      // Verifies SnackBar appears with Undo
      expect(find.text('Added to to-do'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      // Tap Undo
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      // Verifies todo was deleted
      expect(testTodos.isEmpty, isTrue);
    });

    testWidgets('Creates Assignment and Undo reverses it', (tester) async {
      tester.view.physicalSize = const Size(500, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final testItems = <AcademicItem>[];
      final subjects = [
        const Subject(id: 'sub-1', userId: 'user-1', name: 'Physics', sortOrder: 0),
      ];

      final container = ProviderContainer(
        overrides: [
          mainNavIndexProvider.overrideWith(() => CustomNavIndexNotifier(1)),
          academicItemsProvider.overrideWith(() => TestAcademicItemsNotifier(testItems)),
          subjectsProvider.overrideWith(() => TestSubjectsNotifier(subjects)),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  key: const Key('open_quick_add'),
                  onPressed: () => QuickAddSheet.show(ctx),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_quick_add')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('add_assignment_title_field')), 'Physics Problem Set');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('quick_add_done_button')));
      await tester.pumpAndSettle();

      expect(testItems.length, 1);
      expect(testItems.first.title, 'Physics Problem Set');
      expect(find.text('Assignment added'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(testItems.isEmpty, isTrue);
    });

    testWidgets('Creates Exam and Undo reverses it', (tester) async {
      tester.view.physicalSize = const Size(500, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final testItems = <AcademicItem>[];
      final container = ProviderContainer(
        overrides: [
          mainNavIndexProvider.overrideWith(() => CustomNavIndexNotifier(1)),
          academicsActiveSegmentProvider.overrideWith(
            () => CustomSegmentNotifier(AcademicsSegment.exams),
          ),
          academicItemsProvider.overrideWith(() => TestAcademicItemsNotifier(testItems)),
          subjectsProvider.overrideWith(() => TestSubjectsNotifier(const [])),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  key: const Key('open_quick_add'),
                  onPressed: () => QuickAddSheet.show(ctx),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_quick_add')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('add_exam_title_field')), 'Final Exam');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('quick_add_done_button')));
      await tester.pumpAndSettle();

      expect(testItems.length, 1);
      expect(testItems.first.title, 'Final Exam');
      expect(find.text('Exam added'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(testItems.isEmpty, isTrue);
    });

    testWidgets('Creates Expense and Undo reverses it', (tester) async {
      tester.view.physicalSize = const Size(500, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final testTxs = <ExpenseTransaction>[];
      final container = ProviderContainer(
        overrides: [
          mainNavIndexProvider.overrideWith(() => CustomNavIndexNotifier(2)),
          allTransactionsProvider.overrideWith(() => TestAllTransactionsNotifier(testTxs)),
          monthSummariesProvider.overrideWith(() => TestMonthSummariesNotifier(const [])),
          expenseSettingsProvider.overrideWith(() => TestExpenseSettingsNotifier(
                const ExpenseSettings(
                  userId: 'test-user',
                  monthlyAllowance: 5000,
                  totalSavings: 1000,
                  lastResetMonth: '2026-11',
                ),
              )),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  key: const Key('open_quick_add'),
                  onPressed: () => QuickAddSheet.show(ctx),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_quick_add')));
      await tester.pumpAndSettle();

      // Enter Amount
      await tester.enterText(find.byKey(const Key('transaction_amount_field')), '150');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('quick_add_done_button')));
      await tester.pumpAndSettle();

      expect(testTxs.length, 1);
      expect(testTxs.first.amount, 150.0);
      expect(find.text('Expense logged'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(testTxs.isEmpty, isTrue);
    });
  });

  group('3. Habit Checklist & Isolation Tests', () {
    testWidgets('Habit type shows today habits with checkboxes, no text field, no create control', (tester) async {
      final testHabits = [
        Habit(id: 'h-1', userId: 'user-1', title: 'Read 20 mins', icon: 'menu_book', createdAt: DateTime.now()),
      ];
      final testLogs = <HabitLog>[];

      final container = ProviderContainer(
        overrides: [
          habitsProvider.overrideWith(() => TestHabitsNotifier(testHabits)),
          habitLogsProvider.overrideWith(() => TestHabitLogsNotifier(testLogs)),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: QuickAddSheet(initialType: QuickAddType.habit),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Habit name visible
      expect(find.text('Read 20 mins'), findsOneWidget);
      // Checkbox visible
      expect(find.byKey(const Key('quick_add_habit_checkbox_h-1')), findsOneWidget);

      // NO text fields and NO create habit button
      expect(find.byKey(const Key('add_habit_title_field')), findsNothing);
      expect(find.byKey(const Key('create_habit_button')), findsNothing);

      // Tap checkbox marks done
      await tester.tap(find.byKey(const Key('quick_add_habit_checkbox_h-1')));
      await tester.pumpAndSettle();
      expect(testLogs.length, 1);

      // Tap Done pops sheet
      expect(find.byKey(const Key('quick_add_done_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('quick_add_done_button')));
      await tester.pumpAndSettle();
    });

    testWidgets('Habit empty state shows Open Habits button which navigates to Habits tab', (tester) async {
      final navIndexNotifier = MainNavIndexNotifier();
      final container = ProviderContainer(
        overrides: [
          mainNavIndexProvider.overrideWith(() => navIndexNotifier),
          habitsProvider.overrideWith(() => TestHabitsNotifier(const [])),
          habitLogsProvider.overrideWith(() => TestHabitLogsNotifier([])),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: QuickAddSheet(initialType: QuickAddType.habit),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No habits yet'), findsOneWidget);
      expect(find.byKey(const Key('quick_add_open_habits_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('quick_add_open_habits_button')));
      await tester.pumpAndSettle();

      // Switched to Habits tab (index 3)
      expect(container.read(mainNavIndexProvider), 3);
    });
  });

  group('4. Title Preservation & Discard Confirmation Tests', () {
    testWidgets('Preserves typed title when switching among To-do, Assignment, Exam', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: QuickAddSheet(initialType: QuickAddType.todo),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter title in To-do
      await tester.enterText(find.byKey(const Key('add_todo_title_field')), 'Draft Proposal');
      await tester.pumpAndSettle();

      // Switch to Assignment
      await tester.tap(find.byKey(const Key('quick_add_type_assignment')));
      await tester.pumpAndSettle();

      // Title must be preserved
      final assignmentField = tester.widget<TextField>(find.byKey(const Key('add_assignment_title_field')));
      expect(assignmentField.controller?.text, 'Draft Proposal');

      // Switch to Exam
      await tester.tap(find.byKey(const Key('quick_add_type_exam')));
      await tester.pumpAndSettle();

      // Title must still be preserved
      final examField = tester.widget<TextField>(find.byKey(const Key('add_exam_title_field')));
      expect(examField.controller?.text, 'Draft Proposal');
    });

    testWidgets('Discard confirmation dialog appears when dirty and dismissed', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: QuickAddSheet(initialType: QuickAddType.todo),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Type title to make dirty
      await tester.enterText(find.byKey(const Key('add_todo_title_field')), 'Unsaved task');
      await tester.pumpAndSettle();

      // Tap Close button
      await tester.tap(find.byKey(const Key('quick_add_close_button')));
      await tester.pumpAndSettle();

      // Confirmation dialog must appear
      expect(find.text('Discard this entry?'), findsOneWidget);
      expect(find.byKey(const Key('discard_cancel_button')), findsOneWidget);
      expect(find.byKey(const Key('discard_confirm_button')), findsOneWidget);

      // Cancel keeps sheet open
      await tester.tap(find.byKey(const Key('discard_cancel_button')));
      await tester.pumpAndSettle();
      expect(find.text('Discard this entry?'), findsNothing);
      expect(find.byKey(const Key('quick_add_sheet')), findsOneWidget);

      // Tap Close button again and confirm Discard
      await tester.tap(find.byKey(const Key('quick_add_close_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('discard_confirm_button')));
      await tester.pumpAndSettle();
    });
  });

  group('5. Responsive Layout & Accessibility Matrix Tests', () {
    for (final size in [
      const Size(360, 640),
      const Size(800, 1000),
      const Size(1280, 800),
    ]) {
      testWidgets('Renders at ${size.width}x${size.height} with textScale 1.3 without overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            child: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: const TextScaler.linear(1.3),
              ),
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: const Scaffold(
                  body: QuickAddSheet(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('quick_add_sheet')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
