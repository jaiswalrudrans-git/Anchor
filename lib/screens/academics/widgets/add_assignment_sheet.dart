import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../providers/academics_providers.dart';

/// Modal bottom sheet exclusively for adding assignments.
/// Contains ONLY assignment fields: title, optional subject dropdown, and due date.
/// Contains NO exam fields, syllabus fields, or foreign domain inputs.
class AddAssignmentSheet extends ConsumerStatefulWidget {
  final String? initialSubjectId;

  const AddAssignmentSheet({
    super.key,
    this.initialSubjectId,
  });

  static Future<void> show(BuildContext context, {String? initialSubjectId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.maxRadius)),
      ),
      builder: (ctx) => AddAssignmentSheet(initialSubjectId: initialSubjectId),
    );
  }

  @override
  ConsumerState<AddAssignmentSheet> createState() => _AddAssignmentSheetState();
}

class _AddAssignmentSheetState extends ConsumerState<AddAssignmentSheet> {
  final _titleController = TextEditingController();
  late DateTime _dueDate;
  String? _selectedSubjectId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _dueDate = AppDateUtils.today();
    _selectedSubjectId = widget.initialSubjectId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(academicItemsProvider.notifier).addItem(
            title: title,
            itemType: 'assignment',
            dueDate: _dueDate,
            subjectId: _selectedSubjectId,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add assignment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickCustomDate() async {
    final today = AppDateUtils.today();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate.isBefore(today) ? today : _dueDate,
      firstDate: today,
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: AppTheme.lightTheme,
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dueDate = AppDateUtils.dateOnly(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = AppDateUtils.today();
    final tomorrow = AppDateUtils.tomorrow();
    final isToday = _dueDate == today;
    final isTomorrow = _dueDate == tomorrow;
    final isCustom = !isToday && !isTomorrow;

    final subjectsAsync = ref.watch(subjectsProvider);
    final subjects = subjectsAsync.value ?? [];

    return Padding(
      key: const Key('add_assignment_sheet'),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'New Assignment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
                splashRadius: 18,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Assignment Title Field
          TextField(
            key: const Key('add_assignment_title_field'),
            controller: _titleController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            autocorrect: false,
            enableSuggestions: false,
            style: const TextStyle(fontSize: 14, color: AppColors.primaryText),
            decoration: const InputDecoration(
              hintText: 'Assignment Title (e.g. Lab Report 2)',
            ),
          ),
          const SizedBox(height: 16),

          // Subject Dropdown
          if (subjects.isNotEmpty) ...[
            DropdownButtonFormField<String?>(
              key: const Key('add_assignment_subject_dropdown'),
              initialValue: subjects.any((s) => s.id == _selectedSubjectId)
                  ? _selectedSubjectId
                  : null,
              decoration: const InputDecoration(
                labelText: 'Subject (Optional)',
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('No Subject'),
                ),
                ...subjects.map(
                  (s) => DropdownMenuItem<String?>(
                    value: s.id,
                    child: Text(s.name),
                  ),
                ),
              ],
              onChanged: (val) {
                setState(() => _selectedSubjectId = val);
              },
            ),
            const SizedBox(height: 16),
          ],

          // Due Date Picker Selector
          const Text(
            'Due Date',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            key: const Key('add_assignment_date_picker'),
            children: [
              Expanded(
                child: ChoiceChip(
                  label: Center(
                    child: Text(
                      'Today',
                      style: TextStyle(
                        color: isToday ? AppColors.background : AppColors.primaryText,
                        fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                  selected: isToday,
                  selectedColor: AppColors.primaryText,
                  checkmarkColor: AppColors.background,
                  onSelected: (_) {
                    setState(() => _dueDate = today);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: Center(
                    child: Text(
                      'Tomorrow',
                      style: TextStyle(
                        color: isTomorrow ? AppColors.background : AppColors.primaryText,
                        fontWeight: isTomorrow ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                  selected: isTomorrow,
                  selectedColor: AppColors.primaryText,
                  checkmarkColor: AppColors.background,
                  onSelected: (_) {
                    setState(() => _dueDate = tomorrow);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: Center(
                    child: Text(
                      isCustom
                          ? DateFormat('MMM d').format(_dueDate)
                          : 'Pick Date',
                      style: TextStyle(
                        color: isCustom ? AppColors.background : AppColors.primaryText,
                        fontWeight: isCustom ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                  selected: isCustom,
                  selectedColor: AppColors.primaryText,
                  checkmarkColor: AppColors.background,
                  onSelected: (_) => _pickCustomDate(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Submit Button
          ElevatedButton(
            key: const Key('add_assignment_submit_button'),
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.background,
                    ),
                  )
                : const Text('Add Assignment'),
          ),
        ],
      ),
    );
  }
}
