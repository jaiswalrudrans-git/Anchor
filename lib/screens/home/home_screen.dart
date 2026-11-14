import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/rollover_service.dart';
import '../../core/utils/date_utils.dart';
import '../../providers/home_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/responsive_container.dart';
import 'widgets/academic_radar_slot.dart';
import 'widgets/add_todo_sheet.dart';
import 'widgets/kill_idle_widget.dart';
import 'widgets/todo_item_row.dart';
import 'widgets/workout_strip_slot.dart';

/// Complete Home Screen for Stage 2.
/// Includes Kill Idle Time, Smart Carry-Over To-Do List, Tomorrow's section,
/// and placeholder slots for Academic Radar (Stage 3) and Workout Strip (Stage 7).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _quickAddController = TextEditingController();
  bool _isTomorrowExpanded = false;

  @override
  void dispose() {
    _quickAddController.dispose();
    super.dispose();
  }

  Future<void> _submitQuickAdd() async {
    final title = _quickAddController.text.trim();
    if (title.isEmpty) return;

    try {
      await ref.read(todosProvider.notifier).addTodo(title, AppDateUtils.today());
      _quickAddController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add task: $e')),
        );
      }
    }
  }

  Future<void> _handleRefresh() async {
    await ref.read(rolloverServiceProvider).runRollover();
    await ref.read(todosProvider.notifier).refreshTodos();
  }

  @override
  Widget build(BuildContext context) {
    final todosAsync = ref.watch(todosProvider);
    final todaysTodos = ref.watch(todaysTodosProvider);
    final tomorrowsTodos = ref.watch(tomorrowsTodosProvider);

    final completedCount = todaysTodos.where((t) => t.isCompleted).length;
    final totalCount = todaysTodos.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            key: const Key('home_add_todo_header_button'),
            icon: const Icon(Icons.add, size: 20),
            tooltip: 'Add Task',
            onPressed: () => AddTodoSheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh & Check Rollover',
            onPressed: _handleRefresh,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            shape: RoundedRectangleBorder(
              side: AppTheme.borderSide1,
              borderRadius: AppTheme.borderRadius8,
            ),
            onSelected: (value) async {
              if (value == 'sign_out') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Sign out'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ref.read(authServiceProvider).signOut();
                }
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'sign_out',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: AppColors.primaryText),
                    SizedBox(width: 12),
                    Text('Sign out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppColors.primaryText,
          backgroundColor: AppColors.background,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ResponsiveContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Top Area: Status / Kill Idle Time Banner
                  const KillIdleWidget(),

                  // 2. To-Do Widget: Smart Carry-Over To-Do List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            "Today's Tasks",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryText,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (totalCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border, width: 1),
                              ),
                              child: Text(
                                '$completedCount/$totalCount',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      TextButton.icon(
                        key: const Key('home_add_todo_action_button'),
                        onPressed: () => AddTodoSheet.show(context),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Task', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Inline Quick-Add Input
                  Container(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppTheme.borderRadius8,
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('home_quick_add_input'),
                            controller: _quickAddController,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submitQuickAdd(),
                            decoration: const InputDecoration(
                              hintText: 'Add a task for today...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              fillColor: Colors.transparent,
                            ),
                          ),
                        ),
                        IconButton(
                          key: const Key('home_quick_add_button'),
                          icon: const Icon(Icons.arrow_upward, size: 18),
                          tooltip: 'Add task for today',
                          color: AppColors.primaryText,
                          onPressed: _submitQuickAdd,
                        ),
                      ],
                    ),
                  ),

                  // To-Dos list / loading / empty
                  todosAsync.when(
                    data: (_) {
                      if (todaysTodos.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: EmptyState(
                            icon: Icons.checklist_outlined,
                            title: 'Nothing planned for today.',
                            message: 'Add a task above or plan pre-scheduled tasks for tomorrow.',
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
                    loading: () => const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: LoadingState(message: 'Loading your tasks...'),
                    ),
                    error: (err, _) => Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'Error loading tasks: $err',
                          style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Secondary Collapsible Section: Tomorrow
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppTheme.borderRadius8,
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isTomorrowExpanded = !_isTomorrowExpanded;
                            });
                          },
                          borderRadius: AppTheme.borderRadius8,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.next_plan_outlined,
                                      size: 18,
                                      color: AppColors.secondaryText,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Tomorrow',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryText,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppColors.border, width: 1),
                                      ),
                                      child: Text(
                                        '${tomorrowsTodos.length}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.secondaryText,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 18),
                                      tooltip: 'Pre-schedule for Tomorrow',
                                      splashRadius: 18,
                                      onPressed: () {
                                        AddTodoSheet.show(
                                          context,
                                          initialDate: AppDateUtils.tomorrow(),
                                        );
                                      },
                                    ),
                                    Icon(
                                      _isTomorrowExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      size: 20,
                                      color: AppColors.secondaryText,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_isTomorrowExpanded) ...[
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: tomorrowsTodos.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12.0),
                                    child: Center(
                                      child: Text(
                                        'No tasks pre-scheduled for tomorrow.',
                                        style: TextStyle(
                                          color: AppColors.secondaryText,
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. Slot: Academic Radar (Stage 3)
                  const AcademicRadarSlot(),

                  // 4. Slot: Workout Strip (Stage 7)
                  const WorkoutStripSlot(),

                  // Bottom padding for FAB spacing
                  const SizedBox(height: 72),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
