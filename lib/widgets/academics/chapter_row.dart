import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/dimens.dart';
import '../../core/constants/theme.dart';
import '../../models/chapter.dart';
import '../../providers/academics_providers.dart';
import '../../screens/academics/widgets/chapter_vault_sheet.dart';
import '../../widgets/motion/animated_checkbox.dart';

/// Row for a syllabus chapter with studied toggle, file count badge, and vault opener.
class ChapterRow extends ConsumerStatefulWidget {
  final Chapter chapter;
  final VoidCallback? onChapterStudiedToggled;

  const ChapterRow({
    super.key,
    required this.chapter,
    this.onChapterStudiedToggled,
  });

  @override
  ConsumerState<ChapterRow> createState() => _ChapterRowState();
}

class _ChapterRowState extends ConsumerState<ChapterRow> {
  Future<void> _handleToggleStudied() async {
    try {
      await ref
          .read(chaptersProvider.notifier)
          .toggleStudied(widget.chapter.id);
      widget.onChapterStudiedToggled?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update chapter: $e')));
      }
    }
  }

  Future<void> _promptRename(BuildContext context) async {
    final controller = TextEditingController(text: widget.chapter.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Chapter'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Chapter title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newTitle != null &&
        newTitle.isNotEmpty &&
        newTitle != widget.chapter.title) {
      await ref
          .read(chaptersProvider.notifier)
          .renameChapter(widget.chapter.id, newTitle);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Chapter'),
        content: Text(
          'Delete "${widget.chapter.title}"? All attached files in the vault will be removed.',
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
      await ref
          .read(chaptersProvider.notifier)
          .deleteChapter(widget.chapter.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fileCount = ref.watch(chapterFileCountProvider(widget.chapter.id));
    final isStudied = widget.chapter.isStudied;

    return Container(
      key: ValueKey('chapter_${widget.chapter.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: AppDimens.borderRadiusSm,
        border: Border.all(color: palette.border, width: AppDimens.hairline),
      ),
      child: InkWell(
        borderRadius: AppDimens.borderRadiusSm,
        onTap: () => ChapterVaultSheet.show(context, widget.chapter),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          child: Row(
            children: [
              // Studied toggle checkbox
              SizedBox(
                width: 24,
                height: 24,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: 0.0,
                      child: Checkbox(
                        key: ValueKey('chapter_checkbox_${widget.chapter.id}'),
                        value: isStudied,
                        onChanged: (_) => _handleToggleStudied(),
                      ),
                    ),
                    IgnorePointer(
                      child: AnimatedCheckbox(value: isStudied, size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Title (dimmed when studied, no strikethrough)
              Expanded(
                child: Text(
                  widget.chapter.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isStudied ? FontWeight.w400 : FontWeight.w500,
                    color: isStudied
                        ? palette.textSecondary
                        : palette.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // File count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: palette.cardRaised,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: palette.border,
                    width: AppDimens.hairline,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.attach_file,
                      size: 11,
                      color: fileCount > 0 ? palette.accent : palette.textMuted,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$fileCount',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: fileCount > 0
                            ? palette.textPrimary
                            : palette.textMuted,
                        fontFeatures: AppTypography.tabularFigures,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),

              // Context menu (rename / delete)
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: 16,
                  color: palette.textSecondary,
                ),
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: palette.border,
                    width: AppDimens.hairline,
                  ),
                  borderRadius: AppDimens.borderRadiusSm,
                ),
                color: palette.cardRaised,
                onSelected: (val) {
                  if (val == 'rename') {
                    _promptRename(context);
                  } else if (val == 'delete') {
                    _confirmDelete(context);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'rename',
                    child: Text(
                      'Rename Chapter',
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete Chapter',
                      style: TextStyle(color: palette.danger, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
