import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/theme.dart';
import '../core/services/exam_cleanup_service.dart';
import '../core/services/expense_reset_service.dart';
import '../core/services/rollover_service.dart';
import '../providers/academics_providers.dart';
import '../providers/expenses_providers.dart';
import '../providers/habits_providers.dart';
import '../providers/home_providers.dart';
import '../providers/workout_providers.dart';
import 'home/home_screen.dart';
import 'academics/academics_screen.dart';
import 'expenses/expenses_screen.dart';
import 'habits/habits_screen.dart';
import 'workout/workout_screen.dart';

/// Root navigation shell for the authenticated application.
/// Adapts between bottom NavigationBar (< 700px) and left NavigationRail (>= 700px).
/// Uses IndexedStack to preserve state between tabs.
/// Contains NO FloatingActionButton and NO global add actions.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    AcademicsScreen(),
    ExpensesScreen(),
    HabitsScreen(),
    WorkoutScreen(),
  ];

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
        await ref.read(workoutDaysProvider.notifier).refresh();
        await ref.read(workoutExercisesProvider.notifier).refresh();
      }
    } catch (e) {
      debugPrint('MainShell: error running background sync: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 700;

        if (isDesktop) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryText,
                        borderRadius: AppTheme.borderRadius8,
                      ),
                      child: const Center(
                        child: Text(
                          'A',
                          style: TextStyle(
                            color: AppColors.background,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.check_box_outlined),
                      selectedIcon: Icon(Icons.check_box),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.school_outlined),
                      selectedIcon: Icon(Icons.school),
                      label: Text('Academics'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.account_balance_wallet_outlined),
                      selectedIcon: Icon(Icons.account_balance_wallet),
                      label: Text('Expenses'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.repeat_outlined),
                      selectedIcon: Icon(Icons.repeat),
                      label: Text('Habits'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.fitness_center_outlined),
                      selectedIcon: Icon(Icons.fitness_center),
                      label: Text('Workout'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1, color: AppColors.border),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _screens,
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.check_box_outlined),
                selectedIcon: Icon(Icons.check_box),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school),
                label: 'Academics',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet),
                label: 'Expenses',
              ),
              NavigationDestination(
                icon: Icon(Icons.repeat_outlined),
                selectedIcon: Icon(Icons.repeat),
                label: 'Habits',
              ),
              NavigationDestination(
                icon: Icon(Icons.fitness_center_outlined),
                selectedIcon: Icon(Icons.fitness_center),
                label: 'Workout',
              ),
            ],
          ),
        );
      },
    );
  }
}
