import 'package:flutter/material.dart';

import '../core/constants/dimens.dart';
import '../core/constants/theme.dart';

/// Compact metric card displaying an icon, prominent value, and description label.
class StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? iconColor;
  final VoidCallback? onTap;

  const StatChip({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final Widget content = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space12,
        vertical: AppDimens.space8,
      ),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: AppDimens.borderRadiusSm,
        border: Border.all(color: palette.border, width: AppDimens.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppDimens.iconMd,
            color: iconColor ?? palette.accent,
          ),
          const SizedBox(width: AppDimens.space8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: AppDimens.borderRadiusSm,
        child: content,
      );
    }

    return content;
  }
}
