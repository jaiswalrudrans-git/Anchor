import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anchor/core/constants/theme.dart';
import 'package:anchor/screens/academics/widgets/add_assignment_sheet.dart';
import 'package:anchor/screens/academics/widgets/add_exam_sheet.dart';
import 'package:anchor/screens/academics/widgets/add_module_dialog.dart';
import 'package:anchor/screens/academics/widgets/add_subject_dialog.dart';
import 'package:anchor/screens/expenses/widgets/add_transaction_sheet.dart';
import 'package:anchor/screens/habits/widgets/add_habit_sheet.dart';
import 'package:anchor/screens/home/widgets/add_todo_sheet.dart';
import 'package:anchor/screens/main_shell.dart';

void main() {
  group('Add-Button Audit: Strict Page-Specific Isolation', () {
    testWidgets(
      'MainShell contains exactly ONE global Quick Add button and zero FABs',
      (tester) async {
        tester.view.physicalSize = const Size(500, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProviderScope(child: MainShell()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(FloatingActionButton), findsNothing);
        expect(find.byKey(const Key('quick_add_button')), findsOneWidget);
      },
    );

    testWidgets('Home AddTodoSheet contains ONLY to-do fields', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: ProviderScope(child: AddTodoSheet())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('add_todo_title_field')), findsOneWidget);
      expect(
        find.byKey(const Key('add_todo_sheet_submit_button')),
        findsOneWidget,
      );

      expect(find.byKey(const Key('transaction_amount_field')), findsNothing);
      expect(
        find.byKey(const Key('add_assignment_subject_dropdown')),
        findsNothing,
      );
      expect(find.byKey(const Key('add_habit_title_field')), findsNothing);
    });

    testWidgets('Academics AddSubjectDialog contains ONLY subject fields', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: ProviderScope(child: AddSubjectDialog())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('add_subject_name_field')), findsOneWidget);
      expect(
        find.byKey(const Key('add_subject_submit_button')),
        findsOneWidget,
      );

      expect(find.byKey(const Key('transaction_amount_field')), findsNothing);
      expect(find.byKey(const Key('add_todo_title_field')), findsNothing);
    });

    testWidgets('Academics AddModuleDialog contains ONLY module fields', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: ProviderScope(child: AddModuleDialog(subjectId: 'sub-1')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('add_module_title_field')), findsOneWidget);
      expect(find.byKey(const Key('add_module_submit_button')), findsOneWidget);

      expect(find.byKey(const Key('transaction_amount_field')), findsNothing);
      expect(find.byKey(const Key('add_todo_title_field')), findsNothing);
    });

    testWidgets(
      'Academics AddAssignmentSheet contains ONLY assignment fields',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: ProviderScope(child: AddAssignmentSheet()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('add_assignment_title_field')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('assignment_subject_dropdown')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('add_assignment_submit_button')),
          findsOneWidget,
        );

        expect(find.byKey(const Key('transaction_amount_field')), findsNothing);
        expect(find.byKey(const Key('add_habit_title_field')), findsNothing);
      },
    );

    testWidgets('Academics AddExamSheet contains ONLY exam fields', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: ProviderScope(child: AddExamSheet())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('add_exam_title_field')), findsOneWidget);
      expect(find.byKey(const Key('exam_subject_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('add_exam_submit_button')), findsOneWidget);

      expect(find.byKey(const Key('transaction_amount_field')), findsNothing);
      expect(find.byKey(const Key('add_habit_title_field')), findsNothing);
    });

    testWidgets(
      'Expenses AddTransactionSheet contains ONLY transaction fields',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: ProviderScope(child: AddTransactionSheet()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('transaction_amount_field')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('save_transaction_button')),
          findsOneWidget,
        );

        expect(
          find.byKey(const Key('add_assignment_subject_dropdown')),
          findsNothing,
        );
        expect(find.byKey(const Key('add_todo_title_field')), findsNothing);
        expect(find.byKey(const Key('add_habit_title_field')), findsNothing);
      },
    );

    testWidgets(
      'Habits AddHabitSheet contains ONLY habit title, icon, and frequency fields',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: ProviderScope(child: AddHabitSheet())),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('add_habit_title_field')), findsOneWidget);
        expect(find.byKey(const Key('create_habit_button')), findsOneWidget);

        expect(find.byKey(const Key('transaction_amount_field')), findsNothing);
        expect(
          find.byKey(const Key('add_assignment_date_picker')),
          findsNothing,
        );
      },
    );
  });
}
