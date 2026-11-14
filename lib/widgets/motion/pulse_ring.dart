import 'package:flutter/material.dart';
import '../../core/constants/motion.dart';
import '../../core/constants/theme.dart';

/// One-shot soft accent ring pulse around a child for achievement moments.
class PulseRing extends StatefulWidget {
  final Widget child;
  final bool trigger;
  final Duration duration;

  const PulseRing({
    super.key,
    required this.child,
    this.trigger = false,
    this.duration = Motion.moment,
  });

  @override
  State<PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<PulseRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.6), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 0.0), weight: 70),
    ]).animate(_controller);

    if (widget.trigger) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(PulseRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            if (_controller.isAnimating && !MediaQuery.of(context).disableAnimations)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: palette.accent.withValues(alpha: _opacityAnimation.value),
                      width: 2.0,
                    ),
                  ),
                ),
              ),
            Transform.scale(
              scale: _controller.isAnimating ? _scaleAnimation.value : 1.0,
              child: widget.child,
            ),
          ],
        );
      },
    );
  }
}
