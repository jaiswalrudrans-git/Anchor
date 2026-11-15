import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/dimens.dart';
import '../../../core/constants/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/academic_item.dart';
import '../../../models/subject.dart';
import '../../../providers/academics_providers.dart';
import '../../../widgets/academics/assignment_tile.dart';
import '../../../widgets/empty_state.dart';

/// Assignments tab grouping coursework into Overdue, Due today, This week,
/// Later, and Completed sections with animated tiles and 2-column wide layout.
class AssignmentsTab extends ConsumerStatefulWidget {
  const AssignmentsTab({super.key});

  @override
  ConsumerState<AssignmentsTab> createState() => _AssignmentsTabState();
}

class _AssignmentsTabState extends ConsumerState<AssignmentsTab> {
  // Completed is collapsed by default; all others expanded
  final Set<AssignmentGroup> _collapsedGroups = {AssignmentGroup.completed};

  void _toggleGroup(AssignmentGroup group) {
    setState(() {
      if (_collapsedGroups.contains(group)) {
        _collapsedGroups.remove(group);
      } else {
        _collapsedGroups.add(group);
      }
    });
  }

  Widget _buildGroupSection({
    required AssignmentGroup group,
    required List<AcademicItem> items,
    required List<Subject> subjects,
    required bool isExpandedWidth,
    required AppPalette palette,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    final isCollapsed = _collapsedGroups.contains(group);
    final isOverdue = group == AssignmentGroup.overdue;

    Subject? findSubject(String? id) {
      if (id == null) return null;
      try {
        return subjects.firstWhere((s) => s.id == id);
      } catch (_) {
        return null;
      }
    }

    final tiles = items
        .map(
          (item) => AssignmentTile(
            key: ValueKey('assignment_${item.id}'),
            item: item,
            subject: findSubject(item.subjectId),
          ),
        )
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Header Row
          InkWell(
            onTap: () => _toggleGroup(group),
            borderRadius: AppDimens.borderRadiusSm,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                color: isOverdue ? palette.dangerSoft : palette.card,
                borderRadius: AppDimens.borderRadiusSm,
                border: Border.all(
                  color: isOverdue
                      ? palette.danger.withValues(alpha: 0.3)
                      : palette.border,
                  width: AppDimens.hairline,
                ),
              ),
              child: Row(
                children: [
                  if (isOverdue) ...[
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: palette.danger,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    group.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isOverdue ? palette.danger : palette.textPrimary,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? palette.danger.withValues(alpha: 0.2)
                          : palette.cardRaised,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isOverdue
                            ? palette.danger.withValues(alpha: 0.4)
                            : palette.border,
                        width: AppDimens.hairline,
                      ),
                    ),
                    child: Text(
                      '${items.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isOverdue
                            ? palette.danger
                            : palette.textSecondary,
                        fontFeatures: AppTypography.tabularFigures,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isCollapsed
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
                    size: 18,
                    color: isOverdue ? palette.danger : palette.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Section Tiles (2 columns on expanded >= 900 dp)
          if (!isCollapsed) _buildResponsiveTileList(tiles, isExpandedWidth),
        ],
      ),
    );
  }

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
  Widget build(BuildContext context) {
    final palette = context.palette;
    final allItems = ref.watch(academicItemsProvider).value ?? [];
    final subjects = ref.watch(subjectsProvider).value ?? [];
    final today = AppDateUtils.today();

    final grouped = groupAssignments(allItems, today);
    final totalAssignments = grouped.values.fold<int>(
      0,
      (sum, l) => sum + l.length,
    );

    if (totalAssignments == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40.0),
        child: EmptyState(
          key: Key('assignments_empty_state'),
          icon: Icons.assignment_outlined,
          title: 'No assignments',
          message: 'Add one and Anchor will remind you the night before.',
        ),
      );
    }

    final isExpanded = Breakpoints.isExpanded(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in AssignmentGroup.values)
          _buildGroupSection(
            group: group,
            items: grouped[group] ?? [],
            subjects: subjects,
            isExpandedWidth: isExpanded,
            palette: palette,
          ),
      ],
    );
  }
}
