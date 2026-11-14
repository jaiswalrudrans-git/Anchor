import 'package:flutter/material.dart';

/// Design tokens for the strict monochrome wireframe visual system.
class AppColors {
  AppColors._();

  /// Pure white background: `#FFFFFF`
  static const Color background = Color(0xFFFFFFFF);

  /// Surface / card fill: `#F4F4F5`
  static const Color surface = Color(0xFFF4F4F5);

  /// Border outline: `#E4E4E7`
  static const Color border = Color(0xFFE4E4E7);

  /// Primary text and action fill: `#111111`
  static const Color primaryText = Color(0xFF111111);

  /// Secondary text: `#71717A`
  static const Color secondaryText = Color(0xFF71717A);

  /// Future / disabled / placeholder: `#A1A1AA`
  static const Color disabled = Color(0xFFA1A1AA);
}

/// App-wide theme configuration.
/// Strict monochrome wireframe, elevation 0, max 8px border radius, light theme only.
class AppTheme {
  AppTheme._();

  static const double maxRadius = 8.0;
  static final BorderRadius borderRadius8 = BorderRadius.circular(maxRadius);
  static const BorderSide borderSide1 = BorderSide(color: AppColors.border, width: 1.0);

  static ThemeData get lightTheme {
    final baseColorScheme = ColorScheme.light(
      primary: AppColors.primaryText,
      onPrimary: AppColors.background,
      secondary: AppColors.primaryText,
      onSecondary: AppColors.background,
      surface: AppColors.background,
      onSurface: AppColors.primaryText,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      surfaceContainerHighest: AppColors.surface,
      error: AppColors.primaryText,
      onError: AppColors.background,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: baseColorScheme,
      fontFamily: null, // default platform font
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,

      // App bar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryText,
          letterSpacing: -0.2,
        ),
        shape: Border(bottom: borderSide1),
      ),

      // Card
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: borderSide1,
          borderRadius: borderRadius8,
        ),
      ),

      // Elevated button (Primary: #111111 fill, white text)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryText,
          foregroundColor: AppColors.background,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: borderRadius8),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined button (Secondary: outlined with #E4E4E7 border, #111111 text)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryText,
          backgroundColor: Colors.transparent,
          elevation: 0,
          side: borderSide1,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: borderRadius8),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Text button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryText,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: borderRadius8),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Input / Form fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: const TextStyle(color: AppColors.disabled, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.secondaryText, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: borderRadius8,
          borderSide: borderSide1,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius8,
          borderSide: borderSide1,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius8,
          borderSide: const BorderSide(color: AppColors.primaryText, width: 1.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius8,
          borderSide: const BorderSide(color: AppColors.primaryText, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadius8,
          borderSide: const BorderSide(color: AppColors.primaryText, width: 1.5),
        ),
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: AppColors.primaryText, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryText;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.background),
      ),

      // Navigation Bar (mobile < 700px)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.surface,
        indicatorShape: RoundedRectangleBorder(borderRadius: borderRadius8),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.primaryText : AppColors.secondaryText,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? AppColors.primaryText : AppColors.secondaryText,
            size: 22,
          );
        }),
      ),

      // Navigation Rail (desktop >= 700px)
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.background,
        elevation: 0,
        indicatorColor: AppColors.surface,
        indicatorShape: RoundedRectangleBorder(borderRadius: borderRadius8),
        labelType: NavigationRailLabelType.all,
        selectedLabelTextStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryText,
        ),
        unselectedLabelTextStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.secondaryText,
        ),
        selectedIconTheme: const IconThemeData(
          color: AppColors.primaryText,
          size: 22,
        ),
        unselectedIconTheme: const IconThemeData(
          color: AppColors.secondaryText,
          size: 22,
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.background,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: borderSide1,
          borderRadius: borderRadius8,
        ),
        titleTextStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryText,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.secondaryText,
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.background,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(maxRadius)),
        ),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primaryText,
        contentTextStyle: const TextStyle(color: AppColors.background, fontSize: 14),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: borderRadius8),
        behavior: SnackBarBehavior.floating,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        disabledColor: AppColors.surface,
        elevation: 0,
        pressElevation: 0,
        shape: RoundedRectangleBorder(
          side: borderSide1,
          borderRadius: borderRadius8,
        ),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.primaryText,
        ),
      ),

      // Segmented button
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          elevation: WidgetStateProperty.all(0),
          side: WidgetStateProperty.all(borderSide1),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: borderRadius8),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primaryText;
            }
            return AppColors.background;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.background;
            }
            return AppColors.primaryText;
          }),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // ExpansionTile
      expansionTileTheme: const ExpansionTileThemeData(
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        textColor: AppColors.primaryText,
        collapsedTextColor: AppColors.primaryText,
        iconColor: AppColors.primaryText,
        collapsedIconColor: AppColors.secondaryText,
        shape: Border(),
        collapsedShape: Border(),
      ),
    );
  }
}
