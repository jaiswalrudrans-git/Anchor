import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme.dart';
import '../../../models/chapter.dart';
import '../../../models/module.dart';
import '../../../models/subject.dart';
import '../../../providers/academics_providers.dart';
import '../../../widgets/empty_state.dart';
import 'add_chapter_dialog.dart';
import 'add_module_dialog.dart';
import 'chapter_vault_sheet.dart';

/// Syllabus tree displaying modules and nested chapters for the selected subject.
class SyllabusTab extends ConsumerWidget {
  final Subject? selectedSubject;

  const SyllabusTab({
    super.key,
    required this.selectedSubject,
  });

  Future<void> _confirmDeleteModule(
      BuildContext context, WidgetRef ref, AcademicModule module) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Module'),
        content: Text(
          'Delete "${module.title}"? All nested chapters and files will be permanently deleted.',
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
      await ref.read(modulesProvider.notifier).deleteModule(module.id);
    }
  }

  Future<void> _promptRenameModule(
      BuildContext context, WidgetRef ref, AcademicModule module) async {
    final controller = TextEditingController(text: module.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Module'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Module title'),
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

    if (newTitle != null && newTitle.isNotEmpty && newTitle != module.title) {
      await ref.read(modulesProvider.notifier).renameModule(module.id, newTitle);
    }
  }

  Future<void> _confirmDeleteChapter(
      BuildContext context, WidgetRef ref, Chapter chapter) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Chapter'),
        content: Text(
          'Delete "${chapter.title}"? All attached files in the vault will be removed.',
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
      await ref.read(chaptersProvider.notifier).deleteChapter(chapter.id);
    }
  }

  Future<void> _promptRenameChapter(
      BuildContext context, WidgetRef ref, Chapter chapter) async {
    final controller = TextEditingController(text: chapter.title);
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

    if (newTitle != null && newTitle.isNotEmpty && newTitle != chapter.title) {
      await ref.read(chaptersProvider.notifier).renameChapter(chapter.id, newTitle);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectedSubject == null) {
      return const EmptyState(
        icon: Icons.school_outlined,
        title: 'No subjects yet',
        message: 'Tap "+ Subject" above to create your first academic subject.',
      );
    }

    final modules = ref.watch(modulesForSelectedSubjectProvider);
    final chaptersAsync = ref.watch(chaptersProvider);
    final allChapters = chaptersAsync.value ?? [];

    if (modules.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: EmptyState(
          icon: Icons.view_list_outlined,
          title: 'No modules yet',
          message: 'Add a module to organize chapters for ${selectedSubject!.name}.',
          action: OutlinedButton.icon(
            key: const Key('syllabus_empty_add_module_button'),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Module'),
            onPressed: () => AddModuleDialog.show(context, selectedSubject!.id),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        final moduleChapters = sortChapters(
          allChapters.where((c) => c.moduleId == module.id).toList(),
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 12.0),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: AppTheme.borderRadius8,
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              key: PageStorageKey('module_${module.id}'),
              initiallyExpanded: index == 0,
              tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              title: Text(
                module.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              subtitle: Text(
                '${moduleChapters.length} chapter${moduleChapters.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.secondaryText,
                ),
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                shape: RoundedRectangleBorder(
                  side: AppTheme.borderSide1,
                  borderRadius: AppTheme.borderRadius8,
                ),
                onSelected: (val) {
                  if (val == 'rename') {
                    _promptRenameModule(context, ref, module);
                  } else if (val == 'delete') {
                    _confirmDeleteModule(context, ref, module);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'rename',
                    child: Text('Rename Module'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete Module', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
              children: [
                const Divider(height: 1, color: AppColors.border),
                if (moduleChapters.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'No chapters yet.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        TextButton.icon(
                          key: Key('syllabus_add_chapter_button_${module.id}'),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Chapter'),
                          onPressed: () => AddChapterDialog.show(context, module.id),
                        ),
                      ],
                    ),
                  )
                else ...[
                  ...moduleChapters.map((chapter) {
                    return ListTile(
                      key: ValueKey('chapter_${chapter.id}'),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                      leading: const Icon(
                        Icons.description_outlined,
                        size: 20,
                        color: AppColors.primaryText,
                      ),
                      title: Text(
                        chapter.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryText,
                        ),
                      ),
                      subtitle: const Text(
                        'Tap to open Vault',
                        style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz, size: 18),
                        shape: RoundedRectangleBorder(
                          side: AppTheme.borderSide1,
                          borderRadius: AppTheme.borderRadius8,
                        ),
                        onSelected: (val) {
                          if (val == 'rename') {
                            _promptRenameChapter(context, ref, chapter);
                          } else if (val == 'delete') {
                            _confirmDeleteChapter(context, ref, chapter);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'rename',
                            child: Text('Rename Chapter'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete Chapter', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                      onTap: () => ChapterVaultSheet.show(context, chapter),
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        key: Key('syllabus_add_chapter_button_${module.id}'),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Chapter'),
                        onPressed: () => AddChapterDialog.show(context, module.id),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
