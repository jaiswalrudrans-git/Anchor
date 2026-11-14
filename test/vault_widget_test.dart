import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anchor/core/constants/theme.dart';
import 'package:anchor/core/services/file_vault_service.dart';
import 'package:anchor/models/chapter.dart';
import 'package:anchor/models/chapter_file.dart';
import 'package:anchor/providers/academics_providers.dart';
import 'package:anchor/screens/academics/widgets/chapter_vault_sheet.dart';

class TestChapterFilesNotifier extends ChapterFilesNotifier {
  final List<ChapterFile> _initial;
  TestChapterFilesNotifier(this._initial);

  @override
  Future<List<ChapterFile>> build() async => _initial;

  @override
  Future<void> deleteFile(ChapterFile file) async {
    final current = state.value ?? _initial;
    state = AsyncData(current.where((f) => f.id != file.id).toList());
  }
}

void main() {
  final testChapter = const Chapter(
    id: 'ch-1',
    userId: 'user-1',
    moduleId: 'mod-1',
    title: 'Chapter 1: Network Layers',
    sortOrder: 0,
  );

  final testFile1 = ChapterFile(
    id: 'file-1',
    userId: 'user-1',
    chapterId: 'ch-1',
    fileName: 'lecture_notes_cached.pdf',
    fileType: 'PDF',
    fileSize: 1048576 * 2, // 2 MB
    storagePath: 'user-1/ch-1/lecture_notes_cached.pdf',
    createdAt: DateTime(2026, 11, 10),
  );

  final testFile2 = ChapterFile(
    id: 'file-2',
    userId: 'user-1',
    chapterId: 'ch-1',
    fileName: 'slides_cloud.pptx',
    fileType: 'PPTX',
    fileSize: 524288, // 512 KB
    storagePath: 'user-1/ch-1/slides_cloud.pptx',
    createdAt: DateTime(2026, 11, 12),
  );

  group('ChapterVaultSheet Widget Tests', () {
    testWidgets('Empty state renders "No materials yet." when chapter has no files', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chapterFilesProvider.overrideWith(() => TestChapterFilesNotifier([])),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: ChapterVaultSheet(chapter: testChapter),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('chapter_vault_sheet')), findsOneWidget);
      expect(find.text('CHAPTER VAULT'), findsOneWidget);
      expect(find.text('Chapter 1: Network Layers'), findsOneWidget);
      expect(find.byKey(const Key('chapter_vault_upload_button')), findsOneWidget);
      expect(find.text('+ Upload Material (PPT / PDF)'), findsOneWidget);
      expect(find.byKey(const Key('chapter_vault_empty_state')), findsOneWidget);
      expect(find.text('No materials yet.'), findsOneWidget);
    });

    testWidgets('Displays files with type badge, file name, formatted size, and status badges', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chapterFilesProvider.overrideWith(() => TestChapterFilesNotifier([testFile1, testFile2])),
            fileCacheStatusProvider.overrideWith((ref, file) async {
              return file.fileName.contains('cached')
                  ? VaultFileStatus.cachedOffline
                  : VaultFileStatus.cloudOnly;
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: ChapterVaultSheet(chapter: testChapter),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert file names
      expect(find.text('lecture_notes_cached.pdf'), findsOneWidget);
      expect(find.text('slides_cloud.pptx'), findsOneWidget);

      // Assert type badges
      expect(find.text('PDF'), findsOneWidget);
      expect(find.text('PPTX'), findsOneWidget);

      // Assert sizes
      expect(find.text('2.0 MB'), findsOneWidget);
      expect(find.text('512.0 KB'), findsOneWidget);

      // Assert cache status badges
      expect(find.text('Cached Offline'), findsOneWidget);
      expect(find.text('Cloud Only'), findsOneWidget);

      // Assert delete action buttons
      expect(find.byKey(const ValueKey('vault_delete_file-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('vault_delete_file-2')), findsOneWidget);
    });

    testWidgets('Tapping delete button shows confirmation dialog and deleting removes file from list', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chapterFilesProvider.overrideWith(() => TestChapterFilesNotifier([testFile1])),
            fileCacheStatusProvider.overrideWith((ref, file) async => VaultFileStatus.cachedOffline),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: ChapterVaultSheet(chapter: testChapter),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('lecture_notes_cached.pdf'), findsOneWidget);

      // Tap delete button
      await tester.tap(find.byKey(const ValueKey('vault_delete_file-1')));
      await tester.pumpAndSettle();

      // Confirm dialog appears
      expect(find.text('Delete File'), findsOneWidget);
      expect(find.textContaining('lecture_notes_cached.pdf'), findsWidgets);

      // Tap Delete in dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      // File removed, empty state shown
      expect(find.text('lecture_notes_cached.pdf'), findsNothing);
      expect(find.byKey(const Key('chapter_vault_empty_state')), findsOneWidget);
    });

    testWidgets('Only "+ Upload Material (PPT / PDF)" is the add control; no FAB present', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chapterFilesProvider.overrideWith(() => TestChapterFilesNotifier([testFile1])),
            fileCacheStatusProvider.overrideWith((ref, file) async => VaultFileStatus.cachedOffline),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: ChapterVaultSheet(chapter: testChapter),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert upload button exists
      expect(find.byKey(const Key('chapter_vault_upload_button')), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });
}
