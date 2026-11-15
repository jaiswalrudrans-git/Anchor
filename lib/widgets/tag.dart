import 'package:flutter/material.dart';

import '../core/constants/dimens.dart';
import '../core/constants/theme.dart';

/// Small pill badge for categories, subjects, or status chips.
class Tag extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;

  const Tag({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fg = color ?? palette.textSecondary;
    final bg = backgroundColor ?? palette.cardRaised;
    final bd = borderColor ?? palette.border;

    final Widget pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        border: Border.all(color: bd, width: AppDimens.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: fg,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: pill);
    }

    return pill;
  }
}
