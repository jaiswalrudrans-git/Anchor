import 'package:flutter_test/flutter_test.dart';
import 'package:anchor/core/services/exam_cleanup_service.dart';
import 'package:anchor/core/services/notification_service.dart';
import 'package:anchor/models/academic_item.dart';
import 'package:anchor/models/chapter.dart';
import 'package:anchor/models/module.dart';
import 'package:anchor/models/subject.dart';
import 'package:anchor/providers/academics_providers.dart';

void main() {
  group('Notification Reminder Time Pure Calculations', () {
    test('assignmentReminderTime: normal future assignment scheduled at 21:00 on due_date - 1 day', () {
      final now = DateTime(2026, 11, 14, 10, 0, 0);
      final dueDate = DateTime(2026, 11, 20); // due in 6 days

      final reminder = NotificationService.assignmentReminderTime(dueDate, now);

      expect(reminder, isNotNull);
      expect(reminder!.year, 2026);
      expect(reminder.month, 11);
      expect(reminder.day, 19); // 1 day before due date
      expect(reminder.hour, 21);
      expect(reminder.minute, 0);
      expect(reminder.second, 0);
    });

    test('assignmentReminderTime: due tomorrow after 21:00 has already passed returns null', () {
      // Due tomorrow is Nov 15. Reminder would be Nov 14 at 21:00.
      // But now is Nov 14 at 21:30 (already passed).
      final now = DateTime(2026, 11, 14, 21, 30, 0);
      final dueDate = DateTime(2026, 11, 15);

      final reminder = NotificationService.assignmentReminderTime(dueDate, now);

      expect(reminder, isNull);
    });

    test(
      'assignmentReminderTime: due tomorrow before 21:00 returns reminder',
      () {
        final now = DateTime(2026, 11, 14, 20, 59, 0);
        final dueDate = DateTime(2026, 11, 15);

        final reminder = NotificationService.assignmentReminderTime(
          dueDate,
          now,
        );

        expect(reminder, isNotNull);
        expect(reminder, DateTime(2026, 11, 14, 21, 0, 0));
      },
    );

    test('assignmentReminderTime: due today is already past reminder time and returns null', () {
      final now = DateTime(2026, 11, 14, 9, 0, 0);
      final dueDate = DateTime(2026, 11, 14);

      final reminder = NotificationService.assignmentReminderTime(dueDate, now);

      expect(reminder, isNull);
    });

    test('examReminderTime: normal future exam scheduled at 08:00 on due_date - 3 days', () {
      final now = DateTime(2026, 11, 14, 10, 0, 0);
      final dueDate = DateTime(2026, 11, 24); // due in 10 days

      final reminder = NotificationService.examReminderTime(dueDate, now);

      expect(reminder, isNotNull);
      expect(reminder!.year, 2026);
      expect(reminder.month, 11);
      expect(reminder.day, 21); // 3 days before Nov 24
      expect(reminder.hour, 8);
      expect(reminder.minute, 0);
      expect(reminder.second, 0);
    });

    test('examReminderTime: due in 2 days has already passed reminder moment and returns null', () {
      // Exam on Nov 16. 3 days before is Nov 13 at 08:00.
      // Now is Nov 14 -> already passed!
      final now = DateTime(2026, 11, 14, 12, 0, 0);
      final dueDate = DateTime(2026, 11, 16);

      final reminder = NotificationService.examReminderTime(dueDate, now);

      expect(reminder, isNull);
    });

    test('examReminderTime: due in 3 days after 08:00 has already passed returns null', () {
      final now = DateTime(2026, 11, 14, 8, 30, 0);
      final dueDate = DateTime(
        2026,
        11,
        17,
      ); // 3 days before is Nov 14 at 08:00

      final reminder = NotificationService.examReminderTime(dueDate, now);

      expect(reminder, isNull);
    });

    test('notificationId generates positive 31-bit deterministic int', () {
      const id1 = '8f3b6c2a-9e12-4d57-b430-6d425f191b8a';
      const id2 = 'c129e840-77a8-4235-901b-94c637a7b8e1';

      final nid1 = NotificationService.notificationId(id1);
      final nid2 = NotificationService.notificationId(id2);

      expect(nid1, greaterThanOrEqualTo(0));
      expect(nid2, greaterThanOrEqualTo(0));
      expect(nid1, equals(NotificationService.notificationId(id1)));
    });
  });

  group('Past Exam Auto-Cleanup Boundary Tests', () {
    final today = DateTime(2026, 11, 14);

    test('shouldDeleteExam: exam today is kept (false)', () {
      expect(ExamCleanupService.shouldDeleteExam(today, today), isFalse);
    });

    test('shouldDeleteExam: exam tomorrow is kept (false)', () {
      final tomorrow = today.add(const Duration(days: 1));
      expect(ExamCleanupService.shouldDeleteExam(tomorrow, today), isFalse);
    });

    test('shouldDeleteExam: exam yesterday is deleted (true)', () {
      final yesterday = today.subtract(const Duration(days: 1));
      expect(ExamCleanupService.shouldDeleteExam(yesterday, today), isTrue);
    });

    test('filterOverdueExams: filters past exams and leaves today/future exams and assignments untouched', () {
      final items = [
        AcademicItem(
          id: 'exam-past',
          userId: 'u1',
          title: 'Past Exam',
          itemType: 'exam',
          dueDate: DateTime(2026, 11, 13), // yesterday
          isCompleted: false,
          createdAt: DateTime.now(),
        ),
        AcademicItem(
          id: 'exam-today',
          userId: 'u1',
          title: 'Today Exam',
          itemType: 'exam',
          dueDate: DateTime(2026, 11, 14), // today
          isCompleted: false,
          createdAt: DateTime.now(),
        ),
        AcademicItem(
          id: 'exam-future',
          userId: 'u1',
          title: 'Future Exam',
          itemType: 'exam',
          dueDate: DateTime(2026, 11, 20), // future
          isCompleted: false,
          createdAt: DateTime.now(),
        ),
        AcademicItem(
          id: 'assignment-past',
          userId: 'u1',
          title: 'Past Assignment',
          itemType: 'assignment',
          dueDate: DateTime(2026, 11, 10), // assignments never auto-deleted
          isCompleted: false,
          createdAt: DateTime.now(),
        ),
      ];

      final overdue = ExamCleanupService.filterOverdueExams(items, today);

      expect(overdue.length, 1);
      expect(overdue.first.id, 'exam-past');
    });
  });

  group('Academic Radar Filters and Sorting', () {
    final today = DateTime(2026, 11, 14);

    test('filterUrgentAssignments: 7-day window, completed excluded, overdue excluded', () {
      final items = [
        // Overdue (< today) -> excluded from radar
        AcademicItem(
          id: 'a-overdue',
          userId: 'u1',
          title: 'Overdue Assignment',
          itemType: 'assignment',
          dueDate: DateTime(2026, 11, 12),
          isCompleted: false,
          createdAt: DateTime(2026, 11, 1),
        ),
        // Today -> included
        AcademicItem(
          id: 'a-today',
          userId: 'u1',
          title: 'Today Assignment',
          itemType: 'assignment',
          dueDate: DateTime(2026, 11, 14),
          isCompleted: false,
          createdAt: DateTime(2026, 11, 2),
        ),
        // In 3 days -> included
        AcademicItem(
          id: 'a-in-3-days',
          userId: 'u1',
          title: 'In 3 Days Assignment',
          itemType: 'assignment',
          dueDate: DateTime(2026, 11, 17),
          isCompleted: false,
          createdAt: DateTime(2026, 11, 3),
        ),
        // In 7 days (boundary) -> included
        AcademicItem(
          id: 'a-in-7-days',
          userId: 'u1',
          title: 'In 7 Days Assignment',
          itemType: 'assignment',
          dueDate: DateTime(2026, 11, 21),
          isCompleted: false,
          createdAt: DateTime(2026, 11, 4),
        ),
        // In 8 days (> 7 days) -> excluded
        AcademicItem(
          id: 'a-in-8-days',
          userId: 'u1',
          title: 'In 8 Days Assignment',
          itemType: 'assignment',
          dueDate: DateTime(2026, 11, 22),
          isCompleted: false,
          createdAt: DateTime(2026, 11, 5),
        ),
        // Completed within window -> excluded
        AcademicItem(
          id: 'a-completed',
          userId: 'u1',
          title: 'Completed Assignment',
          itemType: 'assignment',
          dueDate: DateTime(2026, 11, 15),
          isCompleted: true,
          createdAt: DateTime(2026, 11, 6),
        ),
      ];

      final urgent = filterUrgentAssignments(items, today);

      expect(urgent.length, 3);
      expect(urgent.map((a) => a.id).toList(), [
        'a-today',
        'a-in-3-days',
        'a-in-7-days',
      ]);
    });

    test('filterUrgentExams: 14-day window strictly sorted due_date ASC', () {
      final items = [
        // Exam today -> included
        AcademicItem(
          id: 'e-today',
          userId: 'u1',
          title: 'Exam Today',
          itemType: 'exam',
          dueDate: DateTime(2026, 11, 14),
          isCompleted: false,
          createdAt: DateTime(2026, 11, 1),
        ),
        // Exam in 5 days -> included
        AcademicItem(
          id: 'e-in-5-days',
          userId: 'u1',
          title: 'Exam In 5 Days',
          itemType: 'exam',
          dueDate: DateTime(2026, 11, 19),
          isCompleted: false,
          createdAt: DateTime(2026, 11, 2),
        ),
        // Exam in 14 days (boundary) -> included
        AcademicItem(
          id: 'e-in-14-days',
          userId: 'u1',
          title: 'Exam In 14 Days',
          itemType: 'exam',
          dueDate: DateTime(2026, 11, 28),
          isCompleted: false,
          createdAt: DateTime(2026, 11, 3),
        ),
        // Exam in 15 days (> 14 days) -> excluded
        AcademicItem(
          id: 'e-in-15-days',
          userId: 'u1',
          title: 'Exam In 15 Days',
          itemType: 'exam',
          dueDate: DateTime(2026, 11, 29),
          isCompleted: false,
          createdAt: DateTime(2026, 11, 4),
        ),
      ];

      final urgent = filterUrgentExams(items, today);

      expect(urgent.length, 3);
      expect(urgent.map((e) => e.id).toList(), [
        'e-today',
        'e-in-5-days',
        'e-in-14-days',
      ]);
    });

    test(
      'sortAssignments: incomplete by dueDate ASC, completed sink to bottom',
      () {
        final items = [
          AcademicItem(
            id: 'comp-1',
            userId: 'u1',
            title: 'Completed 1',
            itemType: 'assignment',
            dueDate: DateTime(2026, 11, 10),
            isCompleted: true,
            createdAt: DateTime(2026, 11, 1),
          ),
          AcademicItem(
            id: 'inc-later',
            userId: 'u1',
            title: 'Incomplete Later',
            itemType: 'assignment',
            dueDate: DateTime(2026, 11, 25),
            isCompleted: false,
            createdAt: DateTime(2026, 11, 2),
          ),
          AcademicItem(
            id: 'inc-sooner',
            userId: 'u1',
            title: 'Incomplete Sooner',
            itemType: 'assignment',
            dueDate: DateTime(2026, 11, 15),
            isCompleted: false,
            createdAt: DateTime(2026, 11, 3),
          ),
        ];

        final sorted = sortAssignments(items);

        expect(sorted.map((a) => a.id).toList(), [
          'inc-sooner',
          'inc-later',
          'comp-1',
        ]);
      },
    );
  });

  group('Syllabus Tree Sorting', () {
    test('sortSubjects: sort_order ASC, then name ASC', () {
      final subjects = [
        const Subject(id: 's2', userId: 'u', name: 'Physics', sortOrder: 2),
        const Subject(id: 's1', userId: 'u', name: 'Chemistry', sortOrder: 1),
        const Subject(id: 's3', userId: 'u', name: 'Biology', sortOrder: 2),
      ];

      final sorted = sortSubjects(subjects);

      expect(sorted.map((s) => s.id).toList(), ['s1', 's3', 's2']);
    });

    test('sortModules: sort_order ASC, then title ASC', () {
      final modules = [
        const AcademicModule(
          id: 'm2',
          userId: 'u',
          subjectId: 's1',
          title: 'Module 2',
          sortOrder: 2,
        ),
        const AcademicModule(
          id: 'm1',
          userId: 'u',
          subjectId: 's1',
          title: 'Module 1',
          sortOrder: 1,
        ),
      ];

      final sorted = sortModules(modules);

      expect(sorted.map((m) => m.id).toList(), ['m1', 'm2']);
    });

    test('sortChapters: sort_order ASC, then title ASC', () {
      final chapters = [
        const Chapter(
          id: 'c2',
          userId: 'u',
          moduleId: 'm1',
          title: 'Chapter 2',
          sortOrder: 2,
        ),
        const Chapter(
          id: 'c1',
          userId: 'u',
          moduleId: 'm1',
          title: 'Chapter 1',
          sortOrder: 1,
        ),
      ];

      final sorted = sortChapters(chapters);

      expect(sorted.map((c) => c.id).toList(), ['c1', 'c2']);
    });
  });
}
