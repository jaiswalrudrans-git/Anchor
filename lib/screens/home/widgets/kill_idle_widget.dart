import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/dimens.dart';
import '../../../core/constants/motion.dart';
import '../../../core/constants/theme.dart';
import '../../../providers/home_providers.dart';
import '../../../widgets/motion/animated_progress_bar.dart';
import '../../../widgets/motion/pressable_scale.dart';
import '../../../widgets/motion/pulse_ring.dart';
import 'kill_idle_dialog.dart';

/// Top banner of Home: shows unlocked "Kill Idle Time" action when all tasks today are done,
/// or a muted locked status line with an animated progress bar otherwise.
class KillIdleWidget extends ConsumerStatefulWidget {
  const KillIdleWidget({super.key});

  @override
  ConsumerState<KillIdleWidget> createState() => _KillIdleWidgetState();
}

class _KillIdleWidgetState extends ConsumerState<KillIdleWidget> {
  bool _prevUnlocked = false;
  bool _pulseTrigger = false;

  @override
  void initState() {
    super.initState();
    _prevUnlocked = ref.read(killIdleUnlockedProvider);
  }

  void _checkUnlockTransition(bool isUnlocked) {
    if (!_prevUnlocked && isUnlocked) {
      setState(() {
        _pulseTrigger = true;
      });
      Future.delayed(Motion.moment, () {
        if (mounted) setState(() => _pulseTrigger = false);
      });
    }
    _prevUnlocked = isUnlocked;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final todaysTodos = ref.watch(todaysTodosProvider);
    final isUnlocked = ref.watch(killIdleUnlockedProvider);

    final completed = todaysTodos.where((t) => t.isCompleted).length;
    final total = todaysTodos.length;
    final progress = total > 0 ? (completed / total) : 0.0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkUnlockTransition(isUnlocked);
    });

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.space16),
      child: AnimatedSwitcher(
        duration: Motion.base,
        transitionBuilder: (child, animation) {
          final scaleAnim = Tween<double>(begin: 0.98, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: scaleAnim, child: child),
          );
        },
        child: isUnlocked
            ? PulseRing(
                key: const ValueKey('unlocked_kill_idle_container'),
                trigger: _pulseTrigger,
                child: PressableScale(
                  onTap: () => KillIdleDialog.show(context),
                  child: Container(
                    key: const Key('kill_idle_time_button'),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: palette.accent,
                      borderRadius: AppDimens.borderRadiusMd,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt, size: 20, color: palette.onAccent),
                        const SizedBox(width: 8),
                        Text(
                          'Kill Idle Time',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: palette.onAccent,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : Container(
                key: const Key('kill_idle_locked_status'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: palette.card,
                  borderRadius: AppDimens.borderRadiusMd,
                  border: Border.all(
                    color: palette.border,
                    width: AppDimens.hairline,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 16,
                          color: palette.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            getKillIdleStatusMessage(todaysTodos),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: palette.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (total > 0 && completed < total) ...[
                      const SizedBox(height: 10),
                      AnimatedProgressBar(
                        value: progress,
                        height: 4.0,
                        colorOverride: palette.accent,
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
