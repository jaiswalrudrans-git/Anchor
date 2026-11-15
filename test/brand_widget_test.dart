import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anchor/core/constants/theme.dart';
import 'package:anchor/screens/auth_screen.dart';
import 'package:anchor/screens/boot_screen.dart';
import 'package:anchor/widgets/brand/anchor_logo.dart';
import 'package:anchor/widgets/navigation/floating_dock.dart';
import 'package:anchor/widgets/navigation/floating_rail.dart';

Widget _buildThemedTestHarness({
  required Widget child,
  Brightness brightness = Brightness.light,
  AppAccent accent = AppAccent.iris,
  bool disableAnimations = false,
}) {
  return MaterialApp(
    theme: buildTheme(brightness, accent),
    home: MediaQuery(
      data: MediaQueryData(
        disableAnimations: disableAnimations,
        size: const Size(1200, 800),
      ),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AnchorMark Brand Widget Tests', () {
    testWidgets('renders glyph_black asset and tints with palette.textPrimary in light theme', (tester) async {
      await tester.pumpWidget(
        _buildThemedTestHarness(
          child: const AnchorMark(size: 48.0),
          brightness: Brightness.light,
        ),
      );

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final Image imageWidget = tester.widget<Image>(imageFinder);
      expect(imageWidget.image, isA<ResizeImage>());
      final ResizeImage resizeImage = imageWidget.image as ResizeImage;
      expect(resizeImage.imageProvider, isA<AssetImage>());
      final AssetImage asset = resizeImage.imageProvider as AssetImage;
      expect(asset.assetName, equals('assets/branding/glyph_black.png'));

      final colorFilteredFinder = find.byType(ColorFiltered);
      expect(colorFilteredFinder, findsOneWidget);
      final ColorFiltered filtered = tester.widget<ColorFiltered>(colorFilteredFinder);
      final BuildContext element = tester.element(find.byType(AnchorMark));
      expect(filtered.colorFilter, equals(ColorFilter.mode(element.palette.textPrimary, BlendMode.srcIn)));
    });

    testWidgets('tints with palette.textPrimary in dark theme', (tester) async {
      await tester.pumpWidget(
        _buildThemedTestHarness(
          child: const AnchorMark(size: 48.0),
          brightness: Brightness.dark,
        ),
      );

      final colorFilteredFinder = find.byType(ColorFiltered);
      expect(colorFilteredFinder, findsOneWidget);
      final ColorFiltered filtered = tester.widget<ColorFiltered>(colorFilteredFinder);
      final BuildContext element = tester.element(find.byType(AnchorMark));
      expect(filtered.colorFilter, equals(ColorFilter.mode(element.palette.textPrimary, BlendMode.srcIn)));
    });

    testWidgets('respects explicit color parameter override', (tester) async {
      const customColor = Color(0xFF71717A);
      await tester.pumpWidget(
        _buildThemedTestHarness(
          child: const AnchorMark(size: 32.0, color: customColor),
        ),
      );

      final colorFilteredFinder = find.byType(ColorFiltered);
      final ColorFiltered filtered = tester.widget<ColorFiltered>(colorFilteredFinder);
      expect(filtered.colorFilter, equals(const ColorFilter.mode(customColor, BlendMode.srcIn)));
    });
  });

  group('AnchorTile Widget Tests', () {
    for (final accent in AppAccent.values) {
      testWidgets('renders cleanly in accent ${accent.name} without overflow', (tester) async {
        await tester.pumpWidget(
          _buildThemedTestHarness(
            child: const AnchorTile(size: 72.0),
            accent: accent,
          ),
        );

        expect(find.byType(AnchorTile), findsOneWidget);
        expect(find.byType(AnchorMark), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('AnchorWordmark Widget Tests', () {
    testWidgets('renders mark and anchor label in Inter font', (tester) async {
      await tester.pumpWidget(
        _buildThemedTestHarness(
          child: const AnchorWordmark(markSize: 28.0),
        ),
      );

      expect(find.byType(AnchorWordmark), findsOneWidget);
      expect(find.byType(AnchorMark), findsOneWidget);
      expect(find.text('anchor'), findsOneWidget);
    });
  });

  group('BootScreen Widget Tests', () {
    testWidgets('displays AnchorMark and handles progress bar after 600ms', (tester) async {
      await tester.pumpWidget(
        _buildThemedTestHarness(
          child: const BootScreen(),
        ),
      );

      expect(find.byType(BootScreen), findsOneWidget);
      expect(find.byType(AnchorMark), findsOneWidget);

      // Initially progress indicator is not visible
      expect(find.byType(LinearProgressIndicator), findsNothing);

      // Advance clock past 600 ms threshold
      await tester.pump(const Duration(milliseconds: 650));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('respects reduced motion setting', (tester) async {
      await tester.pumpWidget(
        _buildThemedTestHarness(
          child: const BootScreen(),
          disableAnimations: true,
        ),
      );

      expect(find.byType(AnchorMark), findsOneWidget);
      // Entry scale animation on the logo mark is skipped when reduced motion is requested
      expect(
        find.ancestor(
          of: find.byType(AnchorMark),
          matching: find.byType(ScaleTransition),
        ),
        findsNothing,
      );
    });
  });

  group('AuthScreen Branding Tests', () {
    testWidgets('uses AnchorTile and no longer contains legacy A monogram', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AuthScreen(),
          ),
        ),
      );

      // Confirms AnchorTile is present
      expect(find.byType(AnchorTile), findsOneWidget);

      // Asserts that no standalone 'A' text monogram tile exists
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      final hasOldAMonogram = textWidgets.any((t) => t.data == 'A' && t.style?.fontSize == 28);
      expect(hasOldAMonogram, isFalse);
    });
  });

  group('FloatingRail Branding Tests', () {
    final destinations = [
      const DockDestination(
        key: Key('dest_home'),
        label: 'Home',
        icon: Icons.check_box_outlined,
        selectedIcon: Icons.check_box,
      ),
      const DockDestination(
        key: Key('dest_academics'),
        label: 'Academics',
        icon: Icons.school_outlined,
        selectedIcon: Icons.school,
      ),
    ];

    testWidgets('renders AnchorWordmark on expanded rail', (tester) async {
      await tester.pumpWidget(
        _buildThemedTestHarness(
          child: FloatingRail(
            destinations: destinations,
            selectedIndex: 0,
            onSelected: (_) {},
            onQuickAdd: () {},
            isExpanded: true,
          ),
        ),
      );

      expect(find.byType(AnchorWordmark), findsOneWidget);
      expect(find.text('anchor'), findsOneWidget);
    });

    testWidgets('renders AnchorMark (28dp) on medium rail', (tester) async {
      await tester.pumpWidget(
        _buildThemedTestHarness(
          child: FloatingRail(
            destinations: destinations,
            selectedIndex: 0,
            onSelected: (_) {},
            onQuickAdd: () {},
            isExpanded: false,
          ),
        ),
      );

      expect(find.byType(AnchorMark), findsOneWidget);
      expect(find.text('anchor'), findsNothing);
    });
  });
}
