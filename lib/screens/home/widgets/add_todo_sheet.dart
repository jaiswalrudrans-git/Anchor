import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/dimens.dart';
import '../../../core/constants/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../providers/home_providers.dart';
import '../../../widgets/quick_add/forms/todo_form_body.dart';

/// Modal bottom sheet for adding a new to-do task.
/// Thin wrapper around `TodoFormBody`.
class AddTodoSheet extends ConsumerStatefulWidget {
  final DateTime? initialDate;

  const AddTodoSheet({super.key, this.initialDate});

  /// Static helper to display the sheet in a standardized bottom sheet.
  static Future<void> show(BuildContext context, {DateTime? initialDate}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.palette.cardRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusXl),
        ),
      ),
      builder: (ctx) => AddTodoSheet(initialDate: initialDate),
    );
  }

  @override
  ConsumerState<AddTodoSheet> createState() => _AddTodoSheetState();
}

class _AddTodoSheetState extends ConsumerState<AddTodoSheet> {
  final _titleController = TextEditingController();
  late DateTime _selectedDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate != null
        ? AppDateUtils.dateOnly(widget.initialDate!)
        : AppDateUtils.today();
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
      await ref.read(todosProvider.notifier).addTodo(title, _selectedDate);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to add task: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      key: const Key('add_todo_sheet'),
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
              Text(
                'New Task',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 20, color: palette.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
                splashRadius: 18,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Shared form body
          TodoFormBody(
            titleController: _titleController,
            selectedDate: _selectedDate,
            onDateChanged: (d) => setState(() => _selectedDate = d),
            onSubmit: _submit,
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            height: 44,
            child: ElevatedButton(
              key: const Key('add_todo_sheet_submit_button'),
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          palette.onAccent,
                        ),
                      ),
                    )
                  : const Text('Add Task'),
            ),
          ),
        ],
      ),
    );
  }
}
