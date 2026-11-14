import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/subject.dart';
import '../../../providers/academics_providers.dart';

/// Academic Radar widget displayed on Home.
/// Replaces the placeholder slot from Stage 2.
/// Displays urgent assignments (next 7 days, incomplete) and upcoming exams (next 14 days).
class AcademicRadarSlot extends ConsumerWidget {
  const AcademicRadarSlot({super.key});

  String _relativeDueLabel(DateTime dueDate, DateTime today) {
    final cleanDue = AppDateUtils.dateOnly(dueDate);
    final cleanToday = AppDateUtils.dateOnly(today);
    final diff = AppDateUtils.daysBetween(cleanToday, cleanDue);

    if (diff == 0) {
      return 'Due today';
    } else if (diff == 1) {
      return 'Due tomorrow';
    } else {
      return 'In $diff days';
    }
  }

  String _relativeExamLabel(DateTime examDate, DateTime today) {
    final cleanExam = AppDateUtils.dateOnly(examDate);
    final cleanToday = AppDateUtils.dateOnly(today);
    final diff = AppDateUtils.daysBetween(cleanToday, cleanExam);

    if (diff <= 0) {
      return 'Today';
    } else if (diff == 1) {
      return 'Tomorrow';
    } else {
      return 'In $diff days';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urgentAssignments = ref.watch(urgentAssignmentsRadarProvider);
    final urgentExams = ref.watch(urgentExamsRadarProvider);
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

    final hasContent = urgentAssignments.isNotEmpty || urgentExams.isNotEmpty;

    return Container(
      key: const Key('academic_radar_slot'),
      margin: const EdgeInsets.only(bottom: 24.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTheme.borderRadius8,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Radar Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                const Icon(
                  Icons.radar,
                  size: 18,
                  color: AppColors.primaryText,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Academic Radar',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.primaryText,
                  ),
                ),
                const Spacer(),
                if (hasContent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Text(
                      '${urgentAssignments.length + urgentExams.length} upcoming',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          if (!hasContent)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: AppColors.secondaryText,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'All clear.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.secondaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // 1. Upcoming Assignments Section (Next 7 days)
            if (urgentAssignments.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 6.0),
                child: Text(
                  'ASSIGNMENTS (NEXT 7 DAYS)',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
              ...urgentAssignments.map((assignment) {
                final subject = findSubject(assignment.subjectId);
                return Container(
                  key: ValueKey('radar_assignment_${assignment.id}'),
                  margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 3.0),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
                    leading: Checkbox(
                      key: ValueKey('radar_checkbox_${assignment.id}'),
                      value: assignment.isCompleted,
                      onChanged: (_) async {
                        await ref
                            .read(academicItemsProvider.notifier)
                            .toggleAssignmentComplete(assignment.id);
                      },
                    ),
                    title: Text(
                      assignment.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryText,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (subject != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
                          const SizedBox(width: 6),
                        ],
                        Text(
                          _relativeDueLabel(assignment.dueDate, today),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],

            // 2. Upcoming Exams Section (Next 14 days)
            if (urgentExams.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 6.0),
                child: Text(
                  'EXAMS (NEXT 14 DAYS)',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
              ...urgentExams.map((exam) {
                final subject = findSubject(exam.subjectId);
                return Container(
                  key: ValueKey('radar_exam_${exam.id}'),
                  margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 3.0),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.quiz_outlined,
                        size: 16,
                        color: AppColors.primaryText,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          exam.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ),
                      if (subject != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
                        const SizedBox(width: 6),
                      ],
                      Text(
                        _relativeExamLabel(exam.dueDate, today),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
