import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/academic_item.dart';
import '../../../models/subject.dart';
import '../../../providers/academics_providers.dart';
import '../../../widgets/empty_state.dart';

/// Assignments tab listing active and completed assignments.
class AssignmentsTab extends ConsumerStatefulWidget {
  const AssignmentsTab({super.key});

  @override
  ConsumerState<AssignmentsTab> createState() => _AssignmentsTabState();
}

class _AssignmentsTabState extends ConsumerState<AssignmentsTab> {
  bool _isCompletedExpanded = false;

  String _relativeDueLabel(DateTime dueDate, DateTime today) {
    final cleanDue = AppDateUtils.dateOnly(dueDate);
    final cleanToday = AppDateUtils.dateOnly(today);
    final diff = AppDateUtils.daysBetween(cleanToday, cleanDue);

    if (diff < 0) {
      final days = diff.abs();
      return 'Overdue by $days day${days == 1 ? '' : 's'}';
    } else if (diff == 0) {
      return 'Due today';
    } else if (diff == 1) {
      return 'Due tomorrow';
    } else {
      return 'Due in $diff days';
    }
  }

  Future<void> _confirmDelete(BuildContext context, AcademicItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Assignment'),
        content: Text('Are you sure you want to delete "${item.title}"?'),
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
      await ref.read(academicItemsProvider.notifier).deleteItem(item.id);
    }
  }

  Widget _buildAssignmentRow({
    required AcademicItem item,
    required Subject? subject,
    required DateTime today,
  }) {
    final isOverdue = !item.isCompleted &&
        AppDateUtils.dateOnly(item.dueDate).isBefore(AppDateUtils.dateOnly(today));

    return Container(
      key: ValueKey('assignment_${item.id}'),
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppTheme.borderRadius8,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
        leading: Checkbox(
          value: item.isCompleted,
          onChanged: (_) async {
            await ref
                .read(academicItemsProvider.notifier)
                .toggleAssignmentComplete(item.id);
          },
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
            color: item.isCompleted
                ? AppColors.disabled
                : (isOverdue ? AppColors.primaryText : AppColors.primaryText),
          ),
        ),
        subtitle: Row(
          children: [
            if (subject != null) ...[
              Container(
                margin: const EdgeInsets.only(right: 8.0),
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Text(
                  subject.name,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            ],
            Text(
              item.isCompleted
                  ? 'Completed'
                  : _relativeDueLabel(item.dueDate, today),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                color: isOverdue ? AppColors.primaryText : AppColors.secondaryText,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 18),
          color: AppColors.secondaryText,
          onPressed: () => _confirmDelete(context, item),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeAssignmentsProvider);
    final completed = ref.watch(completedAssignmentsProvider);
    final subjectsAsync = ref.watch(subjectsProvider);
    final subjects = subjectsAsync.value ?? [];
    final today = AppDateUtils.today();

    Subject? findSubject(String? id) {
      if (id == null) return null;
      try {
        return subjects.firstWhere((s) => s.id == id);
      } catch (_) {
        return null;
      }
    }

    if (active.isEmpty && completed.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40.0),
        child: EmptyState(
          icon: Icons.assignment_outlined,
          title: 'No assignments scheduled',
          message: 'Tap "+ Add Assignment" above to plan upcoming coursework.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Active Incomplete Assignments
        if (active.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              'No active assignments due.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText,
              ),
            ),
          )
        else
          ...active.map((item) {
            return _buildAssignmentRow(
              item: item,
              subject: findSubject(item.subjectId),
              today: today,
            );
          }),

        // Collapsible Completed Section
        if (completed.isNotEmpty) ...[
          const SizedBox(height: 16),
          InkWell(
            onTap: () {
              setState(() => _isCompletedExpanded = !_isCompletedExpanded);
            },
            borderRadius: AppTheme.borderRadius8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppTheme.borderRadius8,
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Completed (${completed.length})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  Icon(
                    _isCompletedExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: AppColors.secondaryText,
                  ),
                ],
              ),
            ),
          ),
          if (_isCompletedExpanded) ...[
            const SizedBox(height: 8),
            ...completed.map((item) {
              return _buildAssignmentRow(
                item: item,
                subject: findSubject(item.subjectId),
                today: today,
              );
            }),
          ],
        ],
      ],
    );
  }
}
