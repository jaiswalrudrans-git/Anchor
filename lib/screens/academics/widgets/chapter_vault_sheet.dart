import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/constants/theme.dart';
import '../../../core/services/file_vault_service.dart';
import '../../../models/chapter.dart';
import '../../../models/chapter_file.dart';
import '../../../providers/academics_providers.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/loading_state.dart';

/// Chapter Vault modal sheet / dialog.
/// Displays study materials for a chapter, allows uploading (PDF, PPT, DOC, etc.),
/// caches files offline on disk, shows Cached Offline / Cloud Only status,
/// opens materials via OS default application, and deletes files everywhere.
class ChapterVaultSheet extends ConsumerStatefulWidget {
  final Chapter chapter;

  const ChapterVaultSheet({
    super.key,
    required this.chapter,
  });

  /// Opens the Chapter Vault as a bottom sheet on mobile or dialog on desktop.
  static Future<void> show(BuildContext context, Chapter chapter) {
    final isDesktop = MediaQuery.of(context).size.width >= 700;

    if (isDesktop) {
      return showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            side: AppTheme.borderSide1,
            borderRadius: AppTheme.borderRadius8,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 680),
            child: ChapterVaultSheet(chapter: chapter),
          ),
        ),
      );
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.maxRadius)),
      ),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: ChapterVaultSheet(chapter: chapter),
      ),
    );
  }

  @override
  ConsumerState<ChapterVaultSheet> createState() => _ChapterVaultSheetState();
}

class _ChapterVaultSheetState extends ConsumerState<ChapterVaultSheet> {
  bool _isUploading = false;
  String? _openingFileId;

  Future<void> _handleUpload() async {
    setState(() => _isUploading = true);

    try {
      final uploaded = await ref
          .read(chapterFilesProvider.notifier)
          .pickAndUpload(chapterId: widget.chapter.id);

      if (mounted && uploaded.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Uploaded ${uploaded.length} file${uploaded.length == 1 ? '' : 's'} (Cached Offline).',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _handleOpenFile(ChapterFile file) async {
    setState(() => _openingFileId = file.id);

    try {
      final result = await ref.read(fileVaultServiceProvider).openFile(file);

      // Refresh status provider so badge flips to Cached Offline
      ref.invalidate(fileCacheStatusProvider(file));

      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message.isNotEmpty
                  ? result.message
                  : 'No application found on device to open .${file.fileType} files.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open file: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _openingFileId = null);
      }
    }
  }

  Future<void> _confirmDelete(ChapterFile file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete File'),
        content: Text(
          'Delete "${file.fileName}"?\nThis removes the file from cloud storage and local offline cache.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref
            .read(chapterFilesProvider.notifier)
            .deleteFile(file);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e')),
          );
        }
      }
    }
  }

  Widget _buildFileRow(ChapterFile file) {
    final isOpening = _openingFileId == file.id;
    final statusAsync = ref.watch(fileCacheStatusProvider(file));

    return Container(
      key: ValueKey('vault_file_${file.id}'),
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        borderRadius: AppTheme.borderRadius8,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Material(
        color: AppColors.background,
        borderRadius: AppTheme.borderRadius8,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          onTap: isOpening ? null : () => _handleOpenFile(file),
          leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Center(
            child: Text(
              file.fileType.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        title: Text(
          file.fileName,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(
              FileVaultService.formatFileSize(file.fileSize),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(width: 8),
            const Text('•', style: TextStyle(color: AppColors.secondaryText)),
            const SizedBox(width: 8),
            statusAsync.when(
              data: (status) {
                final isCached = status == VaultFileStatus.cachedOffline;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCached ? Icons.offline_pin_outlined : Icons.cloud_outlined,
                      size: 13,
                      color: isCached ? AppColors.primaryText : AppColors.secondaryText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isCached ? 'Cached Offline' : 'Cloud Only',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isCached ? FontWeight.w600 : FontWeight.normal,
                        color: isCached ? AppColors.primaryText : AppColors.secondaryText,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Text(
                'Checking...',
                style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
              ),
              error: (err, stack) => const Text(
                'Unknown',
                style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOpening)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                key: ValueKey('vault_delete_${file.id}'),
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppColors.secondaryText,
                onPressed: () => _confirmDelete(file),
              ),
          ],
        ),
      ),
    ),);
  }

  @override
  Widget build(BuildContext context) {
    final filesAsync = ref.watch(chapterFilesProvider);
    final files = ref.watch(chapterFilesForChapterProvider(widget.chapter.id));

    return Padding(
      key: const Key('chapter_vault_sheet'),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Chapter title, refresh, close
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CHAPTER VAULT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryText,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.chapter.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('chapter_vault_refresh_button'),
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Refresh files',
                onPressed: () {
                  ref.read(chapterFilesProvider.notifier).refresh();
                },
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
                splashRadius: 18,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action: Upload Material Button (ONLY add control in the vault)
          ElevatedButton.icon(
            key: const Key('chapter_vault_upload_button'),
            icon: _isUploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.background,
                    ),
                  )
                : const Icon(Icons.upload_file_outlined, size: 18),
            label: Text(
              _isUploading ? 'Uploading Material...' : '+ Upload Material (PPT / PDF)',
              style: const TextStyle(fontSize: 13),
            ),
            onPressed: _isUploading ? null : _handleUpload,
          ),
          const SizedBox(height: 16),

          // File List
          Expanded(
            child: filesAsync.when(
              data: (_) {
                if (files.isEmpty) {
                  return const EmptyState(
                    key: Key('chapter_vault_empty_state'),
                    icon: Icons.inventory_2_outlined,
                    title: 'No materials yet.',
                    message:
                        'Upload lecture slides, notes, or past papers for offline access.',
                  );
                }

                return ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (ctx, index) => _buildFileRow(files[index]),
                );
              },
              loading: () => const Center(
                child: LoadingState(message: 'Loading chapter files...'),
              ),
              error: (err, _) => Center(
                child: Text(
                  'Failed to load files: $err',
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
