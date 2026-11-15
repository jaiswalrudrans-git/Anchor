import 'package:flutter/material.dart';

import '../../core/constants/motion.dart';
import '../../core/constants/theme.dart';

/// Custom animated checkbox with expanding fill and drawing checkmark.
class AnimatedCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool playful;
  final double size;

  const AnimatedCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.playful = false,
    this.size = 22.0,
  });

  @override
  State<AnimatedCheckbox> createState() => _AnimatedCheckboxState();
}

class _AnimatedCheckboxState extends State<AnimatedCheckbox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _checkAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    final duration = widget.playful
        ? const Duration(milliseconds: 350)
        : const Duration(milliseconds: 180);
    _controller = AnimationController(
      vsync: this,
      duration: duration,
      value: widget.value ? 1.0 : 0.0,
    );

    final curve = widget.playful ? Curves.easeOutCubic : Motion.standard;

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: widget.playful ? 1.15 : 1.05),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: widget.playful ? 1.15 : 1.05, end: 1.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: curve));

    _checkAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
  }

  @override
  void didUpdateWidget(AnimatedCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _controller.forward();
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
    final palette = context.palette;
    final isInteractive = widget.onChanged != null;

    return Semantics(
      checked: widget.value,
      enabled: isInteractive,
      child: GestureDetector(
        onTap: isInteractive ? () => widget.onChanged!(!widget.value) : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            final scale = _controller.isAnimating ? _scaleAnimation.value : 1.0;

            return Transform.scale(
              scale: scale,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: Color.lerp(Colors.transparent, palette.accent, t),
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(
                    color: Color.lerp(palette.border, palette.accent, t)!,
                    width: 1.5,
                  ),
                ),
                child: CustomPaint(
                  painter: _CheckPainter(
                    progress: _checkAnimation.value,
                    color: palette.onAccent,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final p1 = Offset(size.width * 0.25, size.height * 0.52);
    final p2 = Offset(size.width * 0.44, size.height * 0.72);
    final p3 = Offset(size.width * 0.76, size.height * 0.30);

    path.moveTo(p1.dx, p1.dy);

    if (progress <= 0.4) {
      final t = progress / 0.4;
      path.lineTo(p1.dx + (p2.dx - p1.dx) * t, p1.dy + (p2.dy - p1.dy) * t);
    } else {
      path.lineTo(p2.dx, p2.dy);
      final t = (progress - 0.4) / 0.6;
      path.lineTo(p2.dx + (p3.dx - p2.dx) * t, p2.dy + (p3.dy - p2.dy) * t);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
