import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/motion.dart';

/// Tap feedback scale widget that animates to 0.97 on press.
/// Supports touch gestures as well as keyboard activation (Enter / Space).
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double targetScale;
  final Duration duration;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.targetScale = 0.97,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveDuration = Motion.duration(context, widget.duration);

    return FocusableActionDetector(
      enabled: widget.onTap != null,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _isPressed ? widget.targetScale : 1.0,
          duration: effectiveDuration,
          curve: Motion.standard,
          child: widget.child,
        ),
      ),
    );
  }
}
