import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme.dart';
import '../../../providers/home_providers.dart';
import 'kill_idle_dialog.dart';

/// Top banner of Home: shows unlocked "Kill Idle Time" action when all tasks today are done,
/// or a muted locked status line otherwise.
class KillIdleWidget extends ConsumerWidget {
  const KillIdleWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todaysTodos = ref.watch(todaysTodosProvider);
    final isUnlocked = ref.watch(killIdleUnlockedProvider);

    if (isUnlocked) {
      // Prominent unlocked button
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        width: double.infinity,
        child: ElevatedButton.icon(
          key: const Key('kill_idle_time_button'),
          onPressed: () => KillIdleDialog.show(context),
          icon: const Icon(Icons.bolt, size: 20),
          label: const Text(
            'Kill Idle Time',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryText,
            foregroundColor: AppColors.background,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: AppTheme.borderRadius8,
            ),
          ),
        ),
      );
    }

    // Muted locked status line
    final message = getKillIdleStatusMessage(todaysTodos);
    return Container(
      key: const Key('kill_idle_locked_status'),
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTheme.borderRadius8,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline,
            size: 16,
            color: AppColors.secondaryText,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
