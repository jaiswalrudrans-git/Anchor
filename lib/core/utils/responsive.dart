import 'package:flutter/material.dart';
import '../constants/dimens.dart';

/// Screen size classes according to Material 3 responsive design.
enum SizeClass {
  compact,  // < 600 dp (Phones, portrait)
  medium,   // 600–899 dp (Tablets, foldables, narrow desktop windows)
  expanded, // >= 900 dp (Desktop, landscape tablets)
}

/// Centralized responsive breakpoint calculations.
class Breakpoints {
  Breakpoints._();

  static const double compactMax = 600.0;
  static const double mediumMax = 900.0;

  static const double maxContentWidth = 1100.0;
  static const double maxSheetDialogWidth = 480.0;

  /// Returns the [SizeClass] for a given width.
  static SizeClass fromWidth(double width) {
    if (width < compactMax) {
      return SizeClass.compact;
    } else if (width < mediumMax) {
      return SizeClass.medium;
    } else {
      return SizeClass.expanded;
    }
  }

  /// Returns the [SizeClass] using the current [BuildContext].
  static SizeClass of(BuildContext context) {
    return fromWidth(MediaQuery.sizeOf(context).width);
  }

  /// Horizontal padding according to size class (16 / 24 / 32).
  static double horizontalPadding(SizeClass sizeClass) {
    switch (sizeClass) {
      case SizeClass.compact:
        return 16.0;
      case SizeClass.medium:
        return 24.0;
      case SizeClass.expanded:
        return 32.0;
    }
  }

  /// Convenience helpers
  static bool isCompact(BuildContext context) => of(context) == SizeClass.compact;
  static bool isMedium(BuildContext context) => of(context) == SizeClass.medium;
  static bool isExpanded(BuildContext context) => of(context) == SizeClass.expanded;
}

/// Centralized shell navigation metrics for floating dock layout & clearance.
class ShellMetrics {
  ShellMetrics._();

  /// Dock bar height (68 dp default, 56 dp on short screens < 480 dp).
  static double dockHeight(BuildContext context) {
    final isShort = MediaQuery.sizeOf(context).height < 480;
    return isShort ? AppDimens.dockHeightShort : AppDimens.dockHeight;
  }

  /// Total vertical height occupied by the dock including margins and safe-area inset.
  static double dockTotalHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isShort = mediaQuery.size.height < 480;
    final dHeight = isShort ? AppDimens.dockHeightShort : AppDimens.dockHeight;
    final safeBottom = mediaQuery.padding.bottom;
    return dHeight + AppDimens.dockBottomOffset + safeBottom;
  }

  /// Recommended bottom padding for scroll views and page containers on compact screens.
  static double contentBottomPadding(BuildContext context) {
    return dockTotalHeight(context) + 16.0;
  }
}
