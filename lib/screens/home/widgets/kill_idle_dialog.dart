import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/dimens.dart';
import '../../../core/constants/motion.dart';
import '../../../core/constants/theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/idle_prompt.dart';
import '../../../providers/home_providers.dart';
import '../../../widgets/motion/fade_slide_in.dart';
import '../../../widgets/motion/pulse_ring.dart';
import '../../../widgets/skeleton_box.dart';

/// Focus Dialog & Timer displayed when Kill Idle Time is unlocked and clicked.
/// Features an adaptive surface, random challenge shuffling, circular 15:00 focus timer,
/// completion moment, and pool manager with undo.
class KillIdleDialog extends ConsumerStatefulWidget {
  final bool isSheet;

  const KillIdleDialog({
    super.key,
    this.isSheet = false,
  });

  static Future<void> show(BuildContext context) {
    final isCompact = Breakpoints.isCompact(context);
    if (isCompact) {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => const KillIdleDialog(isSheet: true),
      );
    } else {
      return showDialog(
        context: context,
        builder: (ctx) => const KillIdleDialog(isSheet: false),
      );
    }
  }

  @override
  ConsumerState<KillIdleDialog> createState() => _KillIdleDialogState();
}

class _KillIdleDialogState extends ConsumerState<KillIdleDialog> {
  static const int _initialSeconds = 15 * 60; // 15:00
  int _remainingSeconds = _initialSeconds;
  bool _isTimerRunning = false;
  Timer? _countdownTimer;

  IdlePrompt? _currentPrompt;
  int _shuffleKey = 0;
  bool _isSessionFinished = false;
  bool _finishPulseTrigger = false;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startOrPauseTimer() {
    if (_isTimerRunning) {
      _countdownTimer?.cancel();
      setState(() {
        _isTimerRunning = false;
      });
    } else {
      setState(() {
        _isTimerRunning = true;
      });
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 1) {
          setState(() {
            _remainingSeconds--;
          });
        } else {
          timer.cancel();
          setState(() {
            _remainingSeconds = 0;
            _isTimerRunning = false;
            _isSessionFinished = true;
            _finishPulseTrigger = true;
          });
          Haptics.success();
          Future.delayed(Motion.moment, () {
            if (mounted) setState(() => _finishPulseTrigger = false);
          });
        }
      });
    }
  }

  void _resetTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _remainingSeconds = _initialSeconds;
      _isSessionFinished = false;
    });
  }

  void _shufflePrompt(List<IdlePrompt> pool) {
    if (pool.isEmpty) return;
    if (pool.length == 1) {
      setState(() {
        _currentPrompt = pool.first;
        _shuffleKey++;
      });
      return;
    }

    final candidates = pool.where((p) => p.id != _currentPrompt?.id).toList();
    final randomItem = candidates[math.Random().nextInt(candidates.length)];
    setState(() {
      _currentPrompt = randomItem;
      _shuffleKey++;
    });
  }

  String _formatTime(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _openManagePool(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.palette.cardRaised,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLg)),
        side: BorderSide(color: context.palette.border, width: AppDimens.hairline),
      ),
      builder: (ctx) => const _ManagePoolSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final promptsAsync = ref.watch(idlePromptsProvider);
    final prompts = promptsAsync.value ?? [];

    if (prompts.isNotEmpty) {
      if (_currentPrompt == null || !prompts.any((p) => p.id == _currentPrompt!.id)) {
        _currentPrompt = prompts[math.Random().nextInt(prompts.length)];
      }
    } else {
      _currentPrompt = null;
    }

    final timerFraction = _isSessionFinished
        ? 1.0
        : (_initialSeconds > 0 ? (_remainingSeconds / _initialSeconds) : 0.0);

    final dialogContent = Padding(
      padding: const EdgeInsets.all(AppDimens.space24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt, size: 22, color: palette.accent),
                  const SizedBox(width: 8),
                  Text(
                    'Kill Idle Time',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close, size: 20, color: palette.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
                splashRadius: 18,
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space16),

          // Random Challenge Card with Animated Shuffle
          Container(
            padding: const EdgeInsets.all(AppDimens.space16),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: AppDimens.borderRadiusSm,
              border: Border.all(color: palette.border, width: AppDimens.hairline),
            ),
            child: Column(
              children: [
                Text(
                  'YOUR CHALLENGE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: palette.accent,
                  ),
                ),
                const SizedBox(height: 12),
                if (promptsAsync.isLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: SkeletonBox(height: 44, borderRadius: AppDimens.borderRadiusSm),
                  )
                else if (prompts.isEmpty)
                  Column(
                    children: [
                      Text(
                        'No prompts in your pool.',
                        style: TextStyle(
                          fontSize: 14,
                          color: palette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref.read(idlePromptsProvider.notifier).seedIfEmpty(),
                        child: Text('Seed Default Prompts', style: TextStyle(color: palette.accent)),
                      ),
                    ],
                  )
                else
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      return FadeSlideIn(
                        index: 0,
                        duration: const Duration(milliseconds: 200),
                        child: child,
                      );
                    },
                    child: Text(
                      _currentPrompt?.promptText ?? '',
                      key: ValueKey('prompt_text_$_shuffleKey'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        height: 26 / 20,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  key: const Key('shuffle_prompt_button'),
                  onPressed: prompts.isEmpty ? null : () => _shufflePrompt(prompts),
                  icon: const Icon(Icons.shuffle, size: 16),
                  label: const Text('Shuffle another'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.textPrimary,
                    side: BorderSide(color: palette.border, width: AppDimens.hairline),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: AppDimens.borderRadiusSm),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.space24),

          // Focus Timer Circular Ring
          Center(
            child: PulseRing(
              trigger: _finishPulseTrigger,
              child: SizedBox(
                width: 150,
                height: 150,
                child: CustomPaint(
                  painter: _TimerRingPainter(
                    progress: timerFraction,
                    trackColor: palette.border,
                    strokeColor: palette.accent,
                    strokeWidth: 4.0,
                  ),
                  child: Center(
                    child: _isSessionFinished
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline, size: 36, color: palette.accent),
                              const SizedBox(height: 4),
                              Text(
                                'Focus session\ndone',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: palette.textPrimary,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatTime(_remainingSeconds),
                                key: const Key('focus_timer_text'),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: palette.textPrimary,
                                  letterSpacing: -1,
                                  fontFeatures: AppTypography.tabularFigures,
                                ),
                              ),
                              Text(
                                _isTimerRunning ? 'focusing...' : '15 min sprint',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: palette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimens.space20),

          // Timer Controls
          if (_isSessionFinished)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.textPrimary,
                      side: BorderSide(color: palette.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _resetTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.accent,
                      foregroundColor: palette.onAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Another round'),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    key: const Key('start_pause_timer_button'),
                    onPressed: _startOrPauseTimer,
                    icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow, size: 18),
                    label: Text(_isTimerRunning ? 'Pause' : 'Start'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.accent,
                      foregroundColor: palette.onAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  key: const Key('reset_timer_button'),
                  onPressed: _resetTimer,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.textSecondary,
                    side: BorderSide(color: palette.border),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                  child: const Text('Reset'),
                ),
              ],
            ),
          const SizedBox(height: AppDimens.space12),

          // Manage Pool Link
          Center(
            child: TextButton.icon(
              key: const Key('manage_pool_button'),
              icon: Icon(Icons.settings_outlined, size: 15, color: palette.textSecondary),
              label: Text(
                'Manage pool (${prompts.length})',
                style: TextStyle(fontSize: 12, color: palette.textSecondary),
              ),
              onPressed: () => _openManagePool(context),
            ),
          ),
        ],
      ),
    );

    if (widget.isSheet) {
      return Container(
        decoration: BoxDecoration(
          color: palette.cardRaised,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLg)),
          border: Border.all(color: palette.border, width: AppDimens.hairline),
        ),
        child: SingleChildScrollView(child: dialogContent),
      );
    }

    return Dialog(
      backgroundColor: palette.cardRaised,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: palette.border, width: AppDimens.hairline),
        borderRadius: AppDimens.borderRadiusMd,
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(child: dialogContent),
      ),
    );
  }
}

/// Circular ring painter for focus timer.
class _TimerRingPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color trackColor;
  final Color strokeColor;
  final double strokeWidth;

  const _TimerRingPainter({
    required this.progress,
    required this.trackColor,
    required this.strokeColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0.0) return;

    // Active progress arc
    final fillPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2; // 12 o'clock
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Bottom Sheet allowing users to view, add, and delete prompts from their pool with Undo.
class _ManagePoolSheet extends ConsumerStatefulWidget {
  const _ManagePoolSheet();

  @override
  ConsumerState<_ManagePoolSheet> createState() => _ManagePoolSheetState();
}

class _ManagePoolSheetState extends ConsumerState<_ManagePoolSheet> {
  final _textController = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submitNewPrompt() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isAdding = true);
    try {
      await ref.read(idlePromptsProvider.notifier).addPrompt(text);
      _textController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add prompt: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final prompts = ref.watch(idlePromptsProvider).value ?? [];

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prompt Pool',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Add New Prompt Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('add_prompt_input_field'),
                  controller: _textController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submitNewPrompt(),
                  decoration: const InputDecoration(
                    hintText: 'Add a custom focus prompt...',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                key: const Key('submit_new_prompt_button'),
                onPressed: _isAdding ? null : _submitNewPrompt,
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Existing Prompts List
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: prompts.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: palette.border),
              itemBuilder: (ctx, index) {
                final prompt = prompts[index];
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    prompt.promptText,
                    style: TextStyle(fontSize: 13, color: palette.textPrimary),
                  ),
                  trailing: IconButton(
                    key: Key('delete_prompt_${prompt.id}'),
                    icon: Icon(Icons.delete_outline, size: 18, color: palette.textSecondary),
                    onPressed: () {
                      final deleted = prompt;
                      ref.read(idlePromptsProvider.notifier).deletePrompt(prompt.id);
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Prompt deleted', style: TextStyle(color: palette.textPrimary)),
                          duration: const Duration(seconds: 4),
                          backgroundColor: palette.cardRaised,
                          action: SnackBarAction(
                            label: 'Undo',
                            textColor: palette.accent,
                            onPressed: () {
                              ref.read(idlePromptsProvider.notifier).restorePrompt(deleted);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
