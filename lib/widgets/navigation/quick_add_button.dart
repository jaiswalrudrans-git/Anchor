import 'package:flutter/material.dart';

import '../../core/constants/dimens.dart';
import '../../core/constants/theme.dart';
import '../motion/pressable_scale.dart';

/// Floating round or extended Quick Add button.
/// Key: `quick_add_button`.
/// - 60 dp circle on compact/medium, or extended pill with 'Add' label on expanded.
/// - Plain custom button independent of the dock shape (no FloatingActionButton).
/// - Accent fill with onAccent plus icon.
/// - Rotates 45° (200 ms) while Quick Add sheet is open.
class QuickAddButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isOpen;
  final bool isExtended;
  final double size;

  const QuickAddButton({
    super.key,
    required this.onPressed,
    this.isOpen = false,
    this.isExtended = false,
    this.size = AppDimens.plusSize,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Semantics(
      label: 'Quick add',
      button: true,
      child: Tooltip(
        message: 'Quick add',
        child: PressableScale(
          onTap: onPressed,
          targetScale: 0.94,
          child: Container(
            key: const Key('quick_add_button'),
            height: isExtended ? 44.0 : size,
            width: isExtended ? null : size,
            padding: isExtended
                ? const EdgeInsets.symmetric(horizontal: 16.0)
                : EdgeInsets.zero,
            decoration: BoxDecoration(
              color: palette.accent,
              shape: isExtended ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: isExtended ? BorderRadius.circular(22.0) : null,
              border: Border.all(
                color: palette.background,
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.isDark
                      ? Colors.transparent
                      : palette.accent.withValues(alpha: 0.25),
                  blurRadius: 8.0,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: isExtended
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedRotation(
                        turns: isOpen ? 0.125 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: Icon(
                          Icons.add,
                          size: 22.0,
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
                    ],
                  )
                : Center(
                    child: AnimatedRotation(
                      turns: isOpen ? 0.125 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: Icon(
                        Icons.add,
                        size: 28.0,
                        color: palette.onAccent,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
