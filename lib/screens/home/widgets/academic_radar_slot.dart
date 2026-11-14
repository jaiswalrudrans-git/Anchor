import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/dimens.dart';
import '../../../core/constants/theme.dart';
import '../../../models/subject.dart';
import '../../../providers/academics_providers.dart';
import '../../../widgets/academics/assignment_tile.dart';
import '../../../widgets/academics/exam_countdown_tile.dart';

/// Academic Radar Slot on Home Screen.
/// Displays urgent incomplete assignments (next 7 days) and upcoming exams (next 14 days)
/// using compact, urgency-aware tiles.
class AcademicRadarSlot extends ConsumerWidget {
  const AcademicRadarSlot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final urgentAssignments = ref.watch(urgentAssignmentsRadarProvider);
    final urgentExams = ref.watch(urgentExamsRadarProvider);
    final allSubjects = ref.watch(subjectsProvider).value ?? [];

    Subject? findSubject(String? id) {
      if (id == null) return null;
      try {
        return allSubjects.firstWhere((s) => s.id == id);
      } catch (_) {
        return null;
      }
    }

    final totalUpcoming = urgentAssignments.length + urgentExams.length;
    final hasContent = totalUpcoming > 0;

    return Container(
      key: const Key('academic_radar_slot'),
      margin: const EdgeInsets.only(bottom: 24.0),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: AppDimens.borderRadiusSm,
        border: Border.all(color: palette.border, width: AppDimens.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Radar Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Icon(
                  Icons.radar,
                  size: 18,
                  color: palette.textPrimary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Academic Radar',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
                const Spacer(),
                if (hasContent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: palette.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: palette.border, width: AppDimens.hairline),
                    ),
                    child: Text(
                      '$totalUpcoming upcoming',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: palette.textSecondary,
                        fontFeatures: AppTypography.tabularFigures,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: palette.border),

          if (!hasContent)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: palette.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'All clear.',
                      style: TextStyle(
                        fontSize: 13,
                        color: palette.textSecondary,
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
                padding: const EdgeInsets.only(left: 14.0, right: 14.0, top: 10.0, bottom: 4.0),
                child: Text(
                  'ASSIGNMENTS (NEXT 7 DAYS)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: palette.textSecondary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                  children: urgentAssignments.map((assignment) {
                    return AssignmentTile(
                      key: ValueKey('radar_assignment_${assignment.id}'),
                      item: assignment,
                      subject: findSubject(assignment.subjectId),
                      isCompact: true,
                      checkboxKey: ValueKey('radar_checkbox_${assignment.id}'),
                    );
                  }).toList(),
                ),
              ),
            ],

            // 2. Upcoming Exams Section (Next 14 days)
            if (urgentExams.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 14.0, right: 14.0, top: 10.0, bottom: 4.0),
                child: Text(
                  'EXAMS (NEXT 14 DAYS)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: palette.textSecondary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                  children: urgentExams.map((exam) {
                    return ExamCountdownTile(
                      key: ValueKey('radar_exam_${exam.id}'),
                      exam: exam,
                      subject: findSubject(exam.subjectId),
                      isCompact: true,
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
