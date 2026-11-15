import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/dimens.dart';
import '../../core/constants/theme.dart';
import '../brand/anchor_logo.dart';
import 'floating_dock.dart';
import 'quick_add_button.dart';

/// Docked sidebar/rail navigation for viewports >= 600 dp.
/// Replaces the legacy floating rail.
/// - Full sidebar (>= 900 dp, uncollapsed): 248 dp wide, docked left, top-aligned
///   with brand row (28 dp AnchorMark + wordmark), full-width Add button with 'Ctrl N' hint,
///   Menu section, 4 row destinations with sliding accentSoft highlight and left accent bar,
///   and collapsible footer with version and collapse toggle.
/// - Compact rail (600–899 dp, or collapsed): 80 dp wide, docked left, 32 dp AnchorMark,
///   48 dp round Add button, top-aligned 64 dp items with 56x32 dp pill behind icon only
///   and 11 sp label below it (never overlapping).
class SideNav extends StatelessWidget {
  final List<DockDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onQuickAdd;
  final bool isQuickAddOpen;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final bool canCollapse;

  const SideNav({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.onQuickAdd,
    this.isQuickAddOpen = false,
    this.isCollapsed = false,
    required this.onToggleCollapse,
    this.canCollapse = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isFull = canCollapse && !isCollapsed;
    final targetWidth = isFull ? AppDimens.sidebarWidth : AppDimens.railWidth;

    return Semantics(
      label: 'Sidebar navigation',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        width: targetWidth,
        height: double.infinity,
        decoration: BoxDecoration(
          color: palette.card,
          border: Border(
            right: BorderSide(
              color: palette.border,
              width: AppDimens.hairline,
            ),
          ),
        ),
        child: ClipRect(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                alignment: Alignment.topLeft,
                children: [
                  ...previousChildren,
                  ?currentChild,
                ],
              );
            },
            child: isFull
                ? OverflowBox(
                    key: const ValueKey('full_sidebar_view'),
                    alignment: Alignment.topLeft,
                    minWidth: AppDimens.sidebarWidth,
                    maxWidth: AppDimens.sidebarWidth,
                    child: SizedBox(
                      width: AppDimens.sidebarWidth,
                      child: _FullSidebar(
                        destinations: destinations,
                        selectedIndex: selectedIndex,
                        onSelected: onSelected,
                        onQuickAdd: onQuickAdd,
                        isQuickAddOpen: isQuickAddOpen,
                        onToggleCollapse: onToggleCollapse,
                      ),
                    ),
                  )
                : OverflowBox(
                    key: const ValueKey('compact_rail_view'),
                    alignment: Alignment.topCenter,
                    minWidth: AppDimens.railWidth,
                    maxWidth: AppDimens.railWidth,
                    child: SizedBox(
                      width: AppDimens.railWidth,
                      child: _CompactRail(
                        destinations: destinations,
                        selectedIndex: selectedIndex,
                        onSelected: onSelected,
                        onQuickAdd: onQuickAdd,
                        isQuickAddOpen: isQuickAddOpen,
                        onToggleCollapse: onToggleCollapse,
                        canExpand: canCollapse,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Full 248 dp sidebar for >= 900 dp uncollapsed viewports.
class _FullSidebar extends StatelessWidget {
  final List<DockDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onQuickAdd;
  final bool isQuickAddOpen;
  final VoidCallback onToggleCollapse;

  const _FullSidebar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.onQuickAdd,
    required this.isQuickAddOpen,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final rowHeight = textScale >= 1.3 ? 48.0 : AppDimens.sidebarItemHeight;
    const itemGap = AppDimens.sidebarItemGap;
    final listHeight = destinations.length * rowHeight + (destinations.length - 1) * itemGap;

    return Padding(
      padding: const EdgeInsets.only(
        left: AppDimens.sidebarPaddingHorizontal,
        right: AppDimens.sidebarPaddingHorizontal,
        top: AppDimens.sidebarPaddingTop,
        bottom: AppDimens.sidebarPaddingBottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Brand Row (height 48): 28 dp AnchorMark + 10 dp gap + wordmark 'anchor'
          SizedBox(
            height: AppDimens.sidebarBrandHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  const AnchorMark(size: 28.0),
                  const SizedBox(width: 10.0),
                  Text(
                    'anchor',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20.0,
                      height: 26.0 / 20.0,
                      fontWeight: FontWeight.w600,
                      color: palette.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimens.space16),

          // 2. Add Button (Full Width, 44 dp height, radius 12, no glow)
          QuickAddButton(
            onPressed: onQuickAdd,
            isOpen: isQuickAddOpen,
            isFullWidth: true,
          ),
          const SizedBox(height: AppDimens.space20),

          // 3. Section Label 'Menu'
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              'Menu',
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
                color: palette.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppDimens.space8),

          // 4. Navigation List (Top-Aligned, sliding highlight)
          SizedBox(
            height: listHeight,
            child: Stack(
              children: [
                // Shared Sliding Highlight: accentSoft background with left accent bar
                AnimatedPositioned(
                  duration: disableAnimations
                      ? Duration.zero
                      : const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  top: selectedIndex * (rowHeight + itemGap),
                  left: 0,
                  right: 0,
                  height: rowHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: palette.accentSoft,
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Container(
                          width: AppDimens.sidebarIndicatorWidth,
                          height: AppDimens.sidebarIndicatorHeight,
                          decoration: BoxDecoration(
                            color: palette.accent,
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 4 Interactive Destination Rows
                Column(
                  children: [
                    for (int i = 0; i < destinations.length; i++) ...[
                      if (i > 0) const SizedBox(height: itemGap),
                      _SidebarItemRow(
                        key: destinations[i].key,
                        destination: destinations[i],
                        isSelected: i == selectedIndex,
                        height: rowHeight,
                        onTap: () => onSelected(i),
                        onNavigateUp: () {
                          if (i > 0) onSelected(i - 1);
                        },
                        onNavigateDown: () {
                          if (i < destinations.length - 1) onSelected(i + 1);
                        },
                        onJumpFirst: () => onSelected(0),
                        onJumpLast: () => onSelected(destinations.length - 1),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // 5. Spacer pushes footer to bottom
          const Spacer(),

          // 6. Footer (1 px hairline border + collapse toggle & version)
          Divider(
            height: 1.0,
            thickness: 1.0,
            color: palette.border,
          ),
          const SizedBox(height: AppDimens.space8),
          Row(
            children: [
              IconButton(
                key: const Key('sidebar_collapse_toggle'),
                icon: const Icon(Icons.chevron_left, size: 20),
                tooltip: 'Collapse sidebar',
                onPressed: onToggleCollapse,
                style: IconButton.styleFrom(
                  foregroundColor: palette.textSecondary,
                  hoverColor: palette.textPrimary.withValues(alpha: 0.06),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w400,
                    color: palette.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Interactive destination row inside the full sidebar.
class _SidebarItemRow extends StatefulWidget {
  final DockDestination destination;
  final bool isSelected;
  final double height;
  final VoidCallback onTap;
  final VoidCallback onNavigateUp;
  final VoidCallback onNavigateDown;
  final VoidCallback onJumpFirst;
  final VoidCallback onJumpLast;

  const _SidebarItemRow({
    super.key,
    required this.destination,
    required this.isSelected,
    required this.height,
    required this.onTap,
    required this.onNavigateUp,
    required this.onNavigateDown,
    required this.onJumpFirst,
    required this.onJumpLast,
  });

  @override
  State<_SidebarItemRow> createState() => _SidebarItemRowState();
}

class _SidebarItemRowState extends State<_SidebarItemRow> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return FocusableActionDetector(
      onShowFocusHighlight: (val) => setState(() => _isFocused = val),
      onShowHoverHighlight: (val) => setState(() => _isHovered = val),
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.arrowUp): const _NavIntent(Direction.up),
        LogicalKeySet(LogicalKeyboardKey.arrowDown): const _NavIntent(Direction.down),
        LogicalKeySet(LogicalKeyboardKey.home): const _NavIntent(Direction.first),
        LogicalKeySet(LogicalKeyboardKey.end): const _NavIntent(Direction.last),
        LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.space): const ActivateIntent(),
      },
      actions: {
        _NavIntent: CallbackAction<_NavIntent>(
          onInvoke: (intent) {
            switch (intent.direction) {
              case Direction.up:
                widget.onNavigateUp();
                break;
              case Direction.down:
                widget.onNavigateDown();
                break;
              case Direction.first:
                widget.onJumpFirst();
                break;
              case Direction.last:
                widget.onJumpLast();
                break;
            }
            return null;
          },
        ),
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: widget.height,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? Colors.transparent // Background is rendered by shared sliding highlight
                  : (_isHovered
                      ? palette.textPrimary.withValues(alpha: 0.06)
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              border: _isFocused
                  ? Border.all(color: palette.accent, width: 2.0)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  widget.isSelected
                      ? widget.destination.selectedIcon
                      : widget.destination.icon,
                  size: 22.0,
                  color: widget.isSelected
                      ? palette.accent
                      : (_isHovered
                          ? palette.textPrimary
                          : palette.textSecondary),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    widget.destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.0,
                      height: 20.0 / 14.0,
                      fontWeight: widget.isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: widget.isSelected
                          ? palette.textPrimary
                          : (_isHovered
                              ? palette.textPrimary
                              : palette.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact 80 dp rail for 600–899 dp viewports or collapsed sidebar.
class _CompactRail extends StatelessWidget {
  final List<DockDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onQuickAdd;
  final bool isQuickAddOpen;
  final VoidCallback onToggleCollapse;
  final bool canExpand;

  const _CompactRail({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.onQuickAdd,
    required this.isQuickAddOpen,
    required this.onToggleCollapse,
    required this.canExpand,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isShort = constraints.maxHeight < 440.0;
        final topPad = isShort ? 8.0 : AppDimens.sidebarPaddingTop;
        final bottomPad = isShort ? 8.0 : AppDimens.sidebarPaddingBottom;
        final spaceBrand = isShort ? 8.0 : AppDimens.space16;
        final spaceAdd = isShort ? 12.0 : AppDimens.space24;

        Widget content = Column(
          mainAxisSize: isShort ? MainAxisSize.min : MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Brand: AnchorMark 32 dp centered at top (no wordmark)
            const Center(child: AnchorMark(size: 32.0)),
            SizedBox(height: spaceBrand),

            // 2. Add Button: 48 dp circle, centered (40 dp if short screen)
            Center(
              child: QuickAddButton(
                onPressed: onQuickAdd,
                isOpen: isQuickAddOpen,
                isFullWidth: false,
                size: isShort ? 40.0 : AppDimens.railAddButtonSize,
              ),
            ),
            SizedBox(height: spaceAdd),

            // 3. Destinations: 4 items (each 64 dp tall, 4 dp gap), pill behind icon only
            for (int i = 0; i < destinations.length; i++) ...[
              if (i > 0) const SizedBox(height: AppDimens.sidebarItemGap),
              _RailItem(
                key: destinations[i].key,
                destination: destinations[i],
                isSelected: i == selectedIndex,
                onTap: () => onSelected(i),
              ),
            ],

            // 4. Spacer pushes footer to bottom (only when not short)
            if (!isShort) const Spacer(),

            // 5. Expand toggle when collapsed from full sidebar (omitted on true medium 600..899 dp)
            if (canExpand)
              Center(
                child: IconButton(
                  key: const Key('sidebar_expand_toggle'),
                  icon: const Icon(Icons.chevron_right, size: 20),
                  tooltip: 'Expand sidebar',
                  onPressed: onToggleCollapse,
                  style: IconButton.styleFrom(
                    foregroundColor: palette.textSecondary,
                    hoverColor: palette.textPrimary.withValues(alpha: 0.06),
                  ),
                ),
              )
            else
              const SizedBox.shrink(),
          ],
        );

        if (isShort) {
          content = SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: content,
          );
        }

        return Padding(
          padding: EdgeInsets.only(top: topPad, bottom: bottomPad),
          child: content,
        );
      },
    );
  }
}

/// Destination item in compact rail: 56x32 dp pill behind icon ONLY, label underneath.
class _RailItem extends StatefulWidget {
  final DockDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  const _RailItem({
    super.key,
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_RailItem> createState() => _RailItemState();
}

class _RailItemState extends State<_RailItem> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Tooltip(
      message: widget.destination.label,
      child: FocusableActionDetector(
        onShowFocusHighlight: (val) => setState(() => _isFocused = val),
        onShowHoverHighlight: (val) => setState(() => _isHovered = val),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onTap,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: AppDimens.railWidth,
              height: AppDimens.railItemHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pill behind icon ONLY (56 x 32 dp)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOutCubic,
                    width: AppDimens.railPillWidth,
                    height: AppDimens.railPillHeight,
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? palette.accentSoft
                          : (_isHovered
                              ? palette.textPrimary.withValues(alpha: 0.06)
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(16.0),
                      border: _isFocused
                          ? Border.all(color: palette.accent, width: 2.0)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      widget.isSelected
                          ? widget.destination.selectedIcon
                          : widget.destination.icon,
                      size: 24.0,
                      color: widget.isSelected
                          ? palette.accent
                          : (_isHovered
                              ? palette.textPrimary
                              : palette.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 4.0),

                  // Label sits safely below the icon pill (never overlapping)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.destination.label,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 11.0,
                          fontWeight: widget.isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: widget.isSelected
                              ? palette.textPrimary
                              : (_isHovered
                                  ? palette.textPrimary
                                  : palette.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum Direction { up, down, first, last }

class _NavIntent extends Intent {
  final Direction direction;
  const _NavIntent(this.direction);
}
