import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme.dart';
import '../../../models/subject.dart';
import '../../../providers/academics_providers.dart';
import '../widgets/date_picker_chips.dart';

/// Reusable form body for creating an exam.
/// Shared between `AddExamSheet` and `QuickAddSheet`.
class ExamFormBody extends ConsumerWidget {
  final TextEditingController titleController;
  final DateTime examDate;
  final ValueChanged<DateTime> onDateChanged;
  final String? selectedSubjectId;
  final ValueChanged<String?> onSubjectChanged;
  final VoidCallback? onSubmit;
  final bool autofocus;

  const ExamFormBody({
    super.key,
    required this.titleController,
    required this.examDate,
    required this.onDateChanged,
    required this.selectedSubjectId,
    required this.onSubjectChanged,
    this.onSubmit,
    this.autofocus = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final subjectsAsync = ref.watch(subjectsProvider);
    final subjects = subjectsAsync.value ?? [];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Exam Name / Title field
        TextField(
          key: const Key('add_exam_title_field'),
          controller: titleController,
          autofocus: autofocus,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit?.call(),
          autocorrect: false,
          enableSuggestions: false,
          style: TextStyle(fontSize: 14, color: palette.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. Midterm Examination',
            hintStyle: TextStyle(fontSize: 14, color: palette.textMuted),
          ),
        ),
        const SizedBox(height: 16),

        // Subject dropdown
        Text(
          'Subject (Optional)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: 8),

        DropdownButtonFormField<String?>(
          key: const Key('exam_subject_dropdown'),
          initialValue: selectedSubjectId,
          dropdownColor: palette.cardRaised,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: palette.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: palette.border),
            ),
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(
                'No subject',
                style: TextStyle(fontSize: 13, color: palette.textSecondary),
              ),
            ),
            ...subjects.map(
              (Subject s) => DropdownMenuItem<String?>(
                value: s.id,
                child: Text(
                  s.name,
                  style: TextStyle(fontSize: 13, color: palette.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: onSubjectChanged,
        ),
        const SizedBox(height: 16),

        // Exam Date Section
        Text(
          'Exam Date',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: 8),

        DatePickerChips(
          key: const Key('add_exam_date_picker'),
          selectedDate: examDate,
          onDateChanged: onDateChanged,
        ),
      ],
    );
  }
}
