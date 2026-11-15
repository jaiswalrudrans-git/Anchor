import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/dimens.dart';
import '../../core/constants/theme.dart';
import '../../core/services/rollover_service.dart';
import '../../core/utils/responsive.dart';
import '../../providers/home_providers.dart';
import '../../widgets/profile/profile_avatar.dart';
import '../../widgets/profile/profile_menu.dart';
import '../../widgets/responsive/page_container.dart';
import 'widgets/academic_radar_slot.dart';
import 'widgets/kill_idle_widget.dart';
import 'widgets/todays_tasks_card.dart';
import 'widgets/tomorrow_section.dart';

/// Complete Home Screen (Polish Stage 3).
/// Includes:
/// - Header block: time-based greeting and clean date line
/// - Kill Idle Time banner with animated progress bar & unlock transition
/// - Today's Tasks card with clockwise progress stroke, inline task input, and achievement pulse
/// - Collapsible Tomorrow section with its own inline pre-scheduler
/// - Academic Radar and Tomorrow preview slots
/// - Responsive two-column layout on expanded (>= 900 dp) and single column on compact/medium (< 900 dp).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Future<void> _handleRefresh() async {
    await ref.read(rolloverServiceProvider).runRollover();
    await ref.read(todosProvider.notifier).refreshTodos();
    await ref.read(idlePromptsProvider.notifier).seedIfEmpty();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getDateString() {
    return DateFormat('EEEE, d MMM').format(DateTime.now());
  }

  Widget _buildHeaderBlock(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _getGreeting(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _getDateString(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: palette.textSecondary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isExpanded = Breakpoints.isExpanded(context);

    // Left Column Content: Header, Kill Idle, Today's Tasks, Tomorrow
    final leftColumnWidgets = [
      _buildHeaderBlock(context),
      const SizedBox(height: AppDimens.space16),
      const KillIdleWidget(),
      const TodaysTasksCard(),
      const SizedBox(height: AppDimens.space16),
      const TomorrowSection(),
    ];

    // Right Column Content: Academic Radar
    const rightColumnWidgets = [AcademicRadarSlot()];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh & Check Rollover',
            onPressed: _handleRefresh,
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: ProfileAvatar(
                key: const Key('home_profile_avatar_button'),
                size: 36,
                tooltip: 'Profile and appearance',
                onTap: () => ProfileMenu.show(context),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: palette.accent,
          backgroundColor: palette.cardRaised,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: PageContainer(
              padding: EdgeInsets.symmetric(
                horizontal: Breakpoints.horizontalPadding(
                  Breakpoints.of(context),
                ),
                vertical: 20.0,
              ),
              child: isExpanded
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left column (flex 3)
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: leftColumnWidgets,
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Right column (flex 2)
                        const Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: rightColumnWidgets,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...leftColumnWidgets,
                        const SizedBox(height: AppDimens.space24),
                        ...rightColumnWidgets,
                        const SizedBox(height: 32),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
