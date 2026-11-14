import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../providers/home_providers.dart';

/// Modal bottom sheet for adding a new to-do task.
/// Exclusively contains to-do fields (title and target date selector).
/// Contains NO academic, expense, or other screen fields.
class AddTodoSheet extends ConsumerStatefulWidget {
  final DateTime? initialDate;

  const AddTodoSheet({
    super.key,
    this.initialDate,
  });

  /// Static helper to display the sheet in a standardized bottom sheet.
  static Future<void> show(BuildContext context, {DateTime? initialDate}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.maxRadius)),
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

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(todosProvider.notifier).addTodo(title, _selectedDate);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add task: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _pickCustomDate() async {
    final today = AppDateUtils.today();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(today) ? today : _selectedDate,
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
        _selectedDate = AppDateUtils.dateOnly(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = AppDateUtils.today();
    final tomorrow = AppDateUtils.tomorrow();
    final isToday = _selectedDate == today;
    final isTomorrow = _selectedDate == tomorrow;
    final isCustom = !isToday && !isTomorrow;

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
              const Text(
                'New Task',
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

          // Title Input Field
          TextField(
            key: const Key('add_todo_title_field'),
            controller: _titleController,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            autocorrect: false,
            enableSuggestions: false,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.primaryText,
            ),
            decoration: const InputDecoration(
              hintText: 'What needs to be done?',
            ),
          ),
          const SizedBox(height: 16),

          // Target Date Selection
          const Text(
            'Target Date',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              // Today Choice
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedDate = today;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isToday ? AppColors.primaryText : Colors.transparent,
                    foregroundColor: isToday ? AppColors.background : AppColors.primaryText,
                    side: BorderSide(
                      color: isToday ? AppColors.primaryText : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: const Text('Today', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),

              // Tomorrow Choice
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedDate = tomorrow;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isTomorrow ? AppColors.primaryText : Colors.transparent,
                    foregroundColor: isTomorrow ? AppColors.background : AppColors.primaryText,
                    side: BorderSide(
                      color: isTomorrow ? AppColors.primaryText : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: const Text('Tomorrow', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),

              // Pick Date Choice
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickCustomDate,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isCustom ? AppColors.primaryText : Colors.transparent,
                    foregroundColor: isCustom ? AppColors.background : AppColors.primaryText,
                    side: BorderSide(
                      color: isCustom ? AppColors.primaryText : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isCustom ? AppDateUtils.formatDbDate(_selectedDate) : 'Pick Date',
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            height: 44,
            child: ElevatedButton(
              key: const Key('add_todo_sheet_submit_button'),
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.background),
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
