import 'package:flutter_test/flutter_test.dart';
import 'package:anchor/models/todo.dart';
import 'package:anchor/models/idle_prompt.dart';
import 'package:anchor/models/subject.dart';
import 'package:anchor/models/module.dart';
import 'package:anchor/models/chapter.dart';
import 'package:anchor/models/chapter_file.dart';
import 'package:anchor/models/academic_item.dart';
import 'package:anchor/models/expense_settings.dart';
import 'package:anchor/models/expense_transaction.dart';
import 'package:anchor/models/habit.dart';
import 'package:anchor/models/habit_log.dart';
import 'package:anchor/models/expense_month_summary.dart';

void main() {
  group('12 Models JSON Round-Trip and copyWith tests', () {
    test('1. Todo', () {
      final json = {
        'id': 'todo-1',
        'user_id': 'user-1',
        'title': 'Finish Stage 1',
        'scheduled_date': '2026-11-14',
        'is_completed': false,
        'rollover_count': 2,
        'created_at': '2026-11-14T08:00:00.000Z',
      };
      final model = Todo.fromJson(json);
      expect(model.id, 'todo-1');
      expect(model.title, 'Finish Stage 1');
      expect(model.rolloverCount, 2);
      expect(model.scheduledDate.year, 2026);
      expect(model.scheduledDate.month, 11);
      expect(model.scheduledDate.day, 14);

      final outJson = model.toJson();
      expect(outJson['id'], json['id']);
      expect(outJson['scheduled_date'], '2026-11-14');
      expect(outJson['rollover_count'], 2);

      final copy = model.copyWith(isCompleted: true);
      expect(copy.isCompleted, true);
      expect(copy.id, model.id);
    });

    test('2. IdlePrompt', () {
      final json = {
        'id': 'prompt-1',
        'user_id': 'user-1',
        'prompt_text': 'Why are you stalling?',
        'created_at': '2026-11-14T08:00:00.000Z',
      };
      final model = IdlePrompt.fromJson(json);
      expect(model.promptText, 'Why are you stalling?');
      final outJson = model.toJson();
      expect(outJson['prompt_text'], json['prompt_text']);

      final copy = model.copyWith(promptText: 'Get back to work');
      expect(copy.promptText, 'Get back to work');
    });

    test('3. Subject', () {
      final json = {
        'id': 'sub-1',
        'user_id': 'user-1',
        'name': 'Mathematics',
        'sort_order': 1,
      };
      final model = Subject.fromJson(json);
      expect(model.name, 'Mathematics');
      expect(model.sortOrder, 1);
      final outJson = model.toJson();
      expect(outJson['name'], 'Mathematics');

      final copy = model.copyWith(sortOrder: 2);
      expect(copy.sortOrder, 2);
    });

    test('4. AcademicModule', () {
      final json = {
        'id': 'mod-1',
        'user_id': 'user-1',
        'subject_id': 'sub-1',
        'title': 'Linear Algebra',
        'sort_order': 0,
      };
      final model = AcademicModule.fromJson(json);
      expect(model.title, 'Linear Algebra');
      expect(model.subjectId, 'sub-1');
      final outJson = model.toJson();
      expect(outJson['title'], json['title']);

      final copy = model.copyWith(title: 'Calculus');
      expect(copy.title, 'Calculus');
    });

    test('5. Chapter', () {
      final json = {
        'id': 'chap-1',
        'user_id': 'user-1',
        'module_id': 'mod-1',
        'title': 'Eigenvalues',
        'sort_order': 3,
      };
      final model = Chapter.fromJson(json);
      expect(model.title, 'Eigenvalues');
      final outJson = model.toJson();
      expect(outJson['sort_order'], 3);

      final copy = model.copyWith(title: 'Matrices');
      expect(copy.title, 'Matrices');
    });

    test('6. ChapterFile', () {
      final json = {
        'id': 'file-1',
        'user_id': 'user-1',
        'chapter_id': 'chap-1',
        'file_name': 'notes.pdf',
        'file_type': 'application/pdf',
        'file_size': 102400,
        'storage_path': 'user-1/chap-1/notes.pdf',
        'created_at': '2026-11-14T08:00:00.000Z',
      };
      final model = ChapterFile.fromJson(json);
      expect(model.fileName, 'notes.pdf');
      expect(model.fileSize, 102400);
      final outJson = model.toJson();
      expect(outJson['storage_path'], 'user-1/chap-1/notes.pdf');

      final copy = model.copyWith(fileName: 'summary.pdf');
      expect(copy.fileName, 'summary.pdf');
    });

    test('7. AcademicItem', () {
      final json = {
        'id': 'item-1',
        'user_id': 'user-1',
        'subject_id': 'sub-1',
        'title': 'Midterm Exam',
        'item_type': 'exam',
        'due_date': '2026-11-20',
        'is_completed': false,
        'created_at': '2026-11-14T08:00:00.000Z',
      };
      final model = AcademicItem.fromJson(json);
      expect(model.itemType, 'exam');
      expect(model.dueDate.day, 20);
      expect(model.isCompleted, false);

      final outJson = model.toJson();
      expect(outJson['due_date'], '2026-11-20');

      final copy = model.copyWith(isCompleted: true);
      expect(copy.isCompleted, true);
    });

    test('8. ExpenseSettings', () {
      final json = {
        'user_id': 'user-1',
        'monthly_allowance': 5000, // tests int to double conversion
        'total_savings': 12500.50,
        'last_reset_month': '2026-11',
      };
      final model = ExpenseSettings.fromJson(json);
      expect(model.monthlyAllowance, 5000.0);
      expect(model.totalSavings, 12500.50);
      expect(model.lastResetMonth, '2026-11');

      final outJson = model.toJson();
      expect(outJson['last_reset_month'], '2026-11');

      final copy = model.copyWith(totalSavings: 15000.0);
      expect(copy.totalSavings, 15000.0);
    });

    test('9. ExpenseTransaction', () {
      final json = {
        'id': 'tx-1',
        'user_id': 'user-1',
        'title': 'Groceries',
        'category': 'Food',
        'amount': 45.75,
        'tx_type': 'spent',
        'tx_date': '2026-11-14T10:30:00.000Z',
      };
      final model = ExpenseTransaction.fromJson(json);
      expect(model.category, 'Food');
      expect(model.amount, 45.75);
      expect(model.txType, 'spent');

      final outJson = model.toJson();
      expect(outJson['amount'], 45.75);

      final copy = model.copyWith(amount: 50.0);
      expect(copy.amount, 50.0);
    });

    test('10. Habit', () {
      final json = {
        'id': 'habit-1',
        'user_id': 'user-1',
        'title': 'Read 20 mins',
        'created_at': '2026-11-14T08:00:00.000Z',
      };
      final model = Habit.fromJson(json);
      expect(model.title, 'Read 20 mins');

      final outJson = model.toJson();
      expect(outJson['title'], json['title']);

      final copy = model.copyWith(title: 'Read 30 mins');
      expect(copy.title, 'Read 30 mins');
    });

    test('11. HabitLog', () {
      final json = {
        'id': 'hlog-1',
        'user_id': 'user-1',
        'habit_id': 'habit-1',
        'log_date': '2026-11-14',
      };
      final model = HabitLog.fromJson(json);
      expect(model.habitId, 'habit-1');
      expect(model.logDate.year, 2026);
      expect(model.logDate.day, 14);

      final outJson = model.toJson();
      expect(outJson['log_date'], '2026-11-14');

      final copy = model.copyWith(logDate: DateTime(2026, 11, 15));
      expect(copy.logDate.day, 15);
    });

    test('12. ExpenseMonthSummary', () {
      final json = {
        'id': 'sum-1',
        'user_id': 'user-1',
        'month': '2026-10',
        'allowance': 5000,
        'received': 500,
        'spent': 4200.75,
        'saved': 300,
        'remainder': 1000,
        'carried_to_savings': 1000,
        'closed_at': '2026-10-31T23:59:59.000Z',
      };
      final model = ExpenseMonthSummary.fromJson(json);
      expect(model.month, '2026-10');
      expect(model.allowance, 5000.0);
      expect(model.spent, 4200.75);
      expect(model.remainder, 1000.0);

      final outJson = model.toJson();
      expect(outJson['month'], '2026-10');
      expect(outJson['spent'], 4200.75);

      final copy = model.copyWith(spent: 4300.0);
      expect(copy.spent, 4300.0);
    });
  });
}
