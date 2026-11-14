import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anchor/core/constants/theme.dart';
import 'package:anchor/core/utils/responsive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Polish Stage 1 - Theme & Contrast Engine Tests', () {
    test('WCAG contrast ratio >= 4.5:1 for onAccent on all 7 accents in both modes', () {
      for (final accent in AppAccent.values) {
        // Light mode
        final lightTheme = buildTheme(Brightness.light, accent);
        final lightPalette = lightTheme.extension<AppPalette>()!;
        final lightContrast = ContrastHelper.contrastRatio(
          lightPalette.onAccent,
          lightPalette.accent,
        );
        expect(
          lightContrast,
          greaterThanOrEqualTo(4.5),
          reason: 'Light accent ${accent.name} failed WCAG contrast: $lightContrast < 4.5:1',
        );

        // Dark mode
        final darkTheme = buildTheme(Brightness.dark, accent);
        final darkPalette = darkTheme.extension<AppPalette>()!;
        final darkContrast = ContrastHelper.contrastRatio(
          darkPalette.onAccent,
          darkPalette.accent,
        );
        expect(
          darkContrast,
          greaterThanOrEqualTo(4.5),
          reason: 'Dark accent ${accent.name} failed WCAG contrast: $darkContrast < 4.5:1',
        );
      }
    });

    test('WCAG contrast ratio >= 4.5:1 for textPrimary on background', () {
      for (final accent in AppAccent.values) {
        final lightPalette = buildTheme(Brightness.light, accent).extension<AppPalette>()!;
        final lightContrast = ContrastHelper.contrastRatio(
          lightPalette.textPrimary,
          lightPalette.background,
        );
        expect(lightContrast, greaterThanOrEqualTo(4.5));

        final darkPalette = buildTheme(Brightness.dark, accent).extension<AppPalette>()!;
        final darkContrast = ContrastHelper.contrastRatio(
          darkPalette.textPrimary,
          darkPalette.background,
        );
        expect(darkContrast, greaterThanOrEqualTo(4.5));
      }
    });

    test('AppPalette.lerp smoothly interpolates colors without crashing', () {
      final lightPalette = buildTheme(Brightness.light, AppAccent.iris).extension<AppPalette>()!;
      final darkPalette = buildTheme(Brightness.dark, AppAccent.iris).extension<AppPalette>()!;

      final mid = lightPalette.lerp(darkPalette, 0.5);
      expect(mid, isNotNull);
      expect(mid.accent, isNotNull);
      expect(mid.background, isNotNull);
      expect(mid.textPrimary, isNotNull);
    });

    test('ThemeController loads defaults and round-trips through SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final initial = ThemeController.loadInitialTheme(prefs);
      expect(initial.mode, ThemeMode.light);
      expect(initial.accent, AppAccent.iris);

      await prefs.setString(ThemeController.keyMode, 'dark');
      await prefs.setString(ThemeController.keyAccent, 'jade');

      final loaded = ThemeController.loadInitialTheme(prefs);
      expect(loaded.mode, ThemeMode.dark);
      expect(loaded.accent, AppAccent.jade);
    });
  });

  group('Polish Stage 1 - Responsive Breakpoints Tests', () {
    test('Breakpoints.fromWidth correctly classifies compact, medium, expanded', () {
      expect(Breakpoints.fromWidth(359), SizeClass.compact);
      expect(Breakpoints.fromWidth(599), SizeClass.compact);
      expect(Breakpoints.fromWidth(600), SizeClass.medium);
      expect(Breakpoints.fromWidth(899), SizeClass.medium);
      expect(Breakpoints.fromWidth(900), SizeClass.expanded);
      expect(Breakpoints.fromWidth(1200), SizeClass.expanded);
    });

    test('Breakpoints.horizontalPadding matches size class specs (16, 24, 32)', () {
      expect(Breakpoints.horizontalPadding(SizeClass.compact), 16.0);
      expect(Breakpoints.horizontalPadding(SizeClass.medium), 24.0);
      expect(Breakpoints.horizontalPadding(SizeClass.expanded), 32.0);
    });
  });
}
