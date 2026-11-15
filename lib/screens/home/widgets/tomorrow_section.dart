import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/dimens.dart';
import '../../../core/constants/motion.dart';
import '../../../core/constants/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../providers/home_providers.dart';
import '../../../widgets/app_card.dart';
import 'todo_item_row.dart';

/// Collapsible section for pre-scheduling tasks for tomorrow.
class TomorrowSection extends ConsumerStatefulWidget {
  const TomorrowSection({super.key});

  @override
  ConsumerState<TomorrowSection> createState() => _TomorrowSectionState();
}

class _TomorrowSectionState extends ConsumerState<TomorrowSection> {
  bool _isExpanded = false;
  bool _showInlineInput = false;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitTomorrowTask() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    try {
      await ref
          .read(todosProvider.notifier)
          .addTodo(text, AppDateUtils.tomorrow());
      _controller.clear();
      setState(() {
        _showInlineInput = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pre-schedule task: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tomorrowsTodos = ref.watch(tomorrowsTodosProvider);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          InkWell(
            key: const Key('tomorrow_section_header'),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: AppDimens.borderRadiusMd,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.next_plan_outlined,
                          size: 18,
                          color: palette.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Tomorrow',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: palette.cardRaised,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: palette.border,
                              width: AppDimens.hairline,
                            ),
                          ),
                          child: Text(
                            '${tomorrowsTodos.length}',
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: const Key('tomorrow_add_button'),
                        icon: const Icon(Icons.add, size: 18),
                        tooltip: 'Add task for tomorrow',
                        splashRadius: 18,
                        color: palette.textPrimary,
                        onPressed: () {
                          setState(() {
                            _isExpanded = true;
                            _showInlineInput = true;
                          });
                        },
                      ),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 20,
                        color: palette.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Animated Collapsible Body
          AnimatedCrossFade(
            duration: Motion.base,
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Divider(
                  height: 1,
                  thickness: AppDimens.hairline,
                  color: palette.border,
                ),

                // Optional Inline Input for Tomorrow
                if (_showInlineInput)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                    child: Container(
                      decoration: BoxDecoration(
                        color: palette.cardRaised,
                        borderRadius: AppDimens.borderRadiusSm,
                        border: Border.all(
                          color: palette.border,
                          width: AppDimens.hairline,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: const Key('tomorrow_quick_add_input'),
                              controller: _controller,
                              autofocus: true,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submitTomorrowTask(),
                              style: TextStyle(
                                fontSize: 13,
                                color: palette.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Add a task for tomorrow...',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: palette.textMuted,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                fillColor: Colors.transparent,
                                filled: true,
                              ),
                            ),
                          ),
                          IconButton(
                            key: const Key('tomorrow_quick_add_button'),
                            icon: const Icon(Icons.arrow_upward, size: 16),
                            color: palette.accent,
                            onPressed: _submitTomorrowTask,
                          ),
                        ],
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: tomorrowsTodos.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Center(
                            child: Text(
                              'No tasks pre-scheduled for tomorrow.',
                              style: TextStyle(
                                color: palette.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: tomorrowsTodos.map((todo) {
                            return TodoItemRow(
                              key: ValueKey(todo.id),
                              todo: todo,
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
