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
import 'package:anchor/screens/home/widgets/academic_radar_slot.dart';

class TestSubjectsNotifier extends SubjectsNotifier {
  final List<Subject> _initial;
  TestSubjectsNotifier(this._initial);

  @override
  Future<List<Subject>> build() async => _initial;
}

class TestModulesNotifier extends ModulesNotifier {
  final List<AcademicModule> _initial;
  TestModulesNotifier(this._initial);

  @override
  Future<List<AcademicModule>> build() async => _initial;
}

class TestChaptersNotifier extends ChaptersNotifier {
  final List<Chapter> _initial;
  TestChaptersNotifier(this._initial);

  @override
  Future<List<Chapter>> build() async => _initial;
}

class TestAcademicItemsNotifier extends AcademicItemsNotifier {
  List<AcademicItem> _items;
  TestAcademicItemsNotifier(this._items);

  @override
  Future<List<AcademicItem>> build() async => _items;

  @override
  Future<void> toggleAssignmentComplete(String id) async {
    final index = _items.indexWhere((i) => i.id == id);
    if (index != -1) {
      final updated = _items[index].copyWith(
        isCompleted: !_items[index].isCompleted,
      );
      final list = List<AcademicItem>.from(_items);
      list[index] = updated;
      _items = list;
      state = AsyncData(_items);
    }
  }
}

void main() {
  const testSubject = Subject(
    id: 'sub-1',
    userId: 'user-1',
    name: 'Computer Networks',
    sortOrder: 1,
  );

  const testModule = AcademicModule(
    id: 'mod-1',
    userId: 'user-1',
    subjectId: 'sub-1',
    title: 'Module 1: Physical Layer',
    sortOrder: 1,
  );

  const testChapter = Chapter(
    id: 'chap-1',
    userId: 'user-1',
    moduleId: 'mod-1',
    title: 'Chapter 1.1: Transmission Media',
    sortOrder: 1,
  );

  final testAssignment = AcademicItem(
    id: 'assign-1',
    userId: 'user-1',
    subjectId: 'sub-1',
    title: 'Packet Tracer Lab 1',
    itemType: 'assignment',
    dueDate: DateTime.now().add(const Duration(days: 2)),
    isCompleted: false,
    createdAt: DateTime.now(),
  );

  final testExam = AcademicItem(
    id: 'exam-1',
    userId: 'user-1',
    subjectId: 'sub-1',
    title: 'Midterm Exam',
    itemType: 'exam',
    dueDate: DateTime.now().add(const Duration(days: 5)),
    isCompleted: false,
    createdAt: DateTime.now(),
  );

  group('Academics Screen Context-Aware Add Controls & Tabs', () {
    testWidgets(
      'Each segment shows its own context-aware add button and opens strictly its own sheet/dialog',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              subjectsProvider.overrideWith(
                () => TestSubjectsNotifier([testSubject]),
              ),
              modulesProvider.overrideWith(
                () => TestModulesNotifier([testModule]),
              ),
              chaptersProvider.overrideWith(
                () => TestChaptersNotifier([testChapter]),
              ),
              academicItemsProvider.overrideWith(
                () => TestAcademicItemsNotifier([testAssignment, testExam]),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const AcademicsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Initial segment is Syllabus
        expect(
          find.byKey(const Key('academics_add_module_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('academics_add_assignment_button')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('academics_add_exam_button')),
          findsNothing,
        );

        // Tap "Add Module" button
        await tester.tap(find.byKey(const Key('academics_add_module_button')));
        await tester.pumpAndSettle();

        // Verify AddModuleDialog opened (title only)
        expect(find.byKey(const Key('add_module_dialog')), findsOneWidget);
        expect(find.byKey(const Key('add_module_title_field')), findsOneWidget);
        expect(find.text('Exam'), findsNothing);
        expect(find.text('Due Date'), findsNothing);

        // Dismiss dialog
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // 2. Switch to Assignments segment
        await tester.tap(find.text('Assignments'));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('academics_add_module_button')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('academics_add_assignment_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('academics_add_exam_button')),
          findsNothing,
        );

        // Tap "Add Assignment" button
        await tester.tap(
          find.byKey(const Key('academics_add_assignment_button')),
        );
        await tester.pumpAndSettle();

        // Verify AddAssignmentSheet opened (key assertion)
        expect(find.byKey(const Key('add_assignment_sheet')), findsOneWidget);
        expect(
          find.byKey(const Key('add_assignment_title_field')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('add_assignment_date_picker')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('add_assignment_submit_button')),
          findsOneWidget,
        );

        // Verify NO foreign fields
        expect(find.text('Exam Name'), findsNothing);
        expect(find.text('Module Title'), findsNothing);

        // Dismiss sheet
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // 3. Switch to Exams segment
        await tester.tap(find.text('Exams'));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('academics_add_module_button')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('academics_add_assignment_button')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('academics_add_exam_button')),
          findsOneWidget,
        );

        // Tap "Add Exam" button
        await tester.tap(find.byKey(const Key('academics_add_exam_button')));
        await tester.pumpAndSettle();

        // Verify AddExamSheet opened (key assertion)
        expect(find.byKey(const Key('add_exam_sheet')), findsOneWidget);
        expect(find.byKey(const Key('add_exam_title_field')), findsOneWidget);
        expect(find.byKey(const Key('add_exam_date_picker')), findsOneWidget);
        expect(find.byKey(const Key('add_exam_submit_button')), findsOneWidget);

        // Verify NO foreign fields
        expect(find.text('Assignment Title'), findsNothing);
        expect(find.text('Module Title'), findsNothing);

        // Dismiss sheet
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Tapping chapter opens ChapterVaultSheet container with placeholder message',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              subjectsProvider.overrideWith(
                () => TestSubjectsNotifier([testSubject]),
              ),
              modulesProvider.overrideWith(
                () => TestModulesNotifier([testModule]),
              ),
              chaptersProvider.overrideWith(
                () => TestChaptersNotifier([testChapter]),
              ),
              academicItemsProvider.overrideWith(
                () => TestAcademicItemsNotifier([]),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const AcademicsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap the chapter row to open Chapter Vault
        await tester.tap(find.text('Chapter 1.1: Transmission Media'));
        await tester.pumpAndSettle();

        // Assert ChapterVaultSheet opens
        expect(find.byKey(const Key('chapter_vault_sheet')), findsOneWidget);
        expect(
          find.byKey(const Key('chapter_vault_upload_button')),
          findsOneWidget,
        );
        expect(find.text('Chapter 1.1: Transmission Media'), findsWidgets);
      },
    );
  });

  group('Home Academic Radar Widget Tests', () {
    testWidgets(
      'AcademicRadarSlot displays upcoming assignments & exams, and checkbox marks done immediately',
      (tester) async {
        final itemsNotifier = TestAcademicItemsNotifier([
          testAssignment,
          testExam,
        ]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              subjectsProvider.overrideWith(
                () => TestSubjectsNotifier([testSubject]),
              ),
              academicItemsProvider.overrideWith(() => itemsNotifier),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(body: AcademicRadarSlot()),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify both upcoming items exist on the radar
        expect(find.byKey(const Key('academic_radar_slot')), findsOneWidget);
        expect(find.text('Packet Tracer Lab 1'), findsOneWidget);
        expect(find.text('Midterm Exam'), findsOneWidget);
        expect(find.text('2 upcoming'), findsOneWidget);

        // Tap assignment checkbox to complete it
        await tester.tap(
          find.byKey(ValueKey('radar_checkbox_${testAssignment.id}')),
        );
        await tester.pumpAndSettle();

        // Completed assignment disappears immediately from the radar
        expect(find.text('Packet Tracer Lab 1'), findsNothing);
        expect(find.text('Midterm Exam'), findsOneWidget);
        expect(find.text('1 upcoming'), findsOneWidget);
      },
    );

    testWidgets(
      'AcademicRadarSlot displays "All clear." when there are no urgent items',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              subjectsProvider.overrideWith(() => TestSubjectsNotifier([])),
              academicItemsProvider.overrideWith(
                () => TestAcademicItemsNotifier([]),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(body: AcademicRadarSlot()),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('All clear.'), findsOneWidget);
      },
    );
  });
}
