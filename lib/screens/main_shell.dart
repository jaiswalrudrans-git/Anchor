import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/dimens.dart';
import '../core/constants/theme.dart';
import '../core/services/exam_cleanup_service.dart';
import '../core/services/expense_reset_service.dart';
import '../core/services/rollover_service.dart';
import '../core/utils/responsive.dart';
import '../providers/academics_providers.dart';
import '../providers/expenses_providers.dart';
import '../providers/habits_providers.dart';
import '../providers/home_providers.dart';
import '../widgets/navigation/floating_dock.dart';
import '../widgets/navigation/floating_rail.dart';
import '../widgets/navigation/quick_add_button.dart';
import '../widgets/quick_add/quick_add_sheet.dart';
import 'academics/academics_screen.dart';
import 'expenses/expenses_screen.dart';
import 'habits/habits_screen.dart';
import 'home/home_screen.dart';

class MainNavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

/// Controls active navigation tab index in MainShell:
/// 0 = Home, 1 = Academics, 2 = Expenses, 3 = Habits.
final mainNavIndexProvider = NotifierProvider<MainNavIndexNotifier, int>(() {
  return MainNavIndexNotifier();
});

const List<DockDestination> _navDestinations = [
  DockDestination(
    label: 'Home',
    icon: Icons.check_box_outlined,
    selectedIcon: Icons.check_box,
    key: Key('nav_tab_home'),
  ),
  DockDestination(
    label: 'Academics',
    icon: Icons.school_outlined,
    selectedIcon: Icons.school,
    key: Key('nav_tab_academics'),
  ),
  DockDestination(
    label: 'Expenses',
    icon: Icons.account_balance_wallet_outlined,
    selectedIcon: Icons.account_balance_wallet,
    key: Key('nav_tab_expenses'),
  ),
  DockDestination(
    label: 'Habits',
    icon: Icons.repeat_outlined,
    selectedIcon: Icons.repeat,
    key: Key('nav_tab_habits'),
  ),
];

/// Root navigation shell for the authenticated application.
/// Stage 2C: Floating Dock Footer (pop-out tabs + separate round plus).
/// - compact (< 600 dp): floating dock with gliding notch & pop-out bubble + separate Quick Add button
/// - medium & expanded (>= 600 dp): floating rounded NavigationRail with sliding bubble & leading Quick Add
/// Desktop shortcut: Ctrl+N triggers Quick Add.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> with WidgetsBindingObserver {
  static const List<Widget> _screens = [
    HomeScreen(),
    AcademicsScreen(),
    ExpensesScreen(),
    HabitsScreen(),
  ];

  bool _isQuickAddOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Run rollover engine and past exam cleanup on initial authenticated launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerBackgroundSync();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _triggerBackgroundSync();
    }
  }

  Future<void> _triggerBackgroundSync() async {
    try {
      await ref.read(rolloverServiceProvider).runRollover();
      await ref.read(examCleanupServiceProvider).runCleanup();
      await ref.read(expenseResetServiceProvider).runMonthlyReset();
      if (mounted) {
        await ref.read(todosProvider.notifier).refreshTodos();
        await ref.read(academicItemsProvider.notifier).refresh();
        await ref.read(expenseSettingsProvider.notifier).refreshSettings();
        await ref.read(allTransactionsProvider.notifier).refresh();
        await ref.read(monthSummariesProvider.notifier).refresh();
        await ref.read(habitsProvider.notifier).refresh();
        await ref.read(habitLogsProvider.notifier).refresh();
      }
    } catch (e) {
      debugPrint('MainShell: error running background sync: $e');
    }
  }

  Future<void> _openQuickAdd() async {
    if (_isQuickAddOpen) return;
    setState(() => _isQuickAddOpen = true);
    try {
      await QuickAddSheet.show(context);
    } finally {
      if (mounted) {
        setState(() => _isQuickAddOpen = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final currentIndex = ref.watch(mainNavIndexProvider);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): _openQuickAdd,
      },
      child: Focus(
        autofocus: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sizeClass = Breakpoints.fromWidth(constraints.maxWidth);

            if (sizeClass != SizeClass.compact) {
              final isExpanded = sizeClass == SizeClass.expanded;

              return Scaffold(
                backgroundColor: palette.background,
                body: Row(
                  children: [
                    FloatingRail(
                      destinations: _navDestinations,
                      selectedIndex: currentIndex,
                      onSelected: (index) {
                        ref.read(mainNavIndexProvider.notifier).setIndex(index);
                      },
                      onQuickAdd: _openQuickAdd,
                      isQuickAddOpen: _isQuickAddOpen,
                      isExpanded: isExpanded,
                    ),
                    VerticalDivider(
                      thickness: 1,
                      width: 1,
                      color: palette.border,
                    ),
                    Expanded(
                      child: IndexedStack(
                        index: currentIndex,
                        children: _screens,
                      ),
                    ),
                  ],
                ),
              );
            }

            final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
            final safeBottom = MediaQuery.paddingOf(context).bottom;

            return Scaffold(
              backgroundColor: palette.background,
              resizeToAvoidBottomInset: false,
              body: Stack(
                children: [
                  // Page content with IndexedStack
                  Positioned.fill(
                    child: IndexedStack(
                      index: currentIndex,
                      children: _screens,
                    ),
                  ),

                  // Floating Dock + Quick Add Button pinned to bottom
                  Positioned(
                    left: AppDimens.dockMarginHorizontal,
                    right: AppDimens.dockMarginHorizontal,
                    bottom: AppDimens.dockBottomOffset + safeBottom,
                    child: AnimatedSlide(
                      offset: isKeyboardOpen ? const Offset(0, 2.5) : Offset.zero,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: FloatingDock(
                              destinations: _navDestinations,
                              selectedIndex: currentIndex,
                              onSelected: (idx) {
                                ref.read(mainNavIndexProvider.notifier).setIndex(idx);
                              },
                            ),
                          ),
                          const SizedBox(width: AppDimens.dockGap),
                          QuickAddButton(
                            onPressed: _openQuickAdd,
                            isOpen: _isQuickAddOpen,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
