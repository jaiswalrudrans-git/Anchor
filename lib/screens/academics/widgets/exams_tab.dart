import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/responsive.dart';
import '../../../models/subject.dart';
import '../../../providers/academics_providers.dart';
import '../../../widgets/academics/exam_countdown_tile.dart';
import '../../../widgets/empty_state.dart';

/// Exams tab listing upcoming exams sorted strictly by due_date ASC.
/// There is NO "Past" section — past exams are automatically cleaned up.
class ExamsTab extends ConsumerWidget {
  const ExamsTab({super.key});

  Widget _buildResponsiveTileList(List<Widget> tiles, bool isExpandedWidth) {
    if (!isExpandedWidth || tiles.length <= 1) {
      return Column(children: tiles);
    }

    final left = <Widget>[];
    final right = <Widget>[];
    for (int i = 0; i < tiles.length; i++) {
      if (i % 2 == 0) {
        left.add(tiles[i]);
      } else {
        right.add(tiles[i]);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: left)),
        const SizedBox(width: 12),
        Expanded(child: Column(children: right)),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exams = ref.watch(examsListProvider);
    final subjectsAsync = ref.watch(subjectsProvider);
    final subjects = subjectsAsync.value ?? [];

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
          key: Key('exams_empty_state'),
          icon: Icons.event_note_outlined,
          title: 'No exams coming up',
          message: 'Add one to get a reminder 3 days before.',
        ),
      );
    }

    final isExpanded = Breakpoints.isExpanded(context);
    final tiles = exams
        .map(
          (exam) => ExamCountdownTile(
            key: ValueKey('exam_${exam.id}'),
            exam: exam,
            subject: findSubject(exam.subjectId),
          ),
        )
        .toList();

    return _buildResponsiveTileList(tiles, isExpanded);
  }
}
