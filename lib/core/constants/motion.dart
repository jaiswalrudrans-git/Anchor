import 'package:flutter/material.dart';

/// Motion tokens and curve definitions for Polish pass.
class Motion {
  Motion._();

  // Durations
  static const Duration snap = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration moment = Duration(milliseconds: 400);
  static const Duration playful = Duration(milliseconds: 450);

  // Curves
  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutBack;

  /// Returns [d] normally, or [Duration.zero] when the user has enabled reduced motion.
  static Duration duration(BuildContext context, Duration d) {
    if (MediaQuery.of(context).disableAnimations) {
      return Duration.zero;
    }
    return d;
  }
}
