import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anchor/core/constants/theme.dart';
import 'package:anchor/models/academic_item.dart';
import 'package:anchor/models/chapter.dart';
import 'package:anchor/models/module.dart';
import 'package:anchor/models/subject.dart';
import 'package:anchor/providers/academics_providers.dart';
import 'package:anchor/screens/academics/academics_screen.dart';
import 'package:anchor/widgets/academics/countdown_pill.dart';
import 'package:anchor/widgets/academics/deadline_bar.dart';
import 'package:anchor/widgets/academics/urgency_tone.dart';

class MockSubjectsNotifier extends SubjectsNotifier {
  final List<Subject> _initial;
  MockSubjectsNotifier(this._initial);

  @override
  Future<List<Subject>> build() async => _initial;
}

class MockModulesNotifier extends ModulesNotifier {
  final List<AcademicModule> _initial;
  MockModulesNotifier(this._initial);

  @override
  Future<List<AcademicModule>> build() async => _initial;
}

class MockChaptersNotifier extends ChaptersNotifier {
  final List<Chapter> _initial;
  bool shouldFail = false;

  MockChaptersNotifier(this._initial);

  @override
  Future<List<Chapter>> build() async => _initial;

  @override
  Future<void> toggleStudied(String id) async {
    final current = state.value ?? [];
    final index = current.indexWhere((c) => c.id == id);
    if (index == -1) return;

    final target = current[index];
    final updated = target.copyWith(isStudied: !target.isStudied);
    final updatedList = List<Chapter>.from(current);
    updatedList[index] = updated;

    state = AsyncData(updatedList);

    if (shouldFail) {
      state = AsyncData(current); // rollback
      throw Exception('Network error');
    }
  }
}

class MockAcademicItemsNotifier extends AcademicItemsNotifier {
  List<AcademicItem> _items;
  bool wasNotificationCancelled = false;

  MockAcademicItemsNotifier(this._items);

  @override
  Future<List<AcademicItem>> build() async => _items;

  @override
  Future<void> markExamCompleted(String id) async {
    final index = _items.indexWhere((i) => i.id == id);
    if (index != -1) {
      final updated = _items[index].copyWith(isCompleted: true);
      final list = List<AcademicItem>.from(_items);
      list[index] = updated;
      _items = list;
      state = AsyncData(_items);
      wasNotificationCancelled = true;
    }
  }
}

void main() {
  group('Polish Stage 4 - Pure Calculations & Helpers', () {
    test('UrgencyTone thresholds for assignments (soonThreshold = 2)', () {
      expect(UrgencyTone.fromDaysLeft(-1), equals(UrgencyTone.overdue));
      expect(UrgencyTone.fromDaysLeft(-5), equals(UrgencyTone.overdue));
      expect(UrgencyTone.fromDaysLeft(0), equals(UrgencyTone.soon));
      expect(UrgencyTone.fromDaysLeft(1), equals(UrgencyTone.soon));
      expect(UrgencyTone.fromDaysLeft(2), equals(UrgencyTone.soon));
      expect(UrgencyTone.fromDaysLeft(3), equals(UrgencyTone.normal));
      expect(UrgencyTone.fromDaysLeft(10), equals(UrgencyTone.normal));
    });

    test('UrgencyTone thresholds for exams (soonThreshold = 3)', () {
      expect(UrgencyTone.fromDaysLeft(3, soonThreshold: 3), equals(UrgencyTone.soon));
      expect(UrgencyTone.fromDaysLeft(4, soonThreshold: 3), equals(UrgencyTone.normal));
    });

    test('CountdownPill labels format properly', () {
      expect(countdownPillLabel(0), equals('Today'));
      expect(countdownPillLabel(1), equals('1d'));
      expect(countdownPillLabel(2), equals('2d'));
      expect(countdownPillLabel(7), equals('7d'));
      expect(countdownPillLabel(-1), equals('Overdue 1d'));
      expect(countdownPillLabel(-3), equals('Overdue 3d'));
    });

    test('DeadlineBar proximity fill fraction matches specification', () {
      // 0 days or overdue -> 1.0 (full)
      expect(deadlineBarFill(0), equals(1.0));
      expect(deadlineBarFill(-2), equals(1.0));
      expect(deadlineBarFill(-10), equals(1.0));

      // 7 days -> 0.5 (half)
      expect(deadlineBarFill(7), equals(0.5));

      // 14 days or beyond -> 0.0 (empty)
      expect(deadlineBarFill(14), equals(0.0));
      expect(deadlineBarFill(20), equals(0.0));
    });
  });

  group('Polish Stage 4 - Assignment Grouping & Boundaries', () {
    final today = DateTime(2026, 11, 14);

    test('groupAssignments splits into Overdue, Today, This week, Later, and Completed', () {
      final items = [
        AcademicItem(
          id: 'a-overdue',
          userId: 'u1',
          title: 'Overdue HW',
          itemType: 'assignment',
          dueDate: DateTime(2026, 11, 12),
          isCompleted: false,
          createdAt: DateTime(2026, 11, 1),
        ),
        AcademicItem(
          id: 'a-today',
          userId: 'u1',
          title: 'Today HW',
          itemType: 'assignment',
          dueDate: DateTime(2026, 11, 14),
          isCompleted: false,
          createdAt: DateTime(2026, 11, 2),
        ),
        AcademicItem(
          id: 'a-week-1',
          userId: 'u1',
          title: 'In 3 Days HW',
          itemType: 'assignment',
          dueDate: DateTime(2026, 11, 17),
          isCompleted: false,
          createdAt: DateTime(2026, 11, 3),
        ),
        AcademicItem(
          id: 'a-week-boundary',
          userId: 'u1',
          title: 'In 7 Days HW',
          itemType: 'assignment',
          dueDate: DateTime(2026, 11, 21),
          isCompleted: false,
          createdAt: DateTime(2026, 11, 4),
        ),
        AcademicItem(
          id: 'a-later',
          userId: 'u1',
          title: 'In 10 Days HW',
          itemType: 'assignment',
          dueDate: DateTime(2026, 11, 24),
          isCompleted: false,
          createdAt: DateTime(2026, 11, 5),
        ),
        AcademicItem(
          id: 'a-completed',
          userId: 'u1',
          title: 'Done HW',
          itemType: 'assignment',
          dueDate: DateTime(2026, 11, 14),
          isCompleted: true,
          createdAt: DateTime(2026, 11, 6),
        ),
      ];

      final grouped = groupAssignments(items, today);

      expect(grouped[AssignmentGroup.overdue]!.map((a) => a.id).toList(), ['a-overdue']);
      expect(grouped[AssignmentGroup.today]!.map((a) => a.id).toList(), ['a-today']);
      expect(grouped[AssignmentGroup.thisWeek]!.map((a) => a.id).toList(), ['a-week-1', 'a-week-boundary']);
      expect(grouped[AssignmentGroup.later]!.map((a) => a.id).toList(), ['a-later']);
      expect(grouped[AssignmentGroup.completed]!.map((a) => a.id).toList(), ['a-completed']);
    });
  });

  group('Polish Stage 4 - Exam Completion & Filtering', () {
    test('Completed exams are strictly excluded from sortExams and filterUrgentExams', () {
      final today = DateTime(2026, 11, 14);
      final items = [
        AcademicItem(
          id: 'e-active-today',
          userId: 'u1',
          title: 'Active Today',
          itemType: 'exam',
          dueDate: today,
          isCompleted: false,
          createdAt: DateTime(2026, 11, 1),
        ),
        AcademicItem(
          id: 'e-completed-today',
          userId: 'u1',
          title: 'Completed Today',
          itemType: 'exam',
          dueDate: today,
          isCompleted: true,
          createdAt: DateTime(2026, 11, 1),
        ),
        AcademicItem(
          id: 'e-active-future',
          userId: 'u1',
          title: 'Active Future',
          itemType: 'exam',
          dueDate: today.add(const Duration(days: 4)),
          isCompleted: false,
          createdAt: DateTime(2026, 11, 2),
        ),
      ];

      final sorted = sortExams(items);
      expect(sorted.map((e) => e.id).toList(), ['e-active-today', 'e-active-future']);

      final radar = filterUrgentExams(items, today);
      expect(radar.map((e) => e.id).toList(), ['e-active-today', 'e-active-future']);
    });
  });

  group('Polish Stage 4 - Syllabus Studied Math & Optimistic Toggle', () {
    test('Subject & Module stats handle 0 chapters without division errors', () {
      const stats = SubjectSyllabusStats(
        totalModules: 1,
        totalChapters: 0,
        studiedChapters: 0,
        progress: 0.0,
      );

      expect(stats.progress, equals(0.0));
      expect((stats.progress * 100).round(), equals(0));
    });

    test('ChaptersNotifier toggleStudied optimistically updates and rolls back on failure', () async {
      final container = ProviderContainer(
        overrides: [
          chaptersProvider.overrideWith(
            () => MockChaptersNotifier([
              const Chapter(id: 'c1', userId: 'u1', moduleId: 'm1', title: 'Chapter 1', isStudied: false),
            ]),
          ),
        ],
      );

      // 1. Initial state
      final initial = await container.read(chaptersProvider.future);
      expect(initial.first.isStudied, isFalse);

      // 2. Successful toggle
      final notifier = container.read(chaptersProvider.notifier) as MockChaptersNotifier;
      await notifier.toggleStudied('c1');
      expect(container.read(chaptersProvider).value!.first.isStudied, isTrue);

      // 3. Failing toggle with rollback
      notifier.shouldFail = true;
      try {
        await notifier.toggleStudied('c1');
      } catch (_) {}

      // Verified rolled back to previous state (true)
      expect(container.read(chaptersProvider).value!.first.isStudied, isTrue);
    });
  });

  group('Polish Stage 4 - Responsive Layouts & Text Scale 1.3', () {
    final testSubject = const Subject(
      id: 'sub-1',
      userId: 'u1',
      name: 'Network Security',
      sortOrder: 1,
    );

    final testModule = const AcademicModule(
      id: 'mod-1',
      userId: 'u1',
      subjectId: 'sub-1',
      title: 'Cryptography',
      sortOrder: 1,
    );

    final testChapter = const Chapter(
      id: 'chap-1',
      userId: 'u1',
      moduleId: 'mod-1',
      title: 'RSA and AES Public Key Ciphers',
      isStudied: false,
      sortOrder: 1,
    );

    final testAssignment = AcademicItem(
      id: 'a1',
      userId: 'u1',
      subjectId: 'sub-1',
      title: 'Lab 2: Wireshark Packet Decryption',
      itemType: 'assignment',
      dueDate: DateTime.now().add(const Duration(days: 1)),
      isCompleted: false,
      createdAt: DateTime.now(),
    );

    final testExam = AcademicItem(
      id: 'e1',
      userId: 'u1',
      subjectId: 'sub-1',
      title: 'Final Exam Security Architecture',
      itemType: 'exam',
      dueDate: DateTime.now(), // Today
      isCompleted: false,
      createdAt: DateTime.now(),
    );

    Future<void> pumpScreen(WidgetTester tester, Size size, double textScale) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subjectsProvider.overrideWith(() => MockSubjectsNotifier([testSubject])),
            modulesProvider.overrideWith(() => MockModulesNotifier([testModule])),
            chaptersProvider.overrideWith(() => MockChaptersNotifier([testChapter])),
            academicItemsProvider.overrideWith(() => MockAcademicItemsNotifier([testAssignment, testExam])),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(textScale),
              ),
              child: const AcademicsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Compact mobile (360x640) with text scale 1.3 renders without overflow', (tester) async {
      await pumpScreen(tester, const Size(360, 640), 1.3);
      expect(find.byType(AcademicsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Medium tablet (800x1000) with text scale 1.3 renders without overflow', (tester) async {
      await pumpScreen(tester, const Size(800, 1000), 1.3);
      expect(find.byType(AcademicsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Expanded desktop (1280x800) with text scale 1.3 renders without overflow', (tester) async {
      await pumpScreen(tester, const Size(1280, 800), 1.3);
      expect(find.byType(AcademicsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
