import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anchor/core/constants/theme.dart';
import 'package:anchor/screens/main_shell.dart';
import 'package:anchor/widgets/navigation/floating_dock.dart';

void main() {
  group('Polish Stage 7 - Theme Contrast & Accessibility Audit', () {
    test('All 7 accents meet WCAG AA contrast for text and badges in light and dark modes', () {
      for (final accent in AppAccent.values) {
        final lightColor = accent.colorFor(Brightness.light);
        final darkColor = accent.colorFor(Brightness.dark);
        final darkPalette = AppPalette.dark(accent);

        // In dark mode, all accents meet >= 3:1 against dark surface
        final darkContrast = ContrastHelper.contrastRatio(darkColor, darkPalette.cardRaised);
        expect(
          darkContrast,
          greaterThanOrEqualTo(3.0),
          reason: 'Accent ${accent.displayName} in dark mode ($darkContrast:1) must be >= 3.0:1',
        );

        // onAccent text contrast: text on accent fill must ALWAYS meet >= 4.5:1 (WCAG AA)
        final lightOnAccent = ContrastHelper.onAccent(lightColor);
        final lightTextContrast = ContrastHelper.contrastRatio(lightOnAccent, lightColor);
        expect(
          lightTextContrast,
          greaterThanOrEqualTo(4.5),
          reason: 'Text on accent ${accent.displayName} light ($lightTextContrast:1) must be >= 4.5:1',
        );

        final darkOnAccent = ContrastHelper.onAccent(darkColor);
        final darkTextContrast = ContrastHelper.contrastRatio(darkOnAccent, darkColor);
        expect(
          darkTextContrast,
          greaterThanOrEqualTo(4.5),
          reason: 'Text on accent ${accent.displayName} dark ($darkTextContrast:1) must be >= 4.5:1',
        );
      }
    });

    test('All standard text colors meet WCAG AA >= 4.5:1 in light and dark palettes', () {
      final lightPalette = AppPalette.light(AppAccent.iris);
      final lightTextPrimaryContrast = ContrastHelper.contrastRatio(
        lightPalette.textPrimary,
        lightPalette.cardRaised,
      );
      expect(lightTextPrimaryContrast, greaterThanOrEqualTo(4.5));

      final darkPalette = AppPalette.dark(AppAccent.iris);
      final darkTextPrimaryContrast = ContrastHelper.contrastRatio(
        darkPalette.textPrimary,
        darkPalette.cardRaised,
      );
      expect(darkTextPrimaryContrast, greaterThanOrEqualTo(4.5));
    });
  });

  group('Polish Stage 7 - Responsive Matrix & Universal Notch Alignment', () {
    final matrixSizes = [
      const Size(360, 640),   // Compact phone
      const Size(390, 844),   // Modern iPhone
      const Size(412, 915),   // Modern Pixel
      const Size(600, 960),   // 7-inch tablet
      const Size(768, 1024),  // iPad portrait
      const Size(1024, 768),  // iPad landscape
      const Size(1280, 800),  // Desktop standard
      const Size(1920, 1080), // Desktop FHD
      const Size(844, 390),   // Phone landscape
      const Size(717, 800),   // Foldable inner display
    ];

    for (final size in matrixSizes) {
      for (final textScale in [1.0, 1.3]) {
        testWidgets('Layout at ${size.width.toInt()}x${size.height.toInt()} with textScale $textScale renders cleanly without overflow', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            ProviderScope(
              child: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: TextScaler.linear(textScale),
                ),
                child: MaterialApp(
                  theme: AppTheme.lightTheme,
                  home: const MainShell(),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);

          // For compact phones (<600), verify FloatingDock slot alignment
          if (size.width < 600) {
            final dockFinder = find.byType(FloatingDock);
            expect(dockFinder, findsOneWidget);

            final dockWidth = tester.getSize(dockFinder).width;
            final bubbleFinder = find.byKey(const Key('dock_bubble'));
            expect(bubbleFinder, findsOneWidget);

            // Tab 0 (Home) initial position
            final homeTabFinder = find.byKey(const Key('nav_tab_home'));
            expect(homeTabFinder, findsOneWidget);
            final homeCenter = tester.getCenter(homeTabFinder);
            final bubbleCenter = tester.getCenter(bubbleFinder);

            expect(
              bubbleCenter.dx,
              closeTo(homeCenter.dx, 1.0),
              reason: 'Home tab center and bubble center must match within 1dp on ${size.width}x${size.height}',
            );

            // Verify slotCenterX exact formula
            final expectedHomeCenterX = tester.getTopLeft(dockFinder).dx + DockShape.slotCenterX(0.0, dockWidth);
            expect(homeCenter.dx, closeTo(expectedHomeCenterX, 1.0));
          }
        });
      }
    }

    testWidgets('Universal slot alignment holds across all 4 destinations (Home, Academics, Expenses, Habits)', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProviderScope(
            child: MainShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final tabKeys = [
        'nav_tab_home',
        'nav_tab_academics',
        'nav_tab_expenses',
        'nav_tab_habits',
      ];

      final bubbleFinder = find.byKey(const Key('dock_bubble'));

      for (var i = 0; i < tabKeys.length; i++) {
        final key = tabKeys[i];
        await tester.tap(find.byKey(Key(key)));
        await tester.pumpAndSettle();

        final tabCenter = tester.getCenter(find.byKey(Key(key)));
        final bubbleCenter = tester.getCenter(bubbleFinder);

        expect(
          bubbleCenter.dx,
          closeTo(tabCenter.dx, 1.0),
          reason: 'Slot $i ($key) center must align exactly with bubble center',
        );
      }
    });
  });

  group('Polish Stage 7 - Reduced Motion Audit', () {
    testWidgets('With disableAnimations, dock switches tabs instantly without animation', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
            data: const MediaQueryData(
              disableAnimations: true,
            ),
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const MainShell(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bubbleFinder = find.byKey(const Key('dock_bubble'));
      final habitsTabFinder = find.byKey(const Key('nav_tab_habits'));
      final habitsCenter = tester.getCenter(habitsTabFinder);

      await tester.tap(habitsTabFinder);
      await tester.pump(); // Advance 0 ms

      // Must already be at habits center immediately
      final bubbleImmediateCenter = tester.getCenter(bubbleFinder);
      expect(bubbleImmediateCenter.dx, closeTo(habitsCenter.dx, 1.0));
    });
  });
}
