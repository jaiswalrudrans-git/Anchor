import 'package:flutter/material.dart';

/// Spacing, radius, elevation, and sizing tokens.
class AppDimens {
  AppDimens._();

  // 4-point spacing scale
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;

  // Radii
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;

  static final BorderRadius borderRadiusSm = BorderRadius.circular(radiusSm);
  static final BorderRadius borderRadiusMd = BorderRadius.circular(radiusMd);
  static final BorderRadius borderRadiusLg = BorderRadius.circular(radiusLg);
  static final BorderRadius borderRadiusXl = BorderRadius.circular(radiusXl);

  // Borders & Hairlines
  static const double hairline = 1.0;

  // Card padding
  static const double cardPadding = 16.0;

  // Icon sizes
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;

  // Touch target
  static const double minTouchTarget = 44.0;

  // Elevation
  static const double elevationFlat = 0.0;
  static const double elevationSheet = 4.0;

  // Floating dock tokens (Stage 2C)
  static const double dockHeight = 68.0;
  static const double dockRadius = 34.0;
  static const double dockHeightShort = 56.0;
  static const double dockRadiusShort = 28.0;
  static const double bubbleDiameter = 56.0;
  static const double bubbleDiameterShort = 48.0;
  static const double bubbleLift = 14.0;
  static const double bubbleLiftShort = 12.0;
  static const double notchGap = 6.0;
  static const double notchRadius = 34.0; // bubble radius 28 + gap 6 = 34
  static const double notchRadiusShort = 30.0; // bubble radius 24 + gap 6 = 30
  static const double shoulderWidth = 16.0;
  static const double plusSize = 60.0;
  static const double dockMarginHorizontal = 16.0;
  static const double dockGap = 12.0;
  static const double dockBottomOffset = 12.0;
}
