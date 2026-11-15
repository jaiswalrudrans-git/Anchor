import 'package:flutter/material.dart';

import '../../../core/constants/theme.dart';
import '../widgets/date_picker_chips.dart';

/// Reusable form body for creating a new To-do task.
/// Shared between `AddTodoSheet` and `QuickAddSheet`.
class TodoFormBody extends StatelessWidget {
  final TextEditingController titleController;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback? onSubmit;
  final bool autofocus;

  const TodoFormBody({
    super.key,
    required this.titleController,
    required this.selectedDate,
    required this.onDateChanged,
    this.onSubmit,
    this.autofocus = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title Input Field
        TextField(
          key: const Key('add_todo_title_field'),
          controller: titleController,
          autofocus: autofocus,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit?.call(),
          autocorrect: false,
          enableSuggestions: false,
          style: TextStyle(fontSize: 14, color: palette.textPrimary),
          decoration: InputDecoration(
            hintText: 'What needs to be done?',
            hintStyle: TextStyle(fontSize: 14, color: palette.textMuted),
          ),
        ),
        const SizedBox(height: 16),

        // Target Date Section
        Text(
          'Target Date',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: 8),

        DatePickerChips(
          selectedDate: selectedDate,
          onDateChanged: onDateChanged,
        ),
      ],
    );
  }
}
