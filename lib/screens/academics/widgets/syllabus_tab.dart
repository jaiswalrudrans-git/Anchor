import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/dimens.dart';
import '../../../core/constants/motion.dart';
import '../../../core/constants/theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/module.dart';
import '../../../models/subject.dart';
import '../../../providers/academics_providers.dart';
import '../../../widgets/academics/chapter_row.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/motion/animated_progress_bar.dart';
import '../../../widgets/motion/pulse_ring.dart';
import 'add_chapter_dialog.dart';
import 'add_module_dialog.dart';

/// Syllabus tree displaying modules and chapters for the selected subject.
/// Features overall studied percentage card, module progress bars, chapter studied ticks,
/// and a two-pane layout on expanded widths (>= 900 dp).
class SyllabusTab extends ConsumerStatefulWidget {
  final Subject? selectedSubject;

  const SyllabusTab({super.key, required this.selectedSubject});

  @override
  ConsumerState<SyllabusTab> createState() => _SyllabusTabState();
}

class _SyllabusTabState extends ConsumerState<SyllabusTab> {
  final Set<String> _expandedModuleIds = {};
  String? _selectedModuleId;
  String? _pulsingModuleId;

  @override
  void initState() {
    super.initState();
  }

  void _toggleModuleExpanded(String moduleId) {
    setState(() {
      if (_expandedModuleIds.contains(moduleId)) {
        _expandedModuleIds.remove(moduleId);
      } else {
        _expandedModuleIds.add(moduleId);
      }
    });
  }

  void _triggerModulePulse(String moduleId) {
    setState(() => _pulsingModuleId = moduleId);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _pulsingModuleId == moduleId) {
        setState(() => _pulsingModuleId = null);
      }
    });
  }

  Future<void> _confirmDeleteModule(
    BuildContext context,
    AcademicModule module,
  ) async {
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
    BuildContext context,
    AcademicModule module,
  ) async {
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
      await ref
          .read(modulesProvider.notifier)
          .renameModule(module.id, newTitle);
    }
  }

  Widget _buildSubjectHeaderCard(
    Subject subject,
    SubjectSyllabusStats stats,
    AppPalette palette,
  ) {
    final pct = (stats.progress * 100).round();
    final moduleWord = stats.totalModules == 1 ? 'module' : 'modules';
    final chapterWord = stats.totalChapters == 1 ? 'chapter' : 'chapters';

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: AppDimens.borderRadiusMd,
        border: Border.all(color: palette.border, width: AppDimens.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subject.name,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$pct% studied',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: palette.accent,
                  fontFeatures: AppTypography.tabularFigures,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedProgressBar(value: stats.progress, height: 6.0),
          const SizedBox(height: 10),
          Text(
            '${stats.totalModules} $moduleWord · ${stats.totalChapters} $chapterWord (${stats.studiedChapters} studied)',
            style: TextStyle(fontSize: 12, color: palette.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard({
    required AcademicModule module,
    required ModuleSyllabusStats stats,
    required bool isExpanded,
    required bool isSelectedInWide,
    required bool isWideLayout,
    required AppPalette palette,
  }) {
    final allChapters = ref.watch(chaptersProvider).value ?? [];
    final moduleChapters = sortChapters(
      allChapters.where((c) => c.moduleId == module.id).toList(),
    );

    final isPulsing = _pulsingModuleId == module.id;

    Widget progressBar = AnimatedProgressBar(
      value: stats.progress,
      height: 4.0,
    );

    if (isPulsing) {
      progressBar = PulseRing(
        trigger: true,
        duration: Motion.moment,
        child: progressBar,
      );
    }

    final cardHeader = InkWell(
      onTap: isWideLayout
          ? () => setState(() => _selectedModuleId = module.id)
          : () => _toggleModuleExpanded(module.id),
      borderRadius: AppDimens.borderRadiusSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    module.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: palette.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${stats.studiedChapters}/${stats.totalChapters} chapters',
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.textSecondary,
                    fontFeatures: AppTypography.tabularFigures,
                  ),
                ),
                const SizedBox(width: 4),
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
                      _promptRenameModule(context, module);
                    } else if (val == 'delete') {
                      _confirmDeleteModule(context, module);
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'rename',
                      child: Text(
                        'Rename Module',
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete Module',
                        style: TextStyle(color: palette.danger, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                if (!isWideLayout)
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: palette.textSecondary,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            progressBar,
          ],
        ),
      ),
    );

    return AppCard(
      key: ValueKey('module_${module.id}'),
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: EdgeInsets.zero,
      borderColor: isSelectedInWide ? palette.accent : palette.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          cardHeader,
          if (!isWideLayout && isExpanded) ...[
            Divider(height: 1, color: palette.border),
            const SizedBox(height: 6),
            if (moduleChapters.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'No chapters yet.',
                      style: TextStyle(
                        fontSize: 13,
                        color: palette.textSecondary,
                      ),
                    ),
                    TextButton.icon(
                      key: Key('syllabus_add_chapter_button_${module.id}'),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Chapter'),
                      onPressed: () =>
                          AddChapterDialog.show(context, module.id),
                    ),
                  ],
                ),
              )
            else ...[
              ...moduleChapters.map(
                (chapter) => ChapterRow(
                  key: ValueKey('chapter_${chapter.id}'),
                  chapter: chapter,
                  onChapterStudiedToggled: () {
                    // Check if module just reached 100%
                    if (stats.studiedChapters == stats.totalChapters - 1) {
                      _triggerModulePulse(module.id);
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 12.0,
                  top: 4.0,
                  bottom: 8.0,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: Key('syllabus_add_chapter_button_${module.id}'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(
                      'Add Chapter',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: () => AddChapterDialog.show(context, module.id),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildRightPaneDetail(
    AcademicModule module,
    ModuleSyllabusStats stats,
    AppPalette palette,
  ) {
    final allChapters = ref.watch(chaptersProvider).value ?? [];
    final moduleChapters = sortChapters(
      allChapters.where((c) => c.moduleId == module.id).toList(),
    );

    return AppCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  module.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Text(
                '${stats.studiedChapters}/${stats.totalChapters} studied',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: palette.accent,
                  fontFeatures: AppTypography.tabularFigures,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedProgressBar(value: stats.progress, height: 4.0),
          const SizedBox(height: 16),
          Divider(height: 1, color: palette.border),
          const SizedBox(height: 12),
          if (moduleChapters.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'No chapters yet in this module.',
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      key: Key('syllabus_add_chapter_button_${module.id}'),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Chapter'),
                      onPressed: () =>
                          AddChapterDialog.show(context, module.id),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            ...moduleChapters.map(
              (chapter) => ChapterRow(
                key: ValueKey('chapter_${chapter.id}'),
                chapter: chapter,
                onChapterStudiedToggled: () {
                  if (stats.studiedChapters == stats.totalChapters - 1) {
                    _triggerModulePulse(module.id);
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: Key('syllabus_add_chapter_button_${module.id}'),
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  'Add Chapter',
                  style: TextStyle(fontSize: 12),
                ),
                onPressed: () => AddChapterDialog.show(context, module.id),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedSubject == null) {
      return const EmptyState(
        icon: Icons.school_outlined,
        title: 'No subjects yet',
        message: 'Tap "+ Subject" above to create your first academic subject.',
      );
    }

    final palette = context.palette;
    final modules = ref.watch(modulesForSelectedSubjectProvider);
    final subjectStats = ref.watch(
      subjectSyllabusStatsProvider(widget.selectedSubject!.id),
    );

    if (modules.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: EmptyState(
          icon: Icons.view_list_outlined,
          title: 'No modules yet',
          message:
              'Add a module to organize chapters for ${widget.selectedSubject!.name}.',
          action: OutlinedButton.icon(
            key: const Key('syllabus_empty_add_module_button'),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Module'),
            onPressed: () =>
                AddModuleDialog.show(context, widget.selectedSubject!.id),
          ),
        ),
      );
    }

    // Default first module expanded initially
    if (_expandedModuleIds.isEmpty && modules.isNotEmpty) {
      _expandedModuleIds.add(modules.first.id);
    }

    final isWide = Breakpoints.isExpanded(context);
    final activeSelectedModuleId =
        _selectedModuleId != null &&
            modules.any((m) => m.id == _selectedModuleId)
        ? _selectedModuleId!
        : modules.first.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Subject Studied Header Card
        _buildSubjectHeaderCard(widget.selectedSubject!, subjectStats, palette),

        // Responsive Layout: Single column on compact/medium, Two-pane on expanded (>= 900 dp)
        if (!isWide)
          ...modules.map((module) {
            final moduleStats = ref.watch(
              moduleSyllabusStatsProvider(module.id),
            );
            final isExpanded = _expandedModuleIds.contains(module.id);
            return _buildModuleCard(
              module: module,
              stats: moduleStats,
              isExpanded: isExpanded,
              isSelectedInWide: false,
              isWideLayout: false,
              palette: palette,
            );
          })
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Pane: Module list (flex 2)
              Expanded(
                flex: 2,
                child: Column(
                  children: modules.map((module) {
                    final moduleStats = ref.watch(
                      moduleSyllabusStatsProvider(module.id),
                    );
                    final isSelected = module.id == activeSelectedModuleId;
                    return _buildModuleCard(
                      module: module,
                      stats: moduleStats,
                      isExpanded: false,
                      isSelectedInWide: isSelected,
                      isWideLayout: true,
                      palette: palette,
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 16),

              // Right Pane: Chapter detail & vault access (flex 3)
              Expanded(
                flex: 3,
                child: Builder(
                  builder: (ctx) {
                    final activeModule = modules.firstWhere(
                      (m) => m.id == activeSelectedModuleId,
                    );
                    final activeStats = ref.watch(
                      moduleSyllabusStatsProvider(activeModule.id),
                    );
                    return _buildRightPaneDetail(
                      activeModule,
                      activeStats,
                      palette,
                    );
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }
}
