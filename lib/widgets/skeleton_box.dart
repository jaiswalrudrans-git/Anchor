import 'package:flutter/material.dart';
import '../core/constants/dimens.dart';
import '../core/constants/motion.dart';
import '../core/constants/theme.dart';

/// Subtle pulsing skeleton box placeholder for loading states.
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxShape shape;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  const SkeletonBox.circle({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = null,
        shape = BoxShape.circle;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _opacityAnim = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Motion.duration(context, const Duration(milliseconds: 1)) == Duration.zero) {
      _controller.stop();
    }

    final palette = context.palette;
    final r = widget.shape == BoxShape.circle
        ? null
        : (widget.borderRadius ?? AppDimens.borderRadiusSm);

    return AnimatedBuilder(
      animation: _opacityAnim,
      builder: (context, child) {
        return Opacity(
          opacity: _controller.isAnimating ? _opacityAnim.value : 0.5,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: palette.border,
              shape: widget.shape,
              borderRadius: r,
            ),
          ),
        );
      },
    );
  }
}
