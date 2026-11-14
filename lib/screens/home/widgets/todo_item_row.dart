import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/todo.dart';
import '../../../providers/home_providers.dart';

/// Row representing a single to-do task item.
/// Supports completion toggle, rollover badge, rescheduling, and deletion.
class TodoItemRow extends ConsumerWidget {
  final Todo todo;

  const TodoItemRow({
    super.key,
    required this.todo,
  });

  Future<void> _handleReschedule(BuildContext context, WidgetRef ref) async {
    final tomorrow = AppDateUtils.tomorrow();
    final initial = todo.scheduledDate.isBefore(tomorrow) ? tomorrow : todo.scheduledDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: tomorrow,
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: AppTheme.lightTheme,
          child: child!,
        );
      },
    );

    if (picked != null) {
      await ref.read(todosProvider.notifier).reschedule(todo.id, picked);
    }
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${todo.title}"?'),
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
      await ref.read(todosProvider.notifier).delete(todo.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTheme.borderRadius8,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Checkbox
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: todo.isCompleted,
              onChanged: (_) {
                ref.read(todosProvider.notifier).toggleComplete(todo.id);
              },
            ),
          ),
          const SizedBox(width: 12),

          // Title & Rollover Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  todo.title,
                  style: TextStyle(
                    fontSize: 14,
                    color: todo.isCompleted ? AppColors.secondaryText : AppColors.primaryText,
                    decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.secondaryText,
                    fontWeight: todo.isCompleted ? FontWeight.w400 : FontWeight.w500,
                  ),
                ),
                if (todo.rolloverCount > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Text(
                      'Rolled over ${todo.rolloverCount}x',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Reschedule Calendar Icon
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            tooltip: 'Reschedule',
            color: AppColors.secondaryText,
            splashRadius: 18,
            onPressed: () => _handleReschedule(context, ref),
          ),

          // Delete Icon
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: 'Delete',
            color: AppColors.secondaryText,
            splashRadius: 18,
            onPressed: () => _handleDelete(context, ref),
          ),
        ],
      ),
    );
  }
}
