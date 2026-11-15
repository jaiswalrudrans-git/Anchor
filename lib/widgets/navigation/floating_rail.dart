import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/theme.dart';
import '../../core/utils/haptics.dart';
import '../brand/anchor_logo.dart';
import 'floating_dock.dart';
import 'quick_add_button.dart';

/// Restyled floating navigation rail for medium & expanded viewports (>= 600 dp).
/// - Floating rounded panel (radius 28, cardRaised, 1 px border, inset 12 dp).
/// - 4 destinations stacked vertically with a vertically sliding round bubble.
/// - Quick Add button is the rail's leading item above the panel.
/// - Keyboard support: Up/Down arrow navigation, Enter/Space activation, visible focus ring.
class FloatingRail extends StatefulWidget {
  final List<DockDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onQuickAdd;
  final bool isQuickAddOpen;
  final bool isExpanded;

  const FloatingRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.onQuickAdd,
    this.isQuickAddOpen = false,
    this.isExpanded = false,
  });

  @override
  State<FloatingRail> createState() => _FloatingRailState();
}

class _FloatingRailState extends State<FloatingRail>
    with TickerProviderStateMixin {
  late AnimationController _glideController;
  late Animation<double> _glideAnimation;

  late AnimationController _popController;
  late Animation<double> _popAnimation;

  late IconData _bubbleIcon;
  late IconData _targetIcon;

  static const double _slotHeight = 72.0;

  @override
  void initState() {
    super.initState();
    _bubbleIcon = widget.destinations[widget.selectedIndex].selectedIcon;
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
  void didUpdateWidget(FloatingRail oldWidget) {
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
  }

  void _handleGlideTick() {
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
    final railWidth = widget.isExpanded ? 200.0 : 76.0;

    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 1.0,
      maxScaleFactor: 1.15,
      child: Container(
        width: railWidth + 24.0, // includes 12 dp padding on each side
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: widget.isExpanded
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            // 1. App Title / Logo Header (AnchorWordmark on expanded, AnchorMark on medium)
            if (widget.isExpanded) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(8, 12, 8, 16),
                child: AnchorWordmark(markSize: 28.0),
              ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Center(child: AnchorMark(size: 28.0)),
              ),
            ],

            // 2. Leading Quick Add Button above the panel
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: QuickAddButton(
                onPressed: widget.onQuickAdd,
                isOpen: widget.isQuickAddOpen,
                isExtended: widget.isExpanded,
                size: 56.0,
              ),
            ),

            const SizedBox(height: 12.0),

            // 3. Floating Rounded Destinations Panel (Vertically Centered)
            Expanded(
              child: Center(
                child: Container(
                  width: railWidth,
                  height: _slotHeight * widget.destinations.length + 20.0,
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  decoration: BoxDecoration(
                    color: palette.cardRaised,
                    borderRadius: BorderRadius.circular(28.0),
                    border: Border.all(color: palette.border, width: 1.0),
                    boxShadow: [
                      if (!palette.isDark)
                        BoxShadow(
                          color: palette.scrim.withValues(alpha: 0.06),
                          blurRadius: 16.0,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _glideAnimation,
                      _popAnimation,
                    ]),
                    builder: (context, _) {
                      final position = _glideAnimation.value;
                      final popProgress = _popAnimation.value;

                      final bubbleTop =
                          (position * _slotHeight) + (_slotHeight - 48.0) / 2.0;
                      final bubbleLeft = widget.isExpanded
                          ? 12.0
                          : (railWidth - 48.0) / 2.0;

                      final popLift = 4.0 * math.sin(popProgress * math.pi);
                      final scale = 0.94 + 0.06 * (1.0 - popProgress);

                      return Stack(
                        children: [
                          // Vertical Sliding Bubble
                          Positioned(
                            top: bubbleTop - popLift,
                            left: bubbleLeft,
                            child: IgnorePointer(
                              child: Transform.scale(
                                scale: scale,
                                child: Container(
                                  width: 48.0,
                                  height: 48.0,
                                  decoration: BoxDecoration(
                                    color: palette.accentSoft,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: palette.accent,
                                      width: 2.0,
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      _bubbleIcon,
                                      size: 24.0,
                                      color: palette.accent,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Destinations List
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: widget.destinations.asMap().entries.map((
                              entry,
                            ) {
                              final idx = entry.key;
                              final dest = entry.value;
                              final isSelected = widget.selectedIndex == idx;

                              final distance = (position - idx).abs();
                              final iconOpacity = (distance < 0.35)
                                  ? (distance / 0.35).clamp(0.0, 1.0)
                                  : 1.0;

                              return Expanded(
                                child: Focus(
                                  onKeyEvent: (node, event) {
                                    if (event is KeyDownEvent) {
                                      if (event.logicalKey ==
                                          LogicalKeyboardKey.arrowDown) {
                                        if (idx <
                                            widget.destinations.length - 1) {
                                          widget.onSelected(idx + 1);
                                          return KeyEventResult.handled;
                                        }
                                      } else if (event.logicalKey ==
                                          LogicalKeyboardKey.arrowUp) {
                                        if (idx > 0) {
                                          widget.onSelected(idx - 1);
                                          return KeyEventResult.handled;
                                        }
                                      } else if (event.logicalKey ==
                                              LogicalKeyboardKey.enter ||
                                          event.logicalKey ==
                                              LogicalKeyboardKey.space) {
                                        widget.onSelected(idx);
                                        return KeyEventResult.handled;
                                      }
                                    }
                                    return KeyEventResult.ignored;
                                  },
                                  child: Builder(
                                    builder: (context) {
                                      final hasFocus = Focus.of(context)
                                          .hasFocus;

                                      return Semantics(
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
                                          borderRadius: BorderRadius.circular(
                                            24.0,
                                          ),
                                          child: Container(
                                            alignment: Alignment.center,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(24.0),
                                              border: hasFocus
                                                  ? Border.all(
                                                      color: palette.accent,
                                                      width: 2.0,
                                                    )
                                                  : null,
                                            ),
                                            child: widget.isExpanded
                                                ? Row(
                                                    children: [
                                                      const SizedBox(
                                                        width: 8.0,
                                                      ),
                                                      Opacity(
                                                        opacity: iconOpacity,
                                                        child: Icon(
                                                          dest.icon,
                                                          size: 24.0,
                                                          color: palette
                                                              .textSecondary,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        width: 14.0,
                                                      ),
                                                      Expanded(
                                                        child: Text(
                                                          dest.label,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                            fontSize: 13.0,
                                                            fontWeight:
                                                                isSelected
                                                                ? FontWeight
                                                                      .w600
                                                                : FontWeight
                                                                      .w500,
                                                            color: isSelected
                                                                ? palette
                                                                      .textPrimary
                                                                : palette
                                                                      .textSecondary,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Opacity(
                                                        opacity: iconOpacity,
                                                        child: Icon(
                                                          dest.icon,
                                                          size: 24.0,
                                                          color: palette
                                                              .textSecondary,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 2.0,
                                                      ),
                                                      FittedBox(
                                                        fit: BoxFit.scaleDown,
                                                        child: Text(
                                                          dest.label,
                                                          maxLines: 1,
                                                          style: TextStyle(
                                                            fontSize: 10.0,
                                                            fontWeight:
                                                                isSelected
                                                                ? FontWeight
                                                                      .w600
                                                                : FontWeight
                                                                      .w500,
                                                            color: isSelected
                                                                ? palette
                                                                      .textPrimary
                                                                : palette
                                                                      .textSecondary,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
