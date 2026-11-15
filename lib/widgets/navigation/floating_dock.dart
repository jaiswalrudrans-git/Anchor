import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/dimens.dart';
import '../../core/constants/theme.dart';
import '../../core/utils/haptics.dart';

/// Destination item for shell navigation.
class DockDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Key key;

  const DockDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.key,
  });
}

/// Custom shape generator for the floating dock notch and outline.
class DockShape {
  final double cornerRadius;
  final double notchRadius;
  final double bubbleLift;
  final double shoulderWidth;

  const DockShape({
    this.cornerRadius = AppDimens.dockRadius,
    this.notchRadius = AppDimens.notchRadius,
    this.bubbleLift = AppDimens.bubbleLift,
    this.shoulderWidth = AppDimens.shoulderWidth,
  });

  /// Calculates slot center X for a given position [0..3] across [totalWidth].
  static double slotCenterX(double position, double totalWidth) {
    final slotWidth = totalWidth / 4.0;
    return (position + 0.5) * slotWidth;
  }

  /// Builds the closed outer path for the dock given [rect] and animated [position].
  Path buildPath(Rect rect, double position) {
    final width = rect.width;
    final height = rect.height;
    final rCorner = math.min(cornerRadius, height / 2.0);
    final rNotch = notchRadius;
    final lift = bubbleLift;

    // Exact formula: slot center X aligns 1:1 with destination slots and pop-out bubble on every device
    final centerX = slotCenterX(position, width);

    // 1. Base dock pill
    final pill = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, width, height),
          Radius.circular(rCorner),
        ),
      );

    // 2. Notch cutout with smooth cubic Bezier shoulders
    const theta0 = 55.0 * math.pi / 180.0;
    final sinTheta = math.sin(theta0);
    final cosTheta = math.cos(theta0);

    final xArcOffset = rNotch * sinTheta;
    final yArc = -lift + rNotch * cosTheta;

    final pArcLeft = Offset(centerX - xArcOffset, yArc);
    final pArcRight = Offset(centerX + xArcOffset, yArc);

    // Circle tangents at junction points
    final tLeft = Offset(cosTheta, sinTheta);
    final tRight = Offset(cosTheta, -sinTheta);

    final pShoulderStart = Offset(pArcLeft.dx - shoulderWidth, 0.0);
    final c1 = Offset(pShoulderStart.dx + shoulderWidth * 0.45, 0.0);
    final lambdaLeft = shoulderWidth * 0.35;
    final c2 = Offset(
      pArcLeft.dx - lambdaLeft * tLeft.dx,
      math.max(0.0, pArcLeft.dy - lambdaLeft * tLeft.dy),
    );

    final pShoulderEnd = Offset(pArcRight.dx + shoulderWidth, 0.0);
    final lambdaRight = shoulderWidth * 0.35;
    final c3 = Offset(
      pArcRight.dx + lambdaRight * tRight.dx,
      math.max(0.0, pArcRight.dy - lambdaRight * tRight.dy.abs()),
    );
    final c4 = Offset(pShoulderEnd.dx - shoulderWidth * 0.45, 0.0);

    final cutout = Path()
      ..moveTo(pShoulderStart.dx, -50.0)
      ..lineTo(pShoulderStart.dx, 0.0)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, pArcLeft.dx, pArcLeft.dy)
      ..arcToPoint(pArcRight, radius: Radius.circular(rNotch), clockwise: false)
      ..cubicTo(c3.dx, c3.dy, c4.dx, c4.dy, pShoulderEnd.dx, 0.0)
      ..lineTo(pShoulderEnd.dx, -50.0)
      ..close();

    // 3. Subtract notch cutout from base pill: guarantees clean geometric closure and
    // perfect alignment across any device width without edge clipping or misplacement.
    return Path.combine(PathOperation.difference, pill, cutout);
  }
}

/// CustomClipper clipping content to the notched dock shape.
class DockClipper extends CustomClipper<Path> {
  final double position;
  final DockShape shape;

  const DockClipper({required this.position, required this.shape});

  @override
  Path getClip(Size size) {
    return shape.buildPath(Offset.zero & size, position);
  }

  @override
  bool shouldReclip(DockClipper oldClipper) {
    return oldClipper.position != position || oldClipper.shape != shape;
  }
}

/// CustomPainter rendering dock fill, subtle shadow, and 1px border.
class DockShapePainter extends CustomPainter {
  final double position;
  final DockShape shape;
  final AppPalette palette;

  const DockShapePainter({
    required this.position,
    required this.shape,
    required this.palette,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = shape.buildPath(Offset.zero & size, position);

    // Subtle soft shadow in light mode only
    if (!palette.isDark) {
      final shadowPaint = Paint()
        ..color = palette.scrim.withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
      canvas.save();
      canvas.translate(0, 4);
      canvas.drawPath(path, shadowPaint);
      canvas.restore();
    }

    // Dock surface fill (cardRaised)
    final fillPaint = Paint()
      ..color = palette.cardRaised
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 1px border stroke following the full outline (including notch)
    final borderPaint = Paint()
      ..color = palette.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(DockShapePainter oldDelegate) {
    return oldDelegate.position != position ||
        oldDelegate.palette != palette ||
        oldDelegate.shape != shape;
  }
}

/// Round bubble representing the selected destination.
/// Sits in the curved notch, lifts 14 dp above the dock top,
/// features accentSoft fill, 2px accent border ring, and accent icon.
class DockBubble extends StatelessWidget {
  final IconData icon;
  final double diameter;
  final double scale;
  final double popLift;
  final AppPalette palette;

  const DockBubble({
    super.key,
    required this.icon,
    this.diameter = AppDimens.bubbleDiameter,
    this.scale = 1.0,
    this.popLift = 0.0,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -popLift),
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            color: palette.accentSoft,
            shape: BoxShape.circle,
            border: Border.all(color: palette.accent, width: 2.0),
          ),
          child: Center(
            child: Icon(
              icon,
              size: diameter * 0.46, // ~26 dp for 56 dp bubble
              color: palette.accent,
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating rounded dock navigation component for compact viewports (< 600 dp).
/// - 4 equal destination slots.
/// - Gliding concave notch with pop-out bubble for selected destination.
/// - Subtle glide (320 ms) + arrival pop (180 ms).
class FloatingDock extends StatefulWidget {
  final List<DockDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const FloatingDock({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  State<FloatingDock> createState() => _FloatingDockState();
}

class _FloatingDockState extends State<FloatingDock>
    with TickerProviderStateMixin {
  late AnimationController _glideController;
  late Animation<double> _glideAnimation;

  late AnimationController _popController;
  late Animation<double> _popAnimation;

  late int _lastIndex;
  late IconData _bubbleIcon;
  late IconData _targetIcon;

  @override
  void initState() {
    super.initState();
    _lastIndex = widget.selectedIndex;
    _bubbleIcon = widget.destinations[_lastIndex].selectedIcon;
    _targetIcon = _bubbleIcon;

    _glideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _glideAnimation =
        Tween<double>(
          begin: widget.selectedIndex.toDouble(),
          end: widget.selectedIndex.toDouble(),
        ).animate(
          CurvedAnimation(
            parent: _glideController,
            curve: Curves.easeInOutCubic,
          ),
        );

    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _popAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _popController, curve: Curves.easeOutBack),
    );
  }

  @override
  void didUpdateWidget(FloatingDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _animateTo(widget.selectedIndex);
    }
  }

  @override
  void dispose() {
    _glideController.dispose();
    _popController.dispose();
    super.dispose();
  }

  void _animateTo(int newIndex) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    if (disableAnimations) {
      setState(() {
        _lastIndex = newIndex;
        _bubbleIcon = widget.destinations[newIndex].selectedIcon;
        _targetIcon = _bubbleIcon;
      });
      _glideController.value = 1.0;
      _glideAnimation = AlwaysStoppedAnimation<double>(newIndex.toDouble());
      return;
    }

    Haptics.light();

    _targetIcon = widget.destinations[newIndex].selectedIcon;
    final startIndex = _glideAnimation.value;

    _glideAnimation = Tween<double>(begin: startIndex, end: newIndex.toDouble())
        .animate(
          CurvedAnimation(
            parent: _glideController,
            curve: Curves.easeInOutCubic,
          ),
        );

    _glideController.forward(from: 0.0).then((_) {
      if (mounted) {
        _popController.forward(from: 0.0).then((_) {
          if (mounted) {
            _popController.reverse();
          }
        });
      }
    });

    _glideController.addListener(_handleGlideTick);
    _lastIndex = newIndex;
  }

  void _handleGlideTick() {
    // Cross-fade icon at midpoint
    final progress = _glideController.value;
    if (progress >= 0.5 && _bubbleIcon != _targetIcon) {
      setState(() {
        _bubbleIcon = _targetIcon;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isShort = MediaQuery.sizeOf(context).height < 480;

    final dockHeight = isShort
        ? AppDimens.dockHeightShort
        : AppDimens.dockHeight;
    final dockRadius = isShort
        ? AppDimens.dockRadiusShort
        : AppDimens.dockRadius;
    final bubbleDiameter = isShort
        ? AppDimens.bubbleDiameterShort
        : AppDimens.bubbleDiameter;
    final bubbleLift = isShort
        ? AppDimens.bubbleLiftShort
        : AppDimens.bubbleLift;
    final notchRadius = isShort
        ? AppDimens.notchRadiusShort
        : AppDimens.notchRadius;

    final shape = DockShape(
      cornerRadius: dockRadius,
      notchRadius: notchRadius,
      bubbleLift: bubbleLift,
      shoulderWidth: AppDimens.shoulderWidth,
    );

    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 1.0,
      maxScaleFactor: 1.15,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;

          return AnimatedBuilder(
            animation: Listenable.merge([_glideAnimation, _popAnimation]),
            builder: (context, _) {
              final position = _glideAnimation.value;
              final popProgress = _popAnimation.value;

              final bubbleCenterX = DockShape.slotCenterX(position, totalWidth);
              final bubbleLeft = bubbleCenterX - (bubbleDiameter / 2.0);
              final bubbleTop = -bubbleLift - (bubbleDiameter / 2.0);

              // Pop effect: rises 4 dp and settles back, scale 0.94 to 1.0
              final popLift = 4.0 * math.sin(popProgress * math.pi);
              final scale = 0.94 + 0.06 * (1.0 - popProgress);

              return SizedBox(
                width: totalWidth,
                height: dockHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 1. Dock Surface (Fill, border stroke, notch outline, subtle shadow)
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: DockShapePainter(
                            position: position,
                            shape: shape,
                            palette: palette,
                          ),
                        ),
                      ),
                    ),

                    // 2. Destination Items (Icon & Label in equal slots)
                    Positioned.fill(
                      child: Row(
                        children: widget.destinations.asMap().entries.map((
                          entry,
                        ) {
                          final idx = entry.key;
                          final dest = entry.value;
                          final isSelected = widget.selectedIndex == idx;

                          // Fade out dock icon when bubble is hovering over it
                          final distance = (position - idx).abs();
                          final iconOpacity = (distance < 0.35)
                              ? (distance / 0.35).clamp(0.0, 1.0)
                              : 1.0;

                          return Expanded(
                            child: Semantics(
                              label: dest.label,
                              button: true,
                              selected: isSelected,
                              child: InkWell(
                                key: dest.key,
                                onTap: () {
                                  if (widget.selectedIndex != idx) {
                                    widget.onSelected(idx);
                                  }
                                },
                                borderRadius: BorderRadius.circular(dockRadius),
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 48.0,
                                  ),
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Opacity(
                                        opacity: iconOpacity,
                                        child: Icon(
                                          dest.icon,
                                          size: 24.0,
                                          color: palette.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 2.0),
                                      if (!isShort)
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            dest.label,
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontSize: 11.0,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? palette.textPrimary
                                                  : palette.textSecondary,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // 3. Gliding Pop-Out Bubble
                    Positioned(
                      key: const Key('dock_bubble'),
                      left: bubbleLeft,
                      top: bubbleTop,
                      child: IgnorePointer(
                        child: DockBubble(
                          icon: _bubbleIcon,
                          diameter: bubbleDiameter,
                          scale: scale,
                          popLift: popLift,
                          palette: palette,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
