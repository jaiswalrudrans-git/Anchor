import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/theme.dart';
import '../../models/subject.dart';
import '../../providers/academics_providers.dart';
import '../../widgets/responsive_container.dart';
import 'widgets/add_assignment_sheet.dart';
import 'widgets/add_exam_sheet.dart';
import 'widgets/add_module_dialog.dart';
import 'widgets/add_subject_dialog.dart';
import 'widgets/assignments_tab.dart';
import 'widgets/exams_tab.dart';
import 'widgets/syllabus_tab.dart';

enum AcademicsSegment { syllabus, assignments, exams }

/// Academics screen containing Syllabus tree, Assignments, and Exams tabs.
/// Features horizontal subject selector chips and context-aware add controls.
class AcademicsScreen extends ConsumerStatefulWidget {
  const AcademicsScreen({super.key});

  @override
  ConsumerState<AcademicsScreen> createState() => _AcademicsScreenState();
}

class _AcademicsScreenState extends ConsumerState<AcademicsScreen> {
  AcademicsSegment _selectedSegment = AcademicsSegment.syllabus;

  Future<void> _promptRenameSubject(Subject subject) async {
    final controller = TextEditingController(text: subject.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Subject'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Subject name'),
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

    if (newName != null && newName.isNotEmpty && newName != subject.name) {
      await ref.read(subjectsProvider.notifier).renameSubject(subject.id, newName);
    }
  }

  Future<void> _confirmDeleteSubject(Subject subject) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text(
          'Delete "${subject.name}"? All associated modules, chapters, and files will be permanently deleted.',
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
      await ref.read(subjectsProvider.notifier).deleteSubject(subject.id);
    }
  }

  void _showSubjectActions(Subject subject) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.maxRadius)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename Subject'),
              onTap: () {
                Navigator.of(ctx).pop();
                _promptRenameSubject(subject);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Subject', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.of(ctx).pop();
                _confirmDeleteSubject(subject);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextualAddButton(String? selectedSubjectId) {
    switch (_selectedSegment) {
      case AcademicsSegment.syllabus:
        return TextButton.icon(
          key: const Key('academics_add_module_button'),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add Module', style: TextStyle(fontSize: 12)),
          onPressed: selectedSubjectId != null
              ? () => AddModuleDialog.show(context, selectedSubjectId)
              : null,
        );
      case AcademicsSegment.assignments:
        return TextButton.icon(
          key: const Key('academics_add_assignment_button'),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add Assignment', style: TextStyle(fontSize: 12)),
          onPressed: () => AddAssignmentSheet.show(context, initialSubjectId: selectedSubjectId),
        );
      case AcademicsSegment.exams:
        return TextButton.icon(
          key: const Key('academics_add_exam_button'),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add Exam', style: TextStyle(fontSize: 12)),
          onPressed: () => AddExamSheet.show(context, initialSubjectId: selectedSubjectId),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsProvider);
    final subjects = subjectsAsync.value ?? [];
    final selectedSubjectId = ref.watch(selectedSubjectIdProvider);

    Subject? selectedSubject;
    if (selectedSubjectId != null && subjects.isNotEmpty) {
      try {
        selectedSubject = subjects.firstWhere((s) => s.id == selectedSubjectId);
      } catch (_) {
        selectedSubject = subjects.first;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh Academics',
            onPressed: () {
              ref.read(subjectsProvider.notifier).refresh();
              ref.read(modulesProvider.notifier).refresh();
              ref.read(chaptersProvider.notifier).refresh();
              ref.read(academicItemsProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Segmented Toggle at the very top: Syllabus | Assignments | Exams
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<AcademicsSegment>(
                    key: const Key('academics_segmented_toggle'),
                    segments: const [
                      ButtonSegment(
                        value: AcademicsSegment.syllabus,
                        label: Text('Syllabus'),
                      ),
                      ButtonSegment(
                        value: AcademicsSegment.assignments,
                        label: Text('Assignments'),
                      ),
                      ButtonSegment(
                        value: AcademicsSegment.exams,
                        label: Text('Exams'),
                      ),
                    ],
                    selected: {_selectedSegment},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _selectedSegment = newSelection.first;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Tab Contents
                switch (_selectedSegment) {
                  AcademicsSegment.syllabus => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Subject selector chips ONLY in the Syllabus section
                        SizedBox(
                          height: 38,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              ActionChip(
                                key: const Key('academics_add_subject_chip'),
                                avatar: const Icon(Icons.add, size: 16, color: AppColors.primaryText),
                                label: const Text(
                                  'Subject',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryText,
                                  ),
                                ),
                                onPressed: () => AddSubjectDialog.show(context),
                              ),
                              const SizedBox(width: 8),
                              ...subjects.map((subject) {
                                final isSelected = subject.id == selectedSubject?.id;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: GestureDetector(
                                    onLongPress: () => _showSubjectActions(subject),
                                    child: ChoiceChip(
                                      key: ValueKey('subject_chip_${subject.id}'),
                                      label: Text(
                                        subject.name,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                          color: isSelected ? AppColors.background : AppColors.primaryText,
                                        ),
                                      ),
                                      selected: isSelected,
                                      selectedColor: AppColors.primaryText,
                                      checkmarkColor: AppColors.background,
                                      onSelected: (val) {
                                        if (val) {
                                          ref
                                              .read(selectedSubjectIdProvider.notifier)
                                              .select(subject.id);
                                        }
                                      },
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Section header: Subject Modules & + Add Module
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                selectedSubject != null
                                    ? '${selectedSubject.name} Modules'
                                    : 'Syllabus Modules',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryText,
                                  letterSpacing: -0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _buildContextualAddButton(selectedSubject?.id),
                          ],
                        ),
                        const SizedBox(height: 12),

                        SyllabusTab(selectedSubject: selectedSubject),
                      ],
                    ),
                  AcademicsSegment.assignments => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Assignments',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryText,
                                letterSpacing: -0.2,
                              ),
                            ),
                            _buildContextualAddButton(selectedSubject?.id),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const AssignmentsTab(),
                      ],
                    ),
                  AcademicsSegment.exams => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Upcoming Exams',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryText,
                                letterSpacing: -0.2,
                              ),
                            ),
                            _buildContextualAddButton(selectedSubject?.id),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const ExamsTab(),
                      ],
                    ),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }
}
