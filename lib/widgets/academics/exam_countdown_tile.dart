import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/dimens.dart';
import '../../core/constants/theme.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/haptics.dart';
import '../../core/utils/responsive.dart';
import '../../models/academic_item.dart';
import '../../models/subject.dart';
import '../../providers/academics_providers.dart';
import '../../widgets/motion/collapse_on_remove.dart';
import '../../widgets/motion/pulse_ring.dart';
import '../../widgets/tag.dart';
import 'urgency_tone.dart';

/// Countdown tile for upcoming exams.
/// Displays days remaining, subject tag, full date with weekday, and an exam-day
/// "Mark as done" achievement flow with checkmark draw-in and pulse ring.
class ExamCountdownTile extends ConsumerStatefulWidget {
  final AcademicItem exam;
  final Subject? subject;
  final bool isCompact;
  final VoidCallback? onExamCompleted;

  const ExamCountdownTile({
    super.key,
    required this.exam,
    this.subject,
    this.isCompact = false,
    this.onExamCompleted,
  });

  @override
  ConsumerState<ExamCountdownTile> createState() => _ExamCountdownTileState();
}

class _ExamCountdownTileState extends ConsumerState<ExamCountdownTile> {
  bool _isHovered = false;
  bool _isDismissing = false;
  bool _showAchievementMoment = false;

  bool get _isDesktop {
    if (kIsWeb) return false;
    try {
      return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleMarkDone() async {
    if (_isDismissing || _showAchievementMoment) return;

    // 1. Play achievement moment (400 ms)
    Haptics.success();
    setState(() {
      _showAchievementMoment = true;
    });

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    // 2. Slide/collapse away (300 ms)
    setState(() {
      _isDismissing = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    // 3. Mark completed in provider
    await ref
        .read(academicItemsProvider.notifier)
        .markExamCompleted(widget.exam.id);

    widget.onExamCompleted?.call();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Exam'),
        content: Text('Are you sure you want to delete "${widget.exam.title}"?'),
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
      await ref
          .read(academicItemsProvider.notifier)
          .deleteItem(widget.exam.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final today = AppDateUtils.today();
    final cleanExamDate = AppDateUtils.dateOnly(widget.exam.dueDate);
    final daysLeft = AppDateUtils.daysBetween(today, cleanExamDate);
    final isExamToday = daysLeft == 0;
    final tone = UrgencyTone.fromDaysLeft(daysLeft, soonThreshold: 3);
    final formattedDate = DateFormat('EEE, d MMM yyyy').format(widget.exam.dueDate);

    final isCompactScreen = Breakpoints.isCompact(context);
    final showTrailing = isCompactScreen || !_isDesktop || _isHovered;

    Widget leftBlockContent;
    if (_showAchievementMoment) {
      leftBlockContent = Icon(
        Icons.check_circle,
        size: widget.isCompact ? 28 : 36,
        color: palette.accent,
      );
    } else if (isExamToday) {
      leftBlockContent = Text(
        'Today',
        style: TextStyle(
          fontSize: widget.isCompact ? 14 : 16,
          fontWeight: FontWeight.w700,
          color: palette.accent,
          letterSpacing: -0.3,
        ),
      );
    } else {
      leftBlockContent = Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$daysLeft',
            style: TextStyle(
              fontSize: widget.isCompact ? 22 : 28,
              fontWeight: FontWeight.w700,
              color: tone.foreground(palette),
              fontFeatures: AppTypography.tabularFigures,
              letterSpacing: -0.5,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            daysLeft == 1 ? 'day' : 'days',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: palette.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      );
    }

    final card = Container(
      key: ValueKey('exam_${widget.exam.id}'),
      margin: EdgeInsets.only(bottom: widget.isCompact ? 6.0 : 10.0),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: AppDimens.borderRadiusSm,
        border: Border.all(
          color: isExamToday ? palette.accent : palette.border,
          width: isExamToday ? 1.5 : AppDimens.hairline,
        ),
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCompact ? 10.0 : 14.0,
            vertical: widget.isCompact ? 8.0 : 12.0,
          ),
          child: Row(
            children: [
              // Left countdown block
              Container(
                width: widget.isCompact ? 54 : 64,
                height: widget.isCompact ? 48 : 56,
                decoration: BoxDecoration(
                  color: isExamToday
                      ? palette.accentSoft
                      : palette.cardRaised,
                  borderRadius: AppDimens.borderRadiusSm,
                  border: Border.all(
                    color: isExamToday
                        ? palette.accent.withValues(alpha: 0.4)
                        : palette.border,
                    width: AppDimens.hairline,
                  ),
                ),
                alignment: Alignment.center,
                child: leftBlockContent,
              ),
              const SizedBox(width: 12),

              // Right block: exam name, subject tag, full date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.exam.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: widget.isCompact ? 14 : 15,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (widget.subject != null)
                          Tag(
                            label: widget.subject!.name,
                          ),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 11,
                            color: palette.textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Exam day action: Mark as done button
              if (isExamToday) ...[
                const SizedBox(width: 8),
                ElevatedButton(
                  key: ValueKey('mark_exam_done_${widget.exam.id}'),
                  onPressed: _showAchievementMoment ? null : _handleMarkDone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.accent,
                    foregroundColor: palette.onAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Mark as done'),
                ),
              ],

              // Delete button (non-compact, on hover or mobile)
              if (!widget.isCompact && showTrailing && !isExamToday) ...[
                const SizedBox(width: 4),
                IconButton(
                  key: ValueKey('delete_exam_${widget.exam.id}'),
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: palette.textSecondary,
                  ),
                  tooltip: 'Delete exam',
                  splashRadius: 18,
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return CollapseOnRemove(
      isRemoved: _isDismissing,
      duration: const Duration(milliseconds: 300),
      child: _showAchievementMoment
          ? PulseRing(
              trigger: true,
              child: card,
            )
          : card,
    );
  }
}
