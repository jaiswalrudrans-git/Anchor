import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/theme.dart';
import '../../providers/habits_providers.dart';
import '../../widgets/responsive/page_container.dart';
import '../../widgets/responsive/page_top_bar.dart';
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
    final palette = context.palette;

    return Scaffold(
      appBar: PageTopBar(
        title: const Text('Habits'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: OutlinedButton.icon(
              key: const Key('add_habit_button'),
              icon: const Icon(Icons.add, size: 16),
              label: const Text(
                'New Habit',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.textPrimary,
                side: BorderSide(color: palette.border),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.borderRadius8,
                ),
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
        child: PageContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Segmented Toggle: Overview | Weekly Report
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 4.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: palette.card,
                    borderRadius: AppTheme.borderRadius8,
                    border: Border.all(color: palette.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSegmentButton(
                          title: 'Overview',
                          icon: Icons.calendar_view_month_outlined,
                          isSelected: _selectedSegment == 0,
                          onTap: () => setState(() => _selectedSegment = 0),
                          palette: palette,
                        ),
                      ),
                      Container(width: 1, height: 32, color: palette.border),
                      Expanded(
                        child: _buildSegmentButton(
                          title: 'Weekly Report',
                          icon: Icons.bar_chart_outlined,
                          isSelected: _selectedSegment == 1,
                          onTap: () => setState(() => _selectedSegment = 1),
                          palette: palette,
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
    required AppPalette palette,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppTheme.borderRadius8,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        decoration: BoxDecoration(
          color: isSelected ? palette.selectedFill : Colors.transparent,
          borderRadius: AppTheme.borderRadius8,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? palette.onSelected : palette.textSecondary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? palette.onSelected
                      : palette.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
