import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/academic_item.dart';
import '../../../models/subject.dart';
import '../../../providers/academics_providers.dart';
import '../../../widgets/empty_state.dart';

/// Exams tab listing upcoming exams sorted strictly by due_date ASC.
/// There is NO "Past" section — past exams are automatically cleaned up.
class ExamsTab extends ConsumerWidget {
  const ExamsTab({super.key});

  String _relativeExamLabel(DateTime examDate, DateTime today) {
    final cleanExam = AppDateUtils.dateOnly(examDate);
    final cleanToday = AppDateUtils.dateOnly(today);
    final diff = AppDateUtils.daysBetween(cleanToday, cleanExam);

    if (diff < 0) {
      return 'Today'; // Ending today or pending cleanup
    } else if (diff == 0) {
      return 'Today';
    } else if (diff == 1) {
      return 'Tomorrow';
    } else {
      return 'In $diff days';
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, AcademicItem exam) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Exam'),
        content: Text('Are you sure you want to delete "${exam.title}"?'),
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
      await ref.read(academicItemsProvider.notifier).deleteItem(exam.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exams = ref.watch(examsListProvider);
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

    if (exams.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40.0),
        child: EmptyState(
          icon: Icons.event_note_outlined,
          title: 'No upcoming exams scheduled',
          message: 'Tap "+ Add Exam" above to schedule midterms or finals.',
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: exams.length,
      itemBuilder: (context, index) {
        final exam = exams[index];
        final subject = findSubject(exam.subjectId);
        final formattedDate = DateFormat('EEE, MMM d, yyyy').format(exam.dueDate);
        final relLabel = _relativeExamLabel(exam.dueDate, today);

        return Container(
          key: ValueKey('exam_${exam.id}'),
          margin: const EdgeInsets.only(bottom: 8.0),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: AppTheme.borderRadius8,
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            leading: const Icon(
              Icons.quiz_outlined,
              size: 24,
              color: AppColors.primaryText,
            ),
            title: Text(
              exam.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (subject != null) ...[
                      Container(
                        margin: const EdgeInsets.only(right: 8.0),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6.0, vertical: 1.0),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(4),
                          border:
                              Border.all(color: AppColors.border, width: 1),
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
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Text(
                    relLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: AppColors.secondaryText,
                  onPressed: () => _confirmDelete(context, ref, exam),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
