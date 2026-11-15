import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/categories.dart';
import '../../core/constants/dimens.dart';
import '../../core/constants/motion.dart';
import '../../core/constants/theme.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/responsive.dart';
import '../../providers/academics_providers.dart';
import '../../providers/expenses_providers.dart';
import '../../providers/home_providers.dart';
import '../../screens/main_shell.dart';
import '../responsive/adaptive_sheet.dart';
import 'forms/assignment_form_body.dart';
import 'forms/exam_form_body.dart';
import 'forms/habit_today_checklist.dart';
import 'forms/todo_form_body.dart';
import 'forms/transaction_form_body.dart';

/// The 5 item types available in the Global Quick Add sheet.
enum QuickAddType { todo, assignment, exam, expense, habit }

/// Smart default type provider based on current screen and segment:
/// - Home (0) -> To-do
/// - Academics (1): Syllabus or Assignments -> Assignment; Exams -> Exam
/// - Expenses (2) -> Expense
/// - Habits (3) -> Habit
final quickAddContextProvider = Provider<QuickAddType>((ref) {
  final navIndex = ref.watch(mainNavIndexProvider);
  switch (navIndex) {
    case 0:
      return QuickAddType.todo;
    case 1:
      final segment = ref.watch(academicsActiveSegmentProvider);
      if (segment == AcademicsSegment.exams) {
        return QuickAddType.exam;
      }
      return QuickAddType.assignment;
    case 2:
      return QuickAddType.expense;
    case 3:
      return QuickAddType.habit;
    default:
      return QuickAddType.todo;
  }
});

/// Global Quick Add sheet/dialog accessible from every tab.
/// Supports creating To-dos, Assignments, Exams, Expenses, and ticking today's Habits.
class QuickAddSheet extends ConsumerStatefulWidget {
  final QuickAddType? initialType;

  const QuickAddSheet({super.key, this.initialType});

  /// Displays the QuickAddSheet adaptively: bottom sheet on compact, dialog on medium/expanded.
  static Future<void> show(BuildContext context) {
    final palette = context.palette;
    return showAdaptiveSheet(
      context: context,
      backgroundColor: palette.cardRaised,
      shape: Breakpoints.isCompact(context)
          ? const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppDimens.radiusXl),
              ),
            )
          : RoundedRectangleBorder(
              borderRadius: AppDimens.borderRadiusLg,
              side: BorderSide(
                color: palette.border,
                width: AppDimens.hairline,
              ),
            ),
      builder: (ctx) => const QuickAddSheet(),
    );
  }

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  late QuickAddType _currentType;

  // Shared / Title controller (preserved between todo, assignment, exam)
  late final TextEditingController _titleController;

  // Expense controllers
  late final TextEditingController _amountController;
  late final TextEditingController _expenseTitleController;

  // Date selections
  late DateTime _selectedDate;
  late DateTime _dueDate;
  late DateTime _examDate;

  // Academic subject
  String? _selectedSubjectId;

  // Expense state
  String _txType = 'spent';
  String _category = ExpenseCategories.general;

  // Form submission state
  bool _isSubmitting = false;
  String? _errorMessage;

  // Scroll controller for chip row
  final ScrollController _chipScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentType = widget.initialType ?? ref.read(quickAddContextProvider);

    _titleController = TextEditingController()..addListener(_onFieldChanged);
    _amountController = TextEditingController()..addListener(_onFieldChanged);
    _expenseTitleController = TextEditingController()
      ..addListener(_onFieldChanged);

    final today = AppDateUtils.today();
    _selectedDate = today;
    _dueDate = today;
    _examDate = today;
  }

  @override
  void dispose() {
    _titleController.removeListener(_onFieldChanged);
    _amountController.removeListener(_onFieldChanged);
    _expenseTitleController.removeListener(_onFieldChanged);

    _titleController.dispose();
    _amountController.dispose();
    _expenseTitleController.dispose();
    _chipScrollController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  bool get _isDirty {
    switch (_currentType) {
      case QuickAddType.todo:
      case QuickAddType.assignment:
      case QuickAddType.exam:
        return _titleController.text.trim().isNotEmpty;
      case QuickAddType.expense:
        return _amountController.text.trim().isNotEmpty ||
            _expenseTitleController.text.trim().isNotEmpty;
      case QuickAddType.habit:
        return false;
    }
  }

  bool get _isValid {
    if (_isSubmitting) return false;
    switch (_currentType) {
      case QuickAddType.todo:
      case QuickAddType.assignment:
      case QuickAddType.exam:
        return _titleController.text.trim().isNotEmpty;
      case QuickAddType.expense:
        final amt = double.tryParse(_amountController.text.trim());
        return amt != null && amt > 0;
      case QuickAddType.habit:
        return true;
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard this entry?'),
        content: const Text('You have unsaved changes that will be lost.'),
        actions: [
          TextButton(
            key: const Key('discard_cancel_button'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('discard_confirm_button'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Discard',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _selectType(QuickAddType newType) {
    if (_currentType == newType) return;

    setState(() {
      _currentType = newType;
      _errorMessage = null;

      // If switching away from expense, clear expense controllers
      if (newType != QuickAddType.expense) {
        _amountController.clear();
        _expenseTitleController.clear();
      }
    });

    // Auto-scroll chip into view
    final index = QuickAddType.values.indexOf(newType);
    if (_chipScrollController.hasClients) {
      _chipScrollController.animateTo(
        (index * 100.0).clamp(
          0.0,
          _chipScrollController.position.maxScrollExtent,
        ),
        duration: Motion.base,
        curve: Motion.standard,
      );
    }
  }

  void _navigateType(int delta) {
    const values = QuickAddType.values;
    final nextIndex = (_currentType.index + delta).clamp(0, values.length - 1);
    if (nextIndex != _currentType.index) {
      _selectType(values[nextIndex]);
    }
  }

  Future<void> _submit() async {
    if (!_isValid || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      switch (_currentType) {
        case QuickAddType.todo:
          final todosNotifier = ref.read(todosProvider.notifier);
          final title = _titleController.text.trim();
          final newTodo = await todosNotifier.addTodo(title, _selectedDate);
          if (mounted) navigator.pop();

          await todosNotifier.refreshTodos();

          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: const Text('Added to to-do'),
              duration: const Duration(seconds: 4),
              action: newTodo != null
                  ? SnackBarAction(
                      label: 'Undo',
                      onPressed: () async {
                        await todosNotifier.delete(newTodo.id);
                      },
                    )
                  : null,
            ),
          );
          break;

        case QuickAddType.assignment:
          final academicItemsNotifier = ref.read(
            academicItemsProvider.notifier,
          );
          final title = _titleController.text.trim();
          final newItem = await academicItemsNotifier.addItem(
            title: title,
            itemType: 'assignment',
            dueDate: _dueDate,
            subjectId: _selectedSubjectId,
          );
          if (mounted) navigator.pop();

          await academicItemsNotifier.refresh();

          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: const Text('Assignment added'),
              duration: const Duration(seconds: 4),
              action: newItem != null
                  ? SnackBarAction(
                      label: 'Undo',
                      onPressed: () async {
                        await academicItemsNotifier.deleteItem(newItem.id);
                      },
                    )
                  : null,
            ),
          );
          break;

        case QuickAddType.exam:
          final academicItemsNotifier = ref.read(
            academicItemsProvider.notifier,
          );
          final title = _titleController.text.trim();
          final newItem = await academicItemsNotifier.addItem(
            title: title,
            itemType: 'exam',
            dueDate: _examDate,
            subjectId: _selectedSubjectId,
          );
          if (mounted) navigator.pop();

          await academicItemsNotifier.refresh();

          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: const Text('Exam added'),
              duration: const Duration(seconds: 4),
              action: newItem != null
                  ? SnackBarAction(
                      label: 'Undo',
                      onPressed: () async {
                        await academicItemsNotifier.deleteItem(newItem.id);
                      },
                    )
                  : null,
            ),
          );
          break;

        case QuickAddType.expense:
          final allTransactionsNotifier = ref.read(
            allTransactionsProvider.notifier,
          );
          final monthSummariesNotifier = ref.read(
            monthSummariesProvider.notifier,
          );
          final expenseSettingsNotifier = ref.read(
            expenseSettingsProvider.notifier,
          );
          final amount = double.parse(_amountController.text.trim());
          final title = _expenseTitleController.text.trim();
          final newTx = await allTransactionsNotifier.logTransaction(
            amount: amount,
            title: title,
            category: _category,
            txType: _txType,
          );
          if (mounted) navigator.pop();

          await allTransactionsNotifier.refresh();
          await monthSummariesNotifier.refresh();
          await expenseSettingsNotifier.refreshSettings();

          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: const Text('Expense logged'),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () async {
                  await allTransactionsNotifier.deleteTransaction(newTx);
                },
              ),
            ),
          );
          break;

        case QuickAddType.habit:
          if (mounted) navigator.pop();
          break;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildTypeChip({
    required QuickAddType type,
    required String label,
    required IconData icon,
    required AppPalette palette,
  }) {
    final isSelected = _currentType == type;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('quick_add_type_${type.name}'),
          onTap: () => _selectType(type),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: Motion.snap,
            curve: Motion.standard,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? palette.selectedFill : palette.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? palette.selectedFill : palette.border,
                width: AppDimens.hairline,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected
                      ? palette.onSelected
                      : palette.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? palette.onSelected
                        : palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormBody() {
    switch (_currentType) {
      case QuickAddType.todo:
        return TodoFormBody(
          titleController: _titleController,
          selectedDate: _selectedDate,
          onDateChanged: (d) => setState(() => _selectedDate = d),
          onSubmit: _submit,
          autofocus: true,
        );

      case QuickAddType.assignment:
        return AssignmentFormBody(
          titleController: _titleController,
          dueDate: _dueDate,
          onDateChanged: (d) => setState(() => _dueDate = d),
          selectedSubjectId: _selectedSubjectId,
          onSubjectChanged: (s) => setState(() => _selectedSubjectId = s),
          onSubmit: _submit,
          autofocus: true,
        );

      case QuickAddType.exam:
        return ExamFormBody(
          titleController: _titleController,
          examDate: _examDate,
          onDateChanged: (d) => setState(() => _examDate = d),
          selectedSubjectId: _selectedSubjectId,
          onSubjectChanged: (s) => setState(() => _selectedSubjectId = s),
          onSubmit: _submit,
          autofocus: true,
        );

      case QuickAddType.expense:
        return TransactionFormBody(
          amountController: _amountController,
          titleController: _expenseTitleController,
          txType: _txType,
          onTxTypeChanged: (t) => setState(() => _txType = t),
          category: _category,
          onCategoryChanged: (c) => setState(() => _category = c),
          onSubmit: _submit,
        );

      case QuickAddType.habit:
        return HabitTodayChecklist(
          onOpenHabits: () {
            Navigator.of(context).pop();
            ref.read(mainNavIndexProvider.notifier).setIndex(3);
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isCompact = Breakpoints.isCompact(context);
    final nav = Navigator.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canClose = await _confirmDiscard();
        if (canClose && mounted) {
          nav.pop();
        }
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () async {
            final canClose = await _confirmDiscard();
            if (canClose && mounted) nav.pop();
          },
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
              _navigateType(-1),
          const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
              _navigateType(1),
        },
        child: Container(
          key: const Key('quick_add_sheet'),
          constraints: BoxConstraints(
            maxHeight: isCompact
                ? MediaQuery.sizeOf(context).height * 0.9
                : 680,
          ),
          decoration: BoxDecoration(
            color: palette.cardRaised,
            borderRadius: isCompact
                ? const BorderRadius.vertical(
                    top: Radius.circular(AppDimens.radiusXl),
                  )
                : AppDimens.borderRadiusLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Drag handle for compact bottom sheet
              if (isCompact) ...[
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ] else ...[
                const SizedBox(height: 16),
              ],

              // 2. Header Row: Quick add title and Close icon
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quick add',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    IconButton(
                      key: const Key('quick_add_close_button'),
                      icon: const Icon(Icons.close, size: 20),
                      color: palette.textSecondary,
                      tooltip: 'Close',
                      onPressed: () async {
                        final canClose = await _confirmDiscard();
                        if (canClose && mounted) {
                          nav.pop();
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 3. Type Selector Chips
              SizedBox(
                height: 38,
                child: ListView(
                  controller: _chipScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  children: [
                    _buildTypeChip(
                      type: QuickAddType.todo,
                      label: 'To-do',
                      icon: Icons.check_box_outlined,
                      palette: palette,
                    ),
                    _buildTypeChip(
                      type: QuickAddType.assignment,
                      label: 'Assignment',
                      icon: Icons.assignment_outlined,
                      palette: palette,
                    ),
                    _buildTypeChip(
                      type: QuickAddType.exam,
                      label: 'Exam',
                      icon: Icons.school_outlined,
                      palette: palette,
                    ),
                    _buildTypeChip(
                      type: QuickAddType.expense,
                      label: 'Expense',
                      icon: Icons.account_balance_wallet_outlined,
                      palette: palette,
                    ),
                    _buildTypeChip(
                      type: QuickAddType.habit,
                      label: 'Habit',
                      icon: Icons.repeat_outlined,
                      palette: palette,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Scrollable Form Body with Keyboard Inset
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 20.0,
                    right: 20.0,
                    bottom: MediaQuery.viewInsetsOf(context).bottom + 16.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Error Banner if submission failed
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: palette.danger.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: palette.danger.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 16,
                                color: palette.danger,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: palette.danger,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Animated cross-fade + AnimatedSize container for active form body
                      AnimatedSize(
                        duration: Motion.snap,
                        curve: Motion.standard,
                        alignment: Alignment.topCenter,
                        child: AnimatedSwitcher(
                          duration: Motion.snap,
                          switchInCurve: Motion.standard,
                          switchOutCurve: Motion.standard,
                          child: KeyedSubtree(
                            key: ValueKey(_currentType),
                            child: _buildFormBody(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 5. Submit Button (Done)
                      SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          key: const Key('quick_add_done_button'),
                          onPressed: _isValid ? _submit : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: palette.accent,
                            foregroundColor: palette.onAccent,
                            disabledBackgroundColor: palette.accent.withValues(
                              alpha: 0.3,
                            ),
                            disabledForegroundColor: palette.onAccent
                                .withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppDimens.borderRadiusSm,
                            ),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      palette.onAccent,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Done',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
