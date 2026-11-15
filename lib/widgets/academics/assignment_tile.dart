import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/dimens.dart';
import '../../core/constants/motion.dart';
import '../../core/constants/theme.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/responsive.dart';
import '../../models/academic_item.dart';
import '../../models/subject.dart';
import '../../providers/academics_providers.dart';
import '../../widgets/motion/animated_checkbox.dart';
import '../../widgets/motion/collapse_on_remove.dart';
import '../../widgets/tag.dart';
import 'countdown_pill.dart';
import 'deadline_bar.dart';
import 'edit_assignment_sheet.dart';
import 'urgency_tone.dart';

/// Card tile for an assignment, featuring animated completion, urgency pills,
/// optional deadline proximity bar, edit sheet, and undoable deletion.
class AssignmentTile extends ConsumerStatefulWidget {
  final AcademicItem item;
  final Subject? subject;
  final bool isCompact;
  final Key? checkboxKey;
  final VoidCallback? onCompletedToggled;

  const AssignmentTile({
    super.key,
    required this.item,
    this.subject,
    this.isCompact = false,
    this.checkboxKey,
    this.onCompletedToggled,
  });

  @override
  ConsumerState<AssignmentTile> createState() => _AssignmentTileState();
}

class _AssignmentTileState extends ConsumerState<AssignmentTile> {
  bool _isHovered = false;
  bool _isDeleting = false;
  bool _isCollapsingForToggle = false;

  bool get _isDesktop {
    if (kIsWeb) return false;
    try {
      return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    } catch (_) {
      return false;
    }
  }

  void _handleToggle() {
    if (_isCollapsingForToggle) return;

    // Trigger subtle collapse animation if completing
    setState(() => _isCollapsingForToggle = true);

    Future.delayed(const Duration(milliseconds: 250), () async {
      if (!mounted) return;
      await ref
          .read(academicItemsProvider.notifier)
          .toggleAssignmentComplete(widget.item.id);
      widget.onCompletedToggled?.call();
      if (mounted) {
        setState(() => _isCollapsingForToggle = false);
      }
    });
  }

  void _handleDelete(BuildContext context) {
    if (_isDeleting) return;

    final deleted = widget.item;
    final palette = context.palette;
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isDeleting = true);

    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      ref.read(academicItemsProvider.notifier).deleteItem(deleted.id);

      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Assignment "${deleted.title}" deleted',
            style: TextStyle(color: palette.textPrimary),
          ),
          duration: const Duration(seconds: 4),
          backgroundColor: palette.cardRaised,
          action: SnackBarAction(
            label: 'Undo',
            textColor: palette.accent,
            onPressed: () {
              ref.read(academicItemsProvider.notifier).restoreItem(deleted);
            },
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final today = AppDateUtils.today();
    final cleanDue = AppDateUtils.dateOnly(widget.item.dueDate);
    final daysLeft = AppDateUtils.daysBetween(today, cleanDue);
    final tone = UrgencyTone.fromDaysLeft(daysLeft);
    final formattedDate = DateFormat('EEE, d MMM').format(widget.item.dueDate);
    final isOverdue = !widget.item.isCompleted && daysLeft < 0;

    final isCompactScreen = Breakpoints.isCompact(context);
    final showTrailing = isCompactScreen || !_isDesktop || _isHovered;

    return CollapseOnRemove(
      isRemoved: _isDeleting || _isCollapsingForToggle,
      duration: Motion.base,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Container(
          key: ValueKey('assignment_${widget.item.id}'),
          margin: EdgeInsets.only(bottom: widget.isCompact ? 4.0 : 8.0),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: AppDimens.borderRadiusSm,
            border: Border.all(
              color: isOverdue
                  ? palette.danger.withValues(alpha: 0.3)
                  : palette.border,
              width: AppDimens.hairline,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: () => EditAssignmentSheet.show(context, widget.item),
                borderRadius: AppDimens.borderRadiusSm,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.isCompact ? 10.0 : 12.0,
                    vertical: widget.isCompact ? 6.0 : 10.0,
                  ),
                  child: Row(
                    children: [
                      // Checkbox with pop animation
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Opacity(
                              opacity: 0.0,
                              child: Checkbox(
                                key:
                                    widget.checkboxKey ??
                                    ValueKey(
                                      'assignment_checkbox_${widget.item.id}',
                                    ),
                                value: widget.item.isCompleted,
                                onChanged: (_) => _handleToggle(),
                              ),
                            ),
                            IgnorePointer(
                              child: AnimatedCheckbox(
                                value: widget.item.isCompleted,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Title & Metadata
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: widget.isCompact ? 13 : 14,
                                fontWeight: FontWeight.w500,
                                decoration: widget.item.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: palette.textMuted,
                                color: widget.item.isCompleted
                                    ? palette.textMuted
                                    : palette.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                if (widget.subject != null) ...[
                                  Tag(label: widget.subject!.name),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isOverdue
                                        ? palette.danger
                                        : palette.textSecondary,
                                    fontWeight: isOverdue
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Countdown Pill
                      if (!widget.item.isCompleted)
                        CountdownPill(daysLeft: daysLeft, toneOverride: tone),

                      // Delete action
                      if (showTrailing && !widget.isCompact) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          key: ValueKey('delete_assignment_${widget.item.id}'),
                          icon: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: palette.textSecondary,
                          ),
                          tooltip: 'Delete assignment',
                          splashRadius: 18,
                          onPressed: () => _handleDelete(context),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Proximity deadline bar along bottom edge
              if (!widget.isCompact && !widget.item.isCompleted)
                DeadlineBar(daysLeft: daysLeft, toneOverride: tone),
            ],
          ),
        ),
      ),
    );
  }
}
