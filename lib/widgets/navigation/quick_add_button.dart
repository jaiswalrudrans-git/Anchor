import 'package:flutter/material.dart';

import '../../core/constants/dimens.dart';
import '../../core/constants/theme.dart';
import '../motion/pressable_scale.dart';

/// Quick Add button used across phone dock, compact rail, and full sidebar.
/// Key: `quick_add_button`.
/// - Compact dock (< 600 dp): 60 dp round button beside the floating dock.
/// - Compact rail (600–899 dp): 48 dp round button centered under brand glyph.
/// - Full sidebar (>= 900 dp): 224 dp full-width button (height 44, radius 12),
///   with 'Add' label and trailing 'Ctrl N' hint chip, no glow or purple shadow.
class QuickAddButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isOpen;
  final bool isExtended;
  final bool isFullWidth;
  final double size;

  const QuickAddButton({
    super.key,
    required this.onPressed,
    this.isOpen = false,
    this.isExtended = false,
    this.isFullWidth = false,
    this.size = AppDimens.plusSize,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isSidebar = isFullWidth || isExtended;
    final isRail = !isSidebar && size <= AppDimens.railAddButtonSize;

    return Semantics(
      label: 'Quick add',
      button: true,
      child: Tooltip(
        message: isSidebar || isRail ? 'Quick add (Ctrl+N)' : 'Quick add',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: PressableScale(
            onTap: onPressed,
            targetScale: 0.96,
            child: Container(
              key: const Key('quick_add_button'),
              height: isSidebar ? AppDimens.sidebarAddButtonHeight : size,
              width: isSidebar ? double.infinity : size,
              padding: isSidebar
                  ? const EdgeInsets.symmetric(horizontal: 16.0)
                  : EdgeInsets.zero,
              decoration: BoxDecoration(
                color: palette.accent,
                shape: isSidebar ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: isSidebar
                    ? BorderRadius.circular(AppDimens.radiusMd)
                    : null,
                border: isSidebar || isRail
                    ? null
                    : Border.all(color: palette.background, width: 1.0),
                boxShadow: (isSidebar || isRail)
                    ? null
                    : [
                        BoxShadow(
                          color: palette.isDark
                              ? Colors.transparent
                              : palette.accent.withValues(alpha: 0.25),
                          blurRadius: 8.0,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: isSidebar
                  ? Row(
                      children: [
                        AnimatedRotation(
                          turns: isOpen ? 0.125 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          child: Icon(
                            Icons.add,
                            size: 20.0,
                            color: palette.onAccent,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          'Add',
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                            color: palette.onAccent,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 2.0,
                          ),
                          decoration: BoxDecoration(
                            color: palette.onAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            'Ctrl N',
                            style: TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w500,
                              color: palette.onAccent.withValues(alpha: 0.85),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: AnimatedRotation(
                        turns: isOpen ? 0.125 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: Icon(
                          Icons.add,
                          size: isRail ? 22.0 : 28.0,
                          color: palette.onAccent,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
