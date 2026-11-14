import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:anchor/core/services/file_vault_service.dart';

void main() {
  group('File Name Sanitizer Unit Tests', () {
    test('sanitizeFileName removes Windows and Unix forbidden characters', () {
      expect(FileVaultService.sanitizeFileName('lecture:1*intro?.pdf'), 'lecture_1_intro_.pdf');
      expect(FileVaultService.sanitizeFileName('report<2026>|final".docx'), 'report_2026__final_.docx');
      expect(FileVaultService.sanitizeFileName('path/to/my file.ppt'), 'my file.ppt');
      expect(FileVaultService.sanitizeFileName(r'C:\Users\Student\Desktop\notes.txt'), 'notes.txt');
    });

    test('sanitizeFileName strips leading dots and path traversal', () {
      expect(FileVaultService.sanitizeFileName('../../../etc/passwd.pdf'), 'passwd.pdf');
      expect(FileVaultService.sanitizeFileName('.hidden_notes.docx'), 'hidden_notes.docx');
      expect(FileVaultService.sanitizeFileName('...dots.txt'), 'dots.txt');
    });

    test('sanitizeFileName falls back to "file" on empty or all-illegal names', () {
      expect(FileVaultService.sanitizeFileName(''), 'file');
      expect(FileVaultService.sanitizeFileName('   '), 'file');
      expect(FileVaultService.sanitizeFileName('...'), 'file');
      expect(FileVaultService.sanitizeFileName('///'), 'file');
    });

    test('sanitizeFileName leaves clean filenames untouched', () {
      expect(FileVaultService.sanitizeFileName('Maths_Chapter_1.pdf'), 'Maths_Chapter_1.pdf');
      expect(FileVaultService.sanitizeFileName('DSA Syllabus 2026.docx'), 'DSA Syllabus 2026.docx');
    });
  });

  group('Duplicate Name Resolution Unit Tests', () {
    test('resolveDuplicateName returns same name when no collision exists', () {
      final existing = ['chapter1.pdf', 'notes.docx'];
      expect(FileVaultService.resolveDuplicateName('chapter2.pdf', existing), 'chapter2.pdf');
    });

    test('resolveDuplicateName appends (1) on first collision', () {
      final existing = ['chapter1.pdf', 'notes.docx'];
      expect(FileVaultService.resolveDuplicateName('chapter1.pdf', existing), 'chapter1 (1).pdf');
    });

    test('resolveDuplicateName handles multiple collisions sequentially', () {
      final existing = ['notes.pdf', 'notes (1).pdf', 'notes (2).pdf'];
      expect(FileVaultService.resolveDuplicateName('notes.pdf', existing), 'notes (3).pdf');
    });

    test('resolveDuplicateName is case-insensitive', () {
      final existing = ['Notes.PDF'];
      expect(FileVaultService.resolveDuplicateName('notes.pdf', existing), 'notes (1).pdf');
    });

    test('resolveDuplicateName works on files without extensions', () {
      final existing = ['README'];
      expect(FileVaultService.resolveDuplicateName('README', existing), 'README (1)');
    });
  });

  group('File Size Formatting Unit Tests', () {
    test('formatFileSize formats bytes, kilobytes, and megabytes accurately', () {
      expect(FileVaultService.formatFileSize(0), '0 B');
      expect(FileVaultService.formatFileSize(500), '500 B');
      expect(FileVaultService.formatFileSize(1023), '1023 B');
      expect(FileVaultService.formatFileSize(1024), '1.0 KB');
      expect(FileVaultService.formatFileSize(1536), '1.5 KB');
      expect(FileVaultService.formatFileSize(1048576), '1.0 MB');
      expect(FileVaultService.formatFileSize(1048576 * 5 + 524288), '5.5 MB');
    });
  });

  group('Local Disk Cache Status Unit Tests', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('anchor_vault_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('isFileCachedOnDisk returns false when file does not exist', () {
      final missingPath = '${tempDir.path}/nonexistent.pdf';
      expect(
        FileVaultService.isFileCachedOnDisk(localPath: missingPath, expectedSize: 100),
        isFalse,
      );
    });

    test('isFileCachedOnDisk returns true when file exists and size matches', () {
      final testFile = File('${tempDir.path}/test_cached.pdf');
      final bytes = List<int>.generate(256, (i) => i % 256);
      testFile.writeAsBytesSync(bytes, flush: true);

      expect(
        FileVaultService.isFileCachedOnDisk(localPath: testFile.path, expectedSize: 256),
        isTrue,
      );
    });

    test('isFileCachedOnDisk returns false when file exists but size mismatches (partial file)', () {
      final testFile = File('${tempDir.path}/partial.pdf');
      final bytes = List<int>.generate(100, (i) => i % 256);
      testFile.writeAsBytesSync(bytes, flush: true);

      // Expected size is 256, but file on disk has only 100 bytes
      expect(
        FileVaultService.isFileCachedOnDisk(localPath: testFile.path, expectedSize: 256),
        isFalse,
      );
    });
  });
}
