import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/theme.dart';
import '../../providers/habits_providers.dart';
import '../../widgets/responsive_container.dart';
import 'widgets/add_habit_sheet.dart';
import 'widgets/habits_overview_tab.dart';
import 'widgets/weekly_report_tab.dart';

/// Habits Screen (Stage 6).
/// Features:
/// - Top segmented toggle: Overview | Weekly Report
/// - Sole add control: `+ New Habit` opening `AddHabitSheet` (title only)
/// - Zero FloatingActionButton
class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  int _selectedSegment = 0; // 0: Overview, 1: Weekly Report

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Habits',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: OutlinedButton.icon(
              key: const Key('add_habit_button'),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Habit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryText,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadius8),
              ),
              onPressed: () => AddHabitSheet.show(context),
            ),
          ),
          IconButton(
            key: const Key('habits_refresh_button'),
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh habits',
            onPressed: () async {
              await ref.read(habitsProvider.notifier).refresh();
              await ref.read(habitLogsProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Segmented Toggle: Overview | Weekly Report
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 4.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppTheme.borderRadius8,
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSegmentButton(
                          title: 'Overview',
                          icon: Icons.calendar_view_month_outlined,
                          isSelected: _selectedSegment == 0,
                          onTap: () => setState(() => _selectedSegment = 0),
                        ),
                      ),
                      Container(width: 1, height: 32, color: AppColors.border),
                      Expanded(
                        child: _buildSegmentButton(
                          title: 'Weekly Report',
                          icon: Icons.bar_chart_outlined,
                          isSelected: _selectedSegment == 1,
                          onTap: () => setState(() => _selectedSegment = 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Tab Content
              Expanded(
                child: _selectedSegment == 0
                    ? const HabitsOverviewTab()
                    : const WeeklyReportTab(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppTheme.borderRadius8,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryText : Colors.transparent,
          borderRadius: AppTheme.borderRadius8,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.background : AppColors.secondaryText,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.background : AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
