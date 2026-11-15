import 'package:flutter/material.dart';

import '../../core/constants/motion.dart';
import '../../core/constants/theme.dart';

/// Smooth animated number counter using tabular figures.
class CountUpText extends StatelessWidget {
  final num value;
  final TextStyle? style;
  final String Function(num)? formatter;
  final Duration duration;

  const CountUpText({
    super.key,
    required this.value,
    this.style,
    this.formatter,
    this.duration = Motion.base,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveDuration = Motion.duration(context, duration);
    final textStyle = (style ?? Theme.of(context).textTheme.bodyMedium)
        ?.copyWith(fontFeatures: AppTypography.tabularFigures);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value.toDouble()),
      duration: effectiveDuration,
      curve: Motion.standard,
      builder: (context, animValue, child) {
        final formattedText = formatter != null
            ? formatter!(animValue)
            : (value is int
                  ? animValue.round().toString()
                  : animValue.toStringAsFixed(1));

        return Text(formattedText, style: textStyle);
      },
    );
  }
}
