import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/dimens.dart';
import '../../../core/constants/motion.dart';
import '../../../core/constants/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/haptics.dart';
import '../../../providers/home_providers.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_state.dart';
import '../../../widgets/motion/pulse_ring.dart';
import '../../../widgets/skeleton_box.dart';
import 'card_progress_stroke.dart';
import 'todo_item_row.dart';

/// Today's Tasks card surrounded by an animated clockwise progress stroke.
/// Includes inline task scheduler, count chip with "All done" morph, and achievement pulse.
class TodaysTasksCard extends ConsumerStatefulWidget {
  const TodaysTasksCard({super.key});

  @override
  ConsumerState<TodaysTasksCard> createState() => _TodaysTasksCardState();
}

class _TodaysTasksCardState extends ConsumerState<TodaysTasksCard> {
  final _inputController = TextEditingController();
  DateTime _selectedDate = AppDateUtils.today();

  int? _prevCompleted;
  int? _prevTotal;
  bool _pulseTrigger = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _checkAchievement(int completed, int total) {
    if (_prevCompleted != null && _prevTotal != null) {
      final wasAllDone = _prevTotal! > 0 && _prevCompleted == _prevTotal;
      final isNowAllDone = total > 0 && completed == total;
      if (!wasAllDone && isNowAllDone) {
        setState(() {
          _pulseTrigger = true;
        });
        Haptics.success();
        Future.delayed(Motion.moment, () {
          if (mounted) setState(() => _pulseTrigger = false);
        });
      }
    }
    _prevCompleted = completed;
    _prevTotal = total;
  }

  Future<void> _submitTask() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    try {
      await ref.read(todosProvider.notifier).addTodo(text, _selectedDate);
      _inputController.clear();
      setState(() {
        _selectedDate = AppDateUtils.today();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add task: $e')),
        );
      }
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: AppDateUtils.today(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = AppDateUtils.dateOnly(picked);
      });
    }
  }

  String _dateChipLabel() {
    final today = AppDateUtils.today();
    final tomorrow = AppDateUtils.tomorrow();
    if (_selectedDate == today) return 'Today';
    if (_selectedDate == tomorrow) return 'Tomorrow';
    return DateFormat('d MMM').format(_selectedDate);
  }

  String _inputHint() {
    final today = AppDateUtils.today();
    final tomorrow = AppDateUtils.tomorrow();
    if (_selectedDate == today) return 'Add a task for today...';
    if (_selectedDate == tomorrow) return 'Add a task for tomorrow...';
    return 'Add a task for ${DateFormat('d MMM').format(_selectedDate)}...';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final todosAsync = ref.watch(todosProvider);
    final todaysTodos = ref.watch(todaysTodosProvider);

    final completedCount = todaysTodos.where((t) => t.isCompleted).length;
    final totalCount = todaysTodos.length;
    final progress = totalCount > 0 ? (completedCount / totalCount) : 0.0;
    final isAllDone = totalCount > 0 && completedCount == totalCount;

    // Check achievement moment on transitions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkAchievement(completedCount, totalCount);
    });

    final cardContent = Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Row: "Today's tasks" + Morphing Count Chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Today's tasks",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isAllDone
                    ? Container(
                        key: const ValueKey('all_done_chip'),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: palette.accentSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: palette.accent.withValues(alpha: 0.3), width: AppDimens.hairline),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, size: 12, color: palette.accent),
                            const SizedBox(width: 4),
                            Text(
                              'All done',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: palette.accent,
                              ),
                            ),
                          ],
                        ),
                      )
                    : (totalCount > 0
                        ? Container(
                            key: const ValueKey('count_chip'),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: palette.cardRaised,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: palette.border, width: AppDimens.hairline),
                            ),
                            child: Text(
                              '$completedCount/$totalCount',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: palette.textSecondary,
                                fontFeatures: AppTypography.tabularFigures,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('empty_chip'))),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space12),

          // 2. Inline Task Input (Single add control with Date Selector)
          Container(
            decoration: BoxDecoration(
              color: palette.cardRaised,
              borderRadius: AppDimens.borderRadiusSm,
              border: Border.all(color: palette.border, width: AppDimens.hairline),
            ),
            child: Row(
              children: [
                // Date Chip Selector (Today / Tomorrow / Pick date)
                Padding(
                  padding: const EdgeInsets.only(left: 6.0),
                  child: PopupMenuButton<String>(
                    tooltip: 'Change date',
                    shape: RoundedRectangleBorder(
                      borderRadius: AppDimens.borderRadiusSm,
                      side: BorderSide(color: palette.border, width: AppDimens.hairline),
                    ),
                    color: palette.cardRaised,
                    onSelected: (val) {
                      if (val == 'today') {
                        setState(() => _selectedDate = AppDateUtils.today());
                      } else if (val == 'tomorrow') {
                        setState(() => _selectedDate = AppDateUtils.tomorrow());
                      } else if (val == 'custom') {
                        _pickDate(context);
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'today',
                        child: Text('Today', style: TextStyle(color: palette.textPrimary, fontSize: 13)),
                      ),
                      PopupMenuItem(
                        value: 'tomorrow',
                        child: Text('Tomorrow', style: TextStyle(color: palette.textPrimary, fontSize: 13)),
                      ),
                      PopupMenuItem(
                        value: 'custom',
                        child: Text('Pick date...', style: TextStyle(color: palette.accent, fontSize: 13)),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: palette.card,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: palette.border, width: AppDimens.hairline),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 12, color: palette.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            _dateChipLabel(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: palette.textPrimary,
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, size: 14, color: palette.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ),

                // TextField
                Expanded(
                  child: TextField(
                    key: const Key('home_quick_add_input'),
                    controller: _inputController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submitTask(),
                    style: TextStyle(fontSize: 13, color: palette.textPrimary),
                    decoration: InputDecoration(
                      hintText: _inputHint(),
                      hintStyle: TextStyle(fontSize: 13, color: palette.textMuted),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      fillColor: Colors.transparent,
                      filled: true,
                    ),
                  ),
                ),

                // Accent Submit Button
                Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: InkWell(
                    key: const Key('home_quick_add_button'),
                    onTap: _submitTask,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: palette.accent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.arrow_upward,
                        size: 16,
                        color: palette.onAccent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.space12),

          // 3. Task Rows / Empty / Skeletons / Error
          todosAsync.when(
            data: (_) {
              if (todaysTodos.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: EmptyState(
                    icon: Icons.checklist_outlined,
                    title: 'Nothing planned yet',
                    message: 'Add your first task for today.',
                  ),
                );
              }

              return Column(
                children: todaysTodos.map((todo) {
                  return TodoItemRow(
                    key: ValueKey(todo.id),
                    todo: todo,
                  );
                }).toList(),
              );
            },
            loading: () => Column(
              children: [
                SkeletonBox(height: 48, borderRadius: AppDimens.borderRadiusSm),
                const SizedBox(height: 8),
                SkeletonBox(height: 48, borderRadius: AppDimens.borderRadiusSm),
              ],
            ),
            error: (err, _) => ErrorState(
              message: 'Failed to load tasks: $err',
              onRetry: () => ref.read(todosProvider.notifier).refreshTodos(),
            ),
          ),
        ],
      ),
    );

    return PulseRing(
      trigger: _pulseTrigger,
      child: CardWithProgressStroke(
        progress: progress,
        radius: 16.0,
        backgroundColor: palette.card,
        child: cardContent,
      ),
    );
  }
}
