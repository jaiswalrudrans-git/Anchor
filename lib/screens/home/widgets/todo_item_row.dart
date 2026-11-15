import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/dimens.dart';
import '../../../core/constants/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/todo.dart';
import '../../../providers/home_providers.dart';
import '../../../widgets/motion/animated_checkbox.dart';
import '../../../widgets/motion/collapse_on_remove.dart';
import '../../../widgets/tag.dart';

/// Row representing a single to-do task item.
/// Supports animated completion toggle, rollover badge, rescheduling, and delete with 4-second Undo.
class TodoItemRow extends ConsumerStatefulWidget {
  final Todo todo;

  const TodoItemRow({super.key, required this.todo});

  @override
  ConsumerState<TodoItemRow> createState() => _TodoItemRowState();
}

class _TodoItemRowState extends ConsumerState<TodoItemRow> {
  bool _isHovered = false;
  bool _isDeleting = false;

  bool get _isDesktop {
    if (kIsWeb) return false;
    try {
      return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    } catch (_) {
      return false;
    }
  }

  void _handleToggle() {
    ref.read(todosProvider.notifier).toggleComplete(widget.todo.id);
  }

  Future<void> _handleReschedule(BuildContext context) async {
    final tomorrow = AppDateUtils.tomorrow();
    final initial = widget.todo.scheduledDate.isBefore(tomorrow)
        ? tomorrow
        : widget.todo.scheduledDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: tomorrow,
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      await ref.read(todosProvider.notifier).reschedule(widget.todo.id, picked);
    }
  }

  void _handleDelete(BuildContext context) {
    if (_isDeleting) return;

    final deletedTodo = widget.todo;
    final palette = context.palette;
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _isDeleting = true;
    });

    // Animate collapse then trigger deletion and show Undo snackbar
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      ref.read(todosProvider.notifier).delete(deletedTodo.id);

      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Task "${deletedTodo.title}" deleted',
            style: TextStyle(color: palette.textPrimary),
          ),
          duration: const Duration(seconds: 4),
          backgroundColor: palette.cardRaised,
          action: SnackBarAction(
            label: 'Undo',
            textColor: palette.accent,
            onPressed: () {
              ref.read(todosProvider.notifier).restoreTodo(deletedTodo);
            },
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isCompact = Breakpoints.isCompact(context);
    final showTrailing = isCompact || !_isDesktop || _isHovered;

    final content = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: AppDimens.borderRadiusSm,
          border: Border.all(color: palette.border, width: AppDimens.hairline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Checkbox with accessible Stack & animated check
            SizedBox(
              width: 24,
              height: 24,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: 0.0,
                    child: Checkbox(
                      value: widget.todo.isCompleted,
                      onChanged: (_) => _handleToggle(),
                    ),
                  ),
                  IgnorePointer(
                    child: AnimatedCheckbox(
                      value: widget.todo.isCompleted,
                      size: 20,
                      playful: false,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Title with animated strike-through line
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedStrikeThroughText(
                    text: widget.todo.title,
                    isCompleted: widget.todo.isCompleted,
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.todo.isCompleted
                          ? palette.textSecondary
                          : palette.textPrimary,
                      fontWeight: widget.todo.isCompleted
                          ? FontWeight.w400
                          : FontWeight.w500,
                    ),
                    strikeColor: palette.textSecondary,
                  ),
                  if (widget.todo.rolloverCount > 0) ...[
                    const SizedBox(height: 4),
                    Tag(
                      icon: Icons.repeat,
                      label: 'Rolled over ${widget.todo.rolloverCount}x',
                      backgroundColor: palette.warningSoft,
                      color: palette.warning,
                      borderColor: palette.warning.withValues(alpha: 0.3),
                    ),
                  ],
                ],
              ),
            ),

            // Trailing actions: Reschedule Calendar Icon & Delete
            AnimatedOpacity(
              opacity: showTrailing ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 150),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: palette.textSecondary,
                    ),
                    tooltip: 'Reschedule',
                    splashRadius: 18,
                    onPressed: showTrailing
                        ? () => _handleReschedule(context)
                        : null,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: palette.textSecondary,
                    ),
                    tooltip: 'Delete',
                    splashRadius: 18,
                    onPressed: showTrailing
                        ? () => _handleDelete(context)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return CollapseOnRemove(isRemoved: _isDeleting, child: content);
  }
}

/// Helper widget drawing an animated strike-through line in 200 ms.
class AnimatedStrikeThroughText extends StatelessWidget {
  final String text;
  final bool isCompleted;
  final TextStyle style;
  final Color strikeColor;

  const AnimatedStrikeThroughText({
    super.key,
    required this.text,
    required this.isCompleted,
    required this.style,
    required this.strikeColor,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: isCompleted ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      builder: (context, progress, _) {
        return CustomPaint(
          foregroundPainter: progress > 0
              ? _StrikeThroughPainter(progress: progress, color: strikeColor)
              : null,
          child: Text(text, style: style),
        );
      },
    );
  }
}

class _StrikeThroughPainter extends CustomPainter {
  final double progress;
  final Color color;

  _StrikeThroughPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final y = size.height / 2;
    canvas.drawLine(Offset(0, y), Offset(size.width * progress, y), paint);
  }

  @override
  bool shouldRepaint(covariant _StrikeThroughPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
