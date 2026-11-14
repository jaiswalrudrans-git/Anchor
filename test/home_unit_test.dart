import 'package:flutter_test/flutter_test.dart';
import 'package:anchor/core/services/rollover_service.dart';
import 'package:anchor/models/todo.dart';
import 'package:anchor/providers/home_providers.dart';

void main() {
  group('Rollover Engine - computeRollover', () {
    test('same day returns 0 (no rollover needed)', () {
      final today = DateTime(2026, 11, 14);
      final scheduled = DateTime(2026, 11, 14);
      expect(RolloverService.computeRollover(scheduled, today), 0);
    });

    test('future date returns 0', () {
      final today = DateTime(2026, 11, 14);
      final scheduled = DateTime(2026, 11, 15);
      expect(RolloverService.computeRollover(scheduled, today), 0);
    });

    test('1 day overdue returns 1', () {
      final today = DateTime(2026, 11, 14);
      final scheduled = DateTime(2026, 11, 13);
      expect(RolloverService.computeRollover(scheduled, today), 1);
    });

    test('multi-day overdue returns exact days missed', () {
      final today = DateTime(2026, 11, 14);
      final scheduled = DateTime(2026, 11, 10);
      expect(RolloverService.computeRollover(scheduled, today), 4);
    });

    test('month boundary overdue computes accurate days', () {
      final today = DateTime(2026, 11, 2);
      final scheduled = DateTime(2026, 10, 30); // Oct has 31 days -> 3 days difference
      expect(RolloverService.computeRollover(scheduled, today), 3);
    });
  });

  group('To-Do Sorting - sortTodos', () {
    test('tasks with rollover_count > 0 come first, descending by rollover_count', () {
      final t1 = Todo(
        id: '1',
        userId: 'u',
        title: 'Normal task 1',
        scheduledDate: DateTime(2026, 11, 14),
        isCompleted: false,
        rolloverCount: 0,
        createdAt: DateTime(2026, 11, 14, 8, 0),
      );
      final t2 = Todo(
        id: '2',
        userId: 'u',
        title: 'Rolled over once',
        scheduledDate: DateTime(2026, 11, 14),
        isCompleted: false,
        rolloverCount: 1,
        createdAt: DateTime(2026, 11, 13, 8, 0),
      );
      final t3 = Todo(
        id: '3',
        userId: 'u',
        title: 'Rolled over thrice',
        scheduledDate: DateTime(2026, 11, 14),
        isCompleted: false,
        rolloverCount: 3,
        createdAt: DateTime(2026, 11, 11, 8, 0),
      );

      final sorted = sortTodos([t1, t2, t3]);
      expect(sorted[0].id, '3'); // highest rollover (3)
      expect(sorted[1].id, '2'); // rollover (1)
      expect(sorted[2].id, '1'); // rollover (0)
    });

    test('non-rolled tasks sorted by created_at ascending', () {
      final earlier = Todo(
        id: 'earlier',
        userId: 'u',
        title: 'Created at 9am',
        scheduledDate: DateTime(2026, 11, 14),
        isCompleted: false,
        rolloverCount: 0,
        createdAt: DateTime(2026, 11, 14, 9, 0),
      );
      final later = Todo(
        id: 'later',
        userId: 'u',
        title: 'Created at 10am',
        scheduledDate: DateTime(2026, 11, 14),
        isCompleted: false,
        rolloverCount: 0,
        createdAt: DateTime(2026, 11, 14, 10, 0),
      );

      final sorted = sortTodos([later, earlier]);
      expect(sorted[0].id, 'earlier');
      expect(sorted[1].id, 'later');
    });

    test('completed tasks sink to the bottom even with higher rollover', () {
      final completedRolled = Todo(
        id: 'done-rolled',
        userId: 'u',
        title: 'Completed with 5 rollovers',
        scheduledDate: DateTime(2026, 11, 14),
        isCompleted: true,
        rolloverCount: 5,
        createdAt: DateTime(2026, 11, 9, 8, 0),
      );
      final incompleteFresh = Todo(
        id: 'pending-fresh',
        userId: 'u',
        title: 'Pending fresh task',
        scheduledDate: DateTime(2026, 11, 14),
        isCompleted: false,
        rolloverCount: 0,
        createdAt: DateTime(2026, 11, 14, 9, 0),
      );

      final sorted = sortTodos([completedRolled, incompleteFresh]);
      expect(sorted[0].id, 'pending-fresh');
      expect(sorted[1].id, 'done-rolled');
    });
  });

  group('Kill Idle Time Unlock Logic - isKillIdleUnlocked', () {
    test('returns false when today has no tasks', () {
      expect(isKillIdleUnlocked([]), isFalse);
      expect(getKillIdleStatusMessage([]), "Plan today's tasks first.");
    });

    test('returns false when some tasks are pending', () {
      final t1 = Todo(
        id: '1',
        userId: 'u',
        title: 'Done',
        scheduledDate: DateTime(2026, 11, 14),
        isCompleted: true,
        createdAt: DateTime.now(),
      );
      final t2 = Todo(
        id: '2',
        userId: 'u',
        title: 'Pending',
        scheduledDate: DateTime(2026, 11, 14),
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      expect(isKillIdleUnlocked([t1, t2]), isFalse);
      expect(getKillIdleStatusMessage([t1, t2]), '1 task left today. Finish them to unlock Kill Idle Time.');
    });

    test('returns false when rolled-over task is pending', () {
      final t1 = Todo(
        id: '1',
        userId: 'u',
        title: 'Fresh done',
        scheduledDate: DateTime(2026, 11, 14),
        isCompleted: true,
        createdAt: DateTime.now(),
      );
      final t2 = Todo(
        id: '2',
        userId: 'u',
        title: 'Rolled over and pending',
        scheduledDate: DateTime(2026, 11, 14),
        isCompleted: false,
        rolloverCount: 2,
        createdAt: DateTime.now(),
      );

      expect(isKillIdleUnlocked([t1, t2]), isFalse);
      expect(getKillIdleStatusMessage([t1, t2]), '1 task left today. Finish them to unlock Kill Idle Time.');
    });

    test('returns true when all today tasks are completed', () {
      final t1 = Todo(
        id: '1',
        userId: 'u',
        title: 'Done 1',
        scheduledDate: DateTime(2026, 11, 14),
        isCompleted: true,
        createdAt: DateTime.now(),
      );
      final t2 = Todo(
        id: '2',
        userId: 'u',
        title: 'Done 2',
        scheduledDate: DateTime(2026, 11, 14),
        isCompleted: true,
        rolloverCount: 1,
        createdAt: DateTime.now(),
      );

      expect(isKillIdleUnlocked([t1, t2]), isTrue);
      expect(getKillIdleStatusMessage([t1, t2]), 'All tasks done! Kill Idle Time unlocked.');
    });
  });
}
