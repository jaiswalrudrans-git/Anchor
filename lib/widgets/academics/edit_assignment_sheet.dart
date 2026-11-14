import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/dimens.dart';
import '../../core/constants/theme.dart';
import '../../core/utils/date_utils.dart';
import '../../models/academic_item.dart';
import '../../providers/academics_providers.dart';

/// Modal sheet for editing an existing assignment.
class EditAssignmentSheet extends ConsumerStatefulWidget {
  final AcademicItem item;

  const EditAssignmentSheet({super.key, required this.item});

  static Future<void> show(BuildContext context, AcademicItem item) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditAssignmentSheet(item: item),
    );
  }

  @override
  ConsumerState<EditAssignmentSheet> createState() => _EditAssignmentSheetState();
}

class _EditAssignmentSheetState extends ConsumerState<EditAssignmentSheet> {
  late final TextEditingController _titleController;
  late DateTime _selectedDueDate;
  late String? _selectedSubjectId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _selectedDueDate = widget.item.dueDate;
    _selectedSubjectId = widget.item.subjectId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _selectedDueDate = AppDateUtils.dateOnly(picked));
    }
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(academicItemsProvider.notifier).editItem(
            id: widget.item.id,
            title: title,
            dueDate: _selectedDueDate,
            subjectId: _selectedSubjectId,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update assignment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final subjects = ref.watch(subjectsProvider).value ?? [];
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: palette.cardRaised,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: palette.border, width: AppDimens.hairline)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: bottomInset + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Edit Assignment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                  letterSpacing: -0.2,
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
          TextField(
            controller: _titleController,
            autofocus: true,
            style: TextStyle(color: palette.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Assignment title',
              hintStyle: TextStyle(color: palette.textMuted),
              filled: true,
              fillColor: palette.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: AppDimens.borderRadiusSm,
                borderSide: BorderSide(color: palette.border, width: AppDimens.hairline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppDimens.borderRadiusSm,
                borderSide: BorderSide(color: palette.border, width: AppDimens.hairline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppDimens.borderRadiusSm,
                borderSide: BorderSide(color: palette.accent, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _selectedSubjectId,
            dropdownColor: palette.cardRaised,
            style: TextStyle(color: palette.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Subject (Optional)',
              labelStyle: TextStyle(color: palette.textSecondary),
              filled: true,
              fillColor: palette.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: AppDimens.borderRadiusSm,
                borderSide: BorderSide(color: palette.border, width: AppDimens.hairline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppDimens.borderRadiusSm,
                borderSide: BorderSide(color: palette.border, width: AppDimens.hairline),
              ),
            ),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text('No Subject', style: TextStyle(color: palette.textMuted)),
              ),
              ...subjects.map((s) => DropdownMenuItem<String?>(
                    value: s.id,
                    child: Text(s.name, style: TextStyle(color: palette.textPrimary)),
                  )),
            ],
            onChanged: (val) => setState(() => _selectedSubjectId = val),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDate,
            borderRadius: AppDimens.borderRadiusSm,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: palette.background,
                borderRadius: AppDimens.borderRadiusSm,
                border: Border.all(color: palette.border, width: AppDimens.hairline),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 16, color: palette.textSecondary),
                  const SizedBox(width: 10),
                  Text(
                    'Due: ${DateFormat('EEE, d MMM yyyy').format(_selectedDueDate)}',
                    style: TextStyle(fontSize: 13, color: palette.textPrimary),
                  ),
                  const Spacer(),
                  Text('Change', style: TextStyle(fontSize: 12, color: palette.accent, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            key: const Key('edit_assignment_save_button'),
            onPressed: _isSaving ? null : _handleSave,
            child: _isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}
