import 'package:flutter/material.dart';
import '../../core/constants/motion.dart';

/// Wraps list items to animate removal with a height collapse and fade in 250ms.
class CollapseOnRemove extends StatefulWidget {
  final Widget child;
  final bool isRemoved;
  final VoidCallback? onComplete;
  final Duration duration;

  const CollapseOnRemove({
    super.key,
    required this.child,
    this.isRemoved = false,
    this.onComplete,
    this.duration = Motion.base,
  });

  @override
  State<CollapseOnRemove> createState() => _CollapseOnRemoveState();
}

class _CollapseOnRemoveState extends State<CollapseOnRemove>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.isRemoved ? 0.0 : 1.0,
    );

    _animation = CurvedAnimation(parent: _controller, curve: Motion.standard);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(CollapseOnRemove oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRemoved && !oldWidget.isRemoved) {
      if (MediaQuery.of(context).disableAnimations) {
        _controller.value = 0.0;
        widget.onComplete?.call();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _animation,
      child: FadeTransition(
        opacity: _animation,
        child: widget.child,
      ),
    );
  }
}
