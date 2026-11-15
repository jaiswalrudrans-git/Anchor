import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/motion.dart';

/// Staggered fade and 8dp slide up transition for list items.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration duration;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = Motion.base,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Motion.standard,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 8.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Motion.standard));

    // Stagger delay: 20ms per index, capped at 10 items (200ms max delay)
    final delayMs = math.min(widget.index, 10) * 20;
    if (delayMs > 0) {
      Future.delayed(Duration(milliseconds: delayMs), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: _slideAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}
