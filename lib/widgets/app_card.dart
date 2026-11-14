import 'package:flutter/material.dart';
import '../core/constants/dimens.dart';
import '../core/constants/theme.dart';
import 'motion/pressable_scale.dart';

/// Standard polished card surface across Anchor.
/// Uses `palette.card`, hairline `palette.border`, and radius md (12).
class AppCard extends StatelessWidget {
  final Widget? child;
  final Widget? header;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;

  const AppCard({
    super.key,
    this.child,
    this.header,
    this.trailing,
    this.padding = const EdgeInsets.all(AppDimens.cardPadding),
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    Widget cardBody = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? palette.card,
        borderRadius: AppDimens.borderRadiusMd,
        border: Border.all(
          color: borderColor ?? palette.border,
          width: AppDimens.hairline,
        ),
      ),
      child: (header == null && trailing == null)
          ? child
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (header != null || trailing != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (header != null) Expanded(child: header!),
                      ?trailing,
                    ],
                  ),
                  if (child != null) const SizedBox(height: AppDimens.space12),
                ],
                ?child,
              ],
            ),
    );

    if (onTap != null) {
      return PressableScale(
        onTap: onTap,
        child: cardBody,
      );
    }

    return cardBody;
  }
}
