import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';

import 'dimens.dart';

// =============================================================================
// 1. ACCENT ENUM & CONTRAST CALCULATION
// =============================================================================

enum AppAccent {
  iris('iris', 'Iris', Color(0xFF7556E8), Color(0xFFA68BFF)),
  jade('jade', 'Jade', Color(0xFF10A877), Color(0xFF38D9A0)),
  ember('ember', 'Ember', Color(0xFFE5593F), Color(0xFFFF846A)),
  saffron('saffron', 'Saffron', Color(0xFFE7A116), Color(0xFFF6BE45)),
  rose('rose', 'Rose', Color(0xFFD94A7C), Color(0xFFFF86AA)),
  lagoon('lagoon', 'Lagoon', Color(0xFF0C9CA8), Color(0xFF4AD0DB)),
  plum('plum', 'Plum', Color(0xFFA23FB8), Color(0xFFD58BEA));

  final String id;
  final String displayName;
  final Color lightColor;
  final Color darkColor;

  const AppAccent(this.id, this.displayName, this.lightColor, this.darkColor);

  Color colorFor(Brightness brightness) =>
      brightness == Brightness.light ? lightColor : darkColor;

  static AppAccent fromId(String? id) {
    if (id == null) return AppAccent.iris;
    return AppAccent.values.firstWhere(
      (a) => a.id.toLowerCase() == id.trim().toLowerCase(),
      orElse: () => AppAccent.iris,
    );
  }
}

/// WCAG 2.1 relative luminance and contrast calculations.
class ContrastHelper {
  ContrastHelper._();

  static double _channelToLinear(double val) {
    return val <= 0.04045
        ? val / 12.92
        : math.pow((val + 0.055) / 1.055, 2.4).toDouble();
  }

  static double relativeLuminance(Color color) {
    final r = _channelToLinear(color.r);
    final g = _channelToLinear(color.g);
    final b = _channelToLinear(color.b);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double contrastRatio(Color c1, Color c2) {
    final l1 = relativeLuminance(c1);
    final l2 = relativeLuminance(c2);
    final lighter = math.max(l1, l2);
    final darker = math.min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Automatically picks `#FFFFFF` or `#111111` for >= 4.5:1 WCAG contrast against [accent].
  static Color onAccent(Color accent) {
    const white = Color(0xFFFFFFFF);
    const darkText = Color(0xFF111111);

    final crWhite = contrastRatio(accent, white);
    final crDark = contrastRatio(accent, darkText);

    if (crWhite >= 4.5 && crDark < 4.5) return white;
    if (crDark >= 4.5 && crWhite < 4.5) return darkText;
    return crWhite >= crDark ? white : darkText;
  }
}

// =============================================================================
// 2. THEME EXTENSION: AppPalette
// =============================================================================

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  // Neutrals
  final Color background;
  final Color card;
  final Color cardRaised;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  // Accent
  final Color accent;
  final Color accentSoft;
  final Color onAccent;

  // Segment / Pill selection tokens
  final Color selectedFill;
  final Color onSelected;

  // Disabled & Scrim tokens
  final Color disabledForeground;
  final Color disabledFill;
  final Color scrim;

  // Semantic
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;
  final Color onDanger;

  const AppPalette({
    required this.background,
    required this.card,
    required this.cardRaised,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.selectedFill,
    required this.onSelected,
    required this.disabledForeground,
    required this.disabledFill,
    required this.scrim,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.onDanger,
  });

  /// Convenience getter determining whether the palette represents dark mode.
  bool get isDark => ContrastHelper.relativeLuminance(background) < 0.2;

  factory AppPalette.light(AppAccent appAccent) {
    const cardBg = Color(0xFFF4F4F5);
    final accentCol = appAccent.lightColor;
    const successCol = Color(0xFF2E9E6A);
    const warningCol = Color(0xFFD98E04);
    const dangerCol = Color(0xFFD64545);

    return AppPalette(
      background: const Color(0xFFFFFFFF),
      card: cardBg,
      cardRaised: const Color(0xFFFFFFFF),
      border: const Color(0xFFE4E4E7),
      textPrimary: const Color(0xFF111111),
      textSecondary: const Color(0xFF71717A),
      textMuted: const Color(0xFFA1A1AA),
      accent: accentCol,
      accentSoft: Color.alphaBlend(accentCol.withValues(alpha: 0.14), cardBg),
      onAccent: ContrastHelper.onAccent(accentCol),
      selectedFill: const Color(0xFF111111),
      onSelected: const Color(0xFFFFFFFF),
      disabledForeground: const Color(0x61111111),
      disabledFill: const Color(0x1F111111),
      scrim: const Color(0x99000000),
      success: successCol,
      successSoft: Color.alphaBlend(successCol.withValues(alpha: 0.14), cardBg),
      warning: warningCol,
      warningSoft: Color.alphaBlend(warningCol.withValues(alpha: 0.14), cardBg),
      danger: dangerCol,
      dangerSoft: Color.alphaBlend(dangerCol.withValues(alpha: 0.14), cardBg),
      onDanger: const Color(0xFFFFFFFF),
    );
  }

  factory AppPalette.dark(AppAccent appAccent) {
    const cardBg = Color(0xFF17171A);
    const bg = Color(0xFF0E0E10);
    final accentCol = appAccent.darkColor;
    const successCol = Color(0xFF4CC38A);
    const warningCol = Color(0xFFF2B33D);
    const dangerCol = Color(0xFFFF7A7A);

    // Debug assertion ensuring dark neutrals are dark
    assert(() {
      final bgLum = ContrastHelper.relativeLuminance(bg);
      final cardLum = ContrastHelper.relativeLuminance(cardBg);
      assert(
        bgLum < 0.1,
        'Dark palette background luminance ($bgLum) must be < 0.1',
      );
      assert(
        cardLum < 0.1,
        'Dark palette card luminance ($cardLum) must be < 0.1',
      );
      return true;
    }());

    return AppPalette(
      background: bg,
      card: cardBg,
      cardRaised: const Color(0xFF1E1E22),
      border: const Color(0xFF26262B),
      textPrimary: const Color(0xFFEDEDED),
      textSecondary: const Color(0xFF9A9AA3),
      textMuted: const Color(0xFF6B6B73),
      accent: accentCol,
      accentSoft: Color.alphaBlend(accentCol.withValues(alpha: 0.20), cardBg),
      onAccent: ContrastHelper.onAccent(accentCol),
      selectedFill: accentCol,
      onSelected: ContrastHelper.onAccent(accentCol),
      disabledForeground: const Color(0x61EDEDED),
      disabledFill: const Color(0x14EDEDED),
      scrim: const Color(0x99000000),
      success: successCol,
      successSoft: Color.alphaBlend(successCol.withValues(alpha: 0.20), cardBg),
      warning: warningCol,
      warningSoft: Color.alphaBlend(warningCol.withValues(alpha: 0.20), cardBg),
      danger: dangerCol,
      dangerSoft: Color.alphaBlend(dangerCol.withValues(alpha: 0.20), cardBg),
      onDanger: const Color(0xFFFFFFFF),
    );
  }

  @override
  AppPalette copyWith({
    Color? background,
    Color? card,
    Color? cardRaised,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accent,
    Color? accentSoft,
    Color? onAccent,
    Color? selectedFill,
    Color? onSelected,
    Color? disabledForeground,
    Color? disabledFill,
    Color? scrim,
    Color? success,
    Color? successSoft,
    Color? warning,
    Color? warningSoft,
    Color? danger,
    Color? dangerSoft,
    Color? onDanger,
  }) {
    return AppPalette(
      background: background ?? this.background,
      card: card ?? this.card,
      cardRaised: cardRaised ?? this.cardRaised,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      onAccent: onAccent ?? this.onAccent,
      selectedFill: selectedFill ?? this.selectedFill,
      onSelected: onSelected ?? this.onSelected,
      disabledForeground: disabledForeground ?? this.disabledForeground,
      disabledFill: disabledFill ?? this.disabledFill,
      scrim: scrim ?? this.scrim,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      onDanger: onDanger ?? this.onDanger,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardRaised: Color.lerp(cardRaised, other.cardRaised, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      selectedFill: Color.lerp(selectedFill, other.selectedFill, t)!,
      onSelected: Color.lerp(onSelected, other.onSelected, t)!,
      disabledForeground: Color.lerp(
        disabledForeground,
        other.disabledForeground,
        t,
      )!,
      disabledFill: Color.lerp(disabledFill, other.disabledFill, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
    );
  }
}

extension AppPaletteX on BuildContext {
  AppPalette get palette {
    final p = Theme.of(this).extension<AppPalette>();
    return p ?? AppPalette.light(AppAccent.iris);
  }
}

// =============================================================================
// 3. TYPOGRAPHY & TABULAR FIGURES
// =============================================================================

class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Inter';
  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  static TextTheme buildTextTheme(AppPalette palette) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 32,
        height: 38 / 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: palette.textPrimary,
      ),
      displayMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 28,
        height: 34 / 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        color: palette.textPrimary,
      ),
      displaySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 24,
        height: 30 / 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: palette.textPrimary,
      ),
      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: palette.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 20,
        height: 26 / 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: palette.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        height: 24 / 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: palette.textPrimary,
      ),
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 20,
        height: 26 / 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: palette.textPrimary,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        height: 22 / 16,
        fontWeight: FontWeight.w500,
        color: palette.textPrimary,
      ),
      titleSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w500,
        color: palette.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        color: palette.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        color: palette.textPrimary,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w400,
        color: palette.textSecondary,
      ),
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w600,
        color: palette.textPrimary,
      ),
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
        color: palette.textSecondary,
      ),
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 11,
        height: 14 / 11,
        fontWeight: FontWeight.w400,
        color: palette.textMuted,
      ),
    );
  }
}

// =============================================================================
// 4. THEME BUILDER
// =============================================================================

ThemeData buildTheme(Brightness brightness, AppAccent accent) {
  final isLight = brightness == Brightness.light;
  final palette = isLight ? AppPalette.light(accent) : AppPalette.dark(accent);
  final textTheme = AppTypography.buildTextTheme(palette);

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: palette.accent,
    onPrimary: palette.onAccent,
    primaryContainer: palette.accentSoft,
    onPrimaryContainer: palette.accent,
    secondary: palette.accentSoft,
    onSecondary: palette.accent,
    secondaryContainer: palette.accentSoft,
    onSecondaryContainer: palette.accent,
    tertiary: palette.accent,
    onTertiary: palette.onAccent,
    tertiaryContainer: palette.accentSoft,
    onTertiaryContainer: palette.accent,
    error: palette.danger,
    onError: isLight ? const Color(0xFFFFFFFF) : palette.onAccent,
    errorContainer: palette.dangerSoft,
    onErrorContainer: palette.danger,
    surface: palette.background,
    onSurface: palette.textPrimary,
    onSurfaceVariant: palette.textSecondary,
    surfaceDim: palette.card,
    surfaceBright: palette.cardRaised,
    surfaceContainerLowest: palette.background,
    surfaceContainerLow: palette.card,
    surfaceContainer: palette.card,
    surfaceContainerHigh: palette.cardRaised,
    surfaceContainerHighest: palette.cardRaised,
    outline: palette.textMuted,
    outlineVariant: palette.border,
    shadow: isLight ? const Color(0x14000000) : const Color(0x00000000),
    scrim: palette.scrim,
    inverseSurface: isLight ? const Color(0xFF17171A) : const Color(0xFFF4F4F5),
    onInverseSurface: isLight
        ? const Color(0xFFEDEDED)
        : const Color(0xFF111111),
    inversePrimary: isLight ? accent.darkColor : accent.lightColor,
    surfaceTint: Colors.transparent,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: palette.background,
    canvasColor: palette.background,
    cardColor: palette.card,
    dividerColor: palette.border,
    disabledColor: palette.disabledForeground,
    hintColor: palette.textMuted,
    colorScheme: colorScheme,
    fontFamily: AppTypography.fontFamily,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    extensions: [palette],
    splashFactory: NoSplash.splashFactory,
    splashColor: palette.accent.withValues(alpha: 0.12),
    highlightColor: Colors.transparent,

    // Icon Themes
    iconTheme: IconThemeData(color: palette.textPrimary, size: 24),
    primaryIconTheme: IconThemeData(color: palette.textPrimary, size: 24),

    // Text Selection
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: palette.accent,
      selectionColor: palette.accent.withValues(alpha: 0.35),
      selectionHandleColor: palette.accent,
    ),

    // App Bar
    appBarTheme: AppBarTheme(
      backgroundColor: palette.background,
      foregroundColor: palette.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      iconTheme: IconThemeData(color: palette.textPrimary, size: 22),
      actionsIconTheme: IconThemeData(color: palette.textPrimary, size: 22),
      systemOverlayStyle: isLight
          ? SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: palette.background,
              systemNavigationBarIconBrightness: Brightness.dark,
            )
          : SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: palette.background,
              systemNavigationBarIconBrightness: Brightness.light,
            ),
      titleTextStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: palette.textPrimary,
        letterSpacing: -0.2,
      ),
      shape: Border(
        bottom: BorderSide(color: palette.border, width: AppDimens.hairline),
      ),
    ),

    // Card
    cardTheme: CardThemeData(
      color: palette.card,
      surfaceTintColor: Colors.transparent,
      elevation: AppDimens.elevationFlat,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: palette.border, width: AppDimens.hairline),
        borderRadius: AppDimens.borderRadiusMd,
      ),
    ),

    // List Tile
    listTileTheme: ListTileThemeData(
      iconColor: palette.textPrimary,
      textColor: palette.textPrimary,
      selectedColor: palette.accent,
      tileColor: Colors.transparent,
    ),

    // Expansion Tile
    expansionTileTheme: ExpansionTileThemeData(
      iconColor: palette.textPrimary,
      collapsedIconColor: palette.textSecondary,
      textColor: palette.textPrimary,
      collapsedTextColor: palette.textPrimary,
      backgroundColor: Colors.transparent,
      collapsedBackgroundColor: Colors.transparent,
      shape: const Border(),
      collapsedShape: const Border(),
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: palette.onAccent,
        disabledBackgroundColor: palette.disabledFill,
        disabledForegroundColor: palette.disabledForeground,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: AppDimens.borderRadiusMd),
        textStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.textPrimary,
        backgroundColor: Colors.transparent,
        disabledForegroundColor: palette.disabledForeground,
        elevation: 0,
        side: BorderSide(color: palette.border, width: AppDimens.hairline),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: AppDimens.borderRadiusMd),
        textStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: palette.onAccent,
        disabledBackgroundColor: palette.disabledFill,
        disabledForegroundColor: palette.disabledForeground,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppDimens.borderRadiusMd),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.accent,
        disabledForegroundColor: palette.disabledForeground,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: AppDimens.borderRadiusSm),
        textStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: palette.textPrimary,
        disabledForegroundColor: palette.disabledForeground,
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: palette.accent,
      foregroundColor: palette.onAccent,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppDimens.borderRadiusLg),
    ),

    // Segmented Button
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.selectedFill;
          }
          return Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.onSelected;
          }
          return palette.textSecondary;
        }),
        iconColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.onSelected;
          }
          return palette.textSecondary;
        }),
        side: WidgetStateProperty.all(
          BorderSide(color: palette.border, width: AppDimens.hairline),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: AppDimens.borderRadiusMd),
        ),
      ),
    ),

    // Chips
    chipTheme: ChipThemeData(
      backgroundColor: palette.card,
      deleteIconColor: palette.textSecondary,
      disabledColor: palette.disabledFill,
      selectedColor: palette.accent,
      secondarySelectedColor: palette.accentSoft,
      shadowColor: Colors.transparent,
      selectedShadowColor: Colors.transparent,
      checkmarkColor: palette.onAccent,
      labelStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        color: palette.textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      secondaryLabelStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        color: palette.onAccent,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      side: BorderSide(color: palette.border, width: AppDimens.hairline),
      shape: RoundedRectangleBorder(borderRadius: AppDimens.borderRadiusSm),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),

    // Input / Form Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.cardRaised,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      hintStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        color: palette.textMuted,
        fontSize: 14,
      ),
      labelStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        color: palette.textSecondary,
        fontSize: 14,
      ),
      floatingLabelStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        color: palette.accent,
        fontSize: 14,
      ),
      helperStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        color: palette.textMuted,
        fontSize: 12,
      ),
      errorStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        color: palette.danger,
        fontSize: 12,
      ),
      prefixIconColor: palette.textSecondary,
      suffixIconColor: palette.textSecondary,
      border: OutlineInputBorder(
        borderRadius: AppDimens.borderRadiusMd,
        borderSide: BorderSide(
          color: palette.border,
          width: AppDimens.hairline,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppDimens.borderRadiusMd,
        borderSide: BorderSide(
          color: palette.border,
          width: AppDimens.hairline,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppDimens.borderRadiusMd,
        borderSide: BorderSide(color: palette.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppDimens.borderRadiusMd,
        borderSide: BorderSide(
          color: palette.danger,
          width: AppDimens.hairline,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppDimens.borderRadiusMd,
        borderSide: BorderSide(color: palette.danger, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: AppDimens.borderRadiusMd,
        borderSide: BorderSide(
          color: palette.border.withValues(alpha: 0.5),
          width: AppDimens.hairline,
        ),
      ),
    ),

    // Checkbox (rounded 6px, accent fill, onAccent check)
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      side: BorderSide(color: palette.border, width: 1.5),
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return palette.accent;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(palette.onAccent),
    ),

    // Radio
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return palette.accent;
        return palette.border;
      }),
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return palette.onAccent;
        return palette.textMuted;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return palette.accent;
        return palette.cardRaised;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.transparent;
        return palette.border;
      }),
    ),

    // Slider
    sliderTheme: SliderThemeData(
      activeTrackColor: palette.accent,
      inactiveTrackColor: palette.border,
      thumbColor: palette.accent,
      overlayColor: palette.accent.withValues(alpha: 0.14),
    ),

    // Progress Indicator
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: palette.accent,
      linearTrackColor: palette.border,
      circularTrackColor: palette.border,
      refreshBackgroundColor: palette.cardRaised,
    ),

    // Dialog & Bottom Sheet
    dialogTheme: DialogThemeData(
      backgroundColor: palette.cardRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: palette.border, width: AppDimens.hairline),
        borderRadius: AppDimens.borderRadiusLg,
      ),
      titleTextStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        color: palette.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        color: palette.textSecondary,
        fontSize: 14,
      ),
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.cardRaised,
      surfaceTintColor: Colors.transparent,
      elevation: AppDimens.elevationSheet,
      modalBarrierColor: palette.scrim,
      showDragHandle: true,
      dragHandleColor: palette.textMuted,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusXl),
        ),
      ),
    ),

    // Popup Menu & Menus
    popupMenuTheme: PopupMenuThemeData(
      color: palette.cardRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: palette.border, width: AppDimens.hairline),
        borderRadius: AppDimens.borderRadiusMd,
      ),
      textStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        color: palette.textPrimary,
        fontSize: 14,
      ),
    ),

    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(palette.cardRaised),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        elevation: WidgetStateProperty.all(4),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            side: BorderSide(color: palette.border, width: AppDimens.hairline),
            borderRadius: AppDimens.borderRadiusMd,
          ),
        ),
      ),
    ),

    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        color: palette.textPrimary,
        fontSize: 14,
      ),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(palette.cardRaised),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        elevation: WidgetStateProperty.all(4),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            side: BorderSide(color: palette.border, width: AppDimens.hairline),
            borderRadius: AppDimens.borderRadiusMd,
          ),
        ),
      ),
    ),

    // Date Picker & Time Picker
    datePickerTheme: DatePickerThemeData(
      backgroundColor: palette.cardRaised,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: palette.card,
      headerForegroundColor: palette.textPrimary,
      headerHeadlineStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        color: palette.textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      headerHelpStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        color: palette.textSecondary,
        fontSize: 12,
      ),
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return palette.onAccent;
        if (states.contains(WidgetState.disabled)) return palette.textMuted;
        return palette.textPrimary;
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return palette.accent;
        return Colors.transparent;
      }),
      todayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return palette.onAccent;
        return palette.accent;
      }),
      todayBorder: BorderSide(color: palette.accent, width: 1.5),
      yearForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return palette.onAccent;
        return palette.textPrimary;
      }),
      yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return palette.accent;
        return Colors.transparent;
      }),
      dividerColor: palette.border,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: palette.border, width: AppDimens.hairline),
        borderRadius: AppDimens.borderRadiusLg,
      ),
      cancelButtonStyle: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(palette.textSecondary),
      ),
      confirmButtonStyle: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(palette.accent),
      ),
    ),

    timePickerTheme: TimePickerThemeData(
      backgroundColor: palette.cardRaised,
      hourMinuteTextColor: palette.textPrimary,
      hourMinuteColor: palette.card,
      dialBackgroundColor: palette.card,
      dialHandColor: palette.accent,
      dialTextColor: palette.textPrimary,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: palette.border, width: AppDimens.hairline),
        borderRadius: AppDimens.borderRadiusLg,
      ),
    ),

    // Navigation Bar (< 600 dp)
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.background,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      indicatorColor: palette.accentSoft,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 22,
          color: isSelected ? palette.accent : palette.textSecondary,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? palette.accent : palette.textSecondary,
        );
      }),
    ),

    // Navigation Rail (>= 600 dp)
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: palette.background,
      elevation: 0,
      indicatorColor: palette.accentSoft,
      selectedIconTheme: IconThemeData(color: palette.accent, size: 22),
      unselectedIconTheme: IconThemeData(
        color: palette.textSecondary,
        size: 22,
      ),
      selectedLabelTextStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: palette.accent,
      ),
      unselectedLabelTextStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: palette.textSecondary,
      ),
    ),

    // Divider
    dividerTheme: DividerThemeData(
      color: palette.border,
      thickness: AppDimens.hairline,
      space: AppDimens.hairline,
    ),

    // Tooltip
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFF17171A) : const Color(0xFF1E1E22),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: palette.border, width: AppDimens.hairline),
      ),
      textStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        color: isLight ? const Color(0xFFEDEDED) : palette.textPrimary,
        fontSize: 12,
      ),
    ),

    // SnackBar
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: palette.cardRaised,
      actionTextColor: palette.accent,
      elevation: 4,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: palette.border, width: AppDimens.hairline),
        borderRadius: AppDimens.borderRadiusSm,
      ),
      contentTextStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        color: palette.textPrimary,
        fontSize: 14,
      ),
    ),
  );
}

// =============================================================================
// 5. THEME CONTROLLER & NOTIFIER
// =============================================================================

@immutable
class ThemeState {
  final ThemeMode mode;
  final AppAccent accent;

  const ThemeState({required this.mode, required this.accent});

  ThemeState copyWith({ThemeMode? mode, AppAccent? accent}) {
    return ThemeState(mode: mode ?? this.mode, accent: accent ?? this.accent);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeState &&
          runtimeType == other.runtimeType &&
          mode == other.mode &&
          accent == other.accent;

  @override
  int get hashCode => mode.hashCode ^ accent.hashCode;
}

class ThemeController extends Notifier<ThemeState> {
  static AppPalette currentPalette = AppPalette.light(AppAccent.iris);

  static void updateCurrentPalette(
    ThemeState state, [
    Brightness? platformBrightness,
  ]) {
    final isDark =
        state.mode == ThemeMode.dark ||
        (state.mode == ThemeMode.system &&
            platformBrightness == Brightness.dark);
    currentPalette = isDark
        ? AppPalette.dark(state.accent)
        : AppPalette.light(state.accent);
  }

  static void updateDesktopWindow(
    ThemeMode mode, [
    Brightness? platformBrightness,
  ]) {
    if (kIsWeb || !(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return;
    }
    final isDark =
        mode == ThemeMode.dark ||
        (mode == ThemeMode.system && platformBrightness == Brightness.dark);
    try {
      windowManager.setBackgroundColor(
        isDark ? const Color(0xFF0E0E10) : const Color(0xFFFFFFFF),
      );
      windowManager.setBrightness(isDark ? Brightness.dark : Brightness.light);
    } catch (_) {}
  }

  static const String keyMode = 'theme_mode';
  static const String keyAccent = 'theme_accent';
  static ThemeState? _cachedInitial;

  static void setInitialTheme(SharedPreferences prefs) {
    _cachedInitial = loadInitialTheme(prefs);
  }

  @override
  ThemeState build() {
    return _cachedInitial ?? loadInitialTheme();
  }

  static ThemeState loadInitialTheme([SharedPreferences? prefs]) {
    // Check --dart-define overrides first (for testing and build configs)
    const defineMode = String.fromEnvironment('THEME_MODE', defaultValue: '');
    const defineAccent = String.fromEnvironment(
      'THEME_ACCENT',
      defaultValue: '',
    );

    ThemeMode mode = ThemeMode.light;
    if (defineMode.isNotEmpty) {
      if (defineMode.toLowerCase() == 'dark') mode = ThemeMode.dark;
      if (defineMode.toLowerCase() == 'light') mode = ThemeMode.light;
      if (defineMode.toLowerCase() == 'system') mode = ThemeMode.system;
    } else if (prefs != null) {
      final savedMode = prefs.getString(keyMode);
      if (savedMode == 'dark') mode = ThemeMode.dark;
      if (savedMode == 'light') mode = ThemeMode.light;
      if (savedMode == 'system') mode = ThemeMode.system;
    }

    AppAccent accent = AppAccent.iris;
    if (defineAccent.isNotEmpty) {
      accent = AppAccent.fromId(defineAccent);
    } else if (prefs != null) {
      accent = AppAccent.fromId(prefs.getString(keyAccent));
    }

    return ThemeState(mode: mode, accent: accent);
  }

  Future<void> setThemeMode(ThemeMode newMode) async {
    state = state.copyWith(mode: newMode);
    final prefs = await SharedPreferences.getInstance();
    final modeStr = newMode == ThemeMode.dark
        ? 'dark'
        : (newMode == ThemeMode.light ? 'light' : 'system');
    await prefs.setString(keyMode, modeStr);
    _syncToCloud(modeStr, state.accent.id);
  }

  Future<void> setAccent(AppAccent newAccent) async {
    state = state.copyWith(accent: newAccent);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyAccent, newAccent.id);
    final modeStr = state.mode == ThemeMode.dark
        ? 'dark'
        : (state.mode == ThemeMode.light ? 'light' : 'system');
    _syncToCloud(modeStr, newAccent.id);
  }

  Future<void> _syncToCloud(String modeStr, String accentId) async {
    try {
      final client = Supabase.instance.client;
      if (client.auth.currentUser != null) {
        await client.auth.updateUser(
          UserAttributes(
            data: {
              'theme_mode': modeStr,
              'theme_accent': accentId,
              'theme_updated_at': DateTime.now().toUtc().toIso8601String(),
            },
          ),
        );
      }
    } catch (_) {
      // Best-effort; silent failure for offline use
    }
  }

  Future<void> syncFromCloudOnSignIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasLocalMode = prefs.containsKey(keyMode);
      final hasLocalAccent = prefs.containsKey(keyAccent);

      if (!hasLocalMode || !hasLocalAccent) {
        final client = Supabase.instance.client;
        final metadata = client.auth.currentUser?.userMetadata;
        if (metadata != null) {
          if (!hasLocalMode && metadata['theme_mode'] is String) {
            final mStr = metadata['theme_mode'] as String;
            ThemeMode? m;
            if (mStr == 'dark') m = ThemeMode.dark;
            if (mStr == 'light') m = ThemeMode.light;
            if (mStr == 'system') m = ThemeMode.system;
            if (m != null) {
              await prefs.setString(keyMode, mStr);
              state = state.copyWith(mode: m);
            }
          }
          if (!hasLocalAccent && metadata['theme_accent'] is String) {
            final a = AppAccent.fromId(metadata['theme_accent'] as String);
            await prefs.setString(keyAccent, a.id);
            state = state.copyWith(accent: a);
          }
        }
      }
    } catch (_) {
      // Silent failure
    }
  }
}

final themeControllerProvider = NotifierProvider<ThemeController, ThemeState>(
  () {
    return ThemeController();
  },
);

// =============================================================================
// 6. BACKWARDS COMPATIBILITY SHIM (AppColors & AppTheme)
// =============================================================================

/// Backwards compatibility tokens mapping to default monochrome wireframe.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF4F4F5);
  static const Color border = Color(0xFFE4E4E7);
  static const Color primaryText = Color(0xFF111111);
  static const Color secondaryText = Color(0xFF71717A);
  static const Color disabled = Color(0xFFA1A1AA);
  static const Color disabledText = Color(0xFFA1A1AA);
  static const Color progressFill = Color(0xFF111111);
  static const Color divider = Color(0xFFE4E4E7);
}

class AppTheme {
  AppTheme._();

  static const double maxRadius = 8.0;
  static final BorderRadius borderRadius8 = BorderRadius.circular(maxRadius);
  static const BorderSide borderSide1 = BorderSide(
    color: AppColors.border,
    width: 1.0,
  );

  static ThemeData get lightTheme =>
      buildTheme(Brightness.light, AppAccent.iris);
  static ThemeData get darkTheme => buildTheme(Brightness.dark, AppAccent.iris);
}
