import 'package:flutter/material.dart';
import '../../../core/constants/motion.dart';
import '../../../core/constants/theme.dart';

/// CustomPainter that traces a rounded rectangle clockwise starting at the top-left.
class CardProgressStrokePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color trackColor;
  final Color strokeColor;
  final double strokeWidth;
  final double radius;

  const CardProgressStrokePainter({
    required this.progress,
    required this.trackColor,
    required this.strokeColor,
    this.strokeWidth = 2.5,
    this.radius = 16.0,
  });

  /// Builds the clockwise path starting from the top-left after the corner radius.
  static Path buildClockwisePath(Size size, double radius, double strokeWidth) {
    final halfStroke = strokeWidth / 2;
    final w = size.width - strokeWidth;
    final h = size.height - strokeWidth;
    final r = radius - halfStroke;

    final path = Path();
    // Start at top-left corner after the radius: (halfStroke + r, halfStroke)
    path.moveTo(halfStroke + r, halfStroke);
    // 1. Top edge: to (halfStroke + w - r, halfStroke)
    path.lineTo(halfStroke + w - r, halfStroke);
    // 2. Top-right corner arc
    path.arcToPoint(
      Offset(halfStroke + w, halfStroke + r),
      radius: Radius.circular(r),
      clockwise: true,
    );
    // 3. Right edge: to (halfStroke + w, halfStroke + h - r)
    path.lineTo(halfStroke + w, halfStroke + h - r);
    // 4. Bottom-right corner arc
    path.arcToPoint(
      Offset(halfStroke + w - r, halfStroke + h),
      radius: Radius.circular(r),
      clockwise: true,
    );
    // 5. Bottom edge: to (halfStroke + r, halfStroke + h)
    path.lineTo(halfStroke + r, halfStroke + h);
    // 6. Bottom-left corner arc
    path.arcToPoint(
      Offset(halfStroke, halfStroke + h - r),
      radius: Radius.circular(r),
      clockwise: true,
    );
    // 7. Left edge: to (halfStroke, halfStroke + r)
    path.lineTo(halfStroke, halfStroke + r);
    // 8. Top-left corner arc
    path.arcToPoint(
      Offset(halfStroke + r, halfStroke),
      radius: Radius.circular(r),
      clockwise: true,
    );
    path.close();
    return path;
  }

  /// Pure helper returning the extracted path length for unit testing.
  static double getExtractedPathLength(Size size, double radius, double strokeWidth, double progress) {
    final path = buildClockwisePath(size, radius, strokeWidth);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return 0.0;
    final metric = metrics.first;
    final totalLength = metric.length;
    final clamped = progress.clamp(0.0, 1.0);
    return totalLength * clamped;
  }

  /// Pure helper returning total perimeter length.
  static double getTotalPathLength(Size size, double radius, double strokeWidth) {
    final path = buildClockwisePath(size, radius, strokeWidth);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return 0.0;
    return metrics.first.length;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= strokeWidth * 2 || size.height <= strokeWidth * 2) return;

    final path = buildClockwisePath(size, radius, strokeWidth);

    // 1. Neutral track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawPath(path, trackPaint);

    if (progress <= 0.0) return;

    // 2. Animated progress stroke fill
    final fillPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final metrics = path.computeMetrics().toList();
    if (metrics.isNotEmpty) {
      final metric = metrics.first;
      final totalLength = metric.length;
      final clampedProgress = progress.clamp(0.0, 1.0);
      final extractLength = totalLength * clampedProgress;
      if (extractLength > 0) {
        final extractPath = metric.extractPath(0.0, extractLength);
        canvas.drawPath(extractPath, fillPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CardProgressStrokePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius;
  }
}

/// A container card surrounded by an animated clockwise progress stroke.
class CardWithProgressStroke extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final Widget child;
  final double radius;
  final double strokeWidth;
  final Color? backgroundColor;

  const CardWithProgressStroke({
    super.key,
    required this.progress,
    required this.child,
    this.radius = 16.0,
    this.strokeWidth = 2.5,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    if (disableAnimations) {
      return RepaintBoundary(
        child: CustomPaint(
          painter: CardProgressStrokePainter(
            progress: progress,
            trackColor: palette.border,
            strokeColor: palette.accent,
            strokeWidth: strokeWidth,
            radius: radius,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor ?? palette.card,
              borderRadius: BorderRadius.circular(radius),
            ),
            child: child,
          ),
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: progress),
      duration: Motion.moment,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return RepaintBoundary(
          child: CustomPaint(
            painter: CardProgressStrokePainter(
              progress: animatedValue,
              trackColor: palette.border,
              strokeColor: palette.accent,
              strokeWidth: strokeWidth,
              radius: radius,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor ?? palette.card,
                borderRadius: BorderRadius.circular(radius),
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
