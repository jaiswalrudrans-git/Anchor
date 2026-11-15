import 'package:flutter/material.dart';

import '../../core/constants/dimens.dart';
import '../../core/constants/theme.dart';
import '../../core/utils/responsive.dart';

/// Top bar for pages that aligns its title with the left edge of PageContainer
/// and its actions with the right edge across all viewports (compact, medium, expanded).
/// Height: 64 dp, 1 px bottom hairline border.
class PageTopBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  final Widget? leading;
  final double? height;

  const PageTopBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.height,
  });

  @override
  Size get preferredSize => Size.fromHeight(height ?? 56.0);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final sizeClass = Breakpoints.of(context);
    final isCompact = sizeClass == SizeClass.compact;
    final effectiveHeight = height ?? (isCompact ? 56.0 : 64.0);
    final hPadding = Breakpoints.horizontalPadding(sizeClass);

    return Container(
      height: effectiveHeight + MediaQuery.paddingOf(context).top,
      decoration: BoxDecoration(
        color: palette.background,
        border: Border(
          bottom: BorderSide(
            color: palette.border,
            width: AppDimens.hairline,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: Breakpoints.maxContentWidth,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPadding),
              child: SizedBox(
                height: effectiveHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: 8.0),
                    ],
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: DefaultTextStyle(
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: palette.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          child: title,
                        ),
                      ),
                    ),
                    if (actions != null && actions!.isNotEmpty) ...[
                      const SizedBox(width: 8.0),
                      ...actions!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
