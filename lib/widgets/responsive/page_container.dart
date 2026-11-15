import 'package:flutter/material.dart';

import '../../core/utils/responsive.dart';

/// Centers page content with max width 1200, adaptive horizontal padding (16 / 24 / 32),
/// and bottom clearance on compact screens so nothing is hidden behind the bottom dock.
/// On desktop and tablets (>= 600 dp), uses 24 dp bottom padding.
class PageContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const PageContainer({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.maxContentWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final sizeClass = Breakpoints.of(context);
    final hPadding = Breakpoints.horizontalPadding(sizeClass);
    final isCompact = sizeClass == SizeClass.compact;

    final effectivePadding =
        padding ??
        EdgeInsets.fromLTRB(
          hPadding,
          16.0,
          hPadding,
          isCompact ? ShellMetrics.contentBottomPadding(context) : 24.0,
        );

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: effectivePadding, child: child),
      ),
    );
  }
}
