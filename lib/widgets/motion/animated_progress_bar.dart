import 'package:flutter/material.dart';

import '../../core/constants/motion.dart';
import '../../core/constants/theme.dart';

/// Slim animated progress bar smoothly interpolating between progress values.
class AnimatedProgressBar extends StatelessWidget {
  final double value; // 0.0 .. 1.0
  final double height;
  final Color? colorOverride;
  final Duration duration;

  const AnimatedProgressBar({
    super.key,
    required this.value,
    this.height = 4.0,
    this.colorOverride,
    this.duration = Motion.base,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final clampedValue = value.clamp(0.0, 1.0);
    final effectiveDuration = Motion.duration(context, duration);
    final fillColor = colorOverride ?? palette.accent;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.border,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final targetWidth = constraints.maxWidth * clampedValue;

          return Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: effectiveDuration,
              curve: Motion.standard,
              width: targetWidth,
              height: height,
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          );
        },
      ),
    );
  }
}
