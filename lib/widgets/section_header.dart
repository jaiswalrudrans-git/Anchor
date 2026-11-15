import 'package:flutter/material.dart';

import '../core/constants/dimens.dart';
import '../core/constants/theme.dart';

/// Polished section header with title, optional count badge/chip, and optional trailing action.
class SectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.count,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(vertical: AppDimens.space8),
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: AppDimens.space8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: palette.accentSoft,
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                border: Border.all(
                  color: palette.border,
                  width: AppDimens.hairline,
                ),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: palette.accent,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}
