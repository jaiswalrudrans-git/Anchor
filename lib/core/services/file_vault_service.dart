import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../models/chapter_file.dart';

const _uuid = Uuid();

/// Status of a file in the Chapter Vault.
enum VaultFileStatus {
  cachedOffline,
  cloudOnly,
}

/// Service managing offline-first file vault operations:
/// picking, uploading, caching, opening via default OS app, and cascading deletions.
class FileVaultService {
  final SupabaseClient? client;
  static const String bucketName = 'academic_vault';

  FileVaultService({this.client});

  SupabaseClient? get _supabase {
    if (client != null) return client;
    try {
      if (Supabase.instance.isInitialized) {
        return Supabase.instance.client;
      }
    } catch (_) {}
    return null;
  }

  // =========================================================================
  // PURE UTILITY FUNCTIONS (Testable without I/O or Supabase)
  // =========================================================================

  /// Sanitizes a file name by removing illegal filesystem characters and path traversal.
  static String sanitizeFileName(String name) {
    // Strip directory traversal and path separators
    var clean = p.basename(name).trim();
    // Remove characters illegal in Windows and Linux/Android: / \ : * ? " < > | and control chars
    clean = clean.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F\x7F]'), '_');
    // Strip leading/trailing dots or spaces
    clean = clean.replaceAll(RegExp(r'^\.+'), '').trim();
    if (clean.isEmpty || RegExp(r'^[_.\s]+$').hasMatch(clean)) {
      return 'file';
    }
    return clean;
  }

  /// Resolves duplicate file names by appending " (1)", " (2)", etc. before the extension.
  static String resolveDuplicateName(String originalName, List<String> existingNames) {
    final lowerExisting = existingNames.map((n) => n.toLowerCase()).toSet();
    final sanitized = sanitizeFileName(originalName);

    if (!lowerExisting.contains(sanitized.toLowerCase())) {
      return sanitized;
    }

    final ext = p.extension(sanitized);
    final base = p.basenameWithoutExtension(sanitized);

    int counter = 1;
    while (true) {
      final candidate = '$base ($counter)$ext';
      if (!lowerExisting.contains(candidate.toLowerCase())) {
        return candidate;
      }
      counter++;
    }
  }

  /// Formats byte count to a readable KB/MB string.
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      final kb = bytes / 1024.0;
      return '${kb.toStringAsFixed(1)} KB';
    } else {
      final mb = bytes / (1024.0 * 1024.0);
      return '${mb.toStringAsFixed(1)} MB';
    }
  }

  /// Checks whether a local file exists and matches the expected file size.
  static bool isFileCachedOnDisk({
    required String localPath,
    required int expectedSize,
  }) {
    try {
      final file = File(localPath);
      if (!file.existsSync()) return false;
      return file.lengthSync() == expectedSize;
    } catch (_) {
      return false;
    }
  }

  // =========================================================================
  // LOCAL PATH RESOLUTION
  // =========================================================================

  /// Returns the local cache directory for a given chapter:
  /// `{getApplicationDocumentsDirectory()}/vault/{chapter_id}`.
  Future<Directory> getChapterDirectory(String chapterId) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docsDir.path, 'vault', chapterId));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Returns the full local path for a chapter file.
  Future<String> getLocalPath(String chapterId, String fileName) async {
    final dir = await getChapterDirectory(chapterId);
    return p.join(dir.path, fileName);
  }

  /// Computes the cache status for a [ChapterFile].
  Future<VaultFileStatus> getFileStatus(ChapterFile file) async {
    final localPath = await getLocalPath(file.chapterId, file.fileName);
    final cached = isFileCachedOnDisk(localPath: localPath, expectedSize: file.fileSize);
    return cached ? VaultFileStatus.cachedOffline : VaultFileStatus.cloudOnly;
  }

  // =========================================================================
  // VAULT CRUD & STORAGE OPERATIONS
  // =========================================================================

  /// Fetches all files associated with a chapter from the database.
  Future<List<ChapterFile>> fetchChapterFiles(String chapterId) async {
    final client = _supabase;
    if (client == null) return [];

    try {
      final response = await client
          .from('chapter_files')
          .select()
          .eq('chapter_id', chapterId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) => ChapterFile.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('FileVaultService.fetchChapterFiles failed: $e');
      return [];
    }
  }

  /// Opens the file picker, uploads chosen materials to Supabase Storage,
  /// saves their database records, and immediately caches them locally.
  Future<List<ChapterFile>> pickAndUploadFiles({
    required String chapterId,
    required List<String> existingFileNames,
    void Function(String fileName, double progress)? onProgress,
  }) async {
    final client = _supabase;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw StateError('User not authenticated');
    }

    final pickedFiles = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf', 'ppt', 'pptx', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'png', 'jpg', 'jpeg'
      ],
    );

    if (pickedFiles.isEmpty) {
      return [];
    }

    final currentNames = List<String>.from(existingFileNames);
    final uploadedFiles = <ChapterFile>[];

    for (final picked in pickedFiles) {
      final rawName = picked.name;
      final finalName = resolveDuplicateName(rawName, currentNames);
      currentNames.add(finalName);

      final ext = p.extension(finalName).replaceAll('.', '').toUpperCase();
      final storagePath = '${user.id}/$chapterId/$finalName';

      // Read file bytes
      final Uint8List bytes = await picked.readAsBytes();
      final fileSize = bytes.length;

      // 1. Upload to Supabase Storage
      try {
        await client.storage.from(bucketName).uploadBinary(
              storagePath,
              bytes,
              fileOptions: const FileOptions(upsert: true),
            );
      } catch (storageError) {
        debugPrint('FileVaultService: storage upload error for $finalName: $storageError');
        rethrow;
      }

      // 2. Insert into chapter_files database table
      final newFile = ChapterFile(
        id: _uuid.v4(),
        userId: user.id,
        chapterId: chapterId,
        fileName: finalName,
        fileType: ext.isEmpty ? 'FILE' : ext,
        fileSize: fileSize,
        storagePath: storagePath,
        createdAt: DateTime.now(),
      );

      try {
        await client.from('chapter_files').insert(newFile.toJson());
      } catch (dbError) {
        // Rollback: delete storage object on database insert failure (no orphans)
        debugPrint('FileVaultService: DB insert failed. Deleting uploaded storage object: $dbError');
        try {
          await client.storage.from(bucketName).remove([storagePath]);
        } catch (_) {}
        rethrow;
      }

      // 3. Cache file locally on this device so uploading device is Cached Offline immediately
      try {
        final localPath = await getLocalPath(chapterId, finalName);
        final localFile = File(localPath);
        await localFile.writeAsBytes(bytes, flush: true);
      } catch (cacheError) {
        debugPrint('FileVaultService: local caching failed for $finalName: $cacheError');
      }

      uploadedFiles.add(newFile);
    }

    return uploadedFiles;
  }

  /// Opens a file in the OS default application.
  /// If not cached, downloads it to a temporary file first, verifies size,
  /// moves it to the permanent cache path, and then opens it.
  Future<OpenResult> openFile(
    ChapterFile file, {
    void Function(double progress)? onDownloadProgress,
  }) async {
    final localPath = await getLocalPath(file.chapterId, file.fileName);

    // If not cached, download from Supabase Storage
    if (!isFileCachedOnDisk(localPath: localPath, expectedSize: file.fileSize)) {
      final client = _supabase;
      if (client == null) {
        return OpenResult(
          type: ResultType.error,
          message: 'Not downloaded yet and no connection.',
        );
      }

      // Download bytes from Storage
      Uint8List bytes;
      try {
        bytes = await client.storage.from(bucketName).download(file.storagePath);
      } catch (e) {
        debugPrint('FileVaultService.openFile download error: $e');
        return OpenResult(
          type: ResultType.error,
          message: 'Not downloaded yet and no connection.',
        );
      }

      // Write to a temporary file first to prevent partial downloads
      final tempPath = '$localPath.tmp';
      final tempFile = File(tempPath);
      try {
        await tempFile.writeAsBytes(bytes, flush: true);

        // Verify size before renaming
        if (tempFile.lengthSync() == file.fileSize) {
          if (await File(localPath).exists()) {
            await File(localPath).delete();
          }
          await tempFile.rename(localPath);
        } else {
          await tempFile.delete();
          return OpenResult(
            type: ResultType.error,
            message: 'Download incomplete. Please try again.',
          );
        }
      } catch (e) {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
        return OpenResult(
          type: ResultType.error,
          message: 'Failed to write local file: $e',
        );
      }
    }

    // Open with the OS default viewer
    try {
      return await OpenFilex.open(localPath);
    } catch (e) {
      debugPrint('FileVaultService: OpenFilex error: $e');
      return OpenResult(
        type: ResultType.error,
        message: 'No application available to open ${file.fileType} files.',
      );
    }
  }

  /// Deletes a file completely: from Storage, local cache, and the database.
  /// If Storage deletion fails, DB row is retained (no half-deleted state).
  Future<void> deleteFile(ChapterFile file) async {
    final client = _supabase;
    if (client == null) throw StateError('Supabase uninitialized');

    // 1. Delete from Supabase Storage
    try {
      await client.storage.from(bucketName).remove([file.storagePath]);
    } catch (e) {
      debugPrint('FileVaultService.deleteFile Storage error: $e');
      rethrow;
    }

    // 2. Delete local cache file if exists
    try {
      final localPath = await getLocalPath(file.chapterId, file.fileName);
      final localFile = File(localPath);
      if (await localFile.exists()) {
        await localFile.delete();
      }
    } catch (e) {
      debugPrint('FileVaultService.deleteFile local cache delete error: $e');
    }

    // 3. Delete database row
    try {
      await client.from('chapter_files').delete().eq('id', file.id);
    } catch (e) {
      debugPrint('FileVaultService.deleteFile DB delete error: $e');
      rethrow;
    }
  }

  // =========================================================================
  // CASCADING CLEANUP HOOKS (Chapters, Modules, Subjects)
  // =========================================================================

  /// Hook called before a chapter is deleted: removes all associated Storage objects
  /// and deletes the local cache directory `{vault}/{chapterId}`.
  Future<void> onChapterRemoved(String chapterId) async {
    final client = _supabase;
    if (client == null) return;

    try {
      // 1. Query all files for this chapter before DB cascade runs
      final response = await client
          .from('chapter_files')
          .select('storage_path')
          .eq('chapter_id', chapterId);

      final List<dynamic> data = response as List<dynamic>;
      final storagePaths = data
          .map((row) => row['storage_path'] as String?)
          .whereType<String>()
          .toList();

      // 2. Delete all files in bulk from Supabase Storage
      if (storagePaths.isNotEmpty) {
        await client.storage.from(bucketName).remove(storagePaths);
      }

      // 3. Delete local chapter directory
      final docsDir = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docsDir.path, 'vault', chapterId));
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('FileVaultService.onChapterRemoved error: $e');
    }
  }

  /// Hook called before a module is deleted: removes storage objects and local folders
  /// for all nested chapters.
  Future<void> onModuleRemoved(String moduleId) async {
    final client = _supabase;
    if (client == null) return;

    try {
      final response = await client
          .from('chapters')
          .select('id')
          .eq('module_id', moduleId);

      final List<dynamic> data = response as List<dynamic>;
      for (final row in data) {
        final chapterId = row['id'] as String;
        await onChapterRemoved(chapterId);
      }
    } catch (e) {
      debugPrint('FileVaultService.onModuleRemoved error: $e');
    }
  }

  /// Hook called before a subject is deleted: removes storage objects and local folders
  /// for all chapters across all modules.
  Future<void> onSubjectRemoved(String subjectId) async {
    final client = _supabase;
    if (client == null) return;

    try {
      final response = await client
          .from('modules')
          .select('id')
          .eq('subject_id', subjectId);

      final List<dynamic> data = response as List<dynamic>;
      for (final row in data) {
        final moduleId = row['id'] as String;
        await onModuleRemoved(moduleId);
      }
    } catch (e) {
      debugPrint('FileVaultService.onSubjectRemoved error: $e');
    }
  }
}

/// Provider for the singleton [FileVaultService].
final fileVaultServiceProvider = Provider<FileVaultService>((ref) {
  return FileVaultService();
});
