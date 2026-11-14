import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme.dart';
import '../../../models/idle_prompt.dart';
import '../../../providers/home_providers.dart';

/// Focus Dialog displayed when Kill Idle Time is unlocked and clicked.
/// Features a random prompt, shuffle, 15:00 focus timer, and pool manager.
class KillIdleDialog extends ConsumerStatefulWidget {
  const KillIdleDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const KillIdleDialog(),
    );
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
        if (_remainingSeconds > 0) {
          setState(() {
            _remainingSeconds--;
          });
        } else {
          timer.cancel();
          setState(() {
            _isTimerRunning = false;
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
    });
  }

  void _shufflePrompt(List<IdlePrompt> pool) {
    if (pool.isEmpty) return;
    if (pool.length == 1) {
      setState(() {
        _currentPrompt = pool.first;
      });
      return;
    }

    final candidates = pool.where((p) => p.id != _currentPrompt?.id).toList();
    final randomItem = candidates[Random().nextInt(candidates.length)];
    setState(() {
      _currentPrompt = randomItem;
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
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.maxRadius)),
      ),
      builder: (ctx) => const _ManagePromptsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final promptsAsync = ref.watch(idlePromptsProvider);
    final prompts = promptsAsync.value ?? [];

    // Sync or select initial prompt
    if (prompts.isNotEmpty) {
      if (_currentPrompt == null || !prompts.any((p) => p.id == _currentPrompt!.id)) {
        _currentPrompt = prompts[Random().nextInt(prompts.length)];
      }
    } else {
      _currentPrompt = null;
    }

    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        side: AppTheme.borderSide1,
        borderRadius: AppTheme.borderRadius8,
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bolt, size: 20, color: AppColors.primaryText),
                      SizedBox(width: 8),
                      Text(
                        'Kill Idle Time',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    splashRadius: 18,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Random Prompt Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppTheme.borderRadius8,
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  children: [
                    const Text(
                      'YOUR CHALLENGE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _currentPrompt != null
                          ? _currentPrompt!.promptText
                          : 'No prompts available in your pool.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Shuffle Button
                    OutlinedButton.icon(
                      onPressed: prompts.length > 1 ? () => _shufflePrompt(prompts) : null,
                      icon: const Icon(Icons.shuffle, size: 16),
                      label: const Text('Shuffle Another', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 15:00 Countdown Timer
              Center(
                child: Text(
                  _formatTime(_remainingSeconds),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                    color: AppColors.primaryText,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Timer Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _startOrPauseTimer,
                    icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow, size: 18),
                    label: Text(_isTimerRunning ? 'Pause' : 'Start Focus'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _resetTimer,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reset'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),

              // Manage Pool Link
              TextButton.icon(
                onPressed: () => _openManagePool(context),
                icon: const Icon(Icons.tune, size: 16),
                label: const Text(
                  'Manage Prompt Pool',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet to manage (view, add, delete) idle prompt items.
class _ManagePromptsSheet extends ConsumerStatefulWidget {
  const _ManagePromptsSheet();

  @override
  ConsumerState<_ManagePromptsSheet> createState() => _ManagePromptsSheetState();
}

class _ManagePromptsSheetState extends ConsumerState<_ManagePromptsSheet> {
  final _promptInputController = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _promptInputController.dispose();
    super.dispose();
  }

  Future<void> _addPrompt() async {
    final text = _promptInputController.text.trim();
    if (text.isEmpty || _isAdding) return;

    setState(() {
      _isAdding = true;
    });

    try {
      await ref.read(idlePromptsProvider.notifier).addPrompt(text);
      _promptInputController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add prompt: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
    }
  }

  Future<void> _deletePrompt(IdlePrompt prompt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Prompt'),
        content: Text('Delete "${prompt.promptText}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(idlePromptsProvider.notifier).deletePrompt(prompt.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final promptsAsync = ref.watch(idlePromptsProvider);
    final prompts = promptsAsync.value ?? [];

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
              const Text(
                'Prompt Pool',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
                splashRadius: 18,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Add Prompt Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promptInputController,
                  decoration: const InputDecoration(
                    hintText: 'Add custom prompt...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onSubmitted: (_) => _addPrompt(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isAdding ? null : _addPrompt,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Prompt List
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: prompts.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'No prompts in pool. Add one above!',
                        style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: prompts.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = prompts[index];
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                        title: Text(
                          item.promptText,
                          style: const TextStyle(fontSize: 13, color: AppColors.primaryText),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          color: AppColors.secondaryText,
                          splashRadius: 18,
                          onPressed: () => _deletePrompt(item),
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
